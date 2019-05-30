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

-- This is round_4 of the FFT calculation 
-- Step size is 4 so X and X +8  are mixed together
-- X0 with X8, X1 with X9 and etc													
-- U is a constant with a bogus value - you will want to change it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;
	  
library bftLib;
use bftLib.bftPackage.all;	  

entity round_4 is 	  
    generic (
        DATA_WIDTH : integer := 16
       );
    port ( 
        clk : in std_logic;
         x : in xType;
         xOut : out xType
       );		  
end entity round_4;

architecture aR4 of round_4 is	
constant u : uType := 
    (X"AF05",
     X"50FA",
     X"AE15",
     X"51EA",
     X"A2D5",
     X"5D2A",
     X"AC35",
     X"53CA");

begin 					 

transformLoop: for N in 0 to 7 generate
    ct: entity bftLib.coreTransform(aCT)
         generic map (DATA_WIDTH=> DATA_WIDTH)
         port map (clk => clk, x =>x(N), xStep=>x(N+8), u=>u(N), xOut=>xOut(N), xOutStep =>xOut(N+8));
end generate transformLoop; 

end architecture aR4;
