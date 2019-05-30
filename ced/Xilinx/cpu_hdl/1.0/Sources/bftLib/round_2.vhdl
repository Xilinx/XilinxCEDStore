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

-- This is round_2 of the FFT calculation 
-- Step size is 1 so X and X +2  are mixed together
-- X0 with X2, X1 with X3 and etc													
-- U is a constant with a bogus value - you will want to change it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;

library bftLib;
use bftLib.bftPackage.all;
		   
entity round_2 is 	  
    port ( 
        clk : in std_logic;
         x : in xType;
         xOut : out xType
       );		  
end entity round_2;

architecture aR2 of round_2 is	
constant u : uType := 
    ( X"F0F0",
      X"F0F0",
      X"F0F0",
      X"F0F0",
      X"F0F0",
      X"F0F0",
      X"F0F0",
      X"F0F0");

begin 
--This really should be rolled into two generate loops

ct0: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk, x =>x(0), xStep=>x(2), u=>u(0), xOut=>xOut(0), xOutStep =>xOut(2));
 
ct1: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk,  x =>x(1), xStep=>x(3), u=>u(1), xOut=>xOut(1), xOutStep =>xOut(3));
	 
ct2: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk,  x =>x(4), xStep=>x(6), u=>u(2), xOut=>xOut(4), xOutStep =>xOut(6));

ct3: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk,  x =>x(5), xStep=>x(7), u=>u(3), xOut=>xOut(5), xOutStep =>xOut(7));

ct4: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk,  x =>x(8), xStep=>x(10), u=>u(4), xOut=>xOut(8), xOutStep =>xOut(10));

ct5: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk,  x =>x(9), xStep=>x(11), u=>u(5), xOut=>xOut(9), xOutStep =>xOut(11));

ct6: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk,  x =>x(12), xStep=>x(14), u=>u(6), xOut=>xOut(12), xOutStep =>xOut(14));

ct7: entity bftLib.coreTransform(aCT)
 generic map (DATA_WIDTH=> DATA_WIDTH)
 port map (clk => clk,  x =>x(13), xStep=>x(15), u=>u(7), xOut=>xOut(13), xOutStep =>xOut(15));

end architecture aR2;
