library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity controller is
    port (
        
        clk : in std_logic;
        ram_f:in std_logic;
        ram_wr: in unsigned(7 downto 0);
        rst : in std_logic
    );
end controller;
architecture rtl of controller is

component RAM is 
    port(
        clk : in std_logic;
        RAM_BUS:inout unsigned(7 downto 0); --8 bit(both data and address)
        CE: in std_logic;
        LM:in std_logic
    );
end component;
component inst_REG is 
   port(
       clk: in std_logic;
       clre: in std_logic;
        ei: in std_logic;
       li: in std_logic; --load
      REG_BUS:inout unsigned(7 downto 0);
       control_seq:out unsigned(3 downto 0)
   );
end component;
component Accumulator is 
    port(
        clk: in std_Logic;
        ea: in std_logic; --enable acc
        la: in std_logic; --load acc
        acc_bus: inout unsigned(7 downto 0); 
        acc_out: out unsigned(7 downto 0) --goes to adder/substractor
    );
end component;
component B_reg is
    port(
       clk: in std_Logic;
       lb: in std_logic; --load B register
       b_bus: in unsigned(7 downto 0); 
        b_out: out unsigned(7 downto 0) --goes to adder/substractor
   );
end component;
component OUT_REG is --for output
    port(
       clk:in std_logic;
       LO : in std_logic;
       BUS_input : in unsigned(7 downto 0);
       result: out unsigned(7 downto 0)
    );
end component;    
component Prog_counter is
   port(
       clk:in std_logic;
       clr:in std_logic;
       CP:in std_logic;
       to_bus:out unsigned(3 downto 0);
       EP:in std_logic
    );
end component;      
signal T_state: unsigned(5 downto 0):="000000";
signal P_counter:unsigned(3 downto 0):="0000";--program counter
signal Comm_BUS:unsigned(7 downto 0); --common bus
signal acc_out:unsigned(7 downto 0):="00000000";
signal b_out:unsigned(7 downto 0):="00000000";
signal result_output:unsigned(7 downto 0);
signal clre:std_logic:='0';
signal clr:std_logic:='1';--inverted
signal control_bits:std_logic_vector(11 downto 0);--:="001111100011";--off state
signal control_seq:unsigned(3 downto 0); --opcode
signal T_start:std_logic:='0';
signal r_counter:unsigned(3 downto 0):=(others => '0');
signal write_st: std_logic:=ram_f;
signal ALU_REG:unsigned(7 downto 0):="00000000";
signal counter_o:unsigned(1 downto 0):="00";
constant N:integer:=13;--typically 16   
begin
INSTR: inst_REG port map(clk,clre,control_bits(6),control_bits(7),Comm_BUS,control_seq);    
RMAM: RAM port map(clk,Comm_BUS,control_bits(8),control_bits(9));
PC: Prog_counter port map(clk,clr,control_bits(11),Comm_BUS(3 downto 0),control_bits(10)); 
ACC: Accumulator port map(clk,control_bits(4),control_bits(5),Comm_BUS,acc_out); 
BREG: B_reg port map(clk,control_bits(1),Comm_BUS,b_out);
RES_out: OUT_REG port map(clk,control_bits(0),Comm_BUS,result_output); --this need to be fixed in controller
RAM_write:process(clk)
    begin 
        if  write_st='1' then 
            if rising_edge(clk) then
                control_bits(8) <= '0';
                control_bits(9) <= '0';
                if to_integer(r_counter) <= N then
                    Comm_BUS <= ram_wr;
                    r_counter <= r_counter+1;
                else   
                    write_st<='0';
                    r_counter <= "0000";
                    control_bits(8) <= 'Z';
                    control_bits(9) <= 'Z';
                    Comm_BUS<=(others => 'Z');
                end if;
            end if;
        end if;
    end process;                    
   ring_counter: 
    process(clk,write_st)
    begin
        if write_st='0' and counter_o < 3 then
            counter_o <= counter_o+1; --for syncing with ram/write operation
        end if;
        if counter_o>=3 then      
        if falling_edge(clk) then
            if T_start='0' then
                T_state <= "000001";
                T_start <= '1';
            else    
            T_state<=shift_left(unsigned(T_state), 1);
            end if;
            if T_state="100000" then
                T_state<="000001";
            end if;    
        end if;    
        end if;    
    end process;
    Controller:
        process(T_state,control_seq)
	begin
            case T_state is 
                when "000001" =>
                    control_bits <= "010111100011"; --address state; Ep,LM
                when "000010" => 
                    control_bits <= "101111100011";  --program counter incremented; CP
                when "000100" => 
                    control_bits <= "001001100011";  --memory state;CE,LI
                when "001000" => 
                    control_bits <= "000110100011"; --EI,LM
                when "010000" => 
                    case control_seq is 
                        when "0000" => --load Accumulator
                            control_bits <= "001011000011"; --CE,LA
                        when "0001" => --ADD load B
                            control_bits <="001011100001"; --CE,LB
                        when "0010" => --SUB
                            control_bits <="001011100001"; --same    
                        when "1110" => --OUT
                            control_bits <= "001111110010";--Ea and LO are active
                        when others =>
                            control_bits <= "001111100011"; --nop   
                    end case;    
                when "100000" => 
                    case control_seq is 
                       when "0000" => 
                            control_bits <= "001111100011"; --nop
                       when "0001" => --ADD
                            control_bits <=  "001111000111"; --LA,EU 
                       when "0010" => --SUB
                            control_bits <="001111001111"; --SU,LA,EU
                       when "1110" => --OUT
                            control_bits <= "001111100011"; --nop
                        when others =>
                            control_bits <= "001111100011"; --nop       
                    end case; 
                    when others =>
                        control_bits <= "00ZZ11100011"; --so i can write ram           
                end case;  
    end process;
    ALU:
        process(control_bits)
        begin
            if control_bits(2)='1' and control_bits(3)='0' then
                ALU_REG <= acc_out+b_out;           
            elsif control_bits(2)='1' and control_bits(3)='1' then
                ALU_REG <= acc_out-b_out;
            end if;
        end process;    
    Comm_BUS<=ALU_REG when control_bits(2)='1' else (others=>'Z'); 
clr <= not rst; --inverted 
clre <= rst;          
end architecture;