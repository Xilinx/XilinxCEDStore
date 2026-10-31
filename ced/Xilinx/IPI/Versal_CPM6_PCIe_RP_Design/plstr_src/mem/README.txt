TYPE FILE:
1: read
0: write

DATA FILE:
For Writes: write the data required to be written
For Reads: any 32b value can be written to the file as filler

EXPECTED DATA FILE:
For Writes: any 32b value can be added as a filler
For Reads: write the expected value to be read back

ADDRESS FILE:
EP: {bdf[31:16], 8'b0, reg no[7:0]}
RP ctrl0: FC00xxxx
RP ctrl1: FC40xxxx

PS: For each transaction, all of the above FILES should be filled up