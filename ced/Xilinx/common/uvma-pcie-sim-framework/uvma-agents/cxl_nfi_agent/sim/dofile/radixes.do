# This will highlight when M2S-DH is present in BLUE 
radix define m2srwd {
  4'b1000 "1000" -color blue
  4'b0100 "0100" -color blue
  4'b0010 "0010" -color blue
  4'b0001 "0001" -color blue
  4'b11?? "ERR"  -color red
  4'b?11? "ERR"  -color red
  4'b??11 "ERR"  -color red
  4'b1??1 "ERR"  -color red
  4'b1?1? "ERR"  -color red
  4'b?1?1 "ERR"  -color red
}

# This will highlight when M2SReqs are present in ORANGE 
radix define m2sreq {
  1 "1" -color orange
}

# This will highlight when S2MNDRs are present in ORANGE 
radix define s2mndr {
  1 "1" -color orange
  2 "2" -color orange
  3 "3" -color orange
}

# This will highlight when S2MDRSs are present in GREEN 
radix define s2mdrs {
  1 "1" -color blue
  2 "2" -color blue
  3 "3" -color blue
}

