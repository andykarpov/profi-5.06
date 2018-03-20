--ФАПЧ безтабличный версия 1.0
--Составил Лисовой Андрей (Lisica)19.08.2011
--CLK - 8 mh

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL; 
 
entity fapch is                    
port(
f8			: in std_logic;--8 Мегагерц
rdat		: in std_logic;--Вход данных
wf_de		: in std_logic;--с ВГ93
rclk		: buffer std_logic;-- выход RCLK
rawr		:buffer std_logic-- выход RAWR
);
end fapch;

architecture fapch_arch of fapch is
signal rd1:		std_logic;
signal rd2:		std_logic;
signal fa:		std_logic_vector(4 downto 0);

begin


process(f8,rdat,rd1)
begin
if (f8'event and f8='1') then--Формирование RAWR 125 мс
	rd1 <= rdat;
end if;
end process;

process(f8,rd1,rd2)
begin
if (f8'event and f8='1') then
	rd2 <= not rd1;
end if;
end process;

rawr <= '0' when wf_de = '0' and (rd1 = '1' and rd2 = '1') else '1';-- RAWR сформирован, при WF_DE - '1' - запрет на выход

process(f8,rawr,fa)-- собсно смещения RCLK в зависимости от положения RAWR
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
		fa <= fa +1;
	end if;
end if;
end process;

process(f8,rclk)
begin
if wf_de = '0' then--Запрет, RCLK если нет обращения к дисководу (тоже самое и для RAWR)
		rclk <= not fa(4);
		else rclk <= '1';
end if;
end process;

end fapch_arch;