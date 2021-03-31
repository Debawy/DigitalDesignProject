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
signal ANNNflag, seqdonereg: std_logic;
signal rcvreg_32:std_logic_vector(31 downto 0);
signal nobytessent: integer range 0 to 2;
signal hexreg: std_logic_vector(15 downto 0);
signal bcdreg12: std_logic_vector(11 downto 0);
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
               if seqdonereg = '1' then 
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
   ANNNValidate : process(rcvreg_32)--Asynchronous
   variable A, N1, N2, N3 : std_logic_vector(7 downto 0);
   variable Int1, Int2, Int3: integer ;
   begin
      A := rcvreg_32(31 downto 24);
      N1 := rcvreg_32(23 downto 16);
      N2 := rcvreg_32(15 downto 8);
      N3 := rcvreg_32(7 downto 0);
      int1 := to_integer(unsigned(N1(3 downto 0)));
      int2 := to_integer(unsigned(N2(3 downto 0)));
      int3 := to_integer(unsigned(N3(3 downto 0)));           
      ANNNflag <= '0';
      if  (A = "01000000" 
          or A = "01100001") 
          and (N1(7 downto 4) = "0011" 
          and N2(7 downto 4) = "0011" 
          and N3(7 downto 4) = "0011") 
          and (int1<10 
          and int2<10 
          and int3<10 
          and int1 + int2 +int3 /= 0) 
          then
            ANNNflag <= '1';        
      end if; 
   end process;
   ASCIITOBCD : process (ANNNflag)-- what should the sensitivity list be ?
   variable N1, N2, N3 : std_logic_vector(7 downto 0);
   begin 
   N1 := rcvreg_32(23 downto 16);
   N2 := rcvreg_32(15 downto 8);
   N3 := rcvreg_32(7 downto 0);
      if ANNNflag =  '1' then
         numWords_bcd <= (N1(3 downto 0),N2(3 downto 0),N3(3 downto 0));
      else
         numWords_bcd <= ("0000","0000","0000");
      end if; 
   end process;
  CounterReg: process(clk)
  begin
  if rising_edge(clk) then
     if reset = '1' then
         nobytessent <= 0;
     else
        CASE curstate_cmd is
           when WAITFORDP =>
              nobytessent <= 0;
           when SENDBYTES =>
              nobytessent <= nobytessent + 1;
           when OTHERS =>
              nobytessent <= nobytessent;
        END CASE;
    end if;
  end if;
  end process;
  ByteToHexreg:process(clk)
  variable int1 : integer;
  variable int2 : integer;
  variable below10 : std_logic_vector(3 downto 0) := "0011";
  variable above10 : std_logic_vector(3 downto 0) := "0100";
  begin
  if rising_edge(clk) then 
     if reset = '1' then
         hexreg <= (others => '0');
     elsif curstate_cmd = WAITFORDP and dataReady = '1' then
         int1 := to_integer(unsigned(byte(7 downto 4)));
         int2 := to_integer(unsigned(byte(3 downto 0)));
         if int1<10 then
            hexreg(15 downto 8) <= below10 & byte(7 downto 4);
         else
            int1 := int1 - 9;
            hexreg(15 downto 8) <= above10 & std_logic_vector(to_unsigned(int1,4));--https://www.nandland.com/vhdl/tips/tip-convert-numeric-std-logic-vector-to-integer.html#Numeric-Integer-To-Unsigned
         end if;
         if int2 < 10 then
            hexreg(7 downto 0) <= below10 & byte(7 downto 4);
         else
            int2 := int2 - 9;
            hexreg(7 downto 0) <= above10 & std_logic_vector(to_unsigned(int2,4));
         end if;
     elsif curstate_cmd = WAITFORTRANSMISION and txDone = '1' and nobytessent < 2 then 
        hexreg(15 downto 0) <= hexreg(7 downto 0) & "00000000";
     end if;
  end if;
  end process;
  SeqdoneLatch : process(clk)
  begin
     if rising_edge(clk) then
        if reset = '1' then
           SeqDoneReg <= '0';
        elsif seqDone = '1' then
           SeqDoneReg <= '1';
        elsif curstate_cmd = INTIAL then 
           SeqDoneReg <= '0';
        end if;
      end if;
  end process;
  stateRegister_cmd: process(clk)
  begin
     if rising_edge(clk) then
	if (reset = '1') then
	    curstate_cmd <= INTIAL;
        else
	    curstate_cmd <= nxstate_cmd;
	end if;	
     end if;
  end process; 
                                                                        
end Dataflow;