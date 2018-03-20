-- Profi 5.06 extend
-- 20:11:2013
-- Solegstar
-- Lisica
-- Keeper

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;  
entity extend is                    
port(

zx14mhz			:in std_logic; -- частота текущего тактового генератора 14 или ХМГц от Профи
iorqge_sl		:in std_logic; -- IORQGE слота
cpld_121		:out std_logic := 'Z'; -- тестовый сигнал выходящий на пин PLS для отладки
f8				:in std_logic; -- частота 8 МГц для бетадиска
turbo			:in std_logic; -- сигнал TURBO - 0=On, 1=Off
c_dffd			:buffer std_logic; -- Клок порта DFFD c полной дешифрацией и корректировкой
							-- порта FD, для старых нижних плат профи с неполной дешифрацией

----------------Z80----------------------
reset			:in std_logic;
wr_z			:in std_logic;
rd_z			:in std_logic;
iorq_z			:in std_logic;
iorqge			:buffer std_logic;
m1_z			:in std_logic;
mrq_z			:in std_logic;
nmi				:buffer std_logic;
w_a_i_t			:buffer std_logic;
adress			:in std_logic_vector(15 downto 0);
Data			:inout std_logic_vector(7 downto 0);

----ZSpi--
SD_CLK			:out std_logic;
SD_DO			:in std_logic;
SD_CS			:out std_logic;
SD_DI			:out std_logic;

-----------------AY------------------------
bc1a			:out std_logic;
bc1b			:out std_logic;
bdira			:out std_logic;
bdirb			:out std_logic;
ay_clk			:out std_logic; -- альтернативный клок для музпроцессоров.

-----------------DATA BUFFER------------------------
t_ap6			:out std_logic; -- определяет направление буфера шины данных АП6
oe_ap6			:out std_logic; 
t_lvc245		:out std_logic; -- определяет направление буфера шины данных LVC245

-----------------SAA------------------------
saa_cs			:buffer std_logic;
saa_a0			:out std_logic;
saa_clk			:out std_logic;

----------------Soundrive------------------------
dac2_cs			:buffer std_logic;
dac1_cs			:buffer std_logic;
dac				:out std_logic;

----------------VV55------------------------
vv55_cs			:buffer std_logic;

----------------CACHE------------------------
blok			:out std_logic;
cache_we		:out std_logic;
cache_oe		:out std_logic;

----------------Serial port------------------------
lwr				:out std_logic; -- WR для компорта
vi53_cs			:buffer std_logic;
ladr5			:out std_logic;
ladr6			:out std_logic;
vv51_cs			:buffer std_logic;
int				:out std_logic;
rxrdt			:in std_logic;
txrdt			:in std_logic;
timer			:in std_logic;
ri				:in std_logic;
dcd				:in std_logic;

-----------------mega-----------------------
READY_n			:in std_logic;
INT0I			:in std_logic;
INT0			:out std_logic;
INT1			:out std_logic;
ADR0			:out std_logic;
ADR1			:out std_logic;
SEL				:buffer std_logic;
ATM_PB3			:out std_logic := 'Z'; -- сигнал для часов Profi
ATM_PB4			:out std_logic := 'Z'; -- сигнал для часов Profi

---------------HDD------------------
hdd_a0			:out std_logic;
hdd_a1			:out std_logic;
hdd_a2			:out std_logic;
hdd_wr			:out std_logic;
hdd_rd			:out std_logic;
hdd_cs0			:out std_logic;
hdd_cs1			:out std_logic;
hdd_rh_oe		:out std_logic;
hdd_rh_c		:out std_logic;
hdd_wh_oe		:out std_logic;
hdd_wh_c		:out std_logic;
hdd_rwl_t		:out std_logic;

----------------BDI------------------------
tr_dos			:out std_logic;
magik			:in std_logic;
cpm				:in std_logic;
rom14			:in std_logic;

------------------WG93-------------------------------------
wg_clk:			out std_logic;
cswg:			buffer std_logic;
disk0:			out std_logic;
disk1:			out std_logic;
rst:			out std_logic;
hlt:			out std_logic;
side1:			out std_logic;
dden:			out std_logic;
rclk			:buffer std_logic;
wf_de			:in std_logic;
rawr			:buffer std_logic;
tr43			:in std_logic;
sr				:in std_logic;
sl				:in std_logic;
wd				:in std_logic;
intr			:in std_logic;
drq				:in std_logic;
rdat			:in std_logic;
wdat			:out std_logic
);

