library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    port (
        clk     : in std_logic;
        RAM_BUS : inout unsigned(7 downto 0);
        CE      : in std_logic;
        LM      : in std_logic
    );
end entity RAM;

architecture rtl of RAM is
    type Ramtype is array (0 to 16) of unsigned(7 downto 0);
    signal Ram1   : Ramtype := (others => (others => '0'));
    signal output1 : unsigned(7 downto 0):="00000000";
    signal address : unsigned(3 downto 0) := "0000";
    signal write_en : std_logic := '0';
begin
    -- Combinational logic for RAM_BUS output
   -- RAM_BUS <= output1 when CE = '0' and LM = '1' else (others => 'Z');
RAM_BUS <= output1 when CE='0' and LM='1' else (others => 'Z');       
    process(clk, CE, LM)
    begin
        if rising_edge(clk) then
            --if write_en='0' then 
            --output1 <= Ram1(to_integer(address));
           -- end if;
            if LM = '0' and CE = '0' then
                write_en<='1';
                if write_en = '1' then
                    Ram1(to_integer(address)) <= RAM_BUS;
                    address <= address + 1;
                end if;
            elsif LM/='0' and CE/='0' then
                if write_en='1' then
                    address<= "0000";
                    write_en<='0';
                end if;      
            elsif LM = '0' then
                address <= RAM_BUS(3 downto 0);    
            end if;  
        end if;
    end process;    
    process(address)
        begin
            output1 <= Ram1(to_integer(address));
        end process;    
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inst_REG is
    port(
        clk    : in std_logic;
        clre   : in std_logic;
        ei     : in std_logic;  -- Inverted
        li     : in std_logic;  -- Inverted
        REG_BUS: inout unsigned(7 downto 0);
        control_seq: out unsigned(3 downto 0)
    );
end inst_REG;

architecture rtl of inst_REG is
    signal REG_INS : unsigned(7 downto 0);
begin
    REG_BUS <= REG_INS when ei = '0' else (others => 'Z');  -- Inverted ei
    process(clk)
    begin
        if rising_edge(clk) then
            if clre = '1' then
                REG_INS <= (others => '0');
            elsif li = '0' then  -- Inverted li
                REG_INS <= REG_BUS;
            end if;
        end if;
    end process;
    control_seq <= REG_INS(7 downto 4);
end rtl;
---------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Accumulator is
    port(
        clk: in std_Logic;
        ea: in std_logic; --enable acc
        la: in std_logic; --load acc
        acc_bus: inout unsigned(7 downto 0); 
        acc_out: out unsigned(7 downto 0) --goes to adder/substractor
    );
end Accumulator;
architecture rtl of Accumulator is
    signal Acc : unsigned(7 downto 0) := (others=>'0'); -- Accumulator
begin
    acc_bus <= Acc when ea = '1' else (others => 'Z');
    process(clk)
    begin
        if rising_edge(clk) then
            if la = '0' then
                Acc <= acc_bus;
            end if; 
        end if;
    end process;
    process(Acc)
    begin 
        acc_out <= Acc; --goet to adder/sub shouldn't depend on clk
    end process;    
end rtl;   
--------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity B_reg is
    port(
        clk: in std_Logic;
        lb: in std_logic; --load B register
        b_bus: in unsigned(7 downto 0); 
        b_out: out unsigned(7 downto 0) --goes to adder/substractor
    );
end B_reg;
architecture rtl of B_reg is
signal B_buffer: unsigned(7 downto 0):="00000000";
begin
    process(clk)
	begin
        if rising_edge(clk) then
            if lb='0' then
            B_buffer<=b_bus; --load from bus
            end if;     
        end if;
    end process; 
    process(B_buffer)
    begin
        b_out<=B_buffer; --imeadiately goest to adder/substractor
    end process;    
end architecture;  
--------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity OUT_REG is
    port (
        clk: in std_logic;
        LO : in std_logic;
        BUS_input : in unsigned(7 downto 0);
        result: out unsigned(7 downto 0)
    );
end OUT_REG;
architecture rtl of OUT_REG is 
    signal OUT_buffer:unsigned(7 downto 0) := "00000000";
begin
    result <= OUT_buffer;
process(clk)
    begin
        if rising_edge(clk) then
            if LO='0' then
                OUT_buffer<=BUS_input;
            end if;    
        end if;
    end process;        
end architecture;
----------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity Prog_counter is
    port(
        clk:in std_logic;
        clr:in std_logic;
        CP:in std_logic;
        to_bus:out unsigned(3 downto 0);
        EP:in std_logic
    );
end Prog_counter;
architecture rtl of Prog_counter is
signal counter: unsigned(3 downto 0):= (others => '0');
    begin
    to_BUS <= counter when EP='1' else (others => 'Z');    
        process(clk)
            begin
                if falling_edge(clk) then
                    if CP='1' then
                    counter<=counter+1;
                    end if; 
                    if clr='0' then
                    counter<=(others => '0');
                    end if;     
                end if; 
        end process;     

    end architecture;        



