/*
 * DPI-C Socket Library for SystemVerilog
 * Provides persistent socket connections for testbench communication
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifdef _WIN32
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #pragma comment(lib, "ws2_32.lib")
    typedef int socklen_t;
    #define CLOSE_SOCKET closesocket
    #define SOCKET_ERROR_CODE WSAGetLastError()
#else
    #include <unistd.h>
    #include <sys/socket.h>
    #include <sys/types.h>
    #include <netinet/in.h>
    #include <netinet/tcp.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <fcntl.h>
    #include <poll.h>
    #define SOCKET int
    #define INVALID_SOCKET -1
    #define SOCKET_ERROR -1
    #define CLOSE_SOCKET close
    #define SOCKET_ERROR_CODE errno
#endif

#include "svdpi.h"

// Maximum number of concurrent socket connections
#define MAX_SOCKETS 16
#define RECV_BUFFER_SIZE 65536

// Socket connection structure
typedef struct {
    SOCKET sock;
    SOCKET server_sock;  // For server mode - the listening socket
    int is_server;
    int is_connected;
    char last_error[256];
} socket_conn_t;

static socket_conn_t sockets[MAX_SOCKETS];
static int initialized = 0;

// Initialize the socket library
static void init_socket_lib(void) {
    if (initialized) return;
    
#ifdef _WIN32
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        fprintf(stderr, "WSAStartup failed\n");
        return;
    }
#endif
    
    for (int i = 0; i < MAX_SOCKETS; i++) {
        sockets[i].sock = INVALID_SOCKET;
        sockets[i].server_sock = INVALID_SOCKET;
        sockets[i].is_server = 0;
        sockets[i].is_connected = 0;
        sockets[i].last_error[0] = '\0';
    }
    
    initialized = 1;
}

// Find a free socket slot
static int find_free_slot(void) {
    for (int i = 0; i < MAX_SOCKETS; i++) {
        if (sockets[i].sock == INVALID_SOCKET && sockets[i].server_sock == INVALID_SOCKET) {
            return i;
        }
    }
    return -1;
}

/*
 * Create a socket server and wait for a client connection
 * Returns: socket handle (>= 0) on success, -1 on error
 */
int socket_server_create(int port) {
    init_socket_lib();
    
    int slot = find_free_slot();
    if (slot < 0) {
        fprintf(stderr, "socket_server_create: No free socket slots\n");
        return -1;
    }
    
    SOCKET server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock == INVALID_SOCKET) {
        snprintf(sockets[slot].last_error, sizeof(sockets[slot].last_error),
                 "socket() failed: %d", SOCKET_ERROR_CODE);
        fprintf(stderr, "%s\n", sockets[slot].last_error);
        return -1;
    }
    
    // Allow socket reuse
    int opt = 1;
    setsockopt(server_sock, SOL_SOCKET, SO_REUSEADDR, (char*)&opt, sizeof(opt));
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    
    if (bind(server_sock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        snprintf(sockets[slot].last_error, sizeof(sockets[slot].last_error),
                 "bind() failed on port %d: %d", port, SOCKET_ERROR_CODE);
        fprintf(stderr, "%s\n", sockets[slot].last_error);
        CLOSE_SOCKET(server_sock);
        return -1;
    }
    
    if (listen(server_sock, 1) == SOCKET_ERROR) {
        snprintf(sockets[slot].last_error, sizeof(sockets[slot].last_error),
                 "listen() failed: %d", SOCKET_ERROR_CODE);
        fprintf(stderr, "%s\n", sockets[slot].last_error);
        CLOSE_SOCKET(server_sock);
        return -1;
    }
    
    printf("DPI Socket Server: Waiting for connection on port %d...\n", port);
    fflush(stdout);
    
    struct sockaddr_in client_addr;
    socklen_t client_len = sizeof(client_addr);
    SOCKET client_sock = accept(server_sock, (struct sockaddr*)&client_addr, &client_len);
    
    if (client_sock == INVALID_SOCKET) {
        snprintf(sockets[slot].last_error, sizeof(sockets[slot].last_error),
                 "accept() failed: %d", SOCKET_ERROR_CODE);
        fprintf(stderr, "%s\n", sockets[slot].last_error);
        CLOSE_SOCKET(server_sock);
        return -1;
    }
    
    // Disable Nagle's algorithm for lower latency
    int nodelay = 1;
    setsockopt(client_sock, IPPROTO_TCP, TCP_NODELAY, (char*)&nodelay, sizeof(nodelay));
    
    sockets[slot].sock = client_sock;
    sockets[slot].server_sock = server_sock;
    sockets[slot].is_server = 1;
    sockets[slot].is_connected = 1;
    
    printf("DPI Socket Server: Client connected from %s:%d (handle=%d)\n",
           inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port), slot);
    fflush(stdout);
    
    return slot;
}

/*
 * Create a socket client and connect to a server
 * Returns: socket handle (>= 0) on success, -1 on error
 */