end extend;

architecture extend_arch of extend is

---------------------------------------------------------------------------
COMPONENT SPI               
    port(
        --INPUTS
        DI      : in std_logic_vector(7 downto 0);
        CLC     : in std_logic;
        MISO    : in std_logic;
        START   : in std_logic;
        WR_EN   : in std_logic;
        --OUTPUTS
        DO      : out std_logic_vector(7 downto 0);
        SCK     : out std_logic;
        MOSI    : out std_logic
        );
END COMPONENT ;
---------------------------------------------------------------------------

----------------Z80----------------------
signal res				:std_logic;
signal wr				:std_logic; -- синхронный WR
signal rd				:std_logic; -- синхронный RD
signal iorq				:std_logic; -- синхронный iorq
signal m1				:std_logic;
signal mrq				:std_logic;
signal Data_reg			:std_logic_vector (7 downto 0);

-----------DOS-------------
signal dos:				std_logic;
signal dos_on:			std_logic;
signal dos_of:			std_logic;
signal pzu:				std_logic;
signal mem:				std_logic;
signal mag:				std_logic;
signal fwait:			std_logic_vector(3 downto 0);
signal rwait:			std_logic_vector(12 downto 0);
signal RT_F2_1			:std_logic;
signal RT_F2_2			:std_logic;
signal RT_F2_3			:std_logic;
signal csff:			std_logic;
signal RT_F1_1			:std_logic;
signal RT_F1_2			:std_logic;
signal RT_F1			:std_logic;
signal P0				:std_logic;
signal pff:				std_logic_vector(7 downto 0);
signal csap6			:std_logic;

------------FAPCH-------------
signal f:				std_logic_vector(6 downto 0);
signal f1:				std_logic;
signal f4:				std_logic;
signal clk_wg:			std_logic;
signal rdat1:			std_logic;
signal fa:				std_logic_vector(4 downto 0);
signal rd1:				std_logic;
signal rd2:				std_logic;
signal wdata: 			std_logic_vector(3 downto 0);

----------------TurboSound---------------
signal trst:			std_logic;
signal bc1:				std_logic;
signal bdir:			std_logic;
signal csts:			std_logic;
signal fon				:std_logic;
signal ay2_dis			:std_logic;
signal ay_clk_ext		:std_logic;
signal port_fffc		:std_logic_vector(7 downto 0);
signal port_fffc_cs		:std_logic;
signal freq				:std_logic_vector(2 downto 0);

----------------SounDrive---------------
signal CHAN_A			:std_logic;
signal CHAN_B			:std_logic;
signal CHAN_C			:std_logic;
signal CHAN_D			:std_logic;

----------------SAA1099---------------
signal	saa_bit			:std_logic;
signal	ENIO			:std_logic;
signal 	CSFFFD			:std_logic;
signal	saa_sel		:std_logic;

----------------VV55------------------
signal RT_F5			:std_logic;
signal P1				:std_logic;

----------------COM-PORT------------------
signal lwr_n			:std_logic;
signal P4				:std_logic;
signal P4I				:std_logic;
signal FI				:std_logic;
signal INT_RQ			:std_logic;
signal INT_CPLD			:std_logic;
signal port93_b0		:std_logic;
signal WAIT_C			:std_logic_vector(3 downto 0);
signal WAIT_IO			:std_logic;
signal WAIT_EN			:std_logic;
signal WAIT_IO_s		:std_logic;
signal WAIT_C_STOP		:std_logic;

------------------Clock-----------------
signal portAS			:std_logic;
signal portDS			:std_logic;
signal cseff7:			std_logic;
signal peff7:			std_logic_vector(7 downto 0);

