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

library bftLib;
use bftLib.bftPackage.all;

entity bft is 	  
    port ( 
        wbClk, bftClk, reset : in std_logic;
        wbDataForInput :in std_logic;
        wbWriteOut: in std_logic;
        wbDataForOutput : out std_logic; 
        wbInputData : in std_logic_vector (31 downto 0);
        wbOutputData : out std_logic_vector (31 downto 0);
        error : out std_logic
       );
       
attribute fsm_encoding :string;
attribute fsm_encoding of bft : entity is "one-hot" ;
end entity bft;

architecture aBFT of bft is 

component FifoBuffer
	port (
	din: IN std_logic_VECTOR(31 downto 0);
	rd_clk: IN std_logic;
	rd_en: IN std_logic;
	rst: IN std_logic;
	wr_clk: IN std_logic;
	wr_en: IN std_logic;
	dout: OUT std_logic_VECTOR(31 downto 0);
	empty: OUT std_logic;
	full: OUT std_logic);
end component;


signal rnd1_2, rnd2_3, rnd3_4, toBft, fromBft : xType;
							
type demuxType is array (integer range STAGES/2-1 downto 0) of std_logic_vector (2*DATA_WIDTH-1 downto 0);
signal demux : demuxType;
							
type fifoStateType is (s0,s1,s2,s3,s4,s5,s6,s7);
type demuxStateType is (stall, run);
signal loadState, loadNextState : fifoStateType;
signal readState, readNextSTate	: fifoStateType;	
signal demuxState : demuxStateType;
									
signal ingressFifoWrEn: std_logic;
signal validForEgressFifo : std_logic_vector (13 downto 0);  -- a shiftregister to keep track of valid BFT data. 
signal loadIngressFifo, ingressFifoFull, ingressFifoEmpty : std_logic_vector (STAGES/2 -1 downto 0);
signal egressFifoFull, egressFifoEmpty, readEgressFifo,fifoSelect : std_logic_vector (STAGES/2 -1 downto 0);
signal readIngressFifo, loadEgressFoo: std_logic; 
signal loadEgressFifo : std_logic_vector (7 downto 0); 

signal wbDataForInputReg : std_logic;	

--data needs two levels of pipelining.
signal wbInputDataStage0, wbInputDataStage1 : std_logic_vector (31 downto 0);

begin  

--get the data back in sync with the enable
process (wbClk)
 begin
    wbInputDataStage0 <= wbInputData;
    wbInputDataStage1 <= wbInputDataStage0;
end process;

--state machine to load data from the WB bus to the input fifos
process (wbClk)	  
begin
    if rising_edge(wbClk) then
	 
        if (reset = '1') then
        readIngressFifo <='1';
        loadState <= s0;
            wbDataForInputReg <= '0';
        else
        readIngressFifo <='0';        
            loadState <= loadNextState;
            wbDataForInputReg <= wbDataForInput;
        end if;
    end if;
end process;

-- A simple state machine to run the 1 to 4 demux
-- loadIngressFifo is later used as a onehot enable to the fifos

process ( loadState, wbDataForInputReg)
begin
    case loadState is
        when s0 =>
 
            loadEgressFoo <='0';
            if (wbDataForInputReg='1') then
                loadIngressFifo<= X"01";
                loadNextState <= s1;
             else
                loadIngressFifo<= (others =>'0');
            	loadNextState <= s0;
             end if;
      when s1 => 
            loadEgressFoo <='0';
            if (wbDataForInputReg='1') then
                loadIngressFifo<=X"02";
                loadNextState <= s2;
             else
                loadIngressFifo<= ( others =>'0');
            	loadNextState <= s1;
             end if;
      when s2 =>
            loadEgressFoo <='0';
            if (wbDataForInputReg='1') then
                loadIngressFifo<=X"04";
                loadNextState <= s3;
             else
                loadIngressFifo<= ( others =>'0');
            	loadNextState <= s2;
             end if;
      when s3 => 
            loadEgressFoo <='0';
            if (wbDataForInputReg='1') then
                loadIngressFifo<= X"08";
                loadNextState <= s4;
             else
                loadIngressFifo<= ( others =>'0');
            	loadNextState <= s3;
             end if;
      when s4 => 
           loadEgressFoo <='0';
            if (wbDataForInputReg='1') then
                loadIngressFifo<= X"10";
                loadNextState <= s5;
             else
                loadIngressFifo<= ( others =>'0');
            	loadNextState <= s4;
             end if;
      when s5 => 
      
		loadEgressFoo <='0';
            if (wbDataForInputReg='1') then
                loadIngressFifo<= X"20";
                loadNextState <= s6;
             else
                loadIngressFifo<= ( others =>'0');
            	loadNextState <= s5;
             end if;
      when s6 => 
	  
          loadEgressFoo <='0';
            if (wbDataForInputReg='1') then
                loadIngressFifo<= X"40";
                loadNextState <= s7;
             else
                loadIngressFifo<= ( others =>'0');
            	loadNextState <= s6;
             end if;
      when s7 =>
           loadEgressFoo <='1';
						   
            if (wbDataForInputReg='1') then
                loadIngressFifo<= X"80";
                loadNextState <= s0;
             else
                loadIngressFifo<= ( others =>'0');
            	loadNextState <= s7;
             end if;


       when others =>		
	  end case;
