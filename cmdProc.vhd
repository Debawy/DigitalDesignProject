library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.common_pack.all;
entity CommandProcessor is 
   port( clk:in std_logic;
         reset:in std_logic;
         rxnow:in std_logic;
         rxData:in std_logic_vector (7 downto 0);
         txData:out std_logic_vector (7 downto 0);
         rxdone:out std_logic;
         ovErr:	in std_logic;
         framErr:in std_logic;
         txnow:out std_logic;
         txdone:in std_logic;
         start: out std_logic;
         numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
         dataReady: in std_logic;
         byte: in std_logic_vector(7 downto 0);
         maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
         dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
         seqDone: in std_logic
        );
end CommandProcessor;
architecture dataflow of CommandProcessor is
type CMD_STATE_TYPE is (INTIAL,ECHO,ANNNCHECK,WAITFORDP,SENDBYTES,WAITFORTRANSMISION);
signal curstate_cmd, nxstate_cmd:CMD_STATE_TYPE;
signal ANNNflag: std_logic;
signal rcvreg_32:std_logic_vector(31 downto 0);
signal nobytessent: integer range 0 to 2;
signal hexreg: std_logic_vector(15 downto 0);
signal A,N1,N2,N3: std_logic_vector(7 downto 0);
signal Int1,Int2,Int3: integer;  
begin
  cmd_nextstate: process(curstate_cmd,rxnow,txdone,ANNNflag,dataReady,seqDone)
  begin
    CASE curstate_cmd is
      when INTIAL =>
         if rxnow = '1' then
            rxdone <= '1'; 
            nxstate_cmd <= ECHO;
         else
            nxstate_cmd <= INTIAL;
         end if;
      when ECHO =>
         rxdone <= '0';
         if txdone = '1' then
            txData <= rcvreg_32(7 downto 0);
            txnow <= '1'; 
            nxstate_cmd <= ANNNCHECK;
         else 
            nxstate_cmd <= ECHO;
         end if;
      when ANNNCHECK =>
         txnow <= '0';
         if ANNNflag = '1' then 
            start <= '1';
            nxstate_cmd <= WAITFORDP;
         else
            nxstate_cmd <= INTIAL;
         end if;
      when WAITFORDP =>
         start <= '0';
         if dataReady = '1' then 
            nxstate_cmd <= SENDBYTES;
         else
            nxstate_cmd <= WAITFORDP;
         end if;
      when SENDBYTES => 
         txData <= hexreg(15 downto 8);
         txnow <= '1';
         nxstate_cmd <= WAITFORTRANSMISION;
      when WAITFORTRANSMISION => 
         txnow <= '0';
         if txdone = '1' then
            if nobytessent = 2 then
               if seqDone = '1' then 
                  nxstate_cmd <= INTIAL;
               else
                  start <= '1';
                  nxstate_cmd <= WAITFORDP;
               end if;
            else 
               nxstate_cmd <= SENDBYTES;
            end if;
         else
            nxstate_cmd <= WAITFORTRANSMISION;
         end if;
      when OTHERS => 
         nxstate_cmd <= INTIAL;
      end case;
   end process;
   shiftreg32: process(clk,curstate_cmd,rxnow)
   begin
   if rising_edge(clk) then
      if reset = '1' then
         rcvreg_32 <= (others => '0');
      elsif (curstate_cmd = INTIAL and rxnow = '1') then
         rcvreg_32 <= rcvreg_32(23 downto 0) & rxData;
      end if;       
   end if;
   end process;
end dataflow;