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

-- This is round_1 of the FFT calculation 
-- Step size is 1 so X and X +1 are mixed together
-- X0 with X1, X2 with X3 and etc
-- U is a constant with a bogus value - you will want to change it

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;

library bftLib;
use bftLib.bftPackage.all;

entity round_1 is 	  
    port ( 
        clk: in std_logic;
         x : in xType;
         xOut  : out xType
       );		  
end entity round_1;

architecture aR1 of round_1 is	
constant u : uType := 
    (X"0123",
     X"4567",
     X"89AB",
     X"CDEF",
     X"0123",
     X"4567",
     X"89AB",
     X"CDEF");

begin 	

transformLoop: for N in 0 to 7 generate
    ct: entity bftLib.coreTransform(aCT)
     generic map (DATA_WIDTH=> DATA_WIDTH)
     port map (clk => clk, x =>x(2*N), xStep=>x(2*N+1), u=>u(N), xOut=>xOut(2*N), xOutStep =>xOut(2*N+1));
end generate transformLoop;

end architecture aR1;