----------------CACHE------------------
signal cache_cs			:std_logic;
signal cache_en			:std_logic;
signal cache_rd			:std_logic;
signal blok_rom			:std_logic;

-----------------ZXspi-----------------
signal z_data:			std_logic_vector(7 downto 0);
signal spi_start:		std_logic;
signal wr_en:			std_logic;
signal port77_wr:		std_logic;
signal nSDCS:			std_logic;
signal spi_iorqge:		std_logic;

--------------------ZXMC-------------------
signal p_sel:				std_logic;
signal portFE:				std_logic;
signal portF7:				std_logic;
signal portEF:				std_logic;
signal portDF:				std_logic;
signal ports1:				std_logic;
signal wait_mc:				std_logic;
signal iorqge_mc:			std_logic;

---------------------------------------------------------
signal f14:				std_logic;
signal w_a_i_t1:		std_logic;
signal w_a_i_t2:		std_logic;
signal drive_oe			:std_logic;
signal floppy_oe		:std_logic;
signal sound_oe			:std_logic;

-- DFFD port clock and #FD port correction-------------
signal fd_sel			:std_logic;
signal fd_port			:std_logic;
signal dffd_80ds		:std_logic;
signal port_dffd		:std_logic;

--------------------HDD-NEMO/PROFI-----------------------
signal WWC			: std_logic;
signal WWE			: std_logic;
signal RWW			: std_logic;
signal RWE			: std_logic;
signal CS1FX		: std_logic;
signal CS3FX		: std_logic;
signal IOW			: std_logic;
signal WRH			: std_logic;
signal IOR			: std_logic;
signal RDH			: std_logic;
signal nemo_cs0		: std_logic;
signal nemo_cs1		: std_logic;
signal nemo_ior		: std_logic;
signal hdd_iorqge	: std_logic;
signal nemo_ebl		: std_logic;
signal profi_ebl	: std_logic;

begin

f14 <= not zx14mhz;
iorqge <= spi_iorqge or iorqge_mc or hdd_iorqge or not saa_cs or iorq_z or iorqge_sl;

----------------Z80-Synchronization---------------------
process(f14)
	begin
		if f14'event and f14='1' then
    		iorq <= iorq_z or iorqge_sl;
    		m1 <= m1_z;
			rd <= rd_z;
			wr <= wr_z;
        end if;
    end process;

			WAIT_IO_s <= WAIT_IO;
			mrq <= mrq_z;

-- DFFD port clock and #FD port correction

process(f14)
	begin
		if f14'event and f14='1' then
			data_reg <= data;
        end if;
    end process;
    
fd_sel <='0' when Data(7 downto 4)="1101" and Data(2 downto 0)="011" else '1';

--process (fd_sel, m1_z, res)
--	begin
--		if res='0' then
			fd_port <='1';
--		elsif (rising_edge(m1_z)) then
--			fd_port <= fd_sel;
--		end if;
--end process;
port_dffd <='0' when adress(15 downto 8)=X"df" and adress(1)='0' and fd_port='1' and iorq='0' else '1';
c_dffd <= not (port_dffd or wr);

process(f14,res,c_dffd,Data)
begin
	if res='0' then
		dffd_80ds <= '0';
	elsif f14'event and f14='1' then
		if port_dffd='0' and wr='0' then
			dffd_80ds <= Data(7);
		end if;
	end if;
end process;
-----------------DATA BUFFER------------------------
drive_oe <= spi_iorqge or profi_ebl or nemo_ebl;
floppy_oe <= not csff and cswg;
sound_oe <= fon and not CHAN_A and not CHAN_B and not CHAN_C and not CHAN_D and CSFFFD and saa_cs and port_fffc_cs;

t_ap6 <= (rd or not wr or not m1_z) and FI and cache_rd;
csap6 <= not SEL and not drive_oe and floppy_oe and sound_oe and vv55_cs and vi53_cs and vv51_cs and P4I and FI and port_dffd and cache_en and cache_cs;
oe_ap6 <= csap6 and m1_z; 
t_lvc245 <= (rd or not wr or not m1_z or (not spi_iorqge and not csff)) and FI;

