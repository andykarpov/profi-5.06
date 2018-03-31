library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity cpld_kbd is
	generic 
	(
		OPEN_COLLECTOR: integer);
	port
	(
	 CLK			 : in std_logic;
	 N_CS			 : in std_logic := '1';
    A           : in std_logic_vector(15 downto 8);     -- address bus for kbd
    KB          : out std_logic_vector(5 downto 0) := "111111";     -- data bus for kbd + extended bit (b6)
    AVR_CLK     : in std_logic;
    AVR_RST     : in std_logic;
    AVR_DATA    : in std_logic;
	 
	 MS_X 	 	: out std_logic_vector(7 downto 0);
	 MS_Y 	 	: out std_logic_vector(7 downto 0);
	 MS_BTNS 	 	: out std_logic_vector(2 downto 0);
	 MS_Z 		: out std_logic_vector(3 downto 0)
	);
    end cpld_kbd;
architecture RTL of cpld_kbd is

    -- 40 spectrum keyboard keys + 1 special bit b6 + 8 bit mouse x, 8 bit y, 3 bit btns, 1 bit change data flag
    type kb_mem is  array( 0 to 64 ) of  std_logic;
    signal kb_data : kb_mem;
    signal kb_addr : integer range 0 to 64;
	 signal ms_flag : std_logic := '0';
	 
	 -- mouse
	 signal currentX 	: unsigned(7 downto 0);
	 signal currentY 	: unsigned(7 downto 0);
	 signal cursorX 		: signed(7 downto 0) := X"7F";
	 signal cursorY 		: signed(7 downto 0) := X"7F";
	 signal deltaX		: signed(8 downto 0);
	 signal deltaY		: signed(8 downto 0);
	 signal deltaZ		: signed(3 downto 0);
	 signal trigger 	: std_logic := '0';

begin

-- Read in the data from MCU's serial bus
process( AVR_CLK, AVR_DATA, AVR_RST)
begin

	-- open collector transmission (active 0)
	if (OPEN_COLLECTOR = 1) then 
		 if (AVR_RST = '0') then
			kb_addr <= 0;
		 else

			 if ( falling_edge( AVR_CLK )) then
				 -- read the key status from the micro-controller
				 -- if the bit is '0' that means the key is pressed
							  kb_data( conv_integer(kb_addr)  ) <=  not(AVR_DATA);
			 end if;

			 if ( rising_edge( AVR_CLK )) then
				 -- increment the pointer
				 kb_addr <= kb_addr + 1;
			 end if;
		 end if;
	-- normal transmission (active 1)
	else
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
							
				KB(5) <= not(kb_data(40));
			else
				KB <= "ZZZZZZ";
			end if;
		

		
		end if;

end process;

process (CLK, kb_data) 
begin
		if (rising_edge(CLK)) then
			trigger <= '0';
			-- update mouse only on ms flag changed
			if (ms_flag /= kb_data(64)) then 
				deltaX(7) <= kb_data(48);
				deltaX(6) <= kb_data(47);
				deltaX(5) <= kb_data(46);
				deltaX(4) <= kb_data(45);
				deltaX(3) <= kb_data(44);
				deltaX(2) <= kb_data(43);
				deltaX(1) <= kb_data(42);
				deltaX(0) <= kb_data(41);
				
				deltaY(7) <= kb_data(56);
				deltaY(6) <= kb_data(55);
				deltaY(5) <= kb_data(54);
				deltaY(4) <= kb_data(53);
				deltaY(3) <= kb_data(52);
				deltaY(2) <= kb_data(51);
				deltaY(1) <= kb_data(50);
				deltaY(0) <= kb_data(49);
				
				deltaZ(3) <= kb_data(63);
				deltaZ(2) <= kb_data(62);
				deltaZ(1) <= kb_data(61);
				deltaZ(0) <= kb_data(60);
				
				MS_BTNS(2) <= not(kb_data(59));
				MS_BTNS(1) <= not(kb_data(58));
				MS_BTNS(0) <= not(kb_data(57));
				
				ms_flag <= kb_data(64);
				trigger <= '1';
			end if;
		end if;
end process;

process (CLK)
	variable newX : signed(7 downto 0);
	variable newY : signed(7 downto 0);
begin
	if rising_edge (CLK) then

		newX := cursorX + deltaX(7 downto 0);
		newY := cursorY + deltaY(7 downto 0);

		if trigger = '1' then
			cursorX <= newX;
			cursorY <= newY;
		end if;
	end if;
end process;
	
	MS_X 		<= std_logic_vector(cursorX);
	MS_Y 		<= std_logic_vector(cursorY);
	MS_Z		<= std_logic_vector(deltaZ);

end RTL;

