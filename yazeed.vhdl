ENTITY ShiftReg1 IS
PORT(
   Clk:    IN STD_LOGIC;
    Clr:    IN STD_LOGIC;
   data_in:IN STD_LOGIC;
    q:OUT STD_LOGIC_VECTOR(31 DOWNTO 0) //represents the 32 bits, 8 bits per echoed key, A is shifted first followed by NNN

    #);

ARCHITECTURE Reg1 OF ShiftReg1 IS
SIGNAL qs: STD_LOGIC_VECTOR(31 DOWNTO 0): //the internal signals
BEGIN
    PROCESS(clk, clr) //sensitivity list, to be swapped with signal names to use for reset/
    BEGIN
        IF clr ='1' THEN
            qs <='00000000 00000000 00000000 00000000' //when we press the clear button the shift register is cleared, 32 bits, 8 bits per letter echoed.
        ELSIF clk'EVENT AND CLK='1' THEN
            qs(31)<= data_in;
            qs(30 DOWNTO 0)<=qs(31 DOWNTO 1);  //so that the value at bit 31 goes to 30, and that at 30 goes to 29, until the value of 1 goes to 0
        END IF;
    END PROCESS;
    q<=qs;
END Reg1

//code based on https://m.youtube.com/watch?v=C4nSQjDcC4k resource edited to carry out our specific task.
//use the three instructions to push to github here.



//16 bit Hexa register
ENTITY ShiftReg2 IS
PORT(
    Clk:    IN STD_LOGIC;
    Clr:    IN STD_LOGIC;
    data_in:IN STD_LOGIC;
    q:OUT STD_LOGIC_VECTOR(15 DOWNTO 0) //represents the 16 bits, 8 bits per byte

    );

ARCHITECTURE Reg1 OF ShiftReg1 IS
SIGNAL qs: STD_LOGIC_VECTOR(15 DOWNTO 0): //the internal signals
BEGIN
   PROCESS(clk, clr) //sensitivity list, to be swapped with signal names to use for reset/
    BEGIN
        IF clr ='1' THEN
            qs <='00000000 00000000 ' //when we press the clear button the shift register is cleared, 16 bits, 2 bytes.
        ELSIF clk'EVENT AND CLK='1' THEN
           qs(15)<= data_in;
            qs(14 DOWNTO 0)<=qs(15 DOWNTO 1);  //so that the value at bit 16 goes to 15, and that at 15 goes to 14, until the value of 1 goes to 0
        END IF;
    END PROCESS;