----------------VV55------------------------
RT_F5 <='0' when adress(7)='0' and adress(1 downto 0)="11" and iorq='0' and CPM='1' and dos='1' else '1';
P1 <='0' when adress(7)='1' and adress(4 downto 0)="00111" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
vv55_cs <= RT_F5 and P1;

----------------CACHE------------------------
cache_cs <= '0' when adress(6 downto 0)="1111011" and iorq='0' else '1';
process(f14,res,magik,adress,cache_cs,rd)
begin
	if res='0' then
		blok_rom <= '0';
	elsif magik='0' then
		blok_rom <= '1';
	elsif f14'event and f14='1' then
		if cache_cs='0' and rd='0' then
			blok_rom <= adress(7);
		end if;
	end if;
end process;

cache_en <= not blok_rom or pzu;
cache_rd <= mrq or cache_en;

process(f14, wr, cache_en, cache_rd)
	begin
		if f14'event and f14='1' then
			cache_we <= wr;
			blok <= cache_en;
			cache_oe <= cache_rd;
        end if;
    end process;

----------------Serial port------------------------
-- одновибратор - по спаду iorq отсчитывает 400ns WAIT проца
-- для работоспособности периферии в турбе или в режиме 
-- расширенного экрана при подключении третьего кварца XМГц

WAIT_IO <= WAIT_C(2) and WAIT_C(1);
WAIT_C_stop <= WAIT_C(2) and WAIT_C(1) and not WAIT_C(0);
wait_en <= res and not (turbo and not dffd_80ds);
process (f14, res, iorq_z, wait_en) 	
	begin					
		if wait_en = '0' then	
			WAIT_C <= "1111";
        elsif f14'event and f14='0' then
			if iorq_z='1' then
				WAIT_C <= "1111"; --WAIT IORQ = 0
			elsif WAIT_C_stop='0' then
				WAIT_C <= WAIT_C + "001"; --COUNT
			elsif WAIT_C_stop='1' then
				WAIT_C <= WAIT_C; --STOP
			end if;
		end if;
	end process;

lwr_n <= wr or WAIT_IO_s;
lwr <= lwr_n;
vi53_cs <= '0' when adress(7)='1' and adress(4 downto 0)="01111" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
ladr5 <= adress(5);
ladr6 <= adress(6);
P4 <= '0' when adress(7)='1' and adress(4 downto 0)="10011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
vv51_cs <= not adress(6) or P4;
P4I <= adress(6) or P4;

process(f14,lwr_n,res,P4I,Data)
begin
	if (res='0') then
		port93_b0 <= '0';
	elsif f14'event and f14='1' then
		if P4I='0' and lwr_n='0' then
			port93_b0 <= Data(0);
		end if;
	end if;
end process;

INT_RQ <= RXRDT or TXRDT;--or TIMER;
INT_CPLD <= '0' when INT_RQ='1' and CPM='0' and port93_b0='1' else '1';
int <= INT_CPLD;
FI <= m1 or iorq or INT_CPLD;

---------------HDD------------------
-- IDE Profi & Nemo
	-- Profi
profi_ebl <='1' when adress(7)='1' and adress(4 downto 0)="01011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '0';
WWC <='0' when wr='0' and adress(7 downto 0)="11001011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
WWE <='0' when wr='0' and adress(7 downto 0)="11101011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
RWW <='0' when wr='1' and adress(7 downto 0)="11001011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
RWE <='0' when wr='1' and adress(7 downto 0)="11101011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
CS3FX <='0' when wr='0' and adress(7 downto 0)="10101011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';
CS1FX <= RWW and WWE;
	-- Nemo
