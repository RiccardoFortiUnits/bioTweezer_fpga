--	Copyright (C) 1988-2014 Altera Corporation

--	Any megafunction design, and related net list (encrypted or decrypted),
--	support information, device programming or simulation file, and any other
--	associated documentation or information provided by Altera or a partner
--	under Altera's Megafunction Partnership Program may be used only to
--	program PLD devices (but not masked PLD devices) from Altera.  Any other
--	use of such megafunction design, net list, support information, device
--	programming or simulation file, or any other related documentation or
--	information is prohibited for any other purpose, including, but not
--	limited to modification, reverse engineering, de-compiling, or use with
--	any other silicon devices, unless such use is explicitly licensed under
--	a separate agreement with Altera or a megafunction partner.  Title to
--	the intellectual property, including patents, copyrights, trademarks,
--	trade secrets, or maskworks, embodied in any such megafunction design,
--	net list, support information, device programming or simulation file, or
--	any other related documentation or information provided by Altera or a
--	megafunction partner, remains with Altera, the megafunction partner, or
--	their respective licensors.  No other licenses, including any licenses
--	needed under any third party's intellectual property, are provided herein.

--NCO ver 14.0 VHDL TESTBENCH

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

use std.textio.all;

entity NCO_8ch_IP_nco_ii_0_tb is
  generic(
		APR	:	INTEGER:=32;
		MPR	:	INTEGER:=16
        );

end NCO_8ch_IP_nco_ii_0_tb;


architecture tb of NCO_8ch_IP_nco_ii_0_tb is

--Convert integer to unsigned std_logicvector function
function int2ustd(value : integer; width : integer) return std_logic_vector is
-- convert integer to unsigned std_logicvector
variable temp :   std_logic_vector(width-1 downto 0);
begin
	if (width>0) then
		temp:=conv_std_logic_vector(conv_unsigned(value, width ), width);
	end if ;
	return temp;
end int2ustd;


component NCO_8ch_IP_nco_ii_0

port(
       phi_inc_i     : IN STD_LOGIC_VECTOR (APR-1 DOWNTO 0);
       clken         : IN STD_LOGIC ;
       clk              : IN STD_LOGIC ;
       reset_n          : IN STD_LOGIC ;
       fsin_o          : OUT STD_LOGIC_VECTOR (MPR-1 DOWNTO 0);
       fcos_o          : OUT STD_LOGIC_VECTOR (MPR-1 DOWNTO 0);
       out_valid        : OUT STD_LOGIC
		);
end component;

signal clk          : std_logic;
signal reset_n      : std_logic;
signal clken        : std_logic;
signal sin_val	     : std_logic_vector (MPR-1 downto 0);
signal cos_val      : std_logic_vector (MPR-1 downto 0);
signal phi          : std_logic_vector (APR-1 downto 0);
signal phi_ch0         : std_logic_vector (APR-1 downto 0);
signal phi_ch1         : std_logic_vector (APR-1 downto 0);
signal phi_ch2         : std_logic_vector (APR-1 downto 0);
signal phi_ch3         : std_logic_vector (APR-1 downto 0);
signal phi_ch4         : std_logic_vector (APR-1 downto 0);
signal phi_ch5         : std_logic_vector (APR-1 downto 0);
signal phi_ch6         : std_logic_vector (APR-1 downto 0);
signal phi_ch7         : std_logic_vector (APR-1 downto 0);
signal sin_val_ch0         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch0         : std_logic_vector (MPR-1 downto 0);
signal sin_val_ch1         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch1         : std_logic_vector (MPR-1 downto 0);
signal sin_val_ch2         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch2         : std_logic_vector (MPR-1 downto 0);
signal sin_val_ch3         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch3         : std_logic_vector (MPR-1 downto 0);
signal sin_val_ch4         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch4         : std_logic_vector (MPR-1 downto 0);
signal sin_val_ch5         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch5         : std_logic_vector (MPR-1 downto 0);
signal sin_val_ch6         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch6         : std_logic_vector (MPR-1 downto 0);
signal sin_val_ch7         : std_logic_vector (MPR-1 downto 0);
signal cos_val_ch7         : std_logic_vector (MPR-1 downto 0);
signal sel_phi      : std_logic_vector(2 downto 0);
signal sel_output   : std_logic_vector(2 downto 0);
signal out_valid    : std_logic;
constant HALF_CYCLE  : time := 25000000 ps;
constant CYCLE       : time := 2*HALF_CYCLE;


begin

-- NCO component instantiation

u1: NCO_8ch_IP_nco_ii_0

port map(  clk              => clk,
           reset_n          => reset_n,
           clken         => clken,
           phi_inc_i     => phi,
           fsin_o          => sin_val,
           fcos_o          => cos_val,
           out_valid        => out_valid
 );

