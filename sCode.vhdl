// validate ANNN
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.ALL;


architecture validateANNN of cmd is
// q is the 32bit input vector
signal q : std_ulogic_vector (31 downto 0);
signal A, firstN, secondN, thirdN : std_ulogic_vector(7 downto 0);
signal ANNNvalid : std_ulogic ; // 1 means valid ANNN , 0 Means invalid ANNN
    
begin
    A <= q(31 downto 24);
    firstN <= q(23 downto 16)
    secondN <= q(15 downto 8)
    thirdN <= q(7 downto 0)

    Validate : process(q)
    begin
        ANNNvalid <= '0' ; //validateANNN is set to 0 as a default
            
        if ( A = 01000000 or A = 01100001
            and 
            firstN = 00110000 or
            firstN = 00110001 or
            firstN = 00110010 or 
            firstN = 00110011 or
            firstN = 00110100 or 
            firstN = 00110101 or 
            firstN = 00110110 or 
            firstN = 00110111 or
            firstN = 00111000 or
            firstN = 00111001
            and
            secondN = 00110000 or
            secondN = 00110001 or
            secondN = 00110010 or 
            secondN = 00110011 or
            secondN = 00110100 or 
            secondN = 00110101 or 
            secondN = 00110110 or 
            secondN = 00110111 or
            secondN = 00111000 or
            secondN = 00111001
            and
            thirdN = 00110000 or
            thirdN = 00110001 or
            thirdN = 00110010 or 
            thirdN = 00110011 or
            thirdN = 00110100 or 
            thirdN = 00110101 or 
            thirdN = 00110110 or 
            thirdN = 00110111 or
            thirdN = 00111000 or
            thirdN = 00111001) then
                ANNNvalid <= 1;
        end if;
    end process;
end
                
            
        





