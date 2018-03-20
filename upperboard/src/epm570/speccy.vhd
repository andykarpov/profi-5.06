library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;  

entity speccy is                    
	port (
		-- CLOCK
		CLK_50MHz		: in std_logic;
		-- VGA
		VGA_R0			: out std_logic;
		VGA_R1			: out std_logic;
		VGA_R2			: out std_logic;	
		VGA_G0			: out std_logic;
		VGA_G1			: out std_logic;
		VGA_G2			: out std_logic;
		VGA_B0			: out std_logic;
		VGA_B2			: out std_logic;
		VGA_B1			: out std_logic;
		VGA_VSYNC		: out std_logic;
		VGA_HSYNC		: out std_logic;
		-- SRAM (CY7C1049DV33-10)
		SRAM_A			: out std_logic_vector(18 downto 0);
		SRAM_D			: inout std_logic_vector(7 downto 0);
		SRAM_nOE		: out std_logic;
		SRAM_nWE		: out std_logic;
		-- External I/O
		nRST			: in std_logic;
		-- PS2
		PS2_KBCLK		: inout std_logic;
		PS2_KBDAT		: inout std_logic		
);		
				
end speccy;

architecture speccy_arch of speccy is

component altpll0 is
port(
		inclk0		: IN STD_LOGIC  := '0';
		c0			: OUT STD_LOGIC 
);
end component;

component lpm_rom0 is
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component zxkbd is
	port(
		clk				:in std_logic;
		reset			:in std_logic;
		res_k			:out std_logic;
		ps2_clk			:in std_logic;
		ps2_data		:in std_logic;
		zx_kb_scan		:in std_logic_vector(7 downto 0);
		zx_kb_out		:out std_logic_vector(4 downto 0);
		k_joy			:out std_logic_vector(4 downto 0); 
		f				:out std_logic_vector(12 downto 1);   
		num_joy			:out std_logic  
);
end component;

component T80s is
	generic (
		Mode 			: integer := 0;		-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write 		: integer := 1;		-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait 			: integer := 1 );	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	port (
		RESET_n			: in std_logic;
		CLK_n			: in std_logic;
		WAIT_n			: in std_logic;
		INT_n			: in std_logic;
		NMI_n			: in std_logic;
		BUSRQ_n			: in std_logic;
		M1_n			: out std_logic;
		MREQ_n			: out std_logic;
		IORQ_n			: out std_logic;
		RD_n			: out std_logic;
		WR_n			: out std_logic;
		RFSH_n			: out std_logic;
		HALT_n			: out std_logic;
		BUSAK_n			: out std_logic;
		A				: out std_logic_vector(15 downto 0);
		DI				: in std_logic_vector(7 downto 0);
		DO				: out std_logic_vector(7 downto 0);
		RestorePC_n 	: in std_logic );
end component;

signal clock		: std_logic;
signal clk_cnt		: std_logic_vector(1 downto 0);
signal hcnt			: std_logic_vector(8 downto 0);
signal vcnt			: std_logic_vector(9 downto 0);
signal hsync		: std_logic;
signal vsync		: std_logic;
signal screen		: std_logic;
signal screen1		: std_logic;
signal blank		: std_logic;
signal vid_0_reg	: std_logic_vector(7 downto 0);
signal vid_1_reg	: std_logic_vector(7 downto 0);
signal vid_b_reg	: std_logic_vector(7 downto 0);
signal vid_c_reg	: std_logic_vector(7 downto 0);
signal vid_dot		: std_logic;
signal vid_sel		: std_logic;
signal r,rb			: std_logic;
signal g,gb			: std_logic;
signal b,bb			: std_logic;
signal cpu_a_bus	: std_logic_vector(15 downto 0);
signal cpu_do_bus	: std_logic_vector(7 downto 0);
signal cpu_di_bus	: std_logic_vector(7 downto 0);
signal cpu_mreq_n	: std_logic;
signal cpu_iorq_n	: std_logic;
signal cpu_wr_n		: std_logic;
signal cpu_rd_n		: std_logic;
signal clk_cpu		: std_logic;
signal rom_sel		: std_logic;
signal rom_do		: std_logic_vector(7 downto 0);
signal port_fe_sel	: std_logic;
signal port_fe		: std_logic_vector(7 downto 0);
signal int			: std_logic;
signal cpu_int_n	: std_logic;
signal res_n		: std_logic;
signal kb_a_bus		: std_logic_vector(7 downto 0);
signal kb_do_bus	: std_logic_vector(4 downto 0);
signal flash		: std_logic_vector(4 downto 0);

