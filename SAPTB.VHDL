library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.finish;

entity CPU_tb is
end CPU_tb;
architecture sim of CPU_tb is
    component controller is
        port (
            clk : in std_logic;
            ram_f:in std_logic;
            ram_wr: in unsigned(7 downto 0);
            rst : in std_logic
        );
end component;
constant clk_period : time := 100 ns; --change for whatever the cpu clk is   
signal clk:std_logic := '0';
signal rst:std_logic := '0';
signal RAM_BUS:unsigned(7 downto 0);
signal ram_f:std_logic:='1';
signal loc_addr:unsigned(3 downto 0):=(others => '0');
constant N:integer:=12;--typically 16   
type instarr is array(0 to N) of unsigned(7 downto 0);
constant t_program: instarr := (
    "00001001", --0H\LDA 9H
    "00011010", --1H\ADD AH
    "00011011", --2H\ADD BH
    "00101100", --3H\SUB CH
    "11100000", --4H\HOUT
    "11110000", --5H\
    "11110000", --6H\
    "11110000", --7H\
    "11110000", --8H\
    "00010000", --9H\10H
    "00010100", --AH\14H
    "00011000", --BH\18H
    "00100100" --CH\20H
);
begin

    controller_inst: controller port map (clk,ram_f,RAM_BUS,rst);  
clk_process :process
    begin
   clk <= '0';
   wait for clk_period/2;
   clk <= '1';
   wait for clk_period/2;
end process;
wr_ram:process(clk)
    begin   
    if rising_edge(clk) then
        if ram_f='1' then
            if to_integer(loc_addr) <= N then
                RAM_BUS <= t_program(to_integer(loc_addr));
                loc_addr <= loc_addr + 1;
            else
                ram_f <= '0';
                loc_addr <= "0000"; 
                --RAM_BUS<="ZZZZZZZZ";
            end if;
        end if;       
    end if;
    end process; 
end architecture;