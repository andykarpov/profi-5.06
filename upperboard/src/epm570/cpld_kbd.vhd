library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity cpld_kbd is
	port
	(
	 CLK			 : in std_logic;
	 N_CS			 : in std_logic := '1';
    A           : in std_logic_vector(15 downto 8);     -- address bus for kbd
    KB          : out std_logic_vector(4 downto 0) := "11111";     -- data bus for kbd
    AVR_CLK     : in std_logic;
    AVR_RST     : in std_logic;
    AVR_DATA    : in std_logic;

	 O_RESET 	 : out std_logic := '0';
	 O_MAGIC		 : out std_logic := '0';
	 O_TURBO 	 : out std_logic := '0';

	 O_F 			 : out std_logic_vector(9 downto 0) := "0000000000"
	 
	);
    end cpld_kbd;
architecture RTL of cpld_kbd is

    -- 40 spectrum keyboard keys + 3 special buttons + 10 functional keys
    type kb_mem is  array( 0 to 52 ) of  std_logic;
    signal kb_data : kb_mem;
    signal kb_addr : integer range 0 to 52;

begin

-- Read in the data from MCU's serial bus
process( AVR_CLK, AVR_DATA, AVR_RST)
begin

    if (AVR_RST = '1') then
      kb_addr <= 0;
    else

	    if ( rising_edge( AVR_CLK )) then
		    -- read the key status from the micro-controller
		    -- if the bit is '1' that means the key is pressed
                    kb_data( conv_integer(kb_addr)  ) <=  AVR_DATA;
	    end if;

	    if ( falling_edge( AVR_CLK )) then
		    -- increment the pointer
		    kb_addr <= kb_addr + 1;
	    end if;
    end if;
end process;
--    
process( kb_data, A, CLK)
begin

--    -- if an address line is low then set the databus to the bit value for that column
--    -- so if multiple address lines are low
--    -- the up/down status of MULTIPLE 'keybits' will be passeds

		if (rising_edge(CLK)) then
		
			if (N_CS = '0') then
				KB(0) <=	not(( kb_data(0)  and not(A(8)  ) ) 
							or 	( kb_data(1)  and not(A(9)  ) ) 
							or 	( kb_data(2) and not(A(10) ) ) 
							or 	( kb_data(3) and not(A(11) ) ) 
							or 	( kb_data(4) and not(A(12) ) ) 
							or 	( kb_data(5) and not(A(13) ) ) 
							or 	( kb_data(6) and not(A(14) ) ) 
							or 	( kb_data(7) and not(A(15) ) )  );

				KB(1) <=	not( ( kb_data(8)  and not(A(8) ) ) 
							or   ( kb_data(9)  and not(A(9) ) ) 
							or   ( kb_data(10) and not(A(10)) ) 
							or   ( kb_data(11) and not(A(11)) ) 
							or   ( kb_data(12) and not(A(12)) ) 
							or   ( kb_data(13) and not(A(13)) ) 
							or   ( kb_data(14) and not(A(14)) ) 
							or   ( kb_data(15) and not(A(15)) ) );

				KB(2) <=		not( ( kb_data(16) and not( A(8)) ) 
							or   ( kb_data(17) and not( A(9)) ) 
							or   ( kb_data(18) and not(A(10)) ) 
							or   ( kb_data(19) and not(A(11)) ) 
							or   ( kb_data(20) and not(A(12)) ) 
							or   ( kb_data(21) and not(A(13)) ) 
							or   ( kb_data(22) and not(A(14)) ) 
							or   ( kb_data(23) and not(A(15)) ) );

				KB(3) <=		not( ( kb_data(24) and not( A(8)) ) 
							or   ( kb_data(25) and not( A(9)) ) 
							or   ( kb_data(26) and not(A(10)) ) 
							or   ( kb_data(27) and not(A(11)) ) 
							or   ( kb_data(28) and not(A(12)) ) 
							or   ( kb_data(29) and not(A(13)) ) 
							or   ( kb_data(30) and not(A(14)) ) 
							or   ( kb_data(31) and not(A(15)) ) );

				KB(4) <=		not( ( kb_data(32) and not( A(8)) ) 
							or   ( kb_data(33) and not( A(9)) ) 
							or   ( kb_data(34) and not(A(10)) ) 
							or   ( kb_data(35) and not(A(11)) ) 
							or   ( kb_data(36) and not(A(12)) ) 
							or   ( kb_data(37) and not(A(13)) ) 
							or   ( kb_data(38) and not(A(14)) ) 
							or   ( kb_data(39) and not(A(15)) ) );
			else
				KB <= "ZZZZZ";
			end if;
					
			O_RESET <= kb_data(41);
			O_MAGIC <= kb_data(40);
			O_TURBO <= kb_data(42);		

			O_F(9) <= kb_data(52);
			O_F(8) <= kb_data(51);
			O_F(7) <= kb_data(50);
			O_F(6) <= kb_data(49);
			O_F(5) <= kb_data(48);
			O_F(4) <= kb_data(47);
			O_F(3) <= kb_data(46);
			O_F(2) <= kb_data(45);
			O_F(1) <= kb_data(44);
			O_F(0) <= kb_data(43);
		end if;

end process;

end RTL;