end process;	  

process (wbClk) 
begin
    if rising_edge(wbClk) then
        loadEgressFifo(0) <= loadEgressFoo;
        loadEgressFifo(7 downto 1) <= loadEgressFifo(6 downto 0);
    end if;
end process;    
        
        
--call the processing elements
arnd1: entity bftLib.round_1(aR1)
  port map (clk => bftClk,  x => toBft,  xOut=>rnd1_2);

arnd2: entity bftLib.round_2(aR2)
  port map (clk => bftClk, x => rnd1_2,  xOut=>rnd2_3);

arnd3: entity bftLib.round_3(aR3)
  port map (clk => bftClk, x => rnd2_3,  xOut=>rnd3_4);

arnd4: entity bftLib.round_4(aR4)
  port map (clk => bftClk, x => rnd3_4,  xOut=>fromBft);

process (wbClk)
begin
    if rising_edge(wbClk) then
        ingressFifoWrEn <= not(wbDataForInput);
    end if;    
end process;

process (bftClk)
begin
  if rising_edge(bftClk) then
      if (reset = '1') then
            validForEgressFifo <= (others => '0');
       else
           validForEgressFifo(0) <= not wbDataForInput;
           validForEgressFifo (13 downto 1) <= validForEgressFifo(12 downto 0);
       end if;    
  end if;     
end process;


--buffer the inputs			
ingressLoop : FOR N in 0 to STAGES/2 -1 generate
    ingressFifo: FifoBuffer
    port map (rd_clk => bftClk, wr_clk =>wbClk, din =>wbInputDataStage1, rd_en =>ingressFifoWrEn, rst =>reset, wr_en =>loadIngressFifo(N), dout(31 downto 16) =>toBft(2*N+1), dout(15 downto 0) =>toBft(2*N),  empty=> ingressFifoEmpty(N) , full => ingressFifoFull(N));
end generate ingressLoop;

--buffer the outputs
egressLoop : for N in 0 to STAGES/2 -1 generate
    egressFifo: FifoBuffer
     port map (rd_clk => wbClk, wr_clk =>bftClk, din(31 downto 16) => fromBft(2*N+1), din(15 downto 0) => fromBft(2*N), rd_en =>readEgressFifo(N), rst =>reset, wr_en =>validForEgressFifo(9), dout =>deMux(N) ,  empty=> egressFifoEmpty(N) , full => egressFifoFull(N));
 end generate egressLoop;

							   
--gennerate an error if full

process (wbClk)
begin
    if rising_edge(wbClk) then
      error <= egressFifoFull(7) or egressFifoFull(6) or egressFifoFull(5) or egressFifoFull(4) or egressFifoFull(3) or egressFifoFull(2) or egressFifoFull(1) or egressFifoFull(0)  ;
    end if;
end process;


-- muxout the output
-- start when output fifo has data (!empty)
-- stops when the output fifo goes empty



--use wbWriteOut (inverted from wb_we_i) as initiator.

process (wbClk)
begin
  if  rising_edge(wbClk) then
         if (reset = '1') then	  
             wbDataForOutput <= '0';
             demuxState <=stall;
             wbOutputData <= (others => '0');
             fifoSelect <= (others => '0');
--             readEgressFifo <= (others => '0');
         else
         case demuxState is
             when stall =>		
                 wbDataForOutput <= '0';
                 wbOutputData <= (others => '0');
                 if (wbWriteOut = '1') then
                      demuxState <= run;
                      fifoSelect <= X"01";
                  else  
                     demuxState <= stall;
                 end if; 
             when run =>	 
                 fifoSelect <= fifoSelect(STAGES/2 -2 downto 0)&fifoSelect(STAGES/2 -1);
                 wbDataForOutput <= '1';
                 case fifoSelect is
                     when X"01"=>
                          wbOutputData <=deMux(0);
                     when X"02"=>
                          wbOutputData <=deMux(1);
                     when X"04"=>
                          wbOutputData <=deMux(2);
                     when X"08"=>
                          wbOutputData <=deMux(3);
                     when X"10"=>
                          wbOutputData <=deMux(4);
                     when X"20"=>
                          wbOutputData <=deMux(5);
                     when X"40"=>
                          wbOutputData <=deMux(6);
                     when X"80"=>
                          wbOutputData <=deMux(7);	
                     when others =>     
                 end case;
                 if (egressFifoEmpty(7) = '1') then
                     demuxState <= stall;
                     wbDataForOutput <= '0';
                     wbOutputData <= (others => '0');
                 end if;	
             when others =>    
		end case;
        end if;
    end if;
end process;    

-- enable the read fifo
process (fifoSelect)
begin
    readEgressFifo <= fifoSelect;
end process;

end architecture aBFT;