nemo_ebl<= '1' when adress (2 downto 1)="00" and m1='1' and iorq='0' and cpm='1' and iorqge_mc='0' else '0';
IOW <='0' when adress(2 downto 0)="000" and m1='1' and iorq='0' and cpm='1' and iorqge_mc='0' and rd='1' and wr='0' else '1';
WRH <='0' when adress(2 downto 0)="001" and m1='1' and iorq='0' and cpm='1' and iorqge_mc='0' and rd='1' and wr='0' else '1';
IOR <='0' when adress(2 downto 0)="000" and m1='1' and iorq='0' and cpm='1' and iorqge_mc='0' and rd='0' and wr='1' else '1';
RDH <='0' when adress(2 downto 0)="001" and m1='1' and iorq='0' and cpm='1' and iorqge_mc='0' and rd='0' and wr='1' else '1';
nemo_cs0<= adress(3) when nemo_ebl='1' else '1';
nemo_cs1<= adress(4) when nemo_ebl='1' else '1';
nemo_ior<= ior when nemo_ebl='1' else '1';

process (f14,adress,wr,rd,cs1fx,cs3fx,rwe,wwe,wwc,rww,iow,nemo_ior,nemo_cs0,nemo_cs1,rdh,ior,wrh,nemo_ebl,profi_ebl)
begin
	if f14'event and f14='0' then
	 if profi_ebl = '1' then		
		hdd_a0 <=adress(8);
		hdd_a1 <=adress(9);
		hdd_a2 <=adress(10);
		hdd_wr <=wr;
		hdd_rd <=rd;
		hdd_cs0 <=cs1fx; -- Profi HDD Controller
		hdd_cs1 <=cs3fx;
		hdd_rh_oe <=rwe;
		hdd_rh_c <=cs1fx;
		hdd_wh_oe <=wwe;
		hdd_wh_c <=wwc;
		hdd_rwl_t <=rww;
		hdd_iorqge<= '0';
	 else 
		hdd_a0 <=adress(5);
		hdd_a1 <=adress(6);
		hdd_a2 <=adress(7);
		hdd_wr <=iow;
		hdd_rd <=nemo_ior;
		hdd_cs0 <=nemo_cs0; -- Nemo HDD Controller
		hdd_cs1 <=nemo_cs1;
		hdd_rh_oe <=rdh;
		hdd_rh_c <=ior;
		hdd_wh_oe <=iow;
		hdd_wh_c <=wrh;
		hdd_rwl_t <=ior;
		hdd_iorqge<= nemo_ebl;
	 end if;
	end if;
end process;

w_a_i_t <= not wait_mc and WAIT_IO_s and mag;
res <= reset;

-------------------------некоторые сигналы---------------------
pzu <= adress(15) or adress(14);
mem <= m1 or mrq;
dos_on <= '1' when (adress(15 downto 8) = "00111101" and mem = '0' and rom14 = '1') or (mag = '0') else '0';
dos_of <= (not pzu or mem) and cpm;

RT_F2_1 <='1' when adress(7 downto 5)="001" and adress(1 downto 0)="11" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '0'; --6D
RT_F2_2 <='1' when adress(7 downto 5)="101" and adress(1 downto 0)="11" and iorq='0' and CPM='0' and dos='1' and rom14='0' else '0'; --75
RT_F2_3 <='1' when adress(7 downto 5)="111" and adress(1 downto 0)="11" and iorq='0' and CPM='1' and dos='0' else '0'; --F3 and FB

csff <= RT_F2_1 or RT_F2_2 or RT_F2_3;

RT_F1_1 <= '0' when adress(7)='0' and adress(1 downto 0)="11" and iorq='0' and CPM='0' and dos='1' and rom14='0' else '1';
RT_F1_2 <= '0' when adress(7)='0' and adress(1 downto 0)="11" and iorq='0' and CPM='1' and dos='0' else '1';
RT_F1 <= RT_F1_1 and RT_F1_2;
P0 <='0' when adress(7)='1' and adress(4 downto 0)="00011" and iorq='0' and CPM='0' and dos='1' and rom14='1' else '1';

cswg <= RT_F1 and P0;

tr_dos <= '0' when dos='0' and cpm='1' else '1';
disk0 <= pff(0);
disk1 <= pff(1);
mag <= '0' when magik='0' and mem='0' and pzu='1' and cpm='1' else '1';
nmi <= mag;