int socket_client_create(const char* host, int port) {
    init_socket_lib();
    
    int slot = find_free_slot();
    if (slot < 0) {
        fprintf(stderr, "socket_client_create: No free socket slots\n");
        return -1;
    }
    
    SOCKET sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == INVALID_SOCKET) {
        snprintf(sockets[slot].last_error, sizeof(sockets[slot].last_error),
                 "socket() failed: %d", SOCKET_ERROR_CODE);
        fprintf(stderr, "%s\n", sockets[slot].last_error);
        return -1;
    }
    
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    
    // Try to parse as IP address first
    if (inet_pton(AF_INET, host, &addr.sin_addr) <= 0) {
        // Try hostname resolution
        struct hostent* he = gethostbyname(host);
        if (he == NULL) {
            snprintf(sockets[slot].last_error, sizeof(sockets[slot].last_error),
                     "Could not resolve hostname: %s", host);
            fprintf(stderr, "%s\n", sockets[slot].last_error);
            CLOSE_SOCKET(sock);
            return -1;
        }
        memcpy(&addr.sin_addr, he->h_addr_list[0], he->h_length);
    }
    
    printf("DPI Socket Client: Connecting to %s:%d...\n", host, port);
    fflush(stdout);
    
    if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) == SOCKET_ERROR) {
        snprintf(sockets[slot].last_error, sizeof(sockets[slot].last_error),
                 "connect() failed: %d", SOCKET_ERROR_CODE);
        fprintf(stderr, "%s\n", sockets[slot].last_error);
        CLOSE_SOCKET(sock);
        return -1;
    }
    
    // Disable Nagle's algorithm for lower latency
    int nodelay = 1;
    setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, (char*)&nodelay, sizeof(nodelay));
    
    sockets[slot].sock = sock;
    sockets[slot].server_sock = INVALID_SOCKET;
    sockets[slot].is_server = 0;
    sockets[slot].is_connected = 1;
    
    printf("DPI Socket Client: Connected (handle=%d)\n", slot);
    fflush(stdout);
    
    return slot;
}

/*
 * Send data over the socket
 * Returns: number of bytes sent on success, -1 on error
 */
int socket_send(int handle, const svOpenArrayHandle data, int length) {
    if (handle < 0 || handle >= MAX_SOCKETS || !sockets[handle].is_connected) {
        fprintf(stderr, "socket_send: Invalid handle %d\n", handle);
        return -1;
    }
    
    unsigned char* ptr = (unsigned char*)svGetArrayPtr(data);
    if (ptr == NULL) {
        fprintf(stderr, "socket_send: NULL data pointer\n");
        return -1;
    }
    
    int total_sent = 0;
    while (total_sent < length) {
        int sent = send(sockets[handle].sock, (char*)(ptr + total_sent), 
                       length - total_sent, 0);
        if (sent == SOCKET_ERROR) {
            snprintf(sockets[handle].last_error, sizeof(sockets[handle].last_error),
                     "send() failed: %d", SOCKET_ERROR_CODE);
            fprintf(stderr, "%s\n", sockets[handle].last_error);
            return -1;
        }
        total_sent += sent;
    }
    
    return total_sent;
}

/*
 * Send a byte array (alternative interface using dynamic array)
 * Returns: number of bytes sent on success, -1 on error
 */
int socket_send_bytes(int handle, const svOpenArrayHandle data) {
    if (handle < 0 || handle >= MAX_SOCKETS || !sockets[handle].is_connected) {
        fprintf(stderr, "socket_send_bytes: Invalid handle %d\n", handle);
        return -1;
    }
    
    int length = svSize(data, 1);
    unsigned char* ptr = (unsigned char*)svGetArrayPtr(data);
    
    if (ptr == NULL || length <= 0) {
        fprintf(stderr, "socket_send_bytes: Invalid data\n");
        return -1;
    }
    
    int total_sent = 0;
    while (total_sent < length) {
        int sent = send(sockets[handle].sock, (char*)(ptr + total_sent), 
                       length - total_sent, 0);
        if (sent == SOCKET_ERROR) {
            snprintf(sockets[handle].last_error, sizeof(sockets[handle].last_error),
                     "send() failed: %d", SOCKET_ERROR_CODE);
            fprintf(stderr, "%s\n", sockets[handle].last_error);
            return -1;
        }
        total_sent += sent;
    }
    
    return total_sent;
}

/*
 * Receive data from the socket (blocking)
 * Returns: number of bytes received on success, 0 on connection closed, -1 on error
 */
int socket_recv(int handle, const svOpenArrayHandle data, int max_length) {
    if (handle < 0 || handle >= MAX_SOCKETS || !sockets[handle].is_connected) {
        fprintf(stderr, "socket_recv: Invalid handle %d\n", handle);
        return -1;
    }
    
    unsigned char* ptr = (unsigned char*)svGetArrayPtr(data);
    if (ptr == NULL) {
        fprintf(stderr, "socket_recv: NULL data pointer\n");
        return -1;
    }
    
    int array_size = svSize(data, 1);
    if (max_length > array_size) {
        max_length = array_size;
    }
    
    int received = recv(sockets[handle].sock, (char*)ptr, max_length, 0);
    
    if (received == SOCKET_ERROR) {
        snprintf(sockets[handle].last_error, sizeof(sockets[handle].last_error),
                 "recv() failed: %d", SOCKET_ERROR_CODE);
        fprintf(stderr, "%s\n", sockets[handle].last_error);
        return -1;
    }
    
    if (received == 0) {
        printf("DPI Socket: Connection closed by peer (handle=%d)\n", handle);
        sockets[handle].is_connected = 0;
    }
    
    return received;
}

