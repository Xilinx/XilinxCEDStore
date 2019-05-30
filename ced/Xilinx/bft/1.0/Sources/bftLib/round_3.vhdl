--/////////////////////////////////////////////////////////////////////////
--// Copyright (c) 2008 Xilinx, Inc.  All rights reserved.
--//
--//                 XILINX CONFIDENTIAL PROPERTY
--// This   document  contains  proprietary information  which   is
--// protected by  copyright. All rights  are reserved.  This notice
--// refers to original work by Xilinx, Inc. which may be derivitive
--// of other work distributed under license of the authors.  In the
--// case of derivitive work, nothing in this notice overrides the
--// original author's license agreeement.  Where applicable, the 
--// original license agreement is included in it's original 
--// unmodified form immediately below this header.
--//
--// Xilinx, Inc.
--// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A
--// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
--// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
--// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
--// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
--// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
--// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
--// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
--// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
--// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
--// AND FITNESS FOR A PARTICULAR PURPOSE.
--//
--/////////////////////////////////////////////////////////////////////////

-- This is round_3 of the FFT calculation 
-- Step size is 4 so X and X +4  are mixed together
-- X0 with X4, X1 with X5 and etc													
-- U is a constant with a bogus value - you will want to change it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;
	  
library bftLib;
use bftLib.bftPackage.all;	  

entity round_3 is 	  
    port ( 
        clk: in std_logic;
         x : in xType;
         xOut : out xType
       );		  
end entity round_3;

architecture aR3 of round_3 is	
constant u : uType := 
    (X"AA55",
     X"55AA",
     X"AA55",
     X"55AA",
     X"AA55",
     X"55AA",
     X"AA55",
     X"55AA");

begin 																					  
	
transformLoop: for N in 0 to 3 generate
    ct0: entity bftLib.coreTransform(aCT)
     generic map (DATA_WIDTH=> DATA_WIDTH)
     port map (clk => clk,  x =>x(N), xStep=>x(N+4), u=>u(N), xOut=>xOut(N), xOutStep =>xOut(N+4));

    ct1: entity bftLib.coreTransform(aCT)
     generic map (DATA_WIDTH=> DATA_WIDTH)
     port map (clk => clk,  x =>x(N+8), xStep=>x(N+12), u=>u(N+4), xOut=>xOut(N+8), xOutStep =>xOut(N+12));
end generate transformLoop;

end architecture aR3;