begin

process (clock, clk_cnt)
begin
	if (clock'event and clock = '0') then
		clk_cnt <= clk_cnt + 1;
	end if;
end process;

process (clock, clk_cnt)
begin
	if (clock'event and clock = '0') then
			clk_cpu <= (clk_cnt(1));
	end if; 
end process;

process (clock, vcnt, hcnt)
begin
	if (clock'event and clock = '1') then
		if (vcnt(9 downto 1) = 239 and hcnt = 316) then 
			int <= '1';
		else 
			int <= '0'; 
		end if;
	end if;
end process;

process (int, hcnt)
begin
	if (int'event and int = '1') then
		cpu_int_n <= '0';
	end if;
	if hcnt = 388 then
		cpu_int_n <='1';
	end if;
end process; 

process (clock, hcnt)
begin
	if (clock'event and clock = '0') then
		if hcnt = 447 then
			hcnt <= "000000000";
		else
			hcnt <= hcnt + 1;
		end if;
	end if; 
end process; 

process (clock, hcnt, vcnt)
begin
if (clock'event and clock = '0') then  
	if hcnt = 328 then 
		if vcnt(9 downto 1) = 311 then 
			vcnt(9 downto 1) <= "000000000";
		else
			vcnt <= vcnt + 1;
		end if;	
	end if;
end if;
end process;

process(clock, hcnt)
begin
	if (clock'event and clock = '1') then
		if hcnt = 328 then hsync <= '0';
		elsif hcnt = 381 then hsync <= '1'; 
		end if;
	end if;
end process;

process (clock, vcnt)
begin
	if (clock'event and clock = '1') then
		if vcnt(9 downto 1) = 256 then vsync <= '0';
		elsif vcnt(9 downto 1) = 260 then vsync <= '1'; 
		end if;
	end if;
end process;

process (clock, hcnt, vcnt)	 
begin
	if (clock'event and clock = '1') then
		 if (hcnt > 301 and hcnt < 417) or (vcnt(9 downto 1) > 224 and vcnt(9 downto 1) < 285) then
			blank <= '1';
		else
			blank <= '0';
		end if;
	end if;
end process;

process (clock, hcnt, vcnt)
begin
	if (clock'event and clock = '1') then
		if (hcnt < 256 and vcnt(9 downto 1) < 192) then
			screen <= '1';
		else 
			screen <= '0';
		end if;
	end if;
end process;

process (clock, hcnt)
begin
	if hcnt(2 downto 0) = "100" then
		if (clock'event and clock = '1') then
			vid_0_reg <= SRAM_D;
		end if;
	end if;
end process;

process (clock, hcnt)
begin
	if hcnt(2 downto 0) = "101" then
		if (clock'event and clock='1') then
			vid_1_reg <= SRAM_D;
		end if;
	end if;
end process;

process (hcnt, clock)	
begin
	if hcnt(2 downto 0) = "111" then
		if (clock'event and clock = '1') then
			vid_b_reg 	<= vid_0_reg;
			vid_c_reg 	<= vid_1_reg;
			screen1 	<= screen;
		end if;
 end if;
end process;

process (hcnt, vid_b_reg)	
begin
	case hcnt(2 downto 0) is
		when "000" => vid_dot <= vid_b_reg(7); 
		when "001" => vid_dot <= vid_b_reg(6);
		when "010" => vid_dot <= vid_b_reg(5);
		when "011" => vid_dot <= vid_b_reg(4);
		when "100" => vid_dot <= vid_b_reg(3);
		when "101" => vid_dot <= vid_b_reg(2);
		when "110" => vid_dot <= vid_b_reg(1);
		when "111" => vid_dot <= vid_b_reg(0);
	end case;
end process;

process (vid_sel, vcnt, hcnt, cpu_a_bus)
begin
	if vid_sel = '1' then
	 	case hcnt(0) is
			when '0' => SRAM_A <= "0000" & "10" & vcnt(8 downto 7) & vcnt(3 downto 1) & vcnt(6 downto 4) & hcnt(7 downto 3);
			when '1' => SRAM_A <= "0000" & "10110" & vcnt(8 downto 4) & hcnt(7 downto 3);
		end case;
	else
		SRAM_A <= "000" & cpu_a_bus;
	end if;	
end process;

SRAM_D <= cpu_do_bus when (vid_sel = '0' and cpu_mreq_n = '0' and cpu_wr_n = '0') else "ZZZZZZZZ";
SRAM_nOE <= '0' when (vid_sel = '1') or (cpu_mreq_n = '0' and cpu_rd_n = '0') else '1';
SRAM_nWE <= '0' when (vid_sel = '0' and cpu_mreq_n = '0' and cpu_wr_n = '0') else '1';

cpu_di_bus <= 	rom_do when (rom_sel = '1' and cpu_mreq_n = '0') else
				SRAM_D when (rom_sel = '0' and cpu_mreq_n = '0') else
				"111" & kb_do_bus when (port_fe_sel = '1') else
				"11111111";

vid_sel <= '1' when (hcnt(2 downto 1) = "10" and clock = '0') else '0';
rom_sel <= '1' when (cpu_a_bus(15 downto 14) = "00") else '0';
port_fe_sel <= '1' when (cpu_a_bus(7 downto 0) = x"FE" and cpu_iorq_n = '0') else '0';
port_fe <= cpu_do_bus when (port_fe_sel = '1' and (cpu_wr_n'event and cpu_wr_n = '1'));
kb_a_bus <= cpu_a_bus(15 downto 8);
flash <= (flash + 1) when (vcnt(9)'event and vcnt(9)='0');

process(screen1, blank, hcnt, vid_dot, vid_c_reg, clock, flash)
variable selector: std_logic_vector(2 downto 0);
begin
selector:=vid_dot & flash(4) & vid_c_reg(7);
	if (clock'event and clock = '1') then
		if blank = '0' then
			if screen1 = '1' then
				case selector is
					when "000"!"010"!"011"!"101" => b <= vid_c_reg(3);					
													bb <= (vid_c_reg(3) and vid_c_reg(6));
													r <= vid_c_reg(4);
													rb <= (vid_c_reg(4) and vid_c_reg(6));
													g <= vid_c_reg(5);
													gb <= (vid_c_reg(5) and vid_c_reg(6));
					when "100"!"001"!"111"!"110" => b <= vid_c_reg(0);
													bb <= (vid_c_reg(0) and vid_c_reg(6));
													r <= vid_c_reg(1);
													rb <= (vid_c_reg(1) and vid_c_reg(6));
													g <= vid_c_reg(2);
													gb <= (vid_c_reg(2) and vid_c_reg(6));
				end case;                 
			else 
				b <= port_fe(0);
				r <= port_fe(1);
				g <= port_fe(2);
				rb <= '0';
				gb <= '0';
				bb <= '0'; 
			end if;
		else
			b <= '0';
			r <= '0';
			g <= '0';
			rb <= '0';
			gb <= '0';
			bb <= '0';
		end if;
	end if;  
end process; 

VGA_R2 <= r;
VGA_G2 <= g;
VGA_B2 <= b;
VGA_R1 <= rb;
VGA_G1 <= gb;
VGA_B1 <= bb;                                        
VGA_R0 <= 'Z';
VGA_G0 <= 'Z';
VGA_B0 <= 'Z';

VGA_HSYNC <= '0' when hsync = '0' else '1';
VGA_VSYNC <= '0' when vsync = '0' else '1'; 

Z80:T80s
port map (
	RESET_n			=> nRST and res_n,
	CLK_n			=> clk_cpu,
	WAIT_n			=> '1',
	INT_n			=> cpu_int_n,
	NMI_n			=> '1',
	BUSRQ_n			=> '1',
	M1_n			=> open,
	MREQ_n			=> cpu_mreq_n,
	IORQ_n			=> cpu_iorq_n,
	RD_n			=> cpu_rd_n,
	WR_n			=> cpu_wr_n,
	RFSH_n			=> open,
	HALT_n			=> open,
	BUSAK_n			=> open,
	A				=> cpu_a_bus,
	DI				=> cpu_di_bus,
	DO				=> cpu_do_bus,
	RestorePC_n 	=> '1' 
);

zxkey:zxkbd        
port map(
	clk				=> clock,
	reset           => '0',
	res_k           => res_n,
	ps2_clk         => PS2_KBCLK,
	ps2_data        => PS2_KBDAT,
	zx_kb_scan      => kb_a_bus,
	zx_kb_out       => kb_do_bus,
	k_joy			=> open,
	f				=> open,
	num_joy			=> open
);

ROM: lpm_rom0
port map(
		address		=> cpu_a_bus(13 downto 0),
		clock		=> clock,
		q			=> rom_do
);

PLL: altpll0
port map(
		inclk0		=> CLK_50MHz,
		c0			=> clock 
);

end speccy_arch;