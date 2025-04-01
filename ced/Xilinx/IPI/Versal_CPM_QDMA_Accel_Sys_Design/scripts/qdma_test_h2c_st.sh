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

#Test variables
#Simple bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 1
#Csh bypass mode --> desc_bypass_en = 1, pfetch_bypass_en = 0
#Csh Internal mode --> desc_bypass_en = 0, pfetch_bypass_en = 0
desc_bypass_en=0
pfetch_bypass_en=0
trfr_size0=5000
trfr_size1=4096
trfr_size2=4000

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
if [ "$desc_bypass_en" -eq 1 ]; then
	if [ "$pfetch_bypass_en" -eq 1 ]; then
		qid=2
		echo "Set PL-design to operate in simple bypass mode --> c2h_dsc_byp_mode = 2'b10" 
		dma-ctl qdma$bus$dev$func reg write bar 2 0x10130 0x2
		dma-ctl qdma$bus$dev$func reg read bar 2 0x10130
		echo "Creating ST queue with C2H in simple bypass mode"
		dma-ctl qdma$bus$dev$func q add idx $qid dir bi mode st
		dma-ctl qdma$bus$dev$func q start idx $qid dir h2c
		echo "Start C2H Queue in Simple bypass mode - set desc_bypass_en and pfetch_bypass_en in SW context"
		dma-ctl qdma$bus$dev$func q start idx $qid dir c2h desc_bypass_en pfetch_bypass_en
		
		dma-to-device -d /dev/qdma$bus$dev$func-ST-$qid -s $trfr_size2 -c 1 -f ./h2c_data.txt
		dma-ctl qdma$bus$dev$func q dump idx $qid dir bi	
	else
		qid=1
		echo "Set PL-design to operate in Csh bypass mode --> c2h_dsc_byp_mode = 2'b01" 
		dma-ctl qdma$bus$dev$func reg write bar 2 0x10130 0x1
		dma-ctl qdma$bus$dev$func reg read bar 2 0x10130
		echo "Creating ST queue with C2H in Csh bypass mode"
		dma-ctl qdma$bus$dev$func q add idx $qid dir bi mode st
		dma-ctl qdma$bus$dev$func q start idx $qid dir h2c
		echo "Start C2H Queue in Csh bypass mode - set desc_bypass_en in SW context" 
		dma-ctl qdma$bus$dev$func q start idx $qid dir c2h desc_bypass_en
		
		dma-to-device -d /dev/qdma$bus$dev$func-ST-$qid -s $trfr_size1 -c 1 -f ./h2c_data.txt
		dma-ctl qdma$bus$dev$func q dump idx $qid dir bi
	fi
else
	qid=0
	echo "Set PL-design to operate in Csh Internal mode --> c2h_dsc_byp_mode = 2'b00" 
	dma-ctl qdma$bus$dev$func reg write bar 2 0x10130 0x0
	dma-ctl qdma$bus$dev$func reg read bar 2 0x10130
	echo "Creating ST queue with C2H in Csh Internal mode "
	dma-ctl qdma$bus$dev$func q add idx $qid dir bi mode st
	dma-ctl qdma$bus$dev$func q start idx $qid dir h2c
	echo "Start C2H Queue in Csh internal mode" 
	dma-ctl qdma$bus$dev$func q start idx $qid dir c2h
	
	dma-to-device -d /dev/qdma$bus$dev$func-ST-$qid -s $trfr_size0 -c 1 -f ./h2c_data.txt
	dma-ctl qdma$bus$dev$func q dump idx $qid dir bi
fi
	

