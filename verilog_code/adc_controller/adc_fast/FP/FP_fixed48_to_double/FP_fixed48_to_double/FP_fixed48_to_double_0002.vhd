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

-- VHDL created from FP_fixed48_to_double_0002
-- VHDL created on Thu Mar 16 14:46:24 2023


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

entity FP_fixed48_to_double_0002 is
    port (
        a : in std_logic_vector(47 downto 0);  -- sfix48
        q : out std_logic_vector(63 downto 0);  -- float64_m52
        clk : in std_logic;
        areset : in std_logic
    );
end FP_fixed48_to_double_0002;

architecture normal of FP_fixed48_to_double_0002 is

    attribute altera_attribute : string;
    attribute altera_attribute of normal : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF; -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 10037; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 15400; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 12020; -name MESSAGE_DISABLE 12030; -name MESSAGE_DISABLE 12010; -name MESSAGE_DISABLE 12110; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 13410; -name MESSAGE_DISABLE 113007";
    
    signal GND_q : STD_LOGIC_VECTOR (0 downto 0);
    signal VCC_q : STD_LOGIC_VECTOR (0 downto 0);
    signal signX_uid6_fxpToFPTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal xXorSign_uid7_fxpToFPTest_b : STD_LOGIC_VECTOR (47 downto 0);
    signal xXorSign_uid7_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal yE_uid8_fxpToFPTest_a : STD_LOGIC_VECTOR (48 downto 0);
    signal yE_uid8_fxpToFPTest_b : STD_LOGIC_VECTOR (48 downto 0);
    signal yE_uid8_fxpToFPTest_o : STD_LOGIC_VECTOR (48 downto 0);
    signal yE_uid8_fxpToFPTest_q : STD_LOGIC_VECTOR (48 downto 0);
    signal y_uid9_fxpToFPTest_in : STD_LOGIC_VECTOR (47 downto 0);
    signal y_uid9_fxpToFPTest_b : STD_LOGIC_VECTOR (47 downto 0);
    signal maxCount_uid11_fxpToFPTest_q : STD_LOGIC_VECTOR (5 downto 0);
    signal inIsZero_uid12_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal msbIn_uid13_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_a : STD_LOGIC_VECTOR (11 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_b : STD_LOGIC_VECTOR (11 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_o : STD_LOGIC_VECTOR (11 downto 0);
    signal expPreRnd_uid14_fxpToFPTest_q : STD_LOGIC_VECTOR (11 downto 0);
    signal zP_uid15_fxpToFPTest_q : STD_LOGIC_VECTOR (4 downto 0);
    signal fracRU_uid16_fxpToFPTest_in : STD_LOGIC_VECTOR (46 downto 0);
    signal fracRU_uid16_fxpToFPTest_b : STD_LOGIC_VECTOR (46 downto 0);
    signal fracRR_uid17_fxpToFPTest_q : STD_LOGIC_VECTOR (51 downto 0);
    signal udf_uid19_fxpToFPTest_a : STD_LOGIC_VECTOR (13 downto 0);
    signal udf_uid19_fxpToFPTest_b : STD_LOGIC_VECTOR (13 downto 0);
    signal udf_uid19_fxpToFPTest_o : STD_LOGIC_VECTOR (13 downto 0);
    signal udf_uid19_fxpToFPTest_n : STD_LOGIC_VECTOR (0 downto 0);
    signal expInf_uid20_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal ovf_uid21_fxpToFPTest_a : STD_LOGIC_VECTOR (13 downto 0);
    signal ovf_uid21_fxpToFPTest_b : STD_LOGIC_VECTOR (13 downto 0);
    signal ovf_uid21_fxpToFPTest_o : STD_LOGIC_VECTOR (13 downto 0);
    signal ovf_uid21_fxpToFPTest_n : STD_LOGIC_VECTOR (0 downto 0);
    signal excSelector_uid22_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal fracZ_uid23_fxpToFPTest_q : STD_LOGIC_VECTOR (51 downto 0);
    signal fracRPostExc_uid24_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal fracRPostExc_uid24_fxpToFPTest_q : STD_LOGIC_VECTOR (51 downto 0);
    signal udfOrInZero_uid25_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal excSelector_uid26_fxpToFPTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal expZ_uid29_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal expR_uid30_fxpToFPTest_in : STD_LOGIC_VECTOR (10 downto 0);
    signal expR_uid30_fxpToFPTest_b : STD_LOGIC_VECTOR (10 downto 0);
    signal expRPostExc_uid31_fxpToFPTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal expRPostExc_uid31_fxpToFPTest_q : STD_LOGIC_VECTOR (10 downto 0);
    signal outRes_uid32_fxpToFPTest_q : STD_LOGIC_VECTOR (63 downto 0);
    signal zs_uid34_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (31 downto 0);
    signal vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid39_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal zs_uid41_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (15 downto 0);
    signal vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid46_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal zs_uid48_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (7 downto 0);
    signal vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid53_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal zs_uid55_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (3 downto 0);
    signal vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid60_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal zs_uid62_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal vCount_uid64_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid67_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vCount_uid71_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal cStage_uid74_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal vCount_uid76_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (5 downto 0);
    signal vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_a : STD_LOGIC_VECTOR (7 downto 0);
    signal vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_b : STD_LOGIC_VECTOR (7 downto 0);
    signal vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_o : STD_LOGIC_VECTOR (7 downto 0);
    signal vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_c : STD_LOGIC_VECTOR (0 downto 0);
    signal vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_q : STD_LOGIC_VECTOR (5 downto 0);
    signal rVStage_uid35_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (31 downto 0);
    signal rVStage_uid35_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (15 downto 0);
    signal rVStage_uid42_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (15 downto 0);
    signal rVStage_uid42_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (31 downto 0);
    signal rVStage_uid49_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (7 downto 0);
    signal rVStage_uid49_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (39 downto 0);
    signal rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (3 downto 0);
    signal rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (43 downto 0);
    signal rVStage_uid63_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (1 downto 0);
    signal rVStage_uid63_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (45 downto 0);
    signal rVStage_uid70_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b : STD_LOGIC_VECTOR (0 downto 0);
    signal rVStage_uid70_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c : STD_LOGIC_VECTOR (46 downto 0);
    signal redist0_rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c_1_q : STD_LOGIC_VECTOR (43 downto 0);
    signal redist1_vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q_1_q : STD_LOGIC_VECTOR (47 downto 0);
    signal redist2_vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist3_vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist4_vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist5_fracRU_uid16_fxpToFPTest_b_1_q : STD_LOGIC_VECTOR (46 downto 0);
    signal redist6_signX_uid6_fxpToFPTest_b_3_q : STD_LOGIC_VECTOR (0 downto 0);

begin


    -- VCC(CONSTANT,1)
    VCC_q <= "1";

    -- signX_uid6_fxpToFPTest(BITSELECT,5)@0
    signX_uid6_fxpToFPTest_b <= STD_LOGIC_VECTOR(a(47 downto 47));

    -- redist6_signX_uid6_fxpToFPTest_b_3(DELAY,94)
    redist6_signX_uid6_fxpToFPTest_b_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => signX_uid6_fxpToFPTest_b, xout => redist6_signX_uid6_fxpToFPTest_b_3_q, clk => clk, aclr => areset );

    -- expInf_uid20_fxpToFPTest(CONSTANT,19)
    expInf_uid20_fxpToFPTest_q <= "11111111111";

    -- expZ_uid29_fxpToFPTest(CONSTANT,28)
    expZ_uid29_fxpToFPTest_q <= "00000000000";

    -- maxCount_uid11_fxpToFPTest(CONSTANT,10)
    maxCount_uid11_fxpToFPTest_q <= "110000";

    -- zs_uid34_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,33)
    zs_uid34_lzcShifterZ1_uid10_fxpToFPTest_q <= "00000000000000000000000000000000";

    -- xXorSign_uid7_fxpToFPTest(LOGICAL,6)@0
    xXorSign_uid7_fxpToFPTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((47 downto 1 => signX_uid6_fxpToFPTest_b(0)) & signX_uid6_fxpToFPTest_b));
    xXorSign_uid7_fxpToFPTest_q <= a xor xXorSign_uid7_fxpToFPTest_b;

    -- yE_uid8_fxpToFPTest(ADD,7)@0
    yE_uid8_fxpToFPTest_a <= STD_LOGIC_VECTOR("0" & xXorSign_uid7_fxpToFPTest_q);
    yE_uid8_fxpToFPTest_b <= STD_LOGIC_VECTOR("000000000000000000000000000000000000000000000000" & signX_uid6_fxpToFPTest_b);
    yE_uid8_fxpToFPTest_o <= STD_LOGIC_VECTOR(UNSIGNED(yE_uid8_fxpToFPTest_a) + UNSIGNED(yE_uid8_fxpToFPTest_b));
    yE_uid8_fxpToFPTest_q <= yE_uid8_fxpToFPTest_o(48 downto 0);

    -- y_uid9_fxpToFPTest(BITSELECT,8)@0
    y_uid9_fxpToFPTest_in <= STD_LOGIC_VECTOR(yE_uid8_fxpToFPTest_q(47 downto 0));
    y_uid9_fxpToFPTest_b <= STD_LOGIC_VECTOR(y_uid9_fxpToFPTest_in(47 downto 0));

    -- rVStage_uid35_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,82)@0
    rVStage_uid35_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= y_uid9_fxpToFPTest_b(47 downto 16);
    rVStage_uid35_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= y_uid9_fxpToFPTest_b(15 downto 0);

    -- vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,35)@0
    vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid35_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid34_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- redist4_vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q_2(DELAY,92)
    redist4_vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist4_vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q_2_q, clk => clk, aclr => areset );

    -- zs_uid41_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,40)
    zs_uid41_lzcShifterZ1_uid10_fxpToFPTest_q <= "0000000000000000";

    -- cStage_uid39_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,38)@0
    cStage_uid39_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid35_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid34_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest(MUX,39)@0 + 1
    vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            CASE (vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_s) IS
                WHEN "0" => vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q <= y_uid9_fxpToFPTest_b;
                WHEN "1" => vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid39_lzcShifterZ1_uid10_fxpToFPTest_q;
                WHEN OTHERS => vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
            END CASE;
        END IF;
    END PROCESS;

    -- rVStage_uid42_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,83)@1
    rVStage_uid42_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q(47 downto 32);
    rVStage_uid42_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q(31 downto 0);

    -- vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,42)@1
    vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid42_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid41_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- redist3_vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q_1(DELAY,91)
    redist3_vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist3_vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q_1_q, clk => clk, aclr => areset );

    -- zs_uid48_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,47)
    zs_uid48_lzcShifterZ1_uid10_fxpToFPTest_q <= "00000000";

    -- cStage_uid46_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,45)@1
    cStage_uid46_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid42_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid41_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest(MUX,46)@1
    vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid46_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid40_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid46_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid49_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,84)@1
    rVStage_uid49_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q(47 downto 40);
    rVStage_uid49_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q(39 downto 0);

    -- vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,49)@1
    vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid49_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid48_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- redist2_vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q_1(DELAY,90)
    redist2_vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist2_vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q_1_q, clk => clk, aclr => areset );

    -- zs_uid55_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,54)
    zs_uid55_lzcShifterZ1_uid10_fxpToFPTest_q <= "0000";

    -- cStage_uid53_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,52)@1
    cStage_uid53_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid49_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid48_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest(MUX,53)@1
    vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid53_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid47_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid53_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,85)@1
    rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q(47 downto 44);
    rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q(43 downto 0);

    -- vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,56)@1 + 1
    vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_qi <= "1" WHEN rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid55_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";
    vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_qi, xout => vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_q, clk => clk, aclr => areset );

    -- zs_uid62_lzcShifterZ1_uid10_fxpToFPTest(CONSTANT,61)
    zs_uid62_lzcShifterZ1_uid10_fxpToFPTest_q <= "00";

    -- redist0_rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c_1(DELAY,88)
    redist0_rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c_1 : dspba_delay
    GENERIC MAP ( width => 44, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c, xout => redist0_rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c_1_q, clk => clk, aclr => areset );

    -- cStage_uid60_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,59)@2
    cStage_uid60_lzcShifterZ1_uid10_fxpToFPTest_q <= redist0_rVStage_uid56_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c_1_q & zs_uid55_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- redist1_vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q_1(DELAY,89)
    redist1_vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q_1 : dspba_delay
    GENERIC MAP ( width => 48, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q, xout => redist1_vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q_1_q, clk => clk, aclr => areset );

    -- vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest(MUX,60)@2
    vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_s, redist1_vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q_1_q, cStage_uid60_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q <= redist1_vStagei_uid54_lzcShifterZ1_uid10_fxpToFPTest_q_1_q;
            WHEN "1" => vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid60_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid63_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,86)@2
    rVStage_uid63_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q(47 downto 46);
    rVStage_uid63_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q(45 downto 0);

    -- vCount_uid64_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,63)@2
    vCount_uid64_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid63_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = zs_uid62_lzcShifterZ1_uid10_fxpToFPTest_q ELSE "0";

    -- GND(CONSTANT,0)
    GND_q <= "0";

    -- cStage_uid67_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,66)@2
    cStage_uid67_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid63_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & zs_uid62_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest(MUX,67)@2
    vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid64_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid67_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid61_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid67_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- rVStage_uid70_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select(BITSELECT,87)@2
    rVStage_uid70_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b <= vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q(47 downto 47);
    rVStage_uid70_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c <= vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q(46 downto 0);

    -- vCount_uid71_lzcShifterZ1_uid10_fxpToFPTest(LOGICAL,70)@2
    vCount_uid71_lzcShifterZ1_uid10_fxpToFPTest_q <= "1" WHEN rVStage_uid70_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_b = GND_q ELSE "0";

    -- vCount_uid76_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,75)@2
    vCount_uid76_lzcShifterZ1_uid10_fxpToFPTest_q <= redist4_vCount_uid36_lzcShifterZ1_uid10_fxpToFPTest_q_2_q & redist3_vCount_uid43_lzcShifterZ1_uid10_fxpToFPTest_q_1_q & redist2_vCount_uid50_lzcShifterZ1_uid10_fxpToFPTest_q_1_q & vCount_uid57_lzcShifterZ1_uid10_fxpToFPTest_q & vCount_uid64_lzcShifterZ1_uid10_fxpToFPTest_q & vCount_uid71_lzcShifterZ1_uid10_fxpToFPTest_q;

    -- vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest(COMPARE,77)@2
    vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_a <= STD_LOGIC_VECTOR("00" & maxCount_uid11_fxpToFPTest_q);
    vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_b <= STD_LOGIC_VECTOR("00" & vCount_uid76_lzcShifterZ1_uid10_fxpToFPTest_q);
    vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_o <= STD_LOGIC_VECTOR(UNSIGNED(vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_a) - UNSIGNED(vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_b));
    vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_c(0) <= vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_o(7);

    -- vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest(MUX,79)@2 + 1
    vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_s <= vCountBig_uid78_lzcShifterZ1_uid10_fxpToFPTest_c;
    vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            CASE (vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_s) IS
                WHEN "0" => vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_q <= vCount_uid76_lzcShifterZ1_uid10_fxpToFPTest_q;
                WHEN "1" => vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_q <= maxCount_uid11_fxpToFPTest_q;
                WHEN OTHERS => vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
            END CASE;
        END IF;
    END PROCESS;

    -- msbIn_uid13_fxpToFPTest(CONSTANT,12)
    msbIn_uid13_fxpToFPTest_q <= "10000101110";

    -- expPreRnd_uid14_fxpToFPTest(SUB,13)@3
    expPreRnd_uid14_fxpToFPTest_a <= STD_LOGIC_VECTOR("0" & msbIn_uid13_fxpToFPTest_q);
    expPreRnd_uid14_fxpToFPTest_b <= STD_LOGIC_VECTOR("000000" & vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_q);
    expPreRnd_uid14_fxpToFPTest_o <= STD_LOGIC_VECTOR(UNSIGNED(expPreRnd_uid14_fxpToFPTest_a) - UNSIGNED(expPreRnd_uid14_fxpToFPTest_b));
    expPreRnd_uid14_fxpToFPTest_q <= expPreRnd_uid14_fxpToFPTest_o(11 downto 0);

    -- expR_uid30_fxpToFPTest(BITSELECT,29)@3
    expR_uid30_fxpToFPTest_in <= expPreRnd_uid14_fxpToFPTest_q(10 downto 0);
    expR_uid30_fxpToFPTest_b <= expR_uid30_fxpToFPTest_in(10 downto 0);

    -- ovf_uid21_fxpToFPTest(COMPARE,20)@3
    ovf_uid21_fxpToFPTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((13 downto 12 => expPreRnd_uid14_fxpToFPTest_q(11)) & expPreRnd_uid14_fxpToFPTest_q));
    ovf_uid21_fxpToFPTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & expInf_uid20_fxpToFPTest_q));
    ovf_uid21_fxpToFPTest_o <= STD_LOGIC_VECTOR(SIGNED(ovf_uid21_fxpToFPTest_a) - SIGNED(ovf_uid21_fxpToFPTest_b));
    ovf_uid21_fxpToFPTest_n(0) <= not (ovf_uid21_fxpToFPTest_o(13));

    -- inIsZero_uid12_fxpToFPTest(LOGICAL,11)@3
    inIsZero_uid12_fxpToFPTest_q <= "1" WHEN vCountFinal_uid80_lzcShifterZ1_uid10_fxpToFPTest_q = maxCount_uid11_fxpToFPTest_q ELSE "0";

    -- udf_uid19_fxpToFPTest(COMPARE,18)@3
    udf_uid19_fxpToFPTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000000000000" & GND_q));
    udf_uid19_fxpToFPTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((13 downto 12 => expPreRnd_uid14_fxpToFPTest_q(11)) & expPreRnd_uid14_fxpToFPTest_q));
    udf_uid19_fxpToFPTest_o <= STD_LOGIC_VECTOR(SIGNED(udf_uid19_fxpToFPTest_a) - SIGNED(udf_uid19_fxpToFPTest_b));
    udf_uid19_fxpToFPTest_n(0) <= not (udf_uid19_fxpToFPTest_o(13));

    -- udfOrInZero_uid25_fxpToFPTest(LOGICAL,24)@3
    udfOrInZero_uid25_fxpToFPTest_q <= udf_uid19_fxpToFPTest_n or inIsZero_uid12_fxpToFPTest_q;

    -- excSelector_uid26_fxpToFPTest(BITJOIN,25)@3
    excSelector_uid26_fxpToFPTest_q <= ovf_uid21_fxpToFPTest_n & udfOrInZero_uid25_fxpToFPTest_q;

    -- expRPostExc_uid31_fxpToFPTest(MUX,30)@3
    expRPostExc_uid31_fxpToFPTest_s <= excSelector_uid26_fxpToFPTest_q;
    expRPostExc_uid31_fxpToFPTest_combproc: PROCESS (expRPostExc_uid31_fxpToFPTest_s, expR_uid30_fxpToFPTest_b, expZ_uid29_fxpToFPTest_q, expInf_uid20_fxpToFPTest_q)
    BEGIN
        CASE (expRPostExc_uid31_fxpToFPTest_s) IS
            WHEN "00" => expRPostExc_uid31_fxpToFPTest_q <= expR_uid30_fxpToFPTest_b;
            WHEN "01" => expRPostExc_uid31_fxpToFPTest_q <= expZ_uid29_fxpToFPTest_q;
            WHEN "10" => expRPostExc_uid31_fxpToFPTest_q <= expInf_uid20_fxpToFPTest_q;
            WHEN "11" => expRPostExc_uid31_fxpToFPTest_q <= expInf_uid20_fxpToFPTest_q;
            WHEN OTHERS => expRPostExc_uid31_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- fracZ_uid23_fxpToFPTest(CONSTANT,22)
    fracZ_uid23_fxpToFPTest_q <= "0000000000000000000000000000000000000000000000000000";

    -- cStage_uid74_lzcShifterZ1_uid10_fxpToFPTest(BITJOIN,73)@2
    cStage_uid74_lzcShifterZ1_uid10_fxpToFPTest_q <= rVStage_uid70_lzcShifterZ1_uid10_fxpToFPTest_merged_bit_select_c & GND_q;

    -- vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest(MUX,74)@2
    vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_s <= vCount_uid71_lzcShifterZ1_uid10_fxpToFPTest_q;
    vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_combproc: PROCESS (vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_s, vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q, cStage_uid74_lzcShifterZ1_uid10_fxpToFPTest_q)
    BEGIN
        CASE (vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_s) IS
            WHEN "0" => vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_q <= vStagei_uid68_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN "1" => vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_q <= cStage_uid74_lzcShifterZ1_uid10_fxpToFPTest_q;
            WHEN OTHERS => vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- fracRU_uid16_fxpToFPTest(BITSELECT,15)@2
    fracRU_uid16_fxpToFPTest_in <= vStagei_uid75_lzcShifterZ1_uid10_fxpToFPTest_q(46 downto 0);
    fracRU_uid16_fxpToFPTest_b <= fracRU_uid16_fxpToFPTest_in(46 downto 0);

    -- redist5_fracRU_uid16_fxpToFPTest_b_1(DELAY,93)
    redist5_fracRU_uid16_fxpToFPTest_b_1 : dspba_delay
    GENERIC MAP ( width => 47, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => fracRU_uid16_fxpToFPTest_b, xout => redist5_fracRU_uid16_fxpToFPTest_b_1_q, clk => clk, aclr => areset );

    -- zP_uid15_fxpToFPTest(CONSTANT,14)
    zP_uid15_fxpToFPTest_q <= "00000";

    -- fracRR_uid17_fxpToFPTest(BITJOIN,16)@3
    fracRR_uid17_fxpToFPTest_q <= redist5_fracRU_uid16_fxpToFPTest_b_1_q & zP_uid15_fxpToFPTest_q;

    -- excSelector_uid22_fxpToFPTest(LOGICAL,21)@3
    excSelector_uid22_fxpToFPTest_q <= inIsZero_uid12_fxpToFPTest_q or ovf_uid21_fxpToFPTest_n or udf_uid19_fxpToFPTest_n;

    -- fracRPostExc_uid24_fxpToFPTest(MUX,23)@3
    fracRPostExc_uid24_fxpToFPTest_s <= excSelector_uid22_fxpToFPTest_q;
    fracRPostExc_uid24_fxpToFPTest_combproc: PROCESS (fracRPostExc_uid24_fxpToFPTest_s, fracRR_uid17_fxpToFPTest_q, fracZ_uid23_fxpToFPTest_q)
    BEGIN
        CASE (fracRPostExc_uid24_fxpToFPTest_s) IS
            WHEN "0" => fracRPostExc_uid24_fxpToFPTest_q <= fracRR_uid17_fxpToFPTest_q;
            WHEN "1" => fracRPostExc_uid24_fxpToFPTest_q <= fracZ_uid23_fxpToFPTest_q;
            WHEN OTHERS => fracRPostExc_uid24_fxpToFPTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- outRes_uid32_fxpToFPTest(BITJOIN,31)@3
    outRes_uid32_fxpToFPTest_q <= redist6_signX_uid6_fxpToFPTest_b_3_q & expRPostExc_uid31_fxpToFPTest_q & fracRPostExc_uid24_fxpToFPTest_q;

    -- xOut(GPOUT,4)@3
    q <= outRes_uid32_fxpToFPTest_q;

END normal;
