#Following are AXI Addresses. They are used to perform DMA transfers
NOC0_DDR_CH1=0X50000000000
NOC0_DDR_CH1_1=0x58000000000
NOC0_DDR_CH3=0x70000000000
NOC0_DDR_CH3_1=0x78000000000
NOC1_DDR_CH2=0x60000000000
NOC1_DDR_CH2_1=0x68000000000

#Following offsets are used to access various PMC regions using PCIe BAR2
RTCA_offset=0x14000
OCM_offset=0xC0000
QSPI_offset=0x1030000
SBI_BOOT_STREAM_offset=0x2100000
SBI_offset=0x1220000
CPM_offset=0x4000000
IPI_PSM_offset=0x310000
IPI_PMC_offset=0x320000
IPI_0_offset=0x330000
IPI_1_offset=0x340000
IPI_PMC_NOBUF_offset=0x390000

echo "-------------------------------------"
echo "  Getting Bus Device Function values"
echo "-------------------------------------"

# Set the device ID of the PCIe device
DEVICE_ID="10ee:"

# Search for the device by its ID and extract the bus, device, and function numbers
BUS_DEV_FUNC=$(lspci -d "$DEVICE_ID" | awk '{print $1}' | awk -F ':' '{print $1" "$2}' | awk -F '.' '{print $1" "$2}')

# Print the bus, device, and function numbers
echo "Bus, device, function: $BUS_DEV_FUNC"

read bus dev func <<< "$BUS_DEV_FUNC"
echo "Bus: $bus"
echo "Device: $dev"
echo "Function: $func"

echo "-------------------------------------------------------------------"
echo "     Clearing MSI-X interrupt initiated for previous H2C transfer"
echo "-------------------------------------------------------------------"

dma-ctl qdma$bus$dev$func reg write bar 2 0x1012C 0x1
dma-ctl qdma$bus$dev$func reg write bar 2 0x1012C 0x0


qid=3

echo "-------------------------------------"
echo "  Creating QDMA QID:$qid"
echo "-------------------------------------"

dma-ctl dev list
echo
echo -n "qmax:"
cat /sys/bus/pci/devices/0000\:$bus\:$dev.$func/qdma/qmax
echo
echo 512 > /sys/bus/pci/devices/0000\:$bus\:$dev.$func/qdma/qmax
echo -n "qmax:" 
cat /sys/bus/pci/devices/0000\:$bus\:$dev.$func/qdma/qmax
echo
dma-ctl dev list
echo

dma-ctl qdma$bus$dev$func q add idx $qid mode mm dir bi
dma-ctl qdma$bus$dev$func q start idx $qid dir bi

echo "-----------------------------------------"
echo "  Sending H2C-MM transfer using QID:$qid"
echo "-----------------------------------------"

dma-to-device -d /dev/qdma$bus$dev$func-MM-$qid -s 0x1388 -a 0x72000000000

echo "-------------------------------------"
echo "          Sending IPI Interrupt"
echo "-------------------------------------"

#The registers are programmed through PCIe BAR2. Offset to IPI registers is 0x300000.
#Writing 0x0 to IPI0_TRIG (IPI) Register
dma-ctl qdma$bus$dev$func reg write bar 2 0x300000 0x0
dma-ctl qdma$bus$dev$func reg read bar 2 0x300000

#Write CPM SMID (0x100 to 0x1FF) to IPI0 agent registers. – offset 0x30_0050 → IPI 0 Profile 1 for Writes and 0xFF30_0054 → IPI 0 Profile 2 for Reads
dma-ctl qdma$bus$dev$func reg write bar 2 0x300050 0x100
dma-ctl qdma$bus$dev$func reg write bar 2 0x300054 0x100

#Write APU SMID to () IPI1 agent register – 0xFF30_0058 → IPI 1 Profile 1 for Writes and 0xFF30_005C → IPI 1 Profile 2 for Reads
dma-ctl qdma$bus$dev$func reg write bar 2 0x300058 0x260
dma-ctl qdma$bus$dev$func reg write bar 2 0x30005C 0x260

#Write the following to IPI0 to IPI1 request message buffer starting at 0xFF3F_04C0.
#0xFF3F_04C0 - lower 32-bits of DDR address used in QDMA-H2C transfer.
#0xFF3F_04C4 - upper 32-bits of DDR address used in QDMA-H2C transfer.
#0xFF3F_04C8 - QID used in QDMA-H2C transfer.
#0xFF3F_04CC - Size QDMA-H2C transfer.
dma-ctl qdma$bus$dev$func reg write bar 2 0x3F04C0 0x0
dma-ctl qdma$bus$dev$func reg write bar 2 0x3F04C4 0x720
dma-ctl qdma$bus$dev$func reg write bar 2 0x3F04C8 0x1
dma-ctl qdma$bus$dev$func reg write bar 2 0x3F04CC 0x1388

#Write 1'b1 to bit 3 of IPI0_TRIG register at 0xFF330000.
dma-ctl qdma$bus$dev$func reg write bar 2 0x330000 0x8

#Read IPI0_OBS register at 0xFF330004. Bit 3 of this register should be 1'b1.
dma-ctl qdma$bus$dev$func reg read bar 2 0x330004

#Read IPI1_ISR register at 0xFF340010. Bit 2 of this register should be 1'b1.
dma-ctl qdma$bus$dev$func reg read bar 2 0x340010

