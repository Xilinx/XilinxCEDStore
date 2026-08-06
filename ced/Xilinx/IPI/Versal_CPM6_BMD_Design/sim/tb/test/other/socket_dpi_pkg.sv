/*
 * DPI-C Socket Package for SystemVerilog
 * Provides persistent socket connections for testbench communication
 *
 * Usage:
 *   1. Import this package: import socket_dpi_pkg::*;
 *   2. Create a server:     int handle = socket_server_create(12345);
 *      Or connect as client: int handle = socket_client_create("localhost", 12345);
 *   3. Send data:           socket_send(handle, data, length);
 *   4. Receive data:        int bytes = socket_recv(handle, buffer, max_len);
 *   5. Close when done:     socket_close(handle);
 */

package socket_dpi_pkg;

    // =========================================================================
    // DPI-C Import Declarations
    // =========================================================================

    /*
     * Create a socket server and wait for a client connection (blocking)
     * @param port - Port number to listen on
     * @return Socket handle (>= 0) on success, -1 on error
     */
    import "DPI-C" function int socket_server_create(input int port);

    /*
     * Create a socket client and connect to a server
     * @param host - Hostname or IP address to connect to
     * @param port - Port number to connect to
     * @return Socket handle (>= 0) on success, -1 on error
     */
    import "DPI-C" function int socket_client_create(input string host, input int port);

    /*
     * Send data over the socket
     * @param handle - Socket handle from create function
     * @param data   - Byte array to send
     * @param length - Number of bytes to send
     * @return Number of bytes sent on success, -1 on error
     */
    import "DPI-C" function int socket_send(
        input int handle,
        input byte data[],
        input int length
    );

    /*
     * Send a complete byte array over the socket
     * @param handle - Socket handle from create function
     * @param data   - Byte array to send (sends entire array)
     * @return Number of bytes sent on success, -1 on error
     */
    import "DPI-C" function int socket_send_bytes(
        input int handle,
        input byte data[]
    );

    /*
     * Receive data from the socket (blocking)
     * @param handle     - Socket handle from create function
     * @param data       - Buffer to receive data into
     * @param max_length - Maximum number of bytes to receive
     * @return Number of bytes received, 0 if connection closed, -1 on error
     */
    import "DPI-C" function int socket_recv(
        input int handle,
        output byte data[],
        input int max_length
    );

    /*
     * Receive exact number of bytes from socket (blocking until all received)
     * @param handle - Socket handle from create function
     * @param data   - Buffer to receive data into
     * @param length - Exact number of bytes to receive
     * @return Number of bytes received, -1 on error
     */
    import "DPI-C" function int socket_recv_exact(
        input int handle,
        output byte data[],
        input int length
    );

    /*
     * Check if data is available to receive (non-blocking)
     * @param handle     - Socket handle from create function
     * @param timeout_ms - Timeout in milliseconds (0 = non-blocking poll)
     * @return 1 if data available, 0 if no data, -1 on error
     */
    import "DPI-C" function int socket_poll(input int handle, input int timeout_ms);

    /*
     * Check if socket is still connected
     * @param handle - Socket handle from create function
     * @return 1 if connected, 0 if not connected
     */
    import "DPI-C" function int socket_is_connected(input int handle);

    /*
     * Close the socket connection
     * @param handle - Socket handle from create function
     * @return 0 on success, -1 on error
     */
    import "DPI-C" function int socket_close(input int handle);

    /*
     * Cleanup all sockets (call at end of simulation)
     */
    import "DPI-C" function void socket_cleanup();


    // =========================================================================
    // Helper Classes and Tasks
    // =========================================================================

    /*
     * Socket connection class for object-oriented usage
     */
    class socket_conn;
        protected int m_handle;
        protected bit m_connected;
        protected string m_name;

        function new(string name = "socket");
            m_handle = -1;
            m_connected = 0;
            m_name = name;
        endfunction

        // Connect as client
        function bit connect(string host, int port);
            if (m_connected) begin
                $display("[%s] Already connected", m_name);
                return 0;
            end
            m_handle = socket_client_create(host, port);
            m_connected = (m_handle >= 0);
            if (!m_connected)
                $error("[%s] Failed to connect to %s:%0d", m_name, host, port);
            return m_connected;
        endfunction

        // Listen as server
        function bit listen(int port);
            if (m_connected) begin
                $display("[%s] Already connected", m_name);
                return 0;
            end
            $display("[%s] Waiting for connection on port %0d...", m_name, port);
            m_handle = socket_server_create(port);
            m_connected = (m_handle >= 0);
            if (!m_connected)
                $error("[%s] Failed to create server on port %0d", m_name, port);
            return m_connected;
        endfunction

        // Send bytes
        function int send(byte data[], int length = -1);
            if (!m_connected) begin
                $error("[%s] Not connected", m_name);
                return -1;
            end
            if (length < 0) length = data.size();
            return socket_send(m_handle, data, length);
        endfunction

        // Send all bytes in array
        function int send_all(byte data[]);
            if (!m_connected) begin
                $error("[%s] Not connected", m_name);
                return -1;
            end
            return socket_send_bytes(m_handle, data);
        endfunction

        // Receive bytes (returns number of bytes received)
        function int recv(output byte data[], input int max_length);
            if (!m_connected) begin
                $error("[%s] Not connected", m_name);
                return -1;
            end
            data = new[max_length];
            return socket_recv(m_handle, data, max_length);
        endfunction

        // Receive exact number of bytes
        function int recv_exact(output byte data[], input int length);
            if (!m_connected) begin
                $error("[%s] Not connected", m_name);
                return -1;
            end
            data = new[length];
            return socket_recv_exact(m_handle, data, length);
        endfunction

        // Check if data available
        function bit has_data(int timeout_ms = 0);
            if (!m_connected) return 0;
            return (socket_poll(m_handle, timeout_ms) > 0);
        endfunction

        // Check if connected
        function bit is_connected();
            if (!m_connected) return 0;
            m_connected = (socket_is_connected(m_handle) != 0);
            return m_connected;
        endfunction

        // Close connection
        function void close();
            if (m_handle >= 0) begin
                socket_close(m_handle);
                m_handle = -1;
            end
            m_connected = 0;
        endfunction

        // Get handle for direct access
        function int get_handle();
            return m_handle;
        endfunction
    endclass


    // =========================================================================
    // Utility Functions
    // =========================================================================

    // Convert string to byte array
    function automatic void string_to_bytes(input string str, output byte data[]);
        data = new[str.len()];
        foreach (str[i])
            data[i] = str[i];
    endfunction

    // Convert byte array to string
    function automatic string bytes_to_string(input byte data[], input int length = -1);
        string str;
        int len;
        len = (length < 0) ? data.size() : length;
        str = "";
        for (int i = 0; i < len; i++)
            str = {str, string'(data[i])};
        return str;
    endfunction

    // Convert 32-bit integer to bytes (little-endian)
    function automatic void int_to_bytes(input int value, output byte data[4]);
        data[0] = value[7:0];
        data[1] = value[15:8];
        data[2] = value[23:16];
        data[3] = value[31:24];
    endfunction

    // Convert bytes to 32-bit integer (little-endian)
    function automatic int bytes_to_int(input byte data[4]);
        return {data[3], data[2], data[1], data[0]};
    endfunction

    // Send a string over the socket
    function automatic int socket_send_string(input int handle, input string str);
        byte data[];
        string_to_bytes(str, data);
        return socket_send_bytes(handle, data);
    endfunction

endpackage
