#RTCA Regisers
echo "-------------------------------------"
echo "    Reading RTCA register space"
echo "-------------------------------------"
dma-ctl qdma01000 reg read bar 2 0x2014000
dma-ctl qdma01000 reg read bar 2 0x2014004
dma-ctl qdma01000 reg read bar 2 0x2014008
#OCM Memory
echo "-------------------------------------"
echo "    Accessing OCM memory space"
echo "-------------------------------------"
dma-ctl qdma01000 reg write bar 2 0xC0000 0xabcd
dma-ctl qdma01000 reg read bar 2 0xC0000
#QSPI
echo "-------------------------------------"
echo "    Reading QSPI register space"
echo "-------------------------------------"
dma-ctl qdma01000 reg read bar 2 0x1030000
dma-ctl qdma01000 reg read bar 2 0x10300A0
dma-ctl qdma01000 reg read bar 2 0x10300FC
dma-ctl qdma01000 reg read bar 2 0x1030104
#CPM
echo "-------------------------------------"
echo "    Reading CPM register space"
echo "-------------------------------------"
dma-ctl qdma01000 reg read bar 2 0x4D0200C
dma-ctl qdma01000 reg read bar 2 0x4E086E0
#SBI
echo "-------------------------------------"
echo "    Reading SBI register space"
echo "-------------------------------------"
dma-ctl qdma01000 reg read bar 2 0x1220000
dma-ctl qdma01000 reg read bar 2 0x1220004
dma-ctl qdma01000 reg read bar 2 0x1220008
dma-ctl qdma01000 reg read bar 2 0x122000C
dma-ctl qdma01000 reg read bar 2 0x1220500
