-- ------------------------------------------------------------------------- 
-- High Level Design Compiler for Intel(R) FPGAs Version 21.1 (Release Build #842)
-- Quartus Prime development tool and MATLAB/Simulink Interface
-- 
-- Legal Notice: Copyright 2021 Intel Corporation.  All rights reserved.
-- Your use of  Intel Corporation's design tools,  logic functions and other
-- software and  tools, and its AMPP partner logic functions, and any output
-- files any  of the foregoing (including  device programming  or simulation
-- files), and  any associated  documentation  or information  are expressly
-- subject  to the terms and  conditions of the  Intel FPGA Software License
-- Agreement, Intel MegaCore Function License Agreement, or other applicable
-- license agreement,  including,  without limitation,  that your use is for
-- the  sole  purpose of  programming  logic devices  manufactured by  Intel
-- and  sold by Intel  or its authorized  distributors. Please refer  to the
-- applicable agreement for further details.
-- ---------------------------------------------------------------------------

-- VHDL created from FP_fixed74_to_double_0002
-- VHDL created on Fri Feb 10 10:51:38 2023


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
use std.TextIO.all;
use work.dspba_library_package.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.altera_syncram;
LIBRARY lpm;
USE lpm.lpm_components.all;

entity FP_fixed74_to_double_0002 is
    port (
        a : in std_logic_vector(73 downto 0);  -- sfix74
        q : out std_logic_vector(63 downto 0);  -- float64_m52
        clk : in std_logic;
        areset : in std_logic
    );
end FP_fixed74_to_double_0002;

architecture normal of FP_fixed74_to_double_0002 is

    attribute altera_attribute : string;
    attribute altera_attribute of normal : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF; -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 10037; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 15400; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 12020; -name MESSAGE_DISABLE 12030; -name MESSAGE_DISABLE 12010; -name MESSAGE_DISABLE 12110; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 13410; -name MESSAGE_DISABLE 113007";
    
    signal GND_q : STD_LOGIC_VECTOR (0 downto 0);
    signal VCC_q : STD_LOGIC_VECTOR (0 downto 0);
    signal signX_uid6_fxpToFPTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal xXorSign_uid7_fxpToFPTest_b : STD_LOGIC_VECTOR (73 downto 0);
    signal xXorSign_uid7_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal yE_uid8_fxpToFPTest_a : STD_LOGIC_VECTOR (74 downto 0);
    signal yE_uid8_fxpToFPTest_b : STD_LOGIC_VECTOR (74 downto 0);
    signal yE_uid8_fxpToFPTest_o : STD_LOGIC_VECTOR (74 downto 0);
    signal yE_uid8_fxpToFPTest_q : STD_LOGIC_VECTOR (74 downto 0);
    signal y_uid9_fxpToFPTest_in : STD_LOGIC_VECTOR (73 downto 0);
    signal y_uid9_fxpToFPTest_b : STD_LOGIC_VECTOR (73 downto 0);
    signal maxCount_uid11_fxpToFPTest_q : STD_LOGIC_VECTOR (6 downto 0);
    signal inIsZero_uid12_fxpToFPTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal inIsZero_uid12_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal msbIn_uid13_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_a : STD_LOGIC_VECTOR (11 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_b : STD_LOGIC_VECTOR (11 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_o : STD_LOGIC_VECTOR (11 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_q : STD_LOGIC_VECTOR (11 downto 0);
    signal expFracRnd_uid16_fxpToFPTest_q : STD_LOGIC_VECTOR (64 downto 0);
    signal sticky_uid20_fxpToFPTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal sticky_uid20_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal nr_uid21_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal rnd_uid22_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal expFracR_uid24_fxpToFPTest_a : STD_LOGIC_VECTOR (66 downto 0);
    signal expFracR_uid24_fxpToFPTest_b : STD_LOGIC_VECTOR (66 downto 0);
    signal expFracR_uid24_fxpToFPTest_o : STD_LOGIC_VECTOR (66 downto 0);
    signal expFracR_uid24_fxpToFPTest_q : STD_LOGIC_VECTOR (65 downto 0);
    signal fracR_uid25_fxpToFPTest_in : STD_LOGIC_VECTOR (52 downto 0);
    signal fracR_uid25_fxpToFPTest_b : STD_LOGIC_VECTOR (51 downto 0);
    signal expR_uid26_fxpToFPTest_b : STD_LOGIC_VECTOR (12 downto 0);
    signal udf_uid27_fxpToFPTest_a : STD_LOGIC_VECTOR (14 downto 0);
    signal udf_uid27_fxpToFPTest_b : STD_LOGIC_VECTOR (14 downto 0);
    signal udf_uid27_fxpToFPTest_o : STD_LOGIC_VECTOR (14 downto 0);
    signal udf_uid27_fxpToFPTest_n : STD_LOGIC_VECTOR (0 downto 0);
    signal expInf_uid28_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal ovf_uid29_fxpToFPTest_a : STD_LOGIC_VECTOR (14 downto 0);
    signal ovf_uid29_fxpToFPTest_b : STD_LOGIC_VECTOR (14 downto 0);
    signal ovf_uid29_fxpToFPTest_o : STD_LOGIC_VECTOR (14 downto 0);
    signal ovf_uid29_fxpToFPTest_n : STD_LOGIC_VECTOR (0 downto 0);
    signal excSelector_uid30_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal fracZ_uid31_fxpToFPTest_q : STD_LOGIC_VECTOR (51 downto 0);
    signal fracRPostExc_uid32_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal fracRPostExc_uid32_fxpToFPTest_q : STD_LOGIC_VECTOR (51 downto 0);
    signal udfOrInZero_uid33_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal excSelector_uid34_fxpToFPTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal expZ_uid37_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal expR_uid38_fxpToFPTest_in : STD_LOGIC_VECTOR (10 downto 0);
    signal expR_uid38_fxpToFPTest_b : STD_LOGIC_VECTOR (10 downto 0);
    signal expRPostExc_uid39_fxpToFPTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal expRPostExc_uid39_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal outRes_uid40_fxpToFPTest_q : STD_LOGIC_VECTOR (63 downto 0);
    signal zs_uid42_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (63 downto 0);
    signal vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid47_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal zs_uid49_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (31 downto 0);
    signal vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid54_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal zs_uid56_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (15 downto 0);
    signal vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid61_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal zs_uid63_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (7 downto 0);
    signal vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid68_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal zs_uid70_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (3 downto 0);
    signal vCount_uid72_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid75_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal zs_uid77_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal vCount_uid79_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid82_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vCount_uid86_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid89_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (73 downto 0);
    signal vCount_uid91_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (6 downto 0);
    signal vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_a : STD_LOGIC_VECTOR (8 downto 0);
    signal vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_b : STD_LOGIC_VECTOR (8 downto 0);
    signal vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_o : STD_LOGIC_VECTOR (8 downto 0);
    signal vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_c : STD_LOGIC_VECTOR (0 downto 0);
    signal vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (6 downto 0);
    signal rVStage_uid43_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (63 downto 0);
    signal rVStage_uid43_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (9 downto 0);
    signal l_uid17_fxpToFPTest_merged_bit_select_in : STD_LOGIC_VECTOR (1 downto 0);
    signal l_uid17_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (0 downto 0);
    signal l_uid17_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (0 downto 0);
    signal rVStage_uid50_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (31 downto 0);
    signal rVStage_uid50_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (41 downto 0);
    signal rVStage_uid57_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (15 downto 0);
    signal rVStage_uid57_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (57 downto 0);
    signal rVStage_uid64_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (7 downto 0);
    signal rVStage_uid64_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (65 downto 0);
    signal rVStage_uid71_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (3 downto 0);
    signal rVStage_uid71_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (69 downto 0);
    signal rVStage_uid78_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (1 downto 0);
    signal rVStage_uid78_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (71 downto 0);
    signal rVStage_uid85_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (0 downto 0);
    signal rVStage_uid85_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (72 downto 0);
    signal fracRnd_uid15_fxpToFPTest_merged_bit_select_in : STD_LOGIC_VECTOR (72 downto 0);
    signal fracRnd_uid15_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (52 downto 0);
    signal fracRnd_uid15_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (19 downto 0);
    signal redist0_fracRnd_uid15_fxpToFPTest_merged_bit_select_b_1_q : STD_LOGIC_VECTOR (52 downto 0);
    signal redist1_vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist2_vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist3_vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist4_vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist5_signX_uid6_fxpToFPTest_b_3_q : STD_LOGIC_VECTOR (0 downto 0);

begin


    -- VCC(CONSTANT,1)
    VCC_q <= "1";

    -- signX_uid6_fxpToFPTest(BITSELECT,5)@0
    signX_uid6_fxpToFPTest_b <= STD_LOGIC_VECTOR(a(73 downto 73));

    -- redist5_signX_uid6_fxpToFPTest_b_3(DELAY,111)
    redist5_signX_uid6_fxpToFPTest_b_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => signX_uid6_fxpToFPTest_b, xout => redist5_signX_uid6_fxpToFPTest_b_3_q, clk => clk, aclr => areset );

    -- expInf_uid28_fxpToFPTest(CONSTANT,27)
    expInf_uid28_fxpToFPTest_q <= "11111111111";

    -- expZ_uid37_fxpToFPTest(CONSTANT,36)
    expZ_uid37_fxpToFPTest_q <= "00000000000";

    -- rVStage_uid85_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,104)@2
    rVStage_uid85_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q(73 downto 73);
    rVStage_uid85_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q(72 downto 0);

    -- GND(CONSTANT,0)
    GND_q <= "0";

    -- cStage_uid89_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,88)@2
    cStage_uid89_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid85_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & GND_q;

    -- rVStage_uid78_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,103)@2
    rVStage_uid78_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q(73 downto 72);
    rVStage_uid78_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q(71 downto 0);

    -- zs_uid77_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,76)
    zs_uid77_lzcShifterZ1_uid10_fxpToFPTest_q <= "00";

    -- cStage_uid82_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,81)@2
    cStage_uid82_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid78_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid77_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- rVStage_uid71_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,102)@2
    rVStage_uid71_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q(73 downto 70);
    rVStage_uid71_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q(69 downto 0);

    -- zs_uid70_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,69)
    zs_uid70_lzcShifterZ1_uid10_fxpToFPTest_q <= "0000";

    -- cStage_uid75_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,74)@2
    cStage_uid75_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid71_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid70_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- rVStage_uid64_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,101)@1
    rVStage_uid64_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_q(73 downto 66);
    rVStage_uid64_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_q(65 downto 0);

    -- zs_uid63_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,62)
    zs_uid63_lzcShifterZ1_uid10_fxpToFPTest_q <= "00000000";

    -- cStage_uid68_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,67)@1
    cStage_uid68_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid64_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid63_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- rVStage_uid57_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,100)@1
    rVStage_uid57_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q(73 downto 58);
    rVStage_uid57_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q(57 downto 0);

    -- zs_uid56_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,55)
    zs_uid56_lzcShifterZ1_uid10_fxpToFPTest_q <= "0000000000000000";

    -- cStage_uid61_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,60)@1
    cStage_uid61_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid57_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid56_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- rVStage_uid50_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,99)@1
    rVStage_uid50_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q(73 downto 42);
    rVStage_uid50_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q(41 downto 0);

    -- zs_uid49_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,48)
    zs_uid49_lzcShifterZ1_uid10_fxpToFPTest_q <= "00000000000000000000000000000000";

    -- cStage_uid54_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,53)@1
    cStage_uid54_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid50_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid49_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- rVStage_uid43_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,97)@0
    rVStage_uid43_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= y_uid9_fxpToFPTest_b(73 downto 10);
    rVStage_uid43_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= y_uid9_fxpToFPTest_b(9 downto 0);

    -- zs_uid42_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,41)
    zs_uid42_lzcShifterZ1_uid10_fxpToFPTest_q <= "0000000000000000000000000000000000000000000000000000000000000000";

    -- cStage_uid47_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,46)@0
    cStage_uid47_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid43_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid42_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- xXorSign_uid7_fxpToFPTest(LOGICAL,6)@0
    xXorSign_uid7_fxpToFPTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((73 downto 1 => signX_uid6_fxpToFPTest_b(0)) & signX_uid6_fxpToFPTest_b));
    xXorSign_uid7_fxpToFPTest_q <= a xor xXorSign_uid7_fxpToFPTest_b;

    -- yE_uid8_fxpToFPTest(ADD,7)@0
    yE_uid8_fxpToFPTest_a <= STD_LOGIC_VECTOR("0" & xXorSign_uid7_fxpToFPTest_q);
    yE_uid8_fxpToFPTest_b <= STD_LOGIC_VECTOR("00000000000000000000000000000000000000000000000000000000000000000000000000" & signX_uid6_fxpToFPTest_b);
    yE_uid8_fxpToFPTest_o <= STD_LOGIC_VECTOR(UNSIGNED(yE_uid8_fxpToFPTest_a) + UNSIGNED(yE_uid8_fxpToFPTest_b));
    yE_uid8_fxpToFPTest_q <= yE_uid8_fxpToFPTest_o(74 downto 0);

    -- y_uid9_fxpToFPTest(BITSELECT,8)@0
    y_uid9_fxpToFPTest_in <= STD_LOGIC_VECTOR(yE_uid8_fxpToFPTest_q(73 downto 0));
    y_uid9_fxpToFPTest_b <= STD_LOGIC_VECTOR(y_uid9_fxpToFPTest_in(73 downto 0));

    -- vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,43)@0
    vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid43_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid42_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest(MUX,47)@0 + 1
    vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            CASE (vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_s) IS
                WHEN "0" => vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q <= y_uid9_fxpToFPTest_b;
                WHEN "1" => vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid47_lzcShifterZ1_uid10_fxpToFPTest_q;
                WHEN OTHERS => vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
            END CASE;
        END IF;
    END PROCESS;

    -- vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,50)@1
    vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid50_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid49_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest(MUX,54)@1
    vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid54_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid48_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid54_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,57)@1
    vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid57_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid56_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest(MUX,61)@1
    vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid61_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid55_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid61_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,64)@1
    vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid64_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid63_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest(MUX,68)@1 + 1
    vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            CASE (vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_s) IS
                WHEN "0" => vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid62_lzcShifterZ1_uid10_fxpToFPTest_q;
                WHEN "1" => vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid68_lzcShifterZ1_uid10_fxpToFPTest_q;
                WHEN OTHERS => vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
            END CASE;
        END IF;
    END PROCESS;

    -- vCount_uid72_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,71)@2
    vCount_uid72_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid71_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid70_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest(MUX,75)@2
    vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid72_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid75_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid69_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid75_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- vCount_uid79_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,78)@2
    vCount_uid79_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid78_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid77_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest(MUX,82)@2
    vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid79_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid82_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid76_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid82_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- vCount_uid86_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,85)@2
    vCount_uid86_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid85_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = GND_q ELSE "0";

    -- vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest(MUX,89)@2
    vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid86_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid89_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid83_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid89_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- fracRnd_uid15_fxpToFPTest_merged_bit_select(BITSELECT,105)@2
    fracRnd_uid15_fxpToFPTest_merged_bit_select_in <= vStagei_uid90_lzcShifterZ1_uid10_fxpToFPTest_q(72 downto 0);
    fracRnd_uid15_fxpToFPTest_merged_bit_select_b <= fracRnd_uid15_fxpToFPTest_merged_bit_select_in(72 downto 20);
    fracRnd_uid15_fxpToFPTest_merged_bit_select_c <= fracRnd_uid15_fxpToFPTest_merged_bit_select_in(19 downto 0);

    -- sticky_uid20_fxpToFPTest(LOGICAL,19)@2 + 1
    sticky_uid20_fxpToFPTest_qi <= "1" WHEN fracRnd_uid15_fxpToFPTest_merged_bit_select_c /= "00000000000000000000" ELSE "0";
    sticky_uid20_fxpToFPTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => sticky_uid20_fxpToFPTest_qi, xout => sticky_uid20_fxpToFPTest_q, clk => clk, aclr => areset );

    -- nr_uid21_fxpToFPTest(LOGICAL,20)@3
    nr_uid21_fxpToFPTest_q <= not (l_uid17_fxpToFPTest_merged_bit_select_c);

    -- l_uid17_fxpToFPTest_merged_bit_select(BITSELECT,98)@3
    l_uid17_fxpToFPTest_merged_bit_select_in <= STD_LOGIC_VECTOR(expFracRnd_uid16_fxpToFPTest_q(1 downto 0));
    l_uid17_fxpToFPTest_merged_bit_select_b <= STD_LOGIC_VECTOR(l_uid17_fxpToFPTest_merged_bit_select_in(1 downto 1));
    l_uid17_fxpToFPTest_merged_bit_select_c <= STD_LOGIC_VECTOR(l_uid17_fxpToFPTest_merged_bit_select_in(0 downto 0));

    -- rnd_uid22_fxpToFPTest(LOGICAL,21)@3
    rnd_uid22_fxpToFPTest_q <= l_uid17_fxpToFPTest_merged_bit_select_b or nr_uid21_fxpToFPTest_q or sticky_uid20_fxpToFPTest_q;

    -- maxCount_uid11_fxpToFPTest(CONSTANT,10)
    maxCount_uid11_fxpToFPTest_q <= "1001010";

    -- redist4_vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q_2(DELAY,110)
    redist4_vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist4_vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q_2_q, clk => clk, aclr => areset );

    -- redist3_vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q_1(DELAY,109)
    redist3_vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist3_vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q_1_q, clk => clk, aclr => areset );

    -- redist2_vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q_1(DELAY,108)
    redist2_vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist2_vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q_1_q, clk => clk, aclr => areset );

    -- redist1_vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q_1(DELAY,107)
    redist1_vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist1_vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q_1_q, clk => clk, aclr => areset );

    -- vCount_uid91_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,90)@2
    vCount_uid91_lzcShifterZ1_uid10_fxpToFPTest_q <= redist4_vCount_uid44_lzcShifterZ1_uid10_fxpToFPTest_q_2_q & redist3_vCount_uid51_lzcShifterZ1_uid10_fxpToFPTest_q_1_q & redist2_vCount_uid58_lzcShifterZ1_uid10_fxpToFPTest_q_1_q & redist1_vCount_uid65_lzcShifterZ1_uid10_fxpToFPTest_q_1_q & vCount_uid72_lzcShifterZ1_uid10_fxpToFPTest_q & vCount_uid79_lzcShifterZ1_uid10_fxpToFPTest_q & vCount_uid86_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest(COMPARE,92)@2
    vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_a <= STD_LOGIC_VECTOR("00" & maxCount_uid11_fxpToFPTest_q);
    vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_b <= STD_LOGIC_VECTOR("00" & vCount_uid91_lzcShifterZ1_uid10_fxpToFPTest_q);
    vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_o <= STD_LOGIC_VECTOR(UNSIGNED(vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_a) - UNSIGNED(vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_b));
    vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_c(0) <= vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_o(8);

    -- vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest(MUX,94)@2
    vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_s <= vCountBig_uid93_lzcShifterZ1_uid10_fxpToFPTest_c;
    vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_s, vCount_uid91_lzcShifterZ1_uid10_fxpToFPTest_q, maxCount_uid11_fxpToFPTest_q)
    BEGIN
        CASE (vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_q <= vCount_uid91_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_q <= maxCount_uid11_fxpToFPTest_q;
            WHEN OTHERS => vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- msbIn_uid13_fxpToFPTest(CONSTANT,12)
    msbIn_uid13_fxpToFPTest_q <= "10001001000";

    -- expPreRnd_uid14_fxpToFPTest(SUB,13)@2 + 1
    expPreRnd_uid14_fxpToFPTest_a <= STD_LOGIC_VECTOR("0" & msbIn_uid13_fxpToFPTest_q);
    expPreRnd_uid14_fxpToFPTest_b <= STD_LOGIC_VECTOR("00000" & vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_q);
    expPreRnd_uid14_fxpToFPTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            expPreRnd_uid14_fxpToFPTest_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            expPreRnd_uid14_fxpToFPTest_o <= STD_LOGIC_VECTOR(UNSIGNED(expPreRnd_uid14_fxpToFPTest_a) - UNSIGNED(expPreRnd_uid14_fxpToFPTest_b));
        END IF;
    END PROCESS;
    expPreRnd_uid14_fxpToFPTest_q <= expPreRnd_uid14_fxpToFPTest_o(11 downto 0);

    -- redist0_fracRnd_uid15_fxpToFPTest_merged_bit_select_b_1(DELAY,106)
    redist0_fracRnd_uid15_fxpToFPTest_merged_bit_select_b_1 : dspba_delay
    GENERIC MAP ( width => 53, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => fracRnd_uid15_fxpToFPTest_merged_bit_select_b, xout => redist0_fracRnd_uid15_fxpToFPTest_merged_bit_select_b_1_q, clk => clk, aclr => areset );

    -- expFracRnd_uid16_fxpToFPTest(BITJOIN,15)@3
    expFracRnd_uid16_fxpToFPTest_q <= expPreRnd_uid14_fxpToFPTest_q & redist0_fracRnd_uid15_fxpToFPTest_merged_bit_select_b_1_q;

    -- expFracR_uid24_fxpToFPTest(ADD,23)@3
    expFracR_uid24_fxpToFPTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((66 downto 65 => expFracRnd_uid16_fxpToFPTest_q(64)) & expFracRnd_uid16_fxpToFPTest_q));
    expFracR_uid24_fxpToFPTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000000000000000000000000000000000000000000000000000000000000000000" & rnd_uid22_fxpToFPTest_q));
    expFracR_uid24_fxpToFPTest_o <= STD_LOGIC_VECTOR(SIGNED(expFracR_uid24_fxpToFPTest_a) + SIGNED(expFracR_uid24_fxpToFPTest_b));
    expFracR_uid24_fxpToFPTest_q <= expFracR_uid24_fxpToFPTest_o(65 downto 0);

    -- expR_uid26_fxpToFPTest(BITSELECT,25)@3
    expR_uid26_fxpToFPTest_b <= STD_LOGIC_VECTOR(expFracR_uid24_fxpToFPTest_q(65 downto 53));

    -- expR_uid38_fxpToFPTest(BITSELECT,37)@3
    expR_uid38_fxpToFPTest_in <= expR_uid26_fxpToFPTest_b(10 downto 0);
    expR_uid38_fxpToFPTest_b <= expR_uid38_fxpToFPTest_in(10 downto 0);

    -- ovf_uid29_fxpToFPTest(COMPARE,28)@3
    ovf_uid29_fxpToFPTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((14 downto 13 => expR_uid26_fxpToFPTest_b(12)) & expR_uid26_fxpToFPTest_b));
    ovf_uid29_fxpToFPTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & expInf_uid28_fxpToFPTest_q));
    ovf_uid29_fxpToFPTest_o <= STD_LOGIC_VECTOR(SIGNED(ovf_uid29_fxpToFPTest_a) - SIGNED(ovf_uid29_fxpToFPTest_b));
    ovf_uid29_fxpToFPTest_n(0) <= not (ovf_uid29_fxpToFPTest_o(14));

    -- inIsZero_uid12_fxpToFPTest(LOGICAL,11)@2 + 1
    inIsZero_uid12_fxpToFPTest_qi <= "1" WHEN vCountFinal_uid95_lzcShifterZ1_uid10_fxpToFPTest_q = maxCount_uid11_fxpToFPTest_q ELSE "0";
    inIsZero_uid12_fxpToFPTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => inIsZero_uid12_fxpToFPTest_qi, xout => inIsZero_uid12_fxpToFPTest_q, clk => clk, aclr => areset );

    -- udf_uid27_fxpToFPTest(COMPARE,26)@3
    udf_uid27_fxpToFPTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("00000000000000" & GND_q));
    udf_uid27_fxpToFPTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((14 downto 13 => expR_uid26_fxpToFPTest_b(12)) & expR_uid26_fxpToFPTest_b));
    udf_uid27_fxpToFPTest_o <= STD_LOGIC_VECTOR(SIGNED(udf_uid27_fxpToFPTest_a) - SIGNED(udf_uid27_fxpToFPTest_b));
    udf_uid27_fxpToFPTest_n(0) <= not (udf_uid27_fxpToFPTest_o(14));

    -- udfOrInZero_uid33_fxpToFPTest(LOGICAL,32)@3
    udfOrInZero_uid33_fxpToFPTest_q <= udf_uid27_fxpToFPTest_n or inIsZero_uid12_fxpToFPTest_q;

    -- excSelector_uid34_fxpToFPTest(BITJOIN,33)@3
    excSelector_uid34_fxpToFPTest_q <= ovf_uid29_fxpToFPTest_n & udfOrInZero_uid33_fxpToFPTest_q;

    -- expRPostExc_uid39_fxpToFPTest(MUX,38)@3
    expRPostExc_uid39_fxpToFPTest_s <= excSelector_uid34_fxpToFPTest_q;
    expRPostExc_uid39_fxpToFPTest_combproc: PROCESS (expRPostExc_uid39_fxpToFPTest_s, expR_uid38_fxpToFPTest_b, expZ_uid37_fxpToFPTest_q, expInf_uid28_fxpToFPTest_q)
    BEGIN
        CASE (expRPostExc_uid39_fxpToFPTest_s) IS
            WHEN "00" => expRPostExc_uid39_fxpToFPTest_q <= expR_uid38_fxpToFPTest_b;
            WHEN "01" => expRPostExc_uid39_fxpToFPTest_q <= expZ_uid37_fxpToFPTest_q;
            WHEN "10" => expRPostExc_uid39_fxpToFPTest_q <= expInf_uid28_fxpToFPTest_q;
            WHEN "11" => expRPostExc_uid39_fxpToFPTest_q <= expInf_uid28_fxpToFPTest_q;
            WHEN OTHERS => expRPostExc_uid39_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- fracZ_uid31_fxpToFPTest(CONSTANT,30)
    fracZ_uid31_fxpToFPTest_q <= "0000000000000000000000000000000000000000000000000000";

    -- fracR_uid25_fxpToFPTest(BITSELECT,24)@3
    fracR_uid25_fxpToFPTest_in <= expFracR_uid24_fxpToFPTest_q(52 downto 0);
    fracR_uid25_fxpToFPTest_b <= fracR_uid25_fxpToFPTest_in(52 downto 1);

    -- excSelector_uid30_fxpToFPTest(LOGICAL,29)@3
    excSelector_uid30_fxpToFPTest_q <= inIsZero_uid12_fxpToFPTest_q or ovf_uid29_fxpToFPTest_n or udf_uid27_fxpToFPTest_n;

    -- fracRPostExc_uid32_fxpToFPTest(MUX,31)@3
    fracRPostExc_uid32_fxpToFPTest_s <= excSelector_uid30_fxpToFPTest_q;
    fracRPostExc_uid32_fxpToFPTest_combproc: PROCESS (fracRPostExc_uid32_fxpToFPTest_s, fracR_uid25_fxpToFPTest_b, fracZ_uid31_fxpToFPTest_q)
    BEGIN
        CASE (fracRPostExc_uid32_fxpToFPTest_s) IS
            WHEN "0" => fracRPostExc_uid32_fxpToFPTest_q <= fracR_uid25_fxpToFPTest_b;
            WHEN "1" => fracRPostExc_uid32_fxpToFPTest_q <= fracZ_uid31_fxpToFPTest_q;
            WHEN OTHERS => fracRPostExc_uid32_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- outRes_uid40_fxpToFPTest(BITJOIN,39)@3
    outRes_uid40_fxpToFPTest_q <= redist5_signX_uid6_fxpToFPTest_b_3_q & expRPostExc_uid39_fxpToFPTest_q & fracRPostExc_uid32_fxpToFPTest_q;

    -- xOut(GPOUT,4)@3
    q <= outRes_uid40_fxpToFPTest_q;

END normal;