reset_n <= '0',
           '1' after 20*HALF_CYCLE ;
clken   <= '1';
phi_ch0<="00000000000110100011011011100011";
phi_ch1<="00000000000011010001101101110001";
phi_ch2<="00000000000010001011110011110110";
phi_ch3<="00000000000001101000110110111000";
phi_ch4<="00000000000001010011111000101101";
phi_ch5<="00000000000001000101111001111011";
phi_ch6<="00000000000000111011111010110010";
phi_ch7<="00000000000000110100011011011100";

-----------------------------------------------------------------------------------------------
-- Testbench Clock Generation
-----------------------------------------------------------------------------------------------
clk_gen : process
begin
   loop
       clk<='0' ,
     	     '1'  after HALF_CYCLE;
       wait for HALF_CYCLE*2;
   end loop;
end process;

-----------------------------------------------------------------------------------------------
-- Output Sinusoidal Signals to Text Files
-----------------------------------------------------------------------------------------------
testbench_o : process(clk)
file sin_file 		: text open write_mode is "fsin_o_test_hdl.txt";
file cos_file 		: text open write_mode is "fcos_o_test_hdl.txt";
variable ls			: line;
variable lc			: line;
variable sin_int	: integer ;
variable cos_int	: integer ;

  begin
    if rising_edge(clk) then
      if(reset_n='1' and out_valid='1') then
        sin_int := conv_integer(sin_val);
        cos_int := conv_integer(cos_val);
        write(ls,sin_int);
        writeline(sin_file,ls);
        write(lc,cos_int);
        writeline(cos_file,lc);
     end if;		
	end if;		
end process testbench_o;

-----------------------------------------------------------------------------------------------
-- Input Phase Increment Channel Selector
-----------------------------------------------------------------------------------------------
input_select : process(clk) is
  begin
    if(falling_edge(clk)) then
      if(reset_n='0') then
        phi  <= (others=>'0');
        sel_phi <= (others=>'0');
      elsif(clken='1') then
        sel_phi <= sel_phi + int2ustd(1,3);
        case sel_phi is
          when "000" =>
            phi <= phi_ch0;
          when "001" =>
            phi <= phi_ch1;
          when "010" =>
            phi <= phi_ch2;
          when "011" =>
            phi <= phi_ch3;
          when "100" =>
            phi <= phi_ch4;
          when "101" =>
            phi <= phi_ch5;
          when "110" =>
            phi <= phi_ch6;
          when "111" =>
            phi <= phi_ch7;
          when others =>
            phi <= phi_ch0;
        end case;
      end if;
    end if;
  end process input_select;
-----------------------------------------------------------------------------------------------
-- Output Phase Channel Selector
-----------------------------------------------------------------------------------------------
output_select : process(clk) is
  begin
    if(rising_edge(clk)) then
      if(reset_n='0') then
        sin_val_ch0 <= (others=>'0');
        cos_val_ch0 <= (others=>'0');
        sin_val_ch1 <= (others=>'0');
        cos_val_ch1 <= (others=>'0');
        sin_val_ch2 <= (others=>'0');
        cos_val_ch2 <= (others=>'0');
        sin_val_ch3 <= (others=>'0');
        cos_val_ch3 <= (others=>'0');
        sin_val_ch4 <= (others=>'0');
        cos_val_ch4 <= (others=>'0');
        sin_val_ch5 <= (others=>'0');
        cos_val_ch5 <= (others=>'0');
        sin_val_ch6 <= (others=>'0');
        cos_val_ch6 <= (others=>'0');
        sin_val_ch7 <= (others=>'0');
        cos_val_ch7 <= (others=>'0');
        sel_output  <= (others=>'0');
      elsif(out_valid='1' and clken='1') then
        sel_output <= sel_output + int2ustd(1,3);
        case sel_output is
          when "000" =>
            sin_val_ch0 <= sin_val;
            cos_val_ch0 <= cos_val;
          when "001" =>
            sin_val_ch1 <= sin_val;
            cos_val_ch1 <= cos_val;
          when "010" =>
            sin_val_ch2 <= sin_val;
            cos_val_ch2 <= cos_val;
          when "011" =>
            sin_val_ch3 <= sin_val;
            cos_val_ch3 <= cos_val;
          when "100" =>
            sin_val_ch4 <= sin_val;
            cos_val_ch4 <= cos_val;
          when "101" =>
            sin_val_ch5 <= sin_val;
            cos_val_ch5 <= cos_val;
          when "110" =>
            sin_val_ch6 <= sin_val;
            cos_val_ch6 <= cos_val;
          when "111" =>
            sin_val_ch7 <= sin_val;
            cos_val_ch7 <= cos_val;
          when others =>
            sin_val_ch0 <= sin_val;
            cos_val_ch0 <= cos_val;
        end case;
      end if;
    end if;
  end process output_select;
end tb;
