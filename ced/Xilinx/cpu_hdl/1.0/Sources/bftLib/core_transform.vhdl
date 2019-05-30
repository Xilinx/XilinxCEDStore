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

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;


entity coreTransform is 	  
    generic (
        DATA_WIDTH : integer := 16
       );
    port ( 
        clk : in std_logic;
         x, xStep, u : in std_logic_vector (DATA_WIDTH-1 downto 0);
         xOut, xOutStep : out std_logic_vector (DATA_WIDTH-1 downto 0)
       );		 
--synthesis packing can change the resutls greatly
--setting up some attributes to force the mapping I want
--attribute register_duplication : string;       
--attribute register_duplication of coreTransform : entity is "yes"; 
--attribute register_balancing : string;
--attribute register_balancing of coreTransform : entity is "yes";
----force a mapping to DSP48s
attribute use_dsp48 : string;
attribute use_dsp48 of coreTransform : entity is "yes";
----turn off resource sharing		
----with resource sharing off this will map to two dsp48s. With it on, a dsp48 and some logic.
attribute resource_sharing : string;
attribute resource_sharing of coreTransform : entity is "no";  

end entity coreTransform;

architecture aCT of coreTransform is

signal xReg, xStepReg, uReg : std_logic_vector (DATA_WIDTH-1 downto 0); 
signal xOutReg, xOutStepReg, xOutRegTemp, xOutStepRegTemp: std_logic_vector (2*DATA_WIDTH -1 downto 0);

begin 															  			 
    process (clk)
    begin
    if rising_edge(clk) then
		  xStepReg <= xStep;	 
          uReg <= u;
          xReg <= x;
    end if;
    end process;		  
    
   

    process (clk)
    begin	
    if rising_edge(clk) then
    	    xOutReg <=  SXT(xReg, 2*DATA_WIDTH) + uReg*xStepReg;
	  	    xOutStepReg <= SXT(xReg, 2*DATA_WIDTH) - uReg*xStepReg;
	end if;  	
	end process;
					
--        xOut <= xOutReg(DATA_WIDTH-1 downto 0) xor xOutReg(2*DATA_WIDTH-1 downto DATA_WIDTH);
--        xOutStep <= xOutStepReg(DATA_WIDTH-1 downto 0) xor xOutStepReg(2*DATA_WIDTH-1 downto DATA_WIDTH);
        xOut <= xOutReg(DATA_WIDTH-1 downto 0) xor xOutReg(2*DATA_WIDTH-1 downto DATA_WIDTH);
        xOutStep <= xOutStepReg(DATA_WIDTH-1 downto 0) xor xOutStepReg(2*DATA_WIDTH-1 downto DATA_WIDTH);

end architecture aCT;