-- Profi RTC
portAS <= '1' when adress(9)='0' and adress(7)='1' and adress(5)='1' and adress(3 downto 0)=X"F" and iorq='0' and cpm='0' and rom14='1' else '0';
portDS <= '1' when adress(9)='0' and adress(7)='1' and adress(5)='0' and adress(3 downto 0)=X"F" and iorq='0' and cpm='0' and rom14='1' else '0';

--------------------MEGA------------------------------------
p_sel <= adress(7) and adress(6) and  adress(2) and  adress(1) and not iorq and m1;
portFE <= not adress(0) and adress(3) and adress(4) and  adress(5) and p_sel;
portF7 <= adress(0) and not adress(3) and  adress(4) and adress(5) and p_sel;
portEF <= adress(0) and adress(3) and not adress(4) and adress(5) and p_sel; 
portDF <= adress(0) and  adress(3) and  adress(4) and not adress(5) and adress(9) and p_sel;
ports1 <= portF7 or portEF or portDF or portAS or portDS;
INT0 <= not portFE;
INT1 <= not ports1;
SEL <= not INT0I or ports1;
wait_mc <=  READY_n and SEL;
ADR0 <= adress(5);
ADR1 <= adress(4);
iorqge_mc <= wr and  SEL;

----------------port ff to WG93------------------------------
process(f14,pff,Data,wr,csff,res)
begin 
if res='0' then
	pff(7 downto 0) <= "00000000";
	elsif (f14'event and f14='1') then
	if csff='1' and wr='0' then
	pff <= Data;
	end if;
end if;
end process;	

dden <= pff(6);
side1 <= not pff(4);
hlt <= pff(3);
rst <= pff(2);

process(dos_of,dos_on,f14,reset)
begin
if reset='0' then
	dos <= '0';
	elsif ( f14'event and f14='1') then
		if dos_of='0' then
		dos <= '1';
		end if;
		if dos_on='1' then
		dos <= '0';
		end if;
end if;
end process;	

-----------------FAPCH------------------------------------------------------
process(f8,f)
begin
if (f8'event and f8='0') then------Делитель 8->4->1 мц
	f <= f+1;
end if;
end process;	

f4 <= f(0);---------частота предкомпенсации записи
wg_clk <= f(2);-----частота на ВГ93 (1Мц)	

------------------------------Формирование RAWR 125 мс-------------------------------------------------------------
process(f8,rdat,rd1)
begin
if (f8'event and f8='1') then
	rd1 <= rdat;
end if;
end process;

process(f8,rd1,rd2)
begin
if (f8'event and f8='1') then
	rd2 <= not rd1;
end if;
end process;
rawr <= '0' when wf_de='0' and (rd1='1' and rd2='1') else '1';-- RAWR сформирован, при WF_DE - '1' - запрет на выход

-----------------Собственно ФАПЧ (расчёт сдвигов RCLK)-------------------------------------------------------------
process(f8,rawr,fa)
begin
if (f8'event and f8='1') then
	if rawr = '0' then
		if fa(3 downto 0) < 3 then
		fa(3 downto 0) <= fa(3 downto 0) + 4;
		elsif fa(3 downto 0) < 5 then
		fa(3 downto 0) <= fa(3 downto 0) + 3;
		elsif fa(3 downto 0) < 7 then
		fa(3 downto 0) <= fa(3 downto 0) + 2;
		elsif fa(3 downto 0) = 7 then
		fa(3 downto 0) <= fa(3 downto 0) + 1;
		elsif fa(3 downto 0) > 12 then
		fa(3 downto 0) <= fa(3 downto 0) - 3;
		elsif fa(3 downto 0) > 9 then
		fa(3 downto 0) <= fa(3 downto 0) - 2;
		elsif fa(3 downto 0) > 8 then
		fa(3 downto 0) <= fa(3 downto 0) - 1;
		end if;
		else
		fa <= fa+1;
	end if;
end if;
end process;

process(f8,rclk,wf_de,fa)
	begin
		if wf_de='0' then--Запрет, RCLK если нет обращения к дисководу (тоже самое и для RAWR)
			rclk <= not fa(4);
		else 
			rclk <= '1';
		end if;
end process;

----------------Предкомпенсация записи---------------------------------------------
wdat <= wdata(3);
process(f4,wd,tr43,sr,sl)
begin
if (f4'event and f4 = '1') then
	if (wd = '1') then
	wdata(0) <= tr43 and sr;
	wdata(1) <= not ((tr43 and sr) or (tr43 and sl));
	wdata(2) <= tr43 and sl;
	wdata(3) <= '0';
	else
	wdata(3) <= wdata(2);
	wdata(2) <= wdata(1);
	wdata(1) <= wdata(0);
	wdata(0) <= '0';
end if;
end if;
end process;

---------------------AY-----------------------
process(f14, freq)
	begin
		if (f14'event and f14='0') then --Делитель 14->7->3,5->1,75МГц
			freq <= freq+1;
	end if;
end process;

process(f14,trst,res,csts)
begin
 if (f14'event and f14='1') then
	if (bc1='1' and trst='0') then
		bc1a <= '1'; else bc1a <= '0';
	end if;
	if (bc1='1' and trst='1' and port_fffc (7)='0') then
		bc1b <= '1'; else bc1b <= '0';
	end if;
	if (bdir='1' and trst='0') then
		bdira <= '1'; else bdira <= '0';
	end if;
	if (bdir='1' and trst='1' and port_fffc (7)='0') then
		bdirb <= '1'; else bdirb <= '0';
	end if;
 end if;
end process;

fon <= '0' when adress(15)='1' and adress(1)='0' and iorqge='0' and iorq='0' and m1='1' else '1';
bc1 <= '1' when adress(14)='1' and fon='0' else '0';
bdir <= '1' when wr='0' and fon='0' else '0';
csts <= '0' when (Data(7 downto 1)="1111111" and BC1='1' and BDIR='1') else '1';

process(f14,trst,res,csts,Data)
begin
	if (res='0') then
		trst <= '0';
	elsif ((f14'event and f14='1') and csts='0') then
		trst <= Data(0);
	end if;
end process;

port_fffc_cs <='0' when adress(15 downto 0)=X"fffc" and iorqge='0' and iorq='0' and m1='1' else '1';

process(f14,res,port_fffc_cs,Data,wr) -- порт FFFC
begin
	if (res='0') then
		port_fffc <= "00000000";
	elsif ((f14'event and f14='1') and port_fffc_cs='0' and wr='0') then
		port_fffc <= Data;
	end if;
end process;

process (port_fffc, ay_clk_ext, freq, dffd_80ds)
begin
	if port_fffc(0)='1' or dffd_80ds='1' then
		ay_clk <= ay_clk_ext; -- альтернативная частота музпроцессора
	else
		ay_clk <= freq(2); -- 1,75МГц
	end if;
end process;

process (port_fffc, ay_clk_ext, f)
begin
	if port_fffc(1)='1' then
		ay_clk_ext <= f(1); -- 2МГц
	else
		ay_clk_ext <= f(2); -- 1МГц
	end if;
end process;

-----------------SAA------------------------
CSFFFD <= '0' when adress(15 downto 0)=X"fffd" and mrq='1' and iorq='0' and m1='1' and nemo_ebl='0' and profi_ebl='0' and spi_iorqge='0' and iorqge_mc='0' else '1';
saa_sel <= '0' when Data(7 downto 4)="1111" and Data(2 downto 0)="110" and wr='0' and CSFFFD='0' else '1';

process(f14,saa_bit,res,csts,saa_sel,Data)
begin
	if (res='0') then
		saa_bit <= '1';
	elsif ((f14'event and f14='0') and saa_sel='0') then
		saa_bit <= Data(3);
	end if;
end process;

saa_cs <= '0' when adress(15)='0' and adress(14)='0' and adress(7 downto 0)=X"ff" and saa_bit='0' and m1='1' and iorq='0' and rd='1' and wr='0' and dos='1' and cpm='1' else '1';
saa_a0 <= adress(8) or saa_bit;
saa_clk <= f8 or saa_bit; 

----------------Soundrive------------------------
CHAN_A <= '1' when (adress(7 downto 0)=X"0f" or adress(7 downto 0)=X"3f") and m1='1' and iorq='0' and dos='1' and cpm='1' else '0'; 
CHAN_B <= '1' when (adress(7 downto 0)=X"1f" or adress(7 downto 0)=X"b3") and m1='1' and iorq='0' and dos='1' and cpm='1' else '0'; 
CHAN_C <= '1' when adress(7 downto 0)=X"4f" and m1='1' and iorq='0' and dos='1' and cpm='1' else '0';
CHAN_D <= '1' when (adress(7 downto 0)=X"5f" or adress(7 downto 0)=X"fb") and m1='1' and iorq='0' and dos='1' and cpm='1' else '0';
dac2_cs <= '0' when (CHAN_C='1' or CHAN_D='1') and rd='1' and wr='0' else '1';
dac1_cs <= '0' when (CHAN_A='1' or CHAN_B='1') and rd='1' and wr='0' else '1';
dac <= '0' when CHAN_A = '1' or CHAN_C = '1' else '1';

---------------------------------------------Cmos--------------------------------------------
cseff7<='1' when (adress=61431 and wr='0' and iorq = '0' and m1 = '1') else '0';

process(res,cseff7,f14,peff7)
begin
if (res = '0') then
	peff7 <= "00000000";
	elsif (f14'event and f14 = '1') then
		if cseff7 = '1' then
		peff7 <= Data;
		end if;
end if;
end process;

------------------------DATA-----------------------------

process(f14,Data,csff,z_data,rd,wr,iorq,intr,drq,adress,cpm,timer,fi,rxrdt,txrdt,ri,dcd,p4i)
begin
if csff='1' and rd='0' and wr='1' then
		Data(7 downto 0) <= intr & drq & "111111";
	elsif (adress(7 downto 0)=X"57" and iorq='0' and rd='0' and wr='1' and cpm='1') then
		Data(7 downto 0) <= z_data(7 downto 0);
	elsif (adress(7 downto 0)=X"77" and iorq='0' and rd='0' and wr='1' and cpm='1') then
		Data <= "11111100";
--	elsif TIMER='1' and FI='0' then
--		Data <= "11110111";
	elsif RXRDT='1' and FI='0' then --and TIMER='0' then
		Data <= "11100111";
	elsif TXRDT='1' and FI='0' then --and TIMER='0' then
		Data <= "11101111";
--	elsif RI='0' and P4I='0' and rd='0' and wr='1' then
--		Data <= "11111110";
--	elsif DCD='1' and P4I='0' and rd='0' and wr='1' then
--		Data <= "01111111";
	else
		Data <= "ZZZZZZZZ"; 
end if; 
end process;

-------------------------------------zcspi---------------------------------------------------
spi_start <= '1' when adress(7 downto 0)=X"57" and iorq='0' and m1='1' and cpm='1' else '0';
wr_en <= '1' when adress(7 downto 0)=X"57" and iorq='0' and m1='1' and wr='0' and cpm='1' else '0';
port77_wr <= '1' when adress(7 downto 0)=X"77" and iorq='0' and m1='1' and wr='0' and cpm='1' else '0';
SD_CS <= nSDCS;
spi_iorqge <= '1' when (adress(7 downto 0)=X"57" and iorq='0' and m1='1' and cpm='1') or (adress(7 downto 0)=X"77" and iorq='0' and m1='1' and cpm='1') else '0';

process (port77_wr, res, f14)
	begin
		if res='0' then
			nSDCS <= '1';
		elsif f14'event and f14='1' then
			if port77_wr='1' then
				nSDCS <= Data(1);
			end if;
		end if;
end process;

zcspi_unit: SPI     -- SD
port map(
	DI				=> Data,
	START			=> spi_start,
	WR_EN			=> wr_en,
	CLC     		=> f14,                
	MISO    		=> SD_DO,
	DO				=> z_data,
	SCK     		=> SD_CLK,
	MOSI    		=> SD_DI
);

end extend_arch;