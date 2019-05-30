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

package bftPackage is
									
--Data_Width can be changed without too much trouble									
    constant DATA_WIDTH : integer := 16;	  
--Changing Stages will break things. You will need to make code modifications	  
    constant STAGES : integer := 16;		  
--Make a TYPE for handling the FFT data. It is easier then not. 
    type xType is array (integer range STAGES-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);
--Make a TYPE for handling the constant sine/cosine co-efficients 									  
    type uType is array (integer range (STAGES/2)-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);
end bftPackage;