/*
 * Receive exact number of bytes from socket (blocking)
 * Returns: number of bytes received on success, -1 on error
 */
int socket_recv_exact(int handle, const svOpenArrayHandle data, int length) {
    if (handle < 0 || handle >= MAX_SOCKETS || !sockets[handle].is_connected) {
        fprintf(stderr, "socket_recv_exact: Invalid handle %d\n", handle);
        return -1;
    }
    
    unsigned char* ptr = (unsigned char*)svGetArrayPtr(data);
    if (ptr == NULL) {
        fprintf(stderr, "socket_recv_exact: NULL data pointer\n");
        return -1;
    }
    
    int array_size = svSize(data, 1);
    if (length > array_size) {
        fprintf(stderr, "socket_recv_exact: Requested %d bytes but array is only %d\n",
                length, array_size);
        return -1;
    }
    
    int total_received = 0;
    while (total_received < length) {
        int received = recv(sockets[handle].sock, (char*)(ptr + total_received),
                           length - total_received, 0);
        if (received == SOCKET_ERROR) {
            snprintf(sockets[handle].last_error, sizeof(sockets[handle].last_error),
                     "recv() failed: %d", SOCKET_ERROR_CODE);
            fprintf(stderr, "%s\n", sockets[handle].last_error);
            return -1;
        }
        if (received == 0) {
            printf("DPI Socket: Connection closed by peer (handle=%d)\n", handle);
            sockets[handle].is_connected = 0;
            return total_received;
        }
        total_received += received;
    }
    
    return total_received;
}

/*
 * Check if data is available to receive (non-blocking)
 * Returns: 1 if data available, 0 if no data, -1 on error
 */
int socket_poll(int handle, int timeout_ms) {
    if (handle < 0 || handle >= MAX_SOCKETS || !sockets[handle].is_connected) {
        return -1;
    }
    
#ifdef _WIN32
    fd_set readfds;
    FD_ZERO(&readfds);
    FD_SET(sockets[handle].sock, &readfds);
    
    struct timeval tv;
    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec = (timeout_ms % 1000) * 1000;
    
    int result = select(0, &readfds, NULL, NULL, &tv);
    if (result == SOCKET_ERROR) {
        return -1;
    }
    return (result > 0) ? 1 : 0;
#else
    struct pollfd pfd;
    pfd.fd = sockets[handle].sock;
    pfd.events = POLLIN;
    pfd.revents = 0;
    
    int result = poll(&pfd, 1, timeout_ms);
    if (result < 0) {
        return -1;
    }
    return (result > 0 && (pfd.revents & POLLIN)) ? 1 : 0;
#endif
}

/*
 * Check if socket is still connected
 * Returns: 1 if connected, 0 if not connected
 */
int socket_is_connected(int handle) {
    if (handle < 0 || handle >= MAX_SOCKETS) {
        return 0;
    }
    return sockets[handle].is_connected;
}

/*
 * Close the socket connection
 * Returns: 0 on success, -1 on error
 */
int socket_close(int handle) {
    if (handle < 0 || handle >= MAX_SOCKETS) {
        fprintf(stderr, "socket_close: Invalid handle %d\n", handle);
        return -1;
    }
    
    if (sockets[handle].sock != INVALID_SOCKET) {
        CLOSE_SOCKET(sockets[handle].sock);
        sockets[handle].sock = INVALID_SOCKET;
    }
    
    if (sockets[handle].server_sock != INVALID_SOCKET) {
        CLOSE_SOCKET(sockets[handle].server_sock);
        sockets[handle].server_sock = INVALID_SOCKET;
    }
    
    sockets[handle].is_connected = 0;
    sockets[handle].is_server = 0;
    
    printf("DPI Socket: Closed (handle=%d)\n", handle);
    fflush(stdout);
    
    return 0;
}

/*
 * Get the last error message for a socket
 */
void socket_get_error(int handle, char* error_msg, int max_len) {
    if (handle >= 0 && handle < MAX_SOCKETS) {
        strncpy(error_msg, sockets[handle].last_error, max_len - 1);
        error_msg[max_len - 1] = '\0';
    } else {
        strncpy(error_msg, "Invalid handle", max_len - 1);
        error_msg[max_len - 1] = '\0';
    }
}

/*
 * Cleanup all sockets (call at end of simulation)
 */
void socket_cleanup(void) {
    for (int i = 0; i < MAX_SOCKETS; i++) {
        if (sockets[i].sock != INVALID_SOCKET || sockets[i].server_sock != INVALID_SOCKET) {
            socket_close(i);
        }
    }
    
#ifdef _WIN32
    WSACleanup();
#endif
    
    initialized = 0;
    printf("DPI Socket: Cleanup complete\n");
    fflush(stdout);
}
