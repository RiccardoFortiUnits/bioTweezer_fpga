-- ------------------------------------------------------------------------- 
-- High Level Design Compiler for Intel(R) FPGAs Version 22.1std (Release Build #922)
-- Quartus Prime development tool and MATLAB/Simulink Interface
-- 
-- Legal Notice: Copyright 2023 Intel Corporation.  All rights reserved.
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

-- VHDL created from cordic_CORDIC_0
-- VHDL created on Fri Jan 12 12:42:32 2024


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

entity cordic_CORDIC_0 is
    port (
        x : in std_logic_vector(31 downto 0);  -- sfix32_en30
        y : in std_logic_vector(31 downto 0);  -- sfix32_en30
        en : in std_logic_vector(0 downto 0);  -- ufix1
        q : out std_logic_vector(26 downto 0);  -- sfix27_en24
        r : out std_logic_vector(26 downto 0);  -- ufix27_en24
        clk : in std_logic;
        areset : in std_logic
    );
end cordic_CORDIC_0;

architecture normal of cordic_CORDIC_0 is

    attribute altera_attribute : string;
    attribute altera_attribute of normal : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF; -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 10037; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 15400; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 12020; -name MESSAGE_DISABLE 12030; -name MESSAGE_DISABLE 12010; -name MESSAGE_DISABLE 12110; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 13410; -name MESSAGE_DISABLE 113007";
    
    signal GND_q : STD_LOGIC_VECTOR (0 downto 0);
    signal VCC_q : STD_LOGIC_VECTOR (0 downto 0);
    signal constantZero_uid6_vecTranslateTest_q : STD_LOGIC_VECTOR (31 downto 0);
    signal signX_uid7_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal signY_uid8_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal invSignX_uid9_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal absXE_uid10_vecTranslateTest_a : STD_LOGIC_VECTOR (33 downto 0);
    signal absXE_uid10_vecTranslateTest_b : STD_LOGIC_VECTOR (33 downto 0);
    signal absXE_uid10_vecTranslateTest_o : STD_LOGIC_VECTOR (33 downto 0);
    signal absXE_uid10_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal absXE_uid10_vecTranslateTest_q : STD_LOGIC_VECTOR (32 downto 0);
    signal invSignY_uid11_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal absYE_uid12_vecTranslateTest_a : STD_LOGIC_VECTOR (33 downto 0);
    signal absYE_uid12_vecTranslateTest_b : STD_LOGIC_VECTOR (33 downto 0);
    signal absYE_uid12_vecTranslateTest_o : STD_LOGIC_VECTOR (33 downto 0);
    signal absYE_uid12_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal absYE_uid12_vecTranslateTest_q : STD_LOGIC_VECTOR (32 downto 0);
    signal absX_uid13_vecTranslateTest_in : STD_LOGIC_VECTOR (31 downto 0);
    signal absX_uid13_vecTranslateTest_b : STD_LOGIC_VECTOR (31 downto 0);
    signal absY_uid14_vecTranslateTest_in : STD_LOGIC_VECTOR (31 downto 0);
    signal absY_uid14_vecTranslateTest_b : STD_LOGIC_VECTOR (31 downto 0);
    signal yNotZero_uid15_vecTranslateTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal yNotZero_uid15_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal yZero_uid16_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xNotZero_uid17_vecTranslateTest_qi : STD_LOGIC_VECTOR (0 downto 0);
    signal xNotZero_uid17_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xZero_uid18_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_1_uid23_vecTranslateTest_a : STD_LOGIC_VECTOR (32 downto 0);
    signal xip1E_1_uid23_vecTranslateTest_b : STD_LOGIC_VECTOR (32 downto 0);
    signal xip1E_1_uid23_vecTranslateTest_o : STD_LOGIC_VECTOR (32 downto 0);
    signal xip1E_1_uid23_vecTranslateTest_q : STD_LOGIC_VECTOR (32 downto 0);
    signal yip1E_1_uid24_vecTranslateTest_a : STD_LOGIC_VECTOR (32 downto 0);
    signal yip1E_1_uid24_vecTranslateTest_b : STD_LOGIC_VECTOR (32 downto 0);
    signal yip1E_1_uid24_vecTranslateTest_o : STD_LOGIC_VECTOR (32 downto 0);
    signal yip1E_1_uid24_vecTranslateTest_q : STD_LOGIC_VECTOR (32 downto 0);
    signal xMSB_uid32_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal invSignOfSelectionSignal_uid37_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_2NA_uid39_vecTranslateTest_q : STD_LOGIC_VECTOR (33 downto 0);
    signal xip1E_2sumAHighB_uid40_vecTranslateTest_a : STD_LOGIC_VECTOR (36 downto 0);
    signal xip1E_2sumAHighB_uid40_vecTranslateTest_b : STD_LOGIC_VECTOR (36 downto 0);
    signal xip1E_2sumAHighB_uid40_vecTranslateTest_o : STD_LOGIC_VECTOR (36 downto 0);
    signal xip1E_2sumAHighB_uid40_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_2sumAHighB_uid40_vecTranslateTest_q : STD_LOGIC_VECTOR (35 downto 0);
    signal yip1E_2NA_uid42_vecTranslateTest_q : STD_LOGIC_VECTOR (33 downto 0);
    signal yip1E_2sumAHighB_uid43_vecTranslateTest_a : STD_LOGIC_VECTOR (35 downto 0);
    signal yip1E_2sumAHighB_uid43_vecTranslateTest_b : STD_LOGIC_VECTOR (35 downto 0);
    signal yip1E_2sumAHighB_uid43_vecTranslateTest_o : STD_LOGIC_VECTOR (35 downto 0);
    signal yip1E_2sumAHighB_uid43_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_2sumAHighB_uid43_vecTranslateTest_q : STD_LOGIC_VECTOR (34 downto 0);
    signal xip1_2_uid48_vecTranslateTest_in : STD_LOGIC_VECTOR (33 downto 0);
    signal xip1_2_uid48_vecTranslateTest_b : STD_LOGIC_VECTOR (33 downto 0);
    signal yip1_2_uid49_vecTranslateTest_in : STD_LOGIC_VECTOR (33 downto 0);
    signal yip1_2_uid49_vecTranslateTest_b : STD_LOGIC_VECTOR (33 downto 0);
    signal xMSB_uid51_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal invSignOfSelectionSignal_uid56_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_3CostZeroPaddingA_uid57_vecTranslateTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal xip1E_3NA_uid58_vecTranslateTest_q : STD_LOGIC_VECTOR (35 downto 0);
    signal xip1E_3sumAHighB_uid59_vecTranslateTest_a : STD_LOGIC_VECTOR (38 downto 0);
    signal xip1E_3sumAHighB_uid59_vecTranslateTest_b : STD_LOGIC_VECTOR (38 downto 0);
    signal xip1E_3sumAHighB_uid59_vecTranslateTest_o : STD_LOGIC_VECTOR (38 downto 0);
    signal xip1E_3sumAHighB_uid59_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_3sumAHighB_uid59_vecTranslateTest_q : STD_LOGIC_VECTOR (37 downto 0);
    signal yip1E_3NA_uid61_vecTranslateTest_q : STD_LOGIC_VECTOR (35 downto 0);
    signal yip1E_3sumAHighB_uid62_vecTranslateTest_a : STD_LOGIC_VECTOR (37 downto 0);
    signal yip1E_3sumAHighB_uid62_vecTranslateTest_b : STD_LOGIC_VECTOR (37 downto 0);
    signal yip1E_3sumAHighB_uid62_vecTranslateTest_o : STD_LOGIC_VECTOR (37 downto 0);
    signal yip1E_3sumAHighB_uid62_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_3sumAHighB_uid62_vecTranslateTest_q : STD_LOGIC_VECTOR (36 downto 0);
    signal xip1_3_uid67_vecTranslateTest_in : STD_LOGIC_VECTOR (35 downto 0);
    signal xip1_3_uid67_vecTranslateTest_b : STD_LOGIC_VECTOR (35 downto 0);
    signal yip1_3_uid68_vecTranslateTest_in : STD_LOGIC_VECTOR (34 downto 0);
    signal yip1_3_uid68_vecTranslateTest_b : STD_LOGIC_VECTOR (34 downto 0);
    signal xMSB_uid70_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal invSignOfSelectionSignal_uid75_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_4CostZeroPaddingA_uid76_vecTranslateTest_q : STD_LOGIC_VECTOR (2 downto 0);
    signal xip1E_4NA_uid77_vecTranslateTest_q : STD_LOGIC_VECTOR (38 downto 0);
    signal xip1E_4sumAHighB_uid78_vecTranslateTest_a : STD_LOGIC_VECTOR (41 downto 0);
    signal xip1E_4sumAHighB_uid78_vecTranslateTest_b : STD_LOGIC_VECTOR (41 downto 0);
    signal xip1E_4sumAHighB_uid78_vecTranslateTest_o : STD_LOGIC_VECTOR (41 downto 0);
    signal xip1E_4sumAHighB_uid78_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_4sumAHighB_uid78_vecTranslateTest_q : STD_LOGIC_VECTOR (40 downto 0);
    signal yip1E_4NA_uid80_vecTranslateTest_q : STD_LOGIC_VECTOR (37 downto 0);
    signal yip1E_4sumAHighB_uid81_vecTranslateTest_a : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1E_4sumAHighB_uid81_vecTranslateTest_b : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1E_4sumAHighB_uid81_vecTranslateTest_o : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1E_4sumAHighB_uid81_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_4sumAHighB_uid81_vecTranslateTest_q : STD_LOGIC_VECTOR (38 downto 0);
    signal xip1_4_uid86_vecTranslateTest_in : STD_LOGIC_VECTOR (38 downto 0);
    signal xip1_4_uid86_vecTranslateTest_b : STD_LOGIC_VECTOR (38 downto 0);
    signal yip1_4_uid87_vecTranslateTest_in : STD_LOGIC_VECTOR (36 downto 0);
    signal yip1_4_uid87_vecTranslateTest_b : STD_LOGIC_VECTOR (36 downto 0);
    signal xMSB_uid89_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal invSignOfSelectionSignal_uid94_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_5CostZeroPaddingA_uid95_vecTranslateTest_q : STD_LOGIC_VECTOR (3 downto 0);
    signal xip1E_5NA_uid96_vecTranslateTest_q : STD_LOGIC_VECTOR (42 downto 0);
    signal xip1E_5sumAHighB_uid97_vecTranslateTest_a : STD_LOGIC_VECTOR (45 downto 0);
    signal xip1E_5sumAHighB_uid97_vecTranslateTest_b : STD_LOGIC_VECTOR (45 downto 0);
    signal xip1E_5sumAHighB_uid97_vecTranslateTest_o : STD_LOGIC_VECTOR (45 downto 0);
    signal xip1E_5sumAHighB_uid97_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_5sumAHighB_uid97_vecTranslateTest_q : STD_LOGIC_VECTOR (44 downto 0);
    signal yip1E_5NA_uid99_vecTranslateTest_q : STD_LOGIC_VECTOR (40 downto 0);
    signal yip1E_5sumAHighB_uid100_vecTranslateTest_a : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1E_5sumAHighB_uid100_vecTranslateTest_b : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1E_5sumAHighB_uid100_vecTranslateTest_o : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1E_5sumAHighB_uid100_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_5sumAHighB_uid100_vecTranslateTest_q : STD_LOGIC_VECTOR (41 downto 0);
    signal xip1_5_uid105_vecTranslateTest_in : STD_LOGIC_VECTOR (42 downto 0);
    signal xip1_5_uid105_vecTranslateTest_b : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1_5_uid106_vecTranslateTest_in : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1_5_uid106_vecTranslateTest_b : STD_LOGIC_VECTOR (39 downto 0);
    signal xMSB_uid108_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal invSignOfSelectionSignal_uid113_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_6CostZeroPaddingA_uid114_vecTranslateTest_q : STD_LOGIC_VECTOR (4 downto 0);
    signal xip1E_6NA_uid115_vecTranslateTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal xip1E_6sumAHighB_uid116_vecTranslateTest_a : STD_LOGIC_VECTOR (50 downto 0);
    signal xip1E_6sumAHighB_uid116_vecTranslateTest_b : STD_LOGIC_VECTOR (50 downto 0);
    signal xip1E_6sumAHighB_uid116_vecTranslateTest_o : STD_LOGIC_VECTOR (50 downto 0);
    signal xip1E_6sumAHighB_uid116_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_6sumAHighB_uid116_vecTranslateTest_q : STD_LOGIC_VECTOR (49 downto 0);
    signal yip1E_6NA_uid118_vecTranslateTest_q : STD_LOGIC_VECTOR (44 downto 0);
    signal yip1E_6sumAHighB_uid119_vecTranslateTest_a : STD_LOGIC_VECTOR (46 downto 0);
    signal yip1E_6sumAHighB_uid119_vecTranslateTest_b : STD_LOGIC_VECTOR (46 downto 0);
    signal yip1E_6sumAHighB_uid119_vecTranslateTest_o : STD_LOGIC_VECTOR (46 downto 0);
    signal yip1E_6sumAHighB_uid119_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_6sumAHighB_uid119_vecTranslateTest_q : STD_LOGIC_VECTOR (45 downto 0);
    signal xip1_6_uid124_vecTranslateTest_in : STD_LOGIC_VECTOR (47 downto 0);
    signal xip1_6_uid124_vecTranslateTest_b : STD_LOGIC_VECTOR (47 downto 0);
    signal yip1_6_uid125_vecTranslateTest_in : STD_LOGIC_VECTOR (43 downto 0);
    signal yip1_6_uid125_vecTranslateTest_b : STD_LOGIC_VECTOR (43 downto 0);
    signal xMSB_uid127_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal invSignOfSelectionSignal_uid132_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_7CostZeroPaddingA_uid133_vecTranslateTest_q : STD_LOGIC_VECTOR (5 downto 0);
    signal xip1E_7NA_uid134_vecTranslateTest_q : STD_LOGIC_VECTOR (53 downto 0);
    signal xip1E_7sumAHighB_uid135_vecTranslateTest_a : STD_LOGIC_VECTOR (56 downto 0);
    signal xip1E_7sumAHighB_uid135_vecTranslateTest_b : STD_LOGIC_VECTOR (56 downto 0);
    signal xip1E_7sumAHighB_uid135_vecTranslateTest_o : STD_LOGIC_VECTOR (56 downto 0);
    signal xip1E_7sumAHighB_uid135_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_7sumAHighB_uid135_vecTranslateTest_q : STD_LOGIC_VECTOR (55 downto 0);
    signal yip1E_7NA_uid137_vecTranslateTest_q : STD_LOGIC_VECTOR (49 downto 0);
    signal yip1E_7sumAHighB_uid138_vecTranslateTest_a : STD_LOGIC_VECTOR (51 downto 0);
    signal yip1E_7sumAHighB_uid138_vecTranslateTest_b : STD_LOGIC_VECTOR (51 downto 0);
    signal yip1E_7sumAHighB_uid138_vecTranslateTest_o : STD_LOGIC_VECTOR (51 downto 0);
    signal yip1E_7sumAHighB_uid138_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_7sumAHighB_uid138_vecTranslateTest_q : STD_LOGIC_VECTOR (50 downto 0);
    signal xip1_7_uid143_vecTranslateTest_in : STD_LOGIC_VECTOR (53 downto 0);
    signal xip1_7_uid143_vecTranslateTest_b : STD_LOGIC_VECTOR (53 downto 0);
    signal yip1_7_uid144_vecTranslateTest_in : STD_LOGIC_VECTOR (48 downto 0);
    signal yip1_7_uid144_vecTranslateTest_b : STD_LOGIC_VECTOR (48 downto 0);
    signal xMSB_uid146_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid150_vecTranslateTest_b : STD_LOGIC_VECTOR (52 downto 0);
    signal twoToMiSiYip_uid151_vecTranslateTest_b : STD_LOGIC_VECTOR (47 downto 0);
    signal invSignOfSelectionSignal_uid153_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_8NA_uid155_vecTranslateTest_q : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1E_8sumAHighB_uid156_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_8sumAHighB_uid156_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_8sumAHighB_uid156_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_8sumAHighB_uid156_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_8sumAHighB_uid156_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_8NA_uid158_vecTranslateTest_q : STD_LOGIC_VECTOR (54 downto 0);
    signal yip1E_8sumAHighB_uid159_vecTranslateTest_a : STD_LOGIC_VECTOR (56 downto 0);
    signal yip1E_8sumAHighB_uid159_vecTranslateTest_b : STD_LOGIC_VECTOR (56 downto 0);
    signal yip1E_8sumAHighB_uid159_vecTranslateTest_o : STD_LOGIC_VECTOR (56 downto 0);
    signal yip1E_8sumAHighB_uid159_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_8sumAHighB_uid159_vecTranslateTest_q : STD_LOGIC_VECTOR (55 downto 0);
    signal xip1_8_uid164_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_8_uid164_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_8_uid165_vecTranslateTest_in : STD_LOGIC_VECTOR (53 downto 0);
    signal yip1_8_uid165_vecTranslateTest_b : STD_LOGIC_VECTOR (53 downto 0);
    signal xMSB_uid167_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid171_vecTranslateTest_b : STD_LOGIC_VECTOR (51 downto 0);
    signal twoToMiSiYip_uid172_vecTranslateTest_b : STD_LOGIC_VECTOR (45 downto 0);
    signal invSignOfSelectionSignal_uid174_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_9_uid175_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_9_uid175_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_9_uid175_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_9_uid175_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_9_uid175_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_9_uid176_vecTranslateTest_a : STD_LOGIC_VECTOR (55 downto 0);
    signal yip1E_9_uid176_vecTranslateTest_b : STD_LOGIC_VECTOR (55 downto 0);
    signal yip1E_9_uid176_vecTranslateTest_o : STD_LOGIC_VECTOR (55 downto 0);
    signal yip1E_9_uid176_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_9_uid176_vecTranslateTest_q : STD_LOGIC_VECTOR (54 downto 0);
    signal xip1_9_uid181_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_9_uid181_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_9_uid182_vecTranslateTest_in : STD_LOGIC_VECTOR (52 downto 0);
    signal yip1_9_uid182_vecTranslateTest_b : STD_LOGIC_VECTOR (52 downto 0);
    signal xMSB_uid184_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid188_vecTranslateTest_b : STD_LOGIC_VECTOR (50 downto 0);
    signal twoToMiSiYip_uid189_vecTranslateTest_b : STD_LOGIC_VECTOR (43 downto 0);
    signal invSignOfSelectionSignal_uid191_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_10_uid192_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_10_uid192_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_10_uid192_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_10_uid192_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_10_uid192_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_10_uid193_vecTranslateTest_a : STD_LOGIC_VECTOR (54 downto 0);
    signal yip1E_10_uid193_vecTranslateTest_b : STD_LOGIC_VECTOR (54 downto 0);
    signal yip1E_10_uid193_vecTranslateTest_o : STD_LOGIC_VECTOR (54 downto 0);
    signal yip1E_10_uid193_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_10_uid193_vecTranslateTest_q : STD_LOGIC_VECTOR (53 downto 0);
    signal xip1_10_uid198_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_10_uid198_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_10_uid199_vecTranslateTest_in : STD_LOGIC_VECTOR (51 downto 0);
    signal yip1_10_uid199_vecTranslateTest_b : STD_LOGIC_VECTOR (51 downto 0);
    signal xMSB_uid201_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid205_vecTranslateTest_b : STD_LOGIC_VECTOR (49 downto 0);
    signal twoToMiSiYip_uid206_vecTranslateTest_b : STD_LOGIC_VECTOR (41 downto 0);
    signal invSignOfSelectionSignal_uid208_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_11_uid209_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_11_uid209_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_11_uid209_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_11_uid209_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_11_uid209_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_11_uid210_vecTranslateTest_a : STD_LOGIC_VECTOR (53 downto 0);
    signal yip1E_11_uid210_vecTranslateTest_b : STD_LOGIC_VECTOR (53 downto 0);
    signal yip1E_11_uid210_vecTranslateTest_o : STD_LOGIC_VECTOR (53 downto 0);
    signal yip1E_11_uid210_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_11_uid210_vecTranslateTest_q : STD_LOGIC_VECTOR (52 downto 0);
    signal xip1_11_uid215_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_11_uid215_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_11_uid216_vecTranslateTest_in : STD_LOGIC_VECTOR (50 downto 0);
    signal yip1_11_uid216_vecTranslateTest_b : STD_LOGIC_VECTOR (50 downto 0);
    signal xMSB_uid218_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid222_vecTranslateTest_b : STD_LOGIC_VECTOR (48 downto 0);
    signal twoToMiSiYip_uid223_vecTranslateTest_b : STD_LOGIC_VECTOR (39 downto 0);
    signal invSignOfSelectionSignal_uid225_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_12_uid226_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_12_uid226_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_12_uid226_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_12_uid226_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_12_uid226_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_12_uid227_vecTranslateTest_a : STD_LOGIC_VECTOR (52 downto 0);
    signal yip1E_12_uid227_vecTranslateTest_b : STD_LOGIC_VECTOR (52 downto 0);
    signal yip1E_12_uid227_vecTranslateTest_o : STD_LOGIC_VECTOR (52 downto 0);
    signal yip1E_12_uid227_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_12_uid227_vecTranslateTest_q : STD_LOGIC_VECTOR (51 downto 0);
    signal xip1_12_uid232_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_12_uid232_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_12_uid233_vecTranslateTest_in : STD_LOGIC_VECTOR (49 downto 0);
    signal yip1_12_uid233_vecTranslateTest_b : STD_LOGIC_VECTOR (49 downto 0);
    signal xMSB_uid235_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid239_vecTranslateTest_b : STD_LOGIC_VECTOR (47 downto 0);
    signal twoToMiSiYip_uid240_vecTranslateTest_b : STD_LOGIC_VECTOR (37 downto 0);
    signal invSignOfSelectionSignal_uid242_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_13_uid243_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_13_uid243_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_13_uid243_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_13_uid243_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_13_uid243_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_13_uid244_vecTranslateTest_a : STD_LOGIC_VECTOR (51 downto 0);
    signal yip1E_13_uid244_vecTranslateTest_b : STD_LOGIC_VECTOR (51 downto 0);
    signal yip1E_13_uid244_vecTranslateTest_o : STD_LOGIC_VECTOR (51 downto 0);
    signal yip1E_13_uid244_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_13_uid244_vecTranslateTest_q : STD_LOGIC_VECTOR (50 downto 0);
    signal xip1_13_uid249_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_13_uid249_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_13_uid250_vecTranslateTest_in : STD_LOGIC_VECTOR (48 downto 0);
    signal yip1_13_uid250_vecTranslateTest_b : STD_LOGIC_VECTOR (48 downto 0);
    signal xMSB_uid252_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid256_vecTranslateTest_b : STD_LOGIC_VECTOR (46 downto 0);
    signal twoToMiSiYip_uid257_vecTranslateTest_b : STD_LOGIC_VECTOR (35 downto 0);
    signal invSignOfSelectionSignal_uid259_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_14_uid260_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_14_uid260_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_14_uid260_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_14_uid260_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_14_uid260_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_14_uid261_vecTranslateTest_a : STD_LOGIC_VECTOR (50 downto 0);
    signal yip1E_14_uid261_vecTranslateTest_b : STD_LOGIC_VECTOR (50 downto 0);
    signal yip1E_14_uid261_vecTranslateTest_o : STD_LOGIC_VECTOR (50 downto 0);
    signal yip1E_14_uid261_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_14_uid261_vecTranslateTest_q : STD_LOGIC_VECTOR (49 downto 0);
    signal xip1_14_uid266_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_14_uid266_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_14_uid267_vecTranslateTest_in : STD_LOGIC_VECTOR (47 downto 0);
    signal yip1_14_uid267_vecTranslateTest_b : STD_LOGIC_VECTOR (47 downto 0);
    signal xMSB_uid269_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid273_vecTranslateTest_b : STD_LOGIC_VECTOR (45 downto 0);
    signal twoToMiSiYip_uid274_vecTranslateTest_b : STD_LOGIC_VECTOR (33 downto 0);
    signal invSignOfSelectionSignal_uid276_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_15_uid277_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_15_uid277_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_15_uid277_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_15_uid277_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_15_uid277_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_15_uid278_vecTranslateTest_a : STD_LOGIC_VECTOR (49 downto 0);
    signal yip1E_15_uid278_vecTranslateTest_b : STD_LOGIC_VECTOR (49 downto 0);
    signal yip1E_15_uid278_vecTranslateTest_o : STD_LOGIC_VECTOR (49 downto 0);
    signal yip1E_15_uid278_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_15_uid278_vecTranslateTest_q : STD_LOGIC_VECTOR (48 downto 0);
    signal xip1_15_uid283_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_15_uid283_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_15_uid284_vecTranslateTest_in : STD_LOGIC_VECTOR (46 downto 0);
    signal yip1_15_uid284_vecTranslateTest_b : STD_LOGIC_VECTOR (46 downto 0);
    signal xMSB_uid286_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid290_vecTranslateTest_b : STD_LOGIC_VECTOR (44 downto 0);
    signal twoToMiSiYip_uid291_vecTranslateTest_b : STD_LOGIC_VECTOR (31 downto 0);
    signal invSignOfSelectionSignal_uid293_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_16_uid294_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_16_uid294_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_16_uid294_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_16_uid294_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_16_uid294_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_16_uid295_vecTranslateTest_a : STD_LOGIC_VECTOR (48 downto 0);
    signal yip1E_16_uid295_vecTranslateTest_b : STD_LOGIC_VECTOR (48 downto 0);
    signal yip1E_16_uid295_vecTranslateTest_o : STD_LOGIC_VECTOR (48 downto 0);
    signal yip1E_16_uid295_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_16_uid295_vecTranslateTest_q : STD_LOGIC_VECTOR (47 downto 0);
    signal xip1_16_uid300_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_16_uid300_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_16_uid301_vecTranslateTest_in : STD_LOGIC_VECTOR (45 downto 0);
    signal yip1_16_uid301_vecTranslateTest_b : STD_LOGIC_VECTOR (45 downto 0);
    signal xMSB_uid303_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid307_vecTranslateTest_b : STD_LOGIC_VECTOR (43 downto 0);
    signal twoToMiSiYip_uid308_vecTranslateTest_b : STD_LOGIC_VECTOR (29 downto 0);
    signal invSignOfSelectionSignal_uid310_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_17_uid311_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_17_uid311_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_17_uid311_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_17_uid311_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_17_uid311_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_17_uid312_vecTranslateTest_a : STD_LOGIC_VECTOR (47 downto 0);
    signal yip1E_17_uid312_vecTranslateTest_b : STD_LOGIC_VECTOR (47 downto 0);
    signal yip1E_17_uid312_vecTranslateTest_o : STD_LOGIC_VECTOR (47 downto 0);
    signal yip1E_17_uid312_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_17_uid312_vecTranslateTest_q : STD_LOGIC_VECTOR (46 downto 0);
    signal xip1_17_uid317_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_17_uid317_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_17_uid318_vecTranslateTest_in : STD_LOGIC_VECTOR (44 downto 0);
    signal yip1_17_uid318_vecTranslateTest_b : STD_LOGIC_VECTOR (44 downto 0);
    signal xMSB_uid320_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid324_vecTranslateTest_b : STD_LOGIC_VECTOR (42 downto 0);
    signal twoToMiSiYip_uid325_vecTranslateTest_b : STD_LOGIC_VECTOR (27 downto 0);
    signal invSignOfSelectionSignal_uid327_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_18_uid328_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_18_uid328_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_18_uid328_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_18_uid328_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_18_uid328_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_18_uid329_vecTranslateTest_a : STD_LOGIC_VECTOR (46 downto 0);
    signal yip1E_18_uid329_vecTranslateTest_b : STD_LOGIC_VECTOR (46 downto 0);
    signal yip1E_18_uid329_vecTranslateTest_o : STD_LOGIC_VECTOR (46 downto 0);
    signal yip1E_18_uid329_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_18_uid329_vecTranslateTest_q : STD_LOGIC_VECTOR (45 downto 0);
    signal xip1_18_uid334_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_18_uid334_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_18_uid335_vecTranslateTest_in : STD_LOGIC_VECTOR (43 downto 0);
    signal yip1_18_uid335_vecTranslateTest_b : STD_LOGIC_VECTOR (43 downto 0);
    signal xMSB_uid337_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid341_vecTranslateTest_b : STD_LOGIC_VECTOR (41 downto 0);
    signal twoToMiSiYip_uid342_vecTranslateTest_b : STD_LOGIC_VECTOR (25 downto 0);
    signal invSignOfSelectionSignal_uid344_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_19_uid345_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_19_uid345_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_19_uid345_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_19_uid345_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_19_uid345_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_19_uid346_vecTranslateTest_a : STD_LOGIC_VECTOR (45 downto 0);
    signal yip1E_19_uid346_vecTranslateTest_b : STD_LOGIC_VECTOR (45 downto 0);
    signal yip1E_19_uid346_vecTranslateTest_o : STD_LOGIC_VECTOR (45 downto 0);
    signal yip1E_19_uid346_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_19_uid346_vecTranslateTest_q : STD_LOGIC_VECTOR (44 downto 0);
    signal xip1_19_uid351_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_19_uid351_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_19_uid352_vecTranslateTest_in : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1_19_uid352_vecTranslateTest_b : STD_LOGIC_VECTOR (42 downto 0);
    signal xMSB_uid354_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid358_vecTranslateTest_b : STD_LOGIC_VECTOR (40 downto 0);
    signal twoToMiSiYip_uid359_vecTranslateTest_b : STD_LOGIC_VECTOR (23 downto 0);
    signal invSignOfSelectionSignal_uid361_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_20_uid362_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_20_uid362_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_20_uid362_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_20_uid362_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_20_uid362_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_20_uid363_vecTranslateTest_a : STD_LOGIC_VECTOR (44 downto 0);
    signal yip1E_20_uid363_vecTranslateTest_b : STD_LOGIC_VECTOR (44 downto 0);
    signal yip1E_20_uid363_vecTranslateTest_o : STD_LOGIC_VECTOR (44 downto 0);
    signal yip1E_20_uid363_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_20_uid363_vecTranslateTest_q : STD_LOGIC_VECTOR (43 downto 0);
    signal xip1_20_uid368_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_20_uid368_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_20_uid369_vecTranslateTest_in : STD_LOGIC_VECTOR (41 downto 0);
    signal yip1_20_uid369_vecTranslateTest_b : STD_LOGIC_VECTOR (41 downto 0);
    signal xMSB_uid371_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid375_vecTranslateTest_b : STD_LOGIC_VECTOR (39 downto 0);
    signal twoToMiSiYip_uid376_vecTranslateTest_b : STD_LOGIC_VECTOR (21 downto 0);
    signal invSignOfSelectionSignal_uid378_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_21_uid379_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_21_uid379_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_21_uid379_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_21_uid379_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_21_uid379_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_21_uid380_vecTranslateTest_a : STD_LOGIC_VECTOR (43 downto 0);
    signal yip1E_21_uid380_vecTranslateTest_b : STD_LOGIC_VECTOR (43 downto 0);
    signal yip1E_21_uid380_vecTranslateTest_o : STD_LOGIC_VECTOR (43 downto 0);
    signal yip1E_21_uid380_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_21_uid380_vecTranslateTest_q : STD_LOGIC_VECTOR (42 downto 0);
    signal xip1_21_uid385_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_21_uid385_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_21_uid386_vecTranslateTest_in : STD_LOGIC_VECTOR (40 downto 0);
    signal yip1_21_uid386_vecTranslateTest_b : STD_LOGIC_VECTOR (40 downto 0);
    signal xMSB_uid388_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid392_vecTranslateTest_b : STD_LOGIC_VECTOR (38 downto 0);
    signal twoToMiSiYip_uid393_vecTranslateTest_b : STD_LOGIC_VECTOR (19 downto 0);
    signal invSignOfSelectionSignal_uid395_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_22_uid396_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_22_uid396_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_22_uid396_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_22_uid396_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_22_uid396_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_22_uid397_vecTranslateTest_a : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1E_22_uid397_vecTranslateTest_b : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1E_22_uid397_vecTranslateTest_o : STD_LOGIC_VECTOR (42 downto 0);
    signal yip1E_22_uid397_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_22_uid397_vecTranslateTest_q : STD_LOGIC_VECTOR (41 downto 0);
    signal xip1_22_uid402_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_22_uid402_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_22_uid403_vecTranslateTest_in : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1_22_uid403_vecTranslateTest_b : STD_LOGIC_VECTOR (39 downto 0);
    signal xMSB_uid405_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid409_vecTranslateTest_b : STD_LOGIC_VECTOR (37 downto 0);
    signal twoToMiSiYip_uid410_vecTranslateTest_b : STD_LOGIC_VECTOR (17 downto 0);
    signal invSignOfSelectionSignal_uid412_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_23_uid413_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_23_uid413_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_23_uid413_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_23_uid413_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_23_uid413_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_23_uid414_vecTranslateTest_a : STD_LOGIC_VECTOR (41 downto 0);
    signal yip1E_23_uid414_vecTranslateTest_b : STD_LOGIC_VECTOR (41 downto 0);
    signal yip1E_23_uid414_vecTranslateTest_o : STD_LOGIC_VECTOR (41 downto 0);
    signal yip1E_23_uid414_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_23_uid414_vecTranslateTest_q : STD_LOGIC_VECTOR (40 downto 0);
    signal xip1_23_uid419_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_23_uid419_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_23_uid420_vecTranslateTest_in : STD_LOGIC_VECTOR (38 downto 0);
    signal yip1_23_uid420_vecTranslateTest_b : STD_LOGIC_VECTOR (38 downto 0);
    signal xMSB_uid422_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid426_vecTranslateTest_b : STD_LOGIC_VECTOR (36 downto 0);
    signal twoToMiSiYip_uid427_vecTranslateTest_b : STD_LOGIC_VECTOR (15 downto 0);
    signal invSignOfSelectionSignal_uid429_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_24_uid430_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_24_uid430_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_24_uid430_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_24_uid430_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_24_uid430_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_24_uid431_vecTranslateTest_a : STD_LOGIC_VECTOR (40 downto 0);
    signal yip1E_24_uid431_vecTranslateTest_b : STD_LOGIC_VECTOR (40 downto 0);
    signal yip1E_24_uid431_vecTranslateTest_o : STD_LOGIC_VECTOR (40 downto 0);
    signal yip1E_24_uid431_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_24_uid431_vecTranslateTest_q : STD_LOGIC_VECTOR (39 downto 0);
    signal xip1_24_uid436_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_24_uid436_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_24_uid437_vecTranslateTest_in : STD_LOGIC_VECTOR (37 downto 0);
    signal yip1_24_uid437_vecTranslateTest_b : STD_LOGIC_VECTOR (37 downto 0);
    signal xMSB_uid439_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid443_vecTranslateTest_b : STD_LOGIC_VECTOR (35 downto 0);
    signal twoToMiSiYip_uid444_vecTranslateTest_b : STD_LOGIC_VECTOR (13 downto 0);
    signal invSignOfSelectionSignal_uid446_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_25_uid447_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_25_uid447_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_25_uid447_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_25_uid447_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_25_uid447_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_25_uid448_vecTranslateTest_a : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1E_25_uid448_vecTranslateTest_b : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1E_25_uid448_vecTranslateTest_o : STD_LOGIC_VECTOR (39 downto 0);
    signal yip1E_25_uid448_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_25_uid448_vecTranslateTest_q : STD_LOGIC_VECTOR (38 downto 0);
    signal xip1_25_uid453_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_25_uid453_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_25_uid454_vecTranslateTest_in : STD_LOGIC_VECTOR (36 downto 0);
    signal yip1_25_uid454_vecTranslateTest_b : STD_LOGIC_VECTOR (36 downto 0);
    signal xMSB_uid456_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiXip_uid460_vecTranslateTest_b : STD_LOGIC_VECTOR (34 downto 0);
    signal twoToMiSiYip_uid461_vecTranslateTest_b : STD_LOGIC_VECTOR (11 downto 0);
    signal invSignOfSelectionSignal_uid463_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_26_uid464_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_26_uid464_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_26_uid464_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_26_uid464_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_26_uid464_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal yip1E_26_uid465_vecTranslateTest_a : STD_LOGIC_VECTOR (38 downto 0);
    signal yip1E_26_uid465_vecTranslateTest_b : STD_LOGIC_VECTOR (38 downto 0);
    signal yip1E_26_uid465_vecTranslateTest_o : STD_LOGIC_VECTOR (38 downto 0);
    signal yip1E_26_uid465_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal yip1E_26_uid465_vecTranslateTest_q : STD_LOGIC_VECTOR (37 downto 0);
    signal xip1_26_uid470_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_26_uid470_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal yip1_26_uid471_vecTranslateTest_in : STD_LOGIC_VECTOR (35 downto 0);
    signal yip1_26_uid471_vecTranslateTest_b : STD_LOGIC_VECTOR (35 downto 0);
    signal xMSB_uid473_vecTranslateTest_b : STD_LOGIC_VECTOR (0 downto 0);
    signal twoToMiSiYip_uid478_vecTranslateTest_b : STD_LOGIC_VECTOR (9 downto 0);
    signal invSignOfSelectionSignal_uid480_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_27_uid481_vecTranslateTest_a : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_27_uid481_vecTranslateTest_b : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_27_uid481_vecTranslateTest_o : STD_LOGIC_VECTOR (62 downto 0);
    signal xip1E_27_uid481_vecTranslateTest_s : STD_LOGIC_VECTOR (0 downto 0);
    signal xip1E_27_uid481_vecTranslateTest_q : STD_LOGIC_VECTOR (61 downto 0);
    signal xip1_27_uid487_vecTranslateTest_in : STD_LOGIC_VECTOR (59 downto 0);
    signal xip1_27_uid487_vecTranslateTest_b : STD_LOGIC_VECTOR (59 downto 0);
    signal concSignVector_uid490_vecTranslateTest_q : STD_LOGIC_VECTOR (26 downto 0);
    signal table_l5_uid492_vecTranslateTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal table_l5_uid493_vecTranslateTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal table_l5_uid494_vecTranslateTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal table_l5_uid495_vecTranslateTest_q : STD_LOGIC_VECTOR (2 downto 0);
    signal os_uid496_vecTranslateTest_q : STD_LOGIC_VECTOR (32 downto 0);
    signal table_l11_uid499_vecTranslateTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal table_l11_uid500_vecTranslateTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal table_l11_uid501_vecTranslateTest_q : STD_LOGIC_VECTOR (6 downto 0);
    signal os_uid502_vecTranslateTest_q : STD_LOGIC_VECTOR (26 downto 0);
    signal table_l17_uid506_vecTranslateTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal table_l17_uid507_vecTranslateTest_q : STD_LOGIC_VECTOR (0 downto 0);
    signal os_uid508_vecTranslateTest_q : STD_LOGIC_VECTOR (20 downto 0);
    signal table_l23_uid511_vecTranslateTest_q : STD_LOGIC_VECTOR (9 downto 0);
    signal table_l23_uid512_vecTranslateTest_q : STD_LOGIC_VECTOR (4 downto 0);
    signal os_uid513_vecTranslateTest_q : STD_LOGIC_VECTOR (14 downto 0);
    signal table_l26_uid516_vecTranslateTest_q : STD_LOGIC_VECTOR (8 downto 0);
    signal lev1_a0_uid519_vecTranslateTest_a : STD_LOGIC_VECTOR (33 downto 0);
    signal lev1_a0_uid519_vecTranslateTest_b : STD_LOGIC_VECTOR (33 downto 0);
    signal lev1_a0_uid519_vecTranslateTest_o : STD_LOGIC_VECTOR (33 downto 0);
    signal lev1_a0_uid519_vecTranslateTest_q : STD_LOGIC_VECTOR (33 downto 0);
    signal lev1_a1_uid520_vecTranslateTest_a : STD_LOGIC_VECTOR (21 downto 0);
    signal lev1_a1_uid520_vecTranslateTest_b : STD_LOGIC_VECTOR (21 downto 0);
    signal lev1_a1_uid520_vecTranslateTest_o : STD_LOGIC_VECTOR (21 downto 0);
    signal lev1_a1_uid520_vecTranslateTest_q : STD_LOGIC_VECTOR (21 downto 0);
    signal lev2_a0_uid521_vecTranslateTest_a : STD_LOGIC_VECTOR (34 downto 0);
    signal lev2_a0_uid521_vecTranslateTest_b : STD_LOGIC_VECTOR (34 downto 0);
    signal lev2_a0_uid521_vecTranslateTest_o : STD_LOGIC_VECTOR (34 downto 0);
    signal lev2_a0_uid521_vecTranslateTest_q : STD_LOGIC_VECTOR (34 downto 0);
    signal lev3_a0_uid522_vecTranslateTest_a : STD_LOGIC_VECTOR (35 downto 0);
    signal lev3_a0_uid522_vecTranslateTest_b : STD_LOGIC_VECTOR (35 downto 0);
    signal lev3_a0_uid522_vecTranslateTest_o : STD_LOGIC_VECTOR (35 downto 0);
    signal lev3_a0_uid522_vecTranslateTest_q : STD_LOGIC_VECTOR (35 downto 0);
    signal atanRes_uid523_vecTranslateTest_in : STD_LOGIC_VECTOR (32 downto 0);
    signal atanRes_uid523_vecTranslateTest_b : STD_LOGIC_VECTOR (27 downto 0);
    signal cstZeroOutFormat_uid524_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal constPiP2uE_uid525_vecTranslateTest_q : STD_LOGIC_VECTOR (26 downto 0);
    signal constPio2P2u_mergedSignalTM_uid528_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal concXZeroYZero_uid530_vecTranslateTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal atanResPostExc_uid531_vecTranslateTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal atanResPostExc_uid531_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal concSigns_uid532_vecTranslateTest_q : STD_LOGIC_VECTOR (1 downto 0);
    signal constPiP2u_uid533_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal constPi_uid534_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal constantZeroOutFormat_uid535_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal constantZeroOutFormatP2u_uid536_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal firstOperand_uid538_vecTranslateTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal firstOperand_uid538_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal secondOperand_uid539_vecTranslateTest_s : STD_LOGIC_VECTOR (1 downto 0);
    signal secondOperand_uid539_vecTranslateTest_q : STD_LOGIC_VECTOR (27 downto 0);
    signal outResExtended_uid540_vecTranslateTest_a : STD_LOGIC_VECTOR (28 downto 0);
    signal outResExtended_uid540_vecTranslateTest_b : STD_LOGIC_VECTOR (28 downto 0);
    signal outResExtended_uid540_vecTranslateTest_o : STD_LOGIC_VECTOR (28 downto 0);
    signal outResExtended_uid540_vecTranslateTest_q : STD_LOGIC_VECTOR (28 downto 0);
    signal atanResPostRR_uid541_vecTranslateTest_b : STD_LOGIC_VECTOR (26 downto 0);
    signal outMagPreRnd_uid543_vecTranslateTest_b : STD_LOGIC_VECTOR (27 downto 0);
    signal outMagPostRnd_uid546_vecTranslateTest_a : STD_LOGIC_VECTOR (28 downto 0);
    signal outMagPostRnd_uid546_vecTranslateTest_b : STD_LOGIC_VECTOR (28 downto 0);
    signal outMagPostRnd_uid546_vecTranslateTest_o : STD_LOGIC_VECTOR (28 downto 0);
    signal outMagPostRnd_uid546_vecTranslateTest_q : STD_LOGIC_VECTOR (28 downto 0);
    signal outMag_uid547_vecTranslateTest_in : STD_LOGIC_VECTOR (27 downto 0);
    signal outMag_uid547_vecTranslateTest_b : STD_LOGIC_VECTOR (26 downto 0);
    signal table_l17_uid505_vecTranslateTest_q_const_q : STD_LOGIC_VECTOR (9 downto 0);
    signal is0_uid491_vecTranslateTest_merged_bit_select_b : STD_LOGIC_VECTOR (5 downto 0);
    signal is0_uid491_vecTranslateTest_merged_bit_select_c : STD_LOGIC_VECTOR (5 downto 0);
    signal is0_uid491_vecTranslateTest_merged_bit_select_d : STD_LOGIC_VECTOR (5 downto 0);
    signal is0_uid491_vecTranslateTest_merged_bit_select_e : STD_LOGIC_VECTOR (5 downto 0);
    signal is0_uid491_vecTranslateTest_merged_bit_select_f : STD_LOGIC_VECTOR (2 downto 0);
    signal redist0_is0_uid491_vecTranslateTest_merged_bit_select_f_1_q : STD_LOGIC_VECTOR (2 downto 0);
    signal redist1_outMagPreRnd_uid543_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (27 downto 0);
    signal redist2_yip1_23_uid420_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (38 downto 0);
    signal redist3_xip1_23_uid419_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (59 downto 0);
    signal redist4_xMSB_uid405_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist5_xMSB_uid388_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist6_xMSB_uid371_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist7_xMSB_uid354_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist8_yip1_19_uid352_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (42 downto 0);
    signal redist9_xip1_19_uid351_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (59 downto 0);
    signal redist10_xMSB_uid337_vecTranslateTest_b_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist11_xMSB_uid320_vecTranslateTest_b_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist12_xMSB_uid303_vecTranslateTest_b_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist13_xMSB_uid286_vecTranslateTest_b_2_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist14_yip1_15_uid284_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (46 downto 0);
    signal redist15_xip1_15_uid283_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (59 downto 0);
    signal redist16_xMSB_uid269_vecTranslateTest_b_3_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist17_xMSB_uid252_vecTranslateTest_b_3_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist18_xMSB_uid235_vecTranslateTest_b_3_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist19_xMSB_uid218_vecTranslateTest_b_3_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist20_yip1_11_uid216_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (50 downto 0);
    signal redist21_xip1_11_uid215_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (59 downto 0);
    signal redist22_xMSB_uid201_vecTranslateTest_b_4_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist23_xMSB_uid184_vecTranslateTest_b_4_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist24_xMSB_uid167_vecTranslateTest_b_4_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist25_xMSB_uid146_vecTranslateTest_b_4_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist26_yip1_7_uid144_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (48 downto 0);
    signal redist27_xip1_7_uid143_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (53 downto 0);
    signal redist28_xMSB_uid127_vecTranslateTest_b_5_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist29_xMSB_uid108_vecTranslateTest_b_5_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist30_xMSB_uid89_vecTranslateTest_b_5_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist31_xMSB_uid70_vecTranslateTest_b_5_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist32_yip1_3_uid68_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (34 downto 0);
    signal redist33_xip1_3_uid67_vecTranslateTest_b_1_q : STD_LOGIC_VECTOR (35 downto 0);
    signal redist34_xMSB_uid51_vecTranslateTest_b_6_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist35_xMSB_uid32_vecTranslateTest_b_6_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist36_xNotZero_uid17_vecTranslateTest_q_7_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist37_yNotZero_uid15_vecTranslateTest_q_7_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist38_signY_uid8_vecTranslateTest_b_7_q : STD_LOGIC_VECTOR (0 downto 0);
    signal redist39_signX_uid7_vecTranslateTest_b_7_q : STD_LOGIC_VECTOR (0 downto 0);

begin


    -- VCC(CONSTANT,1)
    VCC_q <= "1";

    -- xMSB_uid456_vecTranslateTest(BITSELECT,455)@6
    xMSB_uid456_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_25_uid454_vecTranslateTest_b(36 downto 36));

    -- xMSB_uid422_vecTranslateTest(BITSELECT,421)@6
    xMSB_uid422_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist2_yip1_23_uid420_vecTranslateTest_b_1_q(38 downto 38));

    -- xMSB_uid388_vecTranslateTest(BITSELECT,387)@5
    xMSB_uid388_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_21_uid386_vecTranslateTest_b(40 downto 40));

    -- xMSB_uid354_vecTranslateTest(BITSELECT,353)@5
    xMSB_uid354_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist8_yip1_19_uid352_vecTranslateTest_b_1_q(42 downto 42));

    -- xMSB_uid320_vecTranslateTest(BITSELECT,319)@4
    xMSB_uid320_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_17_uid318_vecTranslateTest_b(44 downto 44));

    -- xMSB_uid286_vecTranslateTest(BITSELECT,285)@4
    xMSB_uid286_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist14_yip1_15_uid284_vecTranslateTest_b_1_q(46 downto 46));

    -- xMSB_uid252_vecTranslateTest(BITSELECT,251)@3
    xMSB_uid252_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_13_uid250_vecTranslateTest_b(48 downto 48));

    -- xMSB_uid218_vecTranslateTest(BITSELECT,217)@3
    xMSB_uid218_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist20_yip1_11_uid216_vecTranslateTest_b_1_q(50 downto 50));

    -- xMSB_uid184_vecTranslateTest(BITSELECT,183)@2
    xMSB_uid184_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_9_uid182_vecTranslateTest_b(52 downto 52));

    -- signX_uid7_vecTranslateTest(BITSELECT,6)@0
    signX_uid7_vecTranslateTest_b <= STD_LOGIC_VECTOR(x(31 downto 31));

    -- invSignX_uid9_vecTranslateTest(LOGICAL,8)@0
    invSignX_uid9_vecTranslateTest_q <= not (signX_uid7_vecTranslateTest_b);

    -- constantZero_uid6_vecTranslateTest(CONSTANT,5)
    constantZero_uid6_vecTranslateTest_q <= "00000000000000000000000000000000";

    -- absXE_uid10_vecTranslateTest(ADDSUB,9)@0
    absXE_uid10_vecTranslateTest_s <= invSignX_uid9_vecTranslateTest_q;
    absXE_uid10_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((33 downto 32 => constantZero_uid6_vecTranslateTest_q(31)) & constantZero_uid6_vecTranslateTest_q));
    absXE_uid10_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((33 downto 32 => x(31)) & x));
    absXE_uid10_vecTranslateTest_combproc: PROCESS (absXE_uid10_vecTranslateTest_a, absXE_uid10_vecTranslateTest_b, absXE_uid10_vecTranslateTest_s)
    BEGIN
        IF (absXE_uid10_vecTranslateTest_s = "1") THEN
            absXE_uid10_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(absXE_uid10_vecTranslateTest_a) + SIGNED(absXE_uid10_vecTranslateTest_b));
        ELSE
            absXE_uid10_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(absXE_uid10_vecTranslateTest_a) - SIGNED(absXE_uid10_vecTranslateTest_b));
        END IF;
    END PROCESS;
    absXE_uid10_vecTranslateTest_q <= absXE_uid10_vecTranslateTest_o(32 downto 0);

    -- absX_uid13_vecTranslateTest(BITSELECT,12)@0
    absX_uid13_vecTranslateTest_in <= absXE_uid10_vecTranslateTest_q(31 downto 0);
    absX_uid13_vecTranslateTest_b <= absX_uid13_vecTranslateTest_in(31 downto 0);

    -- signY_uid8_vecTranslateTest(BITSELECT,7)@0
    signY_uid8_vecTranslateTest_b <= STD_LOGIC_VECTOR(y(31 downto 31));

    -- invSignY_uid11_vecTranslateTest(LOGICAL,10)@0
    invSignY_uid11_vecTranslateTest_q <= not (signY_uid8_vecTranslateTest_b);

    -- absYE_uid12_vecTranslateTest(ADDSUB,11)@0
    absYE_uid12_vecTranslateTest_s <= invSignY_uid11_vecTranslateTest_q;
    absYE_uid12_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((33 downto 32 => constantZero_uid6_vecTranslateTest_q(31)) & constantZero_uid6_vecTranslateTest_q));
    absYE_uid12_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((33 downto 32 => y(31)) & y));
    absYE_uid12_vecTranslateTest_combproc: PROCESS (absYE_uid12_vecTranslateTest_a, absYE_uid12_vecTranslateTest_b, absYE_uid12_vecTranslateTest_s)
    BEGIN
        IF (absYE_uid12_vecTranslateTest_s = "1") THEN
            absYE_uid12_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(absYE_uid12_vecTranslateTest_a) + SIGNED(absYE_uid12_vecTranslateTest_b));
        ELSE
            absYE_uid12_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(absYE_uid12_vecTranslateTest_a) - SIGNED(absYE_uid12_vecTranslateTest_b));
        END IF;
    END PROCESS;
    absYE_uid12_vecTranslateTest_q <= absYE_uid12_vecTranslateTest_o(32 downto 0);

    -- absY_uid14_vecTranslateTest(BITSELECT,13)@0
    absY_uid14_vecTranslateTest_in <= absYE_uid12_vecTranslateTest_q(31 downto 0);
    absY_uid14_vecTranslateTest_b <= absY_uid14_vecTranslateTest_in(31 downto 0);

    -- yip1E_1_uid24_vecTranslateTest(SUB,23)@0
    yip1E_1_uid24_vecTranslateTest_a <= STD_LOGIC_VECTOR("0" & absY_uid14_vecTranslateTest_b);
    yip1E_1_uid24_vecTranslateTest_b <= STD_LOGIC_VECTOR("0" & absX_uid13_vecTranslateTest_b);
    yip1E_1_uid24_vecTranslateTest_o <= STD_LOGIC_VECTOR(UNSIGNED(yip1E_1_uid24_vecTranslateTest_a) - UNSIGNED(yip1E_1_uid24_vecTranslateTest_b));
    yip1E_1_uid24_vecTranslateTest_q <= yip1E_1_uid24_vecTranslateTest_o(32 downto 0);

    -- xMSB_uid32_vecTranslateTest(BITSELECT,31)@0
    xMSB_uid32_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1E_1_uid24_vecTranslateTest_q(32 downto 32));

    -- xip1E_1_uid23_vecTranslateTest(ADD,22)@0
    xip1E_1_uid23_vecTranslateTest_a <= STD_LOGIC_VECTOR("0" & absX_uid13_vecTranslateTest_b);
    xip1E_1_uid23_vecTranslateTest_b <= STD_LOGIC_VECTOR("0" & absY_uid14_vecTranslateTest_b);
    xip1E_1_uid23_vecTranslateTest_o <= STD_LOGIC_VECTOR(UNSIGNED(xip1E_1_uid23_vecTranslateTest_a) + UNSIGNED(xip1E_1_uid23_vecTranslateTest_b));
    xip1E_1_uid23_vecTranslateTest_q <= xip1E_1_uid23_vecTranslateTest_o(32 downto 0);

    -- yip1E_2NA_uid42_vecTranslateTest(BITJOIN,41)@0
    yip1E_2NA_uid42_vecTranslateTest_q <= yip1E_1_uid24_vecTranslateTest_q & GND_q;

    -- yip1E_2sumAHighB_uid43_vecTranslateTest(ADDSUB,42)@0
    yip1E_2sumAHighB_uid43_vecTranslateTest_s <= xMSB_uid32_vecTranslateTest_b;
    yip1E_2sumAHighB_uid43_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((35 downto 34 => yip1E_2NA_uid42_vecTranslateTest_q(33)) & yip1E_2NA_uid42_vecTranslateTest_q));
    yip1E_2sumAHighB_uid43_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_1_uid23_vecTranslateTest_q));
    yip1E_2sumAHighB_uid43_vecTranslateTest_combproc: PROCESS (yip1E_2sumAHighB_uid43_vecTranslateTest_a, yip1E_2sumAHighB_uid43_vecTranslateTest_b, yip1E_2sumAHighB_uid43_vecTranslateTest_s)
    BEGIN
        IF (yip1E_2sumAHighB_uid43_vecTranslateTest_s = "1") THEN
            yip1E_2sumAHighB_uid43_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_2sumAHighB_uid43_vecTranslateTest_a) + SIGNED(yip1E_2sumAHighB_uid43_vecTranslateTest_b));
        ELSE
            yip1E_2sumAHighB_uid43_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_2sumAHighB_uid43_vecTranslateTest_a) - SIGNED(yip1E_2sumAHighB_uid43_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_2sumAHighB_uid43_vecTranslateTest_q <= yip1E_2sumAHighB_uid43_vecTranslateTest_o(34 downto 0);

    -- yip1_2_uid49_vecTranslateTest(BITSELECT,48)@0
    yip1_2_uid49_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_2sumAHighB_uid43_vecTranslateTest_q(33 downto 0));
    yip1_2_uid49_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_2_uid49_vecTranslateTest_in(33 downto 0));

    -- xMSB_uid51_vecTranslateTest(BITSELECT,50)@0
    xMSB_uid51_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_2_uid49_vecTranslateTest_b(33 downto 33));

    -- invSignOfSelectionSignal_uid37_vecTranslateTest(LOGICAL,36)@0
    invSignOfSelectionSignal_uid37_vecTranslateTest_q <= not (xMSB_uid32_vecTranslateTest_b);

    -- xip1E_2NA_uid39_vecTranslateTest(BITJOIN,38)@0
    xip1E_2NA_uid39_vecTranslateTest_q <= xip1E_1_uid23_vecTranslateTest_q & GND_q;

    -- xip1E_2sumAHighB_uid40_vecTranslateTest(ADDSUB,39)@0
    xip1E_2sumAHighB_uid40_vecTranslateTest_s <= invSignOfSelectionSignal_uid37_vecTranslateTest_q;
    xip1E_2sumAHighB_uid40_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_2NA_uid39_vecTranslateTest_q));
    xip1E_2sumAHighB_uid40_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((36 downto 33 => yip1E_1_uid24_vecTranslateTest_q(32)) & yip1E_1_uid24_vecTranslateTest_q));
    xip1E_2sumAHighB_uid40_vecTranslateTest_combproc: PROCESS (xip1E_2sumAHighB_uid40_vecTranslateTest_a, xip1E_2sumAHighB_uid40_vecTranslateTest_b, xip1E_2sumAHighB_uid40_vecTranslateTest_s)
    BEGIN
        IF (xip1E_2sumAHighB_uid40_vecTranslateTest_s = "1") THEN
            xip1E_2sumAHighB_uid40_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_2sumAHighB_uid40_vecTranslateTest_a) + SIGNED(xip1E_2sumAHighB_uid40_vecTranslateTest_b));
        ELSE
            xip1E_2sumAHighB_uid40_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_2sumAHighB_uid40_vecTranslateTest_a) - SIGNED(xip1E_2sumAHighB_uid40_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_2sumAHighB_uid40_vecTranslateTest_q <= xip1E_2sumAHighB_uid40_vecTranslateTest_o(35 downto 0);

    -- xip1_2_uid48_vecTranslateTest(BITSELECT,47)@0
    xip1_2_uid48_vecTranslateTest_in <= xip1E_2sumAHighB_uid40_vecTranslateTest_q(33 downto 0);
    xip1_2_uid48_vecTranslateTest_b <= xip1_2_uid48_vecTranslateTest_in(33 downto 0);

    -- xip1E_3CostZeroPaddingA_uid57_vecTranslateTest(CONSTANT,56)
    xip1E_3CostZeroPaddingA_uid57_vecTranslateTest_q <= "00";

    -- yip1E_3NA_uid61_vecTranslateTest(BITJOIN,60)@0
    yip1E_3NA_uid61_vecTranslateTest_q <= yip1_2_uid49_vecTranslateTest_b & xip1E_3CostZeroPaddingA_uid57_vecTranslateTest_q;

    -- yip1E_3sumAHighB_uid62_vecTranslateTest(ADDSUB,61)@0
    yip1E_3sumAHighB_uid62_vecTranslateTest_s <= xMSB_uid51_vecTranslateTest_b;
    yip1E_3sumAHighB_uid62_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((37 downto 36 => yip1E_3NA_uid61_vecTranslateTest_q(35)) & yip1E_3NA_uid61_vecTranslateTest_q));
    yip1E_3sumAHighB_uid62_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & xip1_2_uid48_vecTranslateTest_b));
    yip1E_3sumAHighB_uid62_vecTranslateTest_combproc: PROCESS (yip1E_3sumAHighB_uid62_vecTranslateTest_a, yip1E_3sumAHighB_uid62_vecTranslateTest_b, yip1E_3sumAHighB_uid62_vecTranslateTest_s)
    BEGIN
        IF (yip1E_3sumAHighB_uid62_vecTranslateTest_s = "1") THEN
            yip1E_3sumAHighB_uid62_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_3sumAHighB_uid62_vecTranslateTest_a) + SIGNED(yip1E_3sumAHighB_uid62_vecTranslateTest_b));
        ELSE
            yip1E_3sumAHighB_uid62_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_3sumAHighB_uid62_vecTranslateTest_a) - SIGNED(yip1E_3sumAHighB_uid62_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_3sumAHighB_uid62_vecTranslateTest_q <= yip1E_3sumAHighB_uid62_vecTranslateTest_o(36 downto 0);

    -- yip1_3_uid68_vecTranslateTest(BITSELECT,67)@0
    yip1_3_uid68_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_3sumAHighB_uid62_vecTranslateTest_q(34 downto 0));
    yip1_3_uid68_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_3_uid68_vecTranslateTest_in(34 downto 0));

    -- redist32_yip1_3_uid68_vecTranslateTest_b_1(DELAY,582)
    redist32_yip1_3_uid68_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 35, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => yip1_3_uid68_vecTranslateTest_b, xout => redist32_yip1_3_uid68_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- xMSB_uid70_vecTranslateTest(BITSELECT,69)@1
    xMSB_uid70_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist32_yip1_3_uid68_vecTranslateTest_b_1_q(34 downto 34));

    -- invSignOfSelectionSignal_uid56_vecTranslateTest(LOGICAL,55)@0
    invSignOfSelectionSignal_uid56_vecTranslateTest_q <= not (xMSB_uid51_vecTranslateTest_b);

    -- xip1E_3NA_uid58_vecTranslateTest(BITJOIN,57)@0
    xip1E_3NA_uid58_vecTranslateTest_q <= xip1_2_uid48_vecTranslateTest_b & xip1E_3CostZeroPaddingA_uid57_vecTranslateTest_q;

    -- xip1E_3sumAHighB_uid59_vecTranslateTest(ADDSUB,58)@0
    xip1E_3sumAHighB_uid59_vecTranslateTest_s <= invSignOfSelectionSignal_uid56_vecTranslateTest_q;
    xip1E_3sumAHighB_uid59_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_3NA_uid58_vecTranslateTest_q));
    xip1E_3sumAHighB_uid59_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((38 downto 34 => yip1_2_uid49_vecTranslateTest_b(33)) & yip1_2_uid49_vecTranslateTest_b));
    xip1E_3sumAHighB_uid59_vecTranslateTest_combproc: PROCESS (xip1E_3sumAHighB_uid59_vecTranslateTest_a, xip1E_3sumAHighB_uid59_vecTranslateTest_b, xip1E_3sumAHighB_uid59_vecTranslateTest_s)
    BEGIN
        IF (xip1E_3sumAHighB_uid59_vecTranslateTest_s = "1") THEN
            xip1E_3sumAHighB_uid59_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_3sumAHighB_uid59_vecTranslateTest_a) + SIGNED(xip1E_3sumAHighB_uid59_vecTranslateTest_b));
        ELSE
            xip1E_3sumAHighB_uid59_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_3sumAHighB_uid59_vecTranslateTest_a) - SIGNED(xip1E_3sumAHighB_uid59_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_3sumAHighB_uid59_vecTranslateTest_q <= xip1E_3sumAHighB_uid59_vecTranslateTest_o(37 downto 0);

    -- xip1_3_uid67_vecTranslateTest(BITSELECT,66)@0
    xip1_3_uid67_vecTranslateTest_in <= xip1E_3sumAHighB_uid59_vecTranslateTest_q(35 downto 0);
    xip1_3_uid67_vecTranslateTest_b <= xip1_3_uid67_vecTranslateTest_in(35 downto 0);

    -- redist33_xip1_3_uid67_vecTranslateTest_b_1(DELAY,583)
    redist33_xip1_3_uid67_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 36, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xip1_3_uid67_vecTranslateTest_b, xout => redist33_xip1_3_uid67_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- xip1E_4CostZeroPaddingA_uid76_vecTranslateTest(CONSTANT,75)
    xip1E_4CostZeroPaddingA_uid76_vecTranslateTest_q <= "000";

    -- yip1E_4NA_uid80_vecTranslateTest(BITJOIN,79)@1
    yip1E_4NA_uid80_vecTranslateTest_q <= redist32_yip1_3_uid68_vecTranslateTest_b_1_q & xip1E_4CostZeroPaddingA_uid76_vecTranslateTest_q;

    -- yip1E_4sumAHighB_uid81_vecTranslateTest(ADDSUB,80)@1
    yip1E_4sumAHighB_uid81_vecTranslateTest_s <= xMSB_uid70_vecTranslateTest_b;
    yip1E_4sumAHighB_uid81_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((39 downto 38 => yip1E_4NA_uid80_vecTranslateTest_q(37)) & yip1E_4NA_uid80_vecTranslateTest_q));
    yip1E_4sumAHighB_uid81_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & redist33_xip1_3_uid67_vecTranslateTest_b_1_q));
    yip1E_4sumAHighB_uid81_vecTranslateTest_combproc: PROCESS (yip1E_4sumAHighB_uid81_vecTranslateTest_a, yip1E_4sumAHighB_uid81_vecTranslateTest_b, yip1E_4sumAHighB_uid81_vecTranslateTest_s)
    BEGIN
        IF (yip1E_4sumAHighB_uid81_vecTranslateTest_s = "1") THEN
            yip1E_4sumAHighB_uid81_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_4sumAHighB_uid81_vecTranslateTest_a) + SIGNED(yip1E_4sumAHighB_uid81_vecTranslateTest_b));
        ELSE
            yip1E_4sumAHighB_uid81_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_4sumAHighB_uid81_vecTranslateTest_a) - SIGNED(yip1E_4sumAHighB_uid81_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_4sumAHighB_uid81_vecTranslateTest_q <= yip1E_4sumAHighB_uid81_vecTranslateTest_o(38 downto 0);

    -- yip1_4_uid87_vecTranslateTest(BITSELECT,86)@1
    yip1_4_uid87_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_4sumAHighB_uid81_vecTranslateTest_q(36 downto 0));
    yip1_4_uid87_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_4_uid87_vecTranslateTest_in(36 downto 0));

    -- xMSB_uid89_vecTranslateTest(BITSELECT,88)@1
    xMSB_uid89_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_4_uid87_vecTranslateTest_b(36 downto 36));

    -- invSignOfSelectionSignal_uid75_vecTranslateTest(LOGICAL,74)@1
    invSignOfSelectionSignal_uid75_vecTranslateTest_q <= not (xMSB_uid70_vecTranslateTest_b);

    -- xip1E_4NA_uid77_vecTranslateTest(BITJOIN,76)@1
    xip1E_4NA_uid77_vecTranslateTest_q <= redist33_xip1_3_uid67_vecTranslateTest_b_1_q & xip1E_4CostZeroPaddingA_uid76_vecTranslateTest_q;

    -- xip1E_4sumAHighB_uid78_vecTranslateTest(ADDSUB,77)@1
    xip1E_4sumAHighB_uid78_vecTranslateTest_s <= invSignOfSelectionSignal_uid75_vecTranslateTest_q;
    xip1E_4sumAHighB_uid78_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_4NA_uid77_vecTranslateTest_q));
    xip1E_4sumAHighB_uid78_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((41 downto 35 => redist32_yip1_3_uid68_vecTranslateTest_b_1_q(34)) & redist32_yip1_3_uid68_vecTranslateTest_b_1_q));
    xip1E_4sumAHighB_uid78_vecTranslateTest_combproc: PROCESS (xip1E_4sumAHighB_uid78_vecTranslateTest_a, xip1E_4sumAHighB_uid78_vecTranslateTest_b, xip1E_4sumAHighB_uid78_vecTranslateTest_s)
    BEGIN
        IF (xip1E_4sumAHighB_uid78_vecTranslateTest_s = "1") THEN
            xip1E_4sumAHighB_uid78_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_4sumAHighB_uid78_vecTranslateTest_a) + SIGNED(xip1E_4sumAHighB_uid78_vecTranslateTest_b));
        ELSE
            xip1E_4sumAHighB_uid78_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_4sumAHighB_uid78_vecTranslateTest_a) - SIGNED(xip1E_4sumAHighB_uid78_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_4sumAHighB_uid78_vecTranslateTest_q <= xip1E_4sumAHighB_uid78_vecTranslateTest_o(40 downto 0);

    -- xip1_4_uid86_vecTranslateTest(BITSELECT,85)@1
    xip1_4_uid86_vecTranslateTest_in <= xip1E_4sumAHighB_uid78_vecTranslateTest_q(38 downto 0);
    xip1_4_uid86_vecTranslateTest_b <= xip1_4_uid86_vecTranslateTest_in(38 downto 0);

    -- xip1E_5CostZeroPaddingA_uid95_vecTranslateTest(CONSTANT,94)
    xip1E_5CostZeroPaddingA_uid95_vecTranslateTest_q <= "0000";

    -- yip1E_5NA_uid99_vecTranslateTest(BITJOIN,98)@1
    yip1E_5NA_uid99_vecTranslateTest_q <= yip1_4_uid87_vecTranslateTest_b & xip1E_5CostZeroPaddingA_uid95_vecTranslateTest_q;

    -- yip1E_5sumAHighB_uid100_vecTranslateTest(ADDSUB,99)@1
    yip1E_5sumAHighB_uid100_vecTranslateTest_s <= xMSB_uid89_vecTranslateTest_b;
    yip1E_5sumAHighB_uid100_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((42 downto 41 => yip1E_5NA_uid99_vecTranslateTest_q(40)) & yip1E_5NA_uid99_vecTranslateTest_q));
    yip1E_5sumAHighB_uid100_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & xip1_4_uid86_vecTranslateTest_b));
    yip1E_5sumAHighB_uid100_vecTranslateTest_combproc: PROCESS (yip1E_5sumAHighB_uid100_vecTranslateTest_a, yip1E_5sumAHighB_uid100_vecTranslateTest_b, yip1E_5sumAHighB_uid100_vecTranslateTest_s)
    BEGIN
        IF (yip1E_5sumAHighB_uid100_vecTranslateTest_s = "1") THEN
            yip1E_5sumAHighB_uid100_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_5sumAHighB_uid100_vecTranslateTest_a) + SIGNED(yip1E_5sumAHighB_uid100_vecTranslateTest_b));
        ELSE
            yip1E_5sumAHighB_uid100_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_5sumAHighB_uid100_vecTranslateTest_a) - SIGNED(yip1E_5sumAHighB_uid100_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_5sumAHighB_uid100_vecTranslateTest_q <= yip1E_5sumAHighB_uid100_vecTranslateTest_o(41 downto 0);

    -- yip1_5_uid106_vecTranslateTest(BITSELECT,105)@1
    yip1_5_uid106_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_5sumAHighB_uid100_vecTranslateTest_q(39 downto 0));
    yip1_5_uid106_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_5_uid106_vecTranslateTest_in(39 downto 0));

    -- xMSB_uid108_vecTranslateTest(BITSELECT,107)@1
    xMSB_uid108_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_5_uid106_vecTranslateTest_b(39 downto 39));

    -- invSignOfSelectionSignal_uid94_vecTranslateTest(LOGICAL,93)@1
    invSignOfSelectionSignal_uid94_vecTranslateTest_q <= not (xMSB_uid89_vecTranslateTest_b);

    -- xip1E_5NA_uid96_vecTranslateTest(BITJOIN,95)@1
    xip1E_5NA_uid96_vecTranslateTest_q <= xip1_4_uid86_vecTranslateTest_b & xip1E_5CostZeroPaddingA_uid95_vecTranslateTest_q;

    -- xip1E_5sumAHighB_uid97_vecTranslateTest(ADDSUB,96)@1
    xip1E_5sumAHighB_uid97_vecTranslateTest_s <= invSignOfSelectionSignal_uid94_vecTranslateTest_q;
    xip1E_5sumAHighB_uid97_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_5NA_uid96_vecTranslateTest_q));
    xip1E_5sumAHighB_uid97_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((45 downto 37 => yip1_4_uid87_vecTranslateTest_b(36)) & yip1_4_uid87_vecTranslateTest_b));
    xip1E_5sumAHighB_uid97_vecTranslateTest_combproc: PROCESS (xip1E_5sumAHighB_uid97_vecTranslateTest_a, xip1E_5sumAHighB_uid97_vecTranslateTest_b, xip1E_5sumAHighB_uid97_vecTranslateTest_s)
    BEGIN
        IF (xip1E_5sumAHighB_uid97_vecTranslateTest_s = "1") THEN
            xip1E_5sumAHighB_uid97_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_5sumAHighB_uid97_vecTranslateTest_a) + SIGNED(xip1E_5sumAHighB_uid97_vecTranslateTest_b));
        ELSE
            xip1E_5sumAHighB_uid97_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_5sumAHighB_uid97_vecTranslateTest_a) - SIGNED(xip1E_5sumAHighB_uid97_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_5sumAHighB_uid97_vecTranslateTest_q <= xip1E_5sumAHighB_uid97_vecTranslateTest_o(44 downto 0);

    -- xip1_5_uid105_vecTranslateTest(BITSELECT,104)@1
    xip1_5_uid105_vecTranslateTest_in <= xip1E_5sumAHighB_uid97_vecTranslateTest_q(42 downto 0);
    xip1_5_uid105_vecTranslateTest_b <= xip1_5_uid105_vecTranslateTest_in(42 downto 0);

    -- xip1E_6CostZeroPaddingA_uid114_vecTranslateTest(CONSTANT,113)
    xip1E_6CostZeroPaddingA_uid114_vecTranslateTest_q <= "00000";

    -- yip1E_6NA_uid118_vecTranslateTest(BITJOIN,117)@1
    yip1E_6NA_uid118_vecTranslateTest_q <= yip1_5_uid106_vecTranslateTest_b & xip1E_6CostZeroPaddingA_uid114_vecTranslateTest_q;

    -- yip1E_6sumAHighB_uid119_vecTranslateTest(ADDSUB,118)@1
    yip1E_6sumAHighB_uid119_vecTranslateTest_s <= xMSB_uid108_vecTranslateTest_b;
    yip1E_6sumAHighB_uid119_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((46 downto 45 => yip1E_6NA_uid118_vecTranslateTest_q(44)) & yip1E_6NA_uid118_vecTranslateTest_q));
    yip1E_6sumAHighB_uid119_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & xip1_5_uid105_vecTranslateTest_b));
    yip1E_6sumAHighB_uid119_vecTranslateTest_combproc: PROCESS (yip1E_6sumAHighB_uid119_vecTranslateTest_a, yip1E_6sumAHighB_uid119_vecTranslateTest_b, yip1E_6sumAHighB_uid119_vecTranslateTest_s)
    BEGIN
        IF (yip1E_6sumAHighB_uid119_vecTranslateTest_s = "1") THEN
            yip1E_6sumAHighB_uid119_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_6sumAHighB_uid119_vecTranslateTest_a) + SIGNED(yip1E_6sumAHighB_uid119_vecTranslateTest_b));
        ELSE
            yip1E_6sumAHighB_uid119_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_6sumAHighB_uid119_vecTranslateTest_a) - SIGNED(yip1E_6sumAHighB_uid119_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_6sumAHighB_uid119_vecTranslateTest_q <= yip1E_6sumAHighB_uid119_vecTranslateTest_o(45 downto 0);

    -- yip1_6_uid125_vecTranslateTest(BITSELECT,124)@1
    yip1_6_uid125_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_6sumAHighB_uid119_vecTranslateTest_q(43 downto 0));
    yip1_6_uid125_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_6_uid125_vecTranslateTest_in(43 downto 0));

    -- xMSB_uid127_vecTranslateTest(BITSELECT,126)@1
    xMSB_uid127_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_6_uid125_vecTranslateTest_b(43 downto 43));

    -- invSignOfSelectionSignal_uid113_vecTranslateTest(LOGICAL,112)@1
    invSignOfSelectionSignal_uid113_vecTranslateTest_q <= not (xMSB_uid108_vecTranslateTest_b);

    -- xip1E_6NA_uid115_vecTranslateTest(BITJOIN,114)@1
    xip1E_6NA_uid115_vecTranslateTest_q <= xip1_5_uid105_vecTranslateTest_b & xip1E_6CostZeroPaddingA_uid114_vecTranslateTest_q;

    -- xip1E_6sumAHighB_uid116_vecTranslateTest(ADDSUB,115)@1
    xip1E_6sumAHighB_uid116_vecTranslateTest_s <= invSignOfSelectionSignal_uid113_vecTranslateTest_q;
    xip1E_6sumAHighB_uid116_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_6NA_uid115_vecTranslateTest_q));
    xip1E_6sumAHighB_uid116_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((50 downto 40 => yip1_5_uid106_vecTranslateTest_b(39)) & yip1_5_uid106_vecTranslateTest_b));
    xip1E_6sumAHighB_uid116_vecTranslateTest_combproc: PROCESS (xip1E_6sumAHighB_uid116_vecTranslateTest_a, xip1E_6sumAHighB_uid116_vecTranslateTest_b, xip1E_6sumAHighB_uid116_vecTranslateTest_s)
    BEGIN
        IF (xip1E_6sumAHighB_uid116_vecTranslateTest_s = "1") THEN
            xip1E_6sumAHighB_uid116_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_6sumAHighB_uid116_vecTranslateTest_a) + SIGNED(xip1E_6sumAHighB_uid116_vecTranslateTest_b));
        ELSE
            xip1E_6sumAHighB_uid116_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_6sumAHighB_uid116_vecTranslateTest_a) - SIGNED(xip1E_6sumAHighB_uid116_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_6sumAHighB_uid116_vecTranslateTest_q <= xip1E_6sumAHighB_uid116_vecTranslateTest_o(49 downto 0);

    -- xip1_6_uid124_vecTranslateTest(BITSELECT,123)@1
    xip1_6_uid124_vecTranslateTest_in <= xip1E_6sumAHighB_uid116_vecTranslateTest_q(47 downto 0);
    xip1_6_uid124_vecTranslateTest_b <= xip1_6_uid124_vecTranslateTest_in(47 downto 0);

    -- xip1E_7CostZeroPaddingA_uid133_vecTranslateTest(CONSTANT,132)
    xip1E_7CostZeroPaddingA_uid133_vecTranslateTest_q <= "000000";

    -- yip1E_7NA_uid137_vecTranslateTest(BITJOIN,136)@1
    yip1E_7NA_uid137_vecTranslateTest_q <= yip1_6_uid125_vecTranslateTest_b & xip1E_7CostZeroPaddingA_uid133_vecTranslateTest_q;

    -- yip1E_7sumAHighB_uid138_vecTranslateTest(ADDSUB,137)@1
    yip1E_7sumAHighB_uid138_vecTranslateTest_s <= xMSB_uid127_vecTranslateTest_b;
    yip1E_7sumAHighB_uid138_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((51 downto 50 => yip1E_7NA_uid137_vecTranslateTest_q(49)) & yip1E_7NA_uid137_vecTranslateTest_q));
    yip1E_7sumAHighB_uid138_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & xip1_6_uid124_vecTranslateTest_b));
    yip1E_7sumAHighB_uid138_vecTranslateTest_combproc: PROCESS (yip1E_7sumAHighB_uid138_vecTranslateTest_a, yip1E_7sumAHighB_uid138_vecTranslateTest_b, yip1E_7sumAHighB_uid138_vecTranslateTest_s)
    BEGIN
        IF (yip1E_7sumAHighB_uid138_vecTranslateTest_s = "1") THEN
            yip1E_7sumAHighB_uid138_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_7sumAHighB_uid138_vecTranslateTest_a) + SIGNED(yip1E_7sumAHighB_uid138_vecTranslateTest_b));
        ELSE
            yip1E_7sumAHighB_uid138_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_7sumAHighB_uid138_vecTranslateTest_a) - SIGNED(yip1E_7sumAHighB_uid138_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_7sumAHighB_uid138_vecTranslateTest_q <= yip1E_7sumAHighB_uid138_vecTranslateTest_o(50 downto 0);

    -- yip1_7_uid144_vecTranslateTest(BITSELECT,143)@1
    yip1_7_uid144_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_7sumAHighB_uid138_vecTranslateTest_q(48 downto 0));
    yip1_7_uid144_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_7_uid144_vecTranslateTest_in(48 downto 0));

    -- redist26_yip1_7_uid144_vecTranslateTest_b_1(DELAY,576)
    redist26_yip1_7_uid144_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 49, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => yip1_7_uid144_vecTranslateTest_b, xout => redist26_yip1_7_uid144_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- xMSB_uid146_vecTranslateTest(BITSELECT,145)@2
    xMSB_uid146_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist26_yip1_7_uid144_vecTranslateTest_b_1_q(48 downto 48));

    -- invSignOfSelectionSignal_uid132_vecTranslateTest(LOGICAL,131)@1
    invSignOfSelectionSignal_uid132_vecTranslateTest_q <= not (xMSB_uid127_vecTranslateTest_b);

    -- xip1E_7NA_uid134_vecTranslateTest(BITJOIN,133)@1
    xip1E_7NA_uid134_vecTranslateTest_q <= xip1_6_uid124_vecTranslateTest_b & xip1E_7CostZeroPaddingA_uid133_vecTranslateTest_q;

    -- xip1E_7sumAHighB_uid135_vecTranslateTest(ADDSUB,134)@1
    xip1E_7sumAHighB_uid135_vecTranslateTest_s <= invSignOfSelectionSignal_uid132_vecTranslateTest_q;
    xip1E_7sumAHighB_uid135_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_7NA_uid134_vecTranslateTest_q));
    xip1E_7sumAHighB_uid135_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((56 downto 44 => yip1_6_uid125_vecTranslateTest_b(43)) & yip1_6_uid125_vecTranslateTest_b));
    xip1E_7sumAHighB_uid135_vecTranslateTest_combproc: PROCESS (xip1E_7sumAHighB_uid135_vecTranslateTest_a, xip1E_7sumAHighB_uid135_vecTranslateTest_b, xip1E_7sumAHighB_uid135_vecTranslateTest_s)
    BEGIN
        IF (xip1E_7sumAHighB_uid135_vecTranslateTest_s = "1") THEN
            xip1E_7sumAHighB_uid135_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_7sumAHighB_uid135_vecTranslateTest_a) + SIGNED(xip1E_7sumAHighB_uid135_vecTranslateTest_b));
        ELSE
            xip1E_7sumAHighB_uid135_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_7sumAHighB_uid135_vecTranslateTest_a) - SIGNED(xip1E_7sumAHighB_uid135_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_7sumAHighB_uid135_vecTranslateTest_q <= xip1E_7sumAHighB_uid135_vecTranslateTest_o(55 downto 0);

    -- xip1_7_uid143_vecTranslateTest(BITSELECT,142)@1
    xip1_7_uid143_vecTranslateTest_in <= xip1E_7sumAHighB_uid135_vecTranslateTest_q(53 downto 0);
    xip1_7_uid143_vecTranslateTest_b <= xip1_7_uid143_vecTranslateTest_in(53 downto 0);

    -- redist27_xip1_7_uid143_vecTranslateTest_b_1(DELAY,577)
    redist27_xip1_7_uid143_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 54, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xip1_7_uid143_vecTranslateTest_b, xout => redist27_xip1_7_uid143_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- twoToMiSiXip_uid150_vecTranslateTest(BITSELECT,149)@2
    twoToMiSiXip_uid150_vecTranslateTest_b <= redist27_xip1_7_uid143_vecTranslateTest_b_1_q(53 downto 1);

    -- yip1E_8NA_uid158_vecTranslateTest(BITJOIN,157)@2
    yip1E_8NA_uid158_vecTranslateTest_q <= redist26_yip1_7_uid144_vecTranslateTest_b_1_q & xip1E_7CostZeroPaddingA_uid133_vecTranslateTest_q;

    -- yip1E_8sumAHighB_uid159_vecTranslateTest(ADDSUB,158)@2
    yip1E_8sumAHighB_uid159_vecTranslateTest_s <= xMSB_uid146_vecTranslateTest_b;
    yip1E_8sumAHighB_uid159_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((56 downto 55 => yip1E_8NA_uid158_vecTranslateTest_q(54)) & yip1E_8NA_uid158_vecTranslateTest_q));
    yip1E_8sumAHighB_uid159_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid150_vecTranslateTest_b));
    yip1E_8sumAHighB_uid159_vecTranslateTest_combproc: PROCESS (yip1E_8sumAHighB_uid159_vecTranslateTest_a, yip1E_8sumAHighB_uid159_vecTranslateTest_b, yip1E_8sumAHighB_uid159_vecTranslateTest_s)
    BEGIN
        IF (yip1E_8sumAHighB_uid159_vecTranslateTest_s = "1") THEN
            yip1E_8sumAHighB_uid159_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_8sumAHighB_uid159_vecTranslateTest_a) + SIGNED(yip1E_8sumAHighB_uid159_vecTranslateTest_b));
        ELSE
            yip1E_8sumAHighB_uid159_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_8sumAHighB_uid159_vecTranslateTest_a) - SIGNED(yip1E_8sumAHighB_uid159_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_8sumAHighB_uid159_vecTranslateTest_q <= yip1E_8sumAHighB_uid159_vecTranslateTest_o(55 downto 0);

    -- yip1_8_uid165_vecTranslateTest(BITSELECT,164)@2
    yip1_8_uid165_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_8sumAHighB_uid159_vecTranslateTest_q(53 downto 0));
    yip1_8_uid165_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_8_uid165_vecTranslateTest_in(53 downto 0));

    -- xMSB_uid167_vecTranslateTest(BITSELECT,166)@2
    xMSB_uid167_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_8_uid165_vecTranslateTest_b(53 downto 53));

    -- invSignOfSelectionSignal_uid174_vecTranslateTest(LOGICAL,173)@2
    invSignOfSelectionSignal_uid174_vecTranslateTest_q <= not (xMSB_uid167_vecTranslateTest_b);

    -- twoToMiSiYip_uid172_vecTranslateTest(BITSELECT,171)@2
    twoToMiSiYip_uid172_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_8_uid165_vecTranslateTest_b(53 downto 8));

    -- invSignOfSelectionSignal_uid153_vecTranslateTest(LOGICAL,152)@2
    invSignOfSelectionSignal_uid153_vecTranslateTest_q <= not (xMSB_uid146_vecTranslateTest_b);

    -- twoToMiSiYip_uid151_vecTranslateTest(BITSELECT,150)@2
    twoToMiSiYip_uid151_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist26_yip1_7_uid144_vecTranslateTest_b_1_q(48 downto 1));

    -- xip1E_8NA_uid155_vecTranslateTest(BITJOIN,154)@2
    xip1E_8NA_uid155_vecTranslateTest_q <= redist27_xip1_7_uid143_vecTranslateTest_b_1_q & xip1E_7CostZeroPaddingA_uid133_vecTranslateTest_q;

    -- xip1E_8sumAHighB_uid156_vecTranslateTest(ADDSUB,155)@2
    xip1E_8sumAHighB_uid156_vecTranslateTest_s <= invSignOfSelectionSignal_uid153_vecTranslateTest_q;
    xip1E_8sumAHighB_uid156_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1E_8NA_uid155_vecTranslateTest_q));
    xip1E_8sumAHighB_uid156_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 48 => twoToMiSiYip_uid151_vecTranslateTest_b(47)) & twoToMiSiYip_uid151_vecTranslateTest_b));
    xip1E_8sumAHighB_uid156_vecTranslateTest_combproc: PROCESS (xip1E_8sumAHighB_uid156_vecTranslateTest_a, xip1E_8sumAHighB_uid156_vecTranslateTest_b, xip1E_8sumAHighB_uid156_vecTranslateTest_s)
    BEGIN
        IF (xip1E_8sumAHighB_uid156_vecTranslateTest_s = "1") THEN
            xip1E_8sumAHighB_uid156_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_8sumAHighB_uid156_vecTranslateTest_a) + SIGNED(xip1E_8sumAHighB_uid156_vecTranslateTest_b));
        ELSE
            xip1E_8sumAHighB_uid156_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_8sumAHighB_uid156_vecTranslateTest_a) - SIGNED(xip1E_8sumAHighB_uid156_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_8sumAHighB_uid156_vecTranslateTest_q <= xip1E_8sumAHighB_uid156_vecTranslateTest_o(61 downto 0);

    -- xip1_8_uid164_vecTranslateTest(BITSELECT,163)@2
    xip1_8_uid164_vecTranslateTest_in <= xip1E_8sumAHighB_uid156_vecTranslateTest_q(59 downto 0);
    xip1_8_uid164_vecTranslateTest_b <= xip1_8_uid164_vecTranslateTest_in(59 downto 0);

    -- xip1E_9_uid175_vecTranslateTest(ADDSUB,174)@2
    xip1E_9_uid175_vecTranslateTest_s <= invSignOfSelectionSignal_uid174_vecTranslateTest_q;
    xip1E_9_uid175_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_8_uid164_vecTranslateTest_b));
    xip1E_9_uid175_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 46 => twoToMiSiYip_uid172_vecTranslateTest_b(45)) & twoToMiSiYip_uid172_vecTranslateTest_b));
    xip1E_9_uid175_vecTranslateTest_combproc: PROCESS (xip1E_9_uid175_vecTranslateTest_a, xip1E_9_uid175_vecTranslateTest_b, xip1E_9_uid175_vecTranslateTest_s)
    BEGIN
        IF (xip1E_9_uid175_vecTranslateTest_s = "1") THEN
            xip1E_9_uid175_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_9_uid175_vecTranslateTest_a) + SIGNED(xip1E_9_uid175_vecTranslateTest_b));
        ELSE
            xip1E_9_uid175_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_9_uid175_vecTranslateTest_a) - SIGNED(xip1E_9_uid175_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_9_uid175_vecTranslateTest_q <= xip1E_9_uid175_vecTranslateTest_o(61 downto 0);

    -- xip1_9_uid181_vecTranslateTest(BITSELECT,180)@2
    xip1_9_uid181_vecTranslateTest_in <= xip1E_9_uid175_vecTranslateTest_q(59 downto 0);
    xip1_9_uid181_vecTranslateTest_b <= xip1_9_uid181_vecTranslateTest_in(59 downto 0);

    -- twoToMiSiXip_uid188_vecTranslateTest(BITSELECT,187)@2
    twoToMiSiXip_uid188_vecTranslateTest_b <= xip1_9_uid181_vecTranslateTest_b(59 downto 9);

    -- twoToMiSiXip_uid171_vecTranslateTest(BITSELECT,170)@2
    twoToMiSiXip_uid171_vecTranslateTest_b <= xip1_8_uid164_vecTranslateTest_b(59 downto 8);

    -- yip1E_9_uid176_vecTranslateTest(ADDSUB,175)@2
    yip1E_9_uid176_vecTranslateTest_s <= xMSB_uid167_vecTranslateTest_b;
    yip1E_9_uid176_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((55 downto 54 => yip1_8_uid165_vecTranslateTest_b(53)) & yip1_8_uid165_vecTranslateTest_b));
    yip1E_9_uid176_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid171_vecTranslateTest_b));
    yip1E_9_uid176_vecTranslateTest_combproc: PROCESS (yip1E_9_uid176_vecTranslateTest_a, yip1E_9_uid176_vecTranslateTest_b, yip1E_9_uid176_vecTranslateTest_s)
    BEGIN
        IF (yip1E_9_uid176_vecTranslateTest_s = "1") THEN
            yip1E_9_uid176_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_9_uid176_vecTranslateTest_a) + SIGNED(yip1E_9_uid176_vecTranslateTest_b));
        ELSE
            yip1E_9_uid176_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_9_uid176_vecTranslateTest_a) - SIGNED(yip1E_9_uid176_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_9_uid176_vecTranslateTest_q <= yip1E_9_uid176_vecTranslateTest_o(54 downto 0);

    -- yip1_9_uid182_vecTranslateTest(BITSELECT,181)@2
    yip1_9_uid182_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_9_uid176_vecTranslateTest_q(52 downto 0));
    yip1_9_uid182_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_9_uid182_vecTranslateTest_in(52 downto 0));

    -- yip1E_10_uid193_vecTranslateTest(ADDSUB,192)@2
    yip1E_10_uid193_vecTranslateTest_s <= xMSB_uid184_vecTranslateTest_b;
    yip1E_10_uid193_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((54 downto 53 => yip1_9_uid182_vecTranslateTest_b(52)) & yip1_9_uid182_vecTranslateTest_b));
    yip1E_10_uid193_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid188_vecTranslateTest_b));
    yip1E_10_uid193_vecTranslateTest_combproc: PROCESS (yip1E_10_uid193_vecTranslateTest_a, yip1E_10_uid193_vecTranslateTest_b, yip1E_10_uid193_vecTranslateTest_s)
    BEGIN
        IF (yip1E_10_uid193_vecTranslateTest_s = "1") THEN
            yip1E_10_uid193_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_10_uid193_vecTranslateTest_a) + SIGNED(yip1E_10_uid193_vecTranslateTest_b));
        ELSE
            yip1E_10_uid193_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_10_uid193_vecTranslateTest_a) - SIGNED(yip1E_10_uid193_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_10_uid193_vecTranslateTest_q <= yip1E_10_uid193_vecTranslateTest_o(53 downto 0);

    -- yip1_10_uid199_vecTranslateTest(BITSELECT,198)@2
    yip1_10_uid199_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_10_uid193_vecTranslateTest_q(51 downto 0));
    yip1_10_uid199_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_10_uid199_vecTranslateTest_in(51 downto 0));

    -- xMSB_uid201_vecTranslateTest(BITSELECT,200)@2
    xMSB_uid201_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_10_uid199_vecTranslateTest_b(51 downto 51));

    -- invSignOfSelectionSignal_uid208_vecTranslateTest(LOGICAL,207)@2
    invSignOfSelectionSignal_uid208_vecTranslateTest_q <= not (xMSB_uid201_vecTranslateTest_b);

    -- twoToMiSiYip_uid206_vecTranslateTest(BITSELECT,205)@2
    twoToMiSiYip_uid206_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_10_uid199_vecTranslateTest_b(51 downto 10));

    -- invSignOfSelectionSignal_uid191_vecTranslateTest(LOGICAL,190)@2
    invSignOfSelectionSignal_uid191_vecTranslateTest_q <= not (xMSB_uid184_vecTranslateTest_b);

    -- twoToMiSiYip_uid189_vecTranslateTest(BITSELECT,188)@2
    twoToMiSiYip_uid189_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_9_uid182_vecTranslateTest_b(52 downto 9));

    -- xip1E_10_uid192_vecTranslateTest(ADDSUB,191)@2
    xip1E_10_uid192_vecTranslateTest_s <= invSignOfSelectionSignal_uid191_vecTranslateTest_q;
    xip1E_10_uid192_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_9_uid181_vecTranslateTest_b));
    xip1E_10_uid192_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 44 => twoToMiSiYip_uid189_vecTranslateTest_b(43)) & twoToMiSiYip_uid189_vecTranslateTest_b));
    xip1E_10_uid192_vecTranslateTest_combproc: PROCESS (xip1E_10_uid192_vecTranslateTest_a, xip1E_10_uid192_vecTranslateTest_b, xip1E_10_uid192_vecTranslateTest_s)
    BEGIN
        IF (xip1E_10_uid192_vecTranslateTest_s = "1") THEN
            xip1E_10_uid192_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_10_uid192_vecTranslateTest_a) + SIGNED(xip1E_10_uid192_vecTranslateTest_b));
        ELSE
            xip1E_10_uid192_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_10_uid192_vecTranslateTest_a) - SIGNED(xip1E_10_uid192_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_10_uid192_vecTranslateTest_q <= xip1E_10_uid192_vecTranslateTest_o(61 downto 0);

    -- xip1_10_uid198_vecTranslateTest(BITSELECT,197)@2
    xip1_10_uid198_vecTranslateTest_in <= xip1E_10_uid192_vecTranslateTest_q(59 downto 0);
    xip1_10_uid198_vecTranslateTest_b <= xip1_10_uid198_vecTranslateTest_in(59 downto 0);

    -- xip1E_11_uid209_vecTranslateTest(ADDSUB,208)@2
    xip1E_11_uid209_vecTranslateTest_s <= invSignOfSelectionSignal_uid208_vecTranslateTest_q;
    xip1E_11_uid209_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_10_uid198_vecTranslateTest_b));
    xip1E_11_uid209_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 42 => twoToMiSiYip_uid206_vecTranslateTest_b(41)) & twoToMiSiYip_uid206_vecTranslateTest_b));
    xip1E_11_uid209_vecTranslateTest_combproc: PROCESS (xip1E_11_uid209_vecTranslateTest_a, xip1E_11_uid209_vecTranslateTest_b, xip1E_11_uid209_vecTranslateTest_s)
    BEGIN
        IF (xip1E_11_uid209_vecTranslateTest_s = "1") THEN
            xip1E_11_uid209_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_11_uid209_vecTranslateTest_a) + SIGNED(xip1E_11_uid209_vecTranslateTest_b));
        ELSE
            xip1E_11_uid209_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_11_uid209_vecTranslateTest_a) - SIGNED(xip1E_11_uid209_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_11_uid209_vecTranslateTest_q <= xip1E_11_uid209_vecTranslateTest_o(61 downto 0);

    -- xip1_11_uid215_vecTranslateTest(BITSELECT,214)@2
    xip1_11_uid215_vecTranslateTest_in <= xip1E_11_uid209_vecTranslateTest_q(59 downto 0);
    xip1_11_uid215_vecTranslateTest_b <= xip1_11_uid215_vecTranslateTest_in(59 downto 0);

    -- redist21_xip1_11_uid215_vecTranslateTest_b_1(DELAY,571)
    redist21_xip1_11_uid215_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 60, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xip1_11_uid215_vecTranslateTest_b, xout => redist21_xip1_11_uid215_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- twoToMiSiXip_uid222_vecTranslateTest(BITSELECT,221)@3
    twoToMiSiXip_uid222_vecTranslateTest_b <= redist21_xip1_11_uid215_vecTranslateTest_b_1_q(59 downto 11);

    -- twoToMiSiXip_uid205_vecTranslateTest(BITSELECT,204)@2
    twoToMiSiXip_uid205_vecTranslateTest_b <= xip1_10_uid198_vecTranslateTest_b(59 downto 10);

    -- yip1E_11_uid210_vecTranslateTest(ADDSUB,209)@2
    yip1E_11_uid210_vecTranslateTest_s <= xMSB_uid201_vecTranslateTest_b;
    yip1E_11_uid210_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((53 downto 52 => yip1_10_uid199_vecTranslateTest_b(51)) & yip1_10_uid199_vecTranslateTest_b));
    yip1E_11_uid210_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid205_vecTranslateTest_b));
    yip1E_11_uid210_vecTranslateTest_combproc: PROCESS (yip1E_11_uid210_vecTranslateTest_a, yip1E_11_uid210_vecTranslateTest_b, yip1E_11_uid210_vecTranslateTest_s)
    BEGIN
        IF (yip1E_11_uid210_vecTranslateTest_s = "1") THEN
            yip1E_11_uid210_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_11_uid210_vecTranslateTest_a) + SIGNED(yip1E_11_uid210_vecTranslateTest_b));
        ELSE
            yip1E_11_uid210_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_11_uid210_vecTranslateTest_a) - SIGNED(yip1E_11_uid210_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_11_uid210_vecTranslateTest_q <= yip1E_11_uid210_vecTranslateTest_o(52 downto 0);

    -- yip1_11_uid216_vecTranslateTest(BITSELECT,215)@2
    yip1_11_uid216_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_11_uid210_vecTranslateTest_q(50 downto 0));
    yip1_11_uid216_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_11_uid216_vecTranslateTest_in(50 downto 0));

    -- redist20_yip1_11_uid216_vecTranslateTest_b_1(DELAY,570)
    redist20_yip1_11_uid216_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 51, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => yip1_11_uid216_vecTranslateTest_b, xout => redist20_yip1_11_uid216_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- yip1E_12_uid227_vecTranslateTest(ADDSUB,226)@3
    yip1E_12_uid227_vecTranslateTest_s <= xMSB_uid218_vecTranslateTest_b;
    yip1E_12_uid227_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((52 downto 51 => redist20_yip1_11_uid216_vecTranslateTest_b_1_q(50)) & redist20_yip1_11_uid216_vecTranslateTest_b_1_q));
    yip1E_12_uid227_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid222_vecTranslateTest_b));
    yip1E_12_uid227_vecTranslateTest_combproc: PROCESS (yip1E_12_uid227_vecTranslateTest_a, yip1E_12_uid227_vecTranslateTest_b, yip1E_12_uid227_vecTranslateTest_s)
    BEGIN
        IF (yip1E_12_uid227_vecTranslateTest_s = "1") THEN
            yip1E_12_uid227_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_12_uid227_vecTranslateTest_a) + SIGNED(yip1E_12_uid227_vecTranslateTest_b));
        ELSE
            yip1E_12_uid227_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_12_uid227_vecTranslateTest_a) - SIGNED(yip1E_12_uid227_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_12_uid227_vecTranslateTest_q <= yip1E_12_uid227_vecTranslateTest_o(51 downto 0);

    -- yip1_12_uid233_vecTranslateTest(BITSELECT,232)@3
    yip1_12_uid233_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_12_uid227_vecTranslateTest_q(49 downto 0));
    yip1_12_uid233_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_12_uid233_vecTranslateTest_in(49 downto 0));

    -- xMSB_uid235_vecTranslateTest(BITSELECT,234)@3
    xMSB_uid235_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_12_uid233_vecTranslateTest_b(49 downto 49));

    -- invSignOfSelectionSignal_uid242_vecTranslateTest(LOGICAL,241)@3
    invSignOfSelectionSignal_uid242_vecTranslateTest_q <= not (xMSB_uid235_vecTranslateTest_b);

    -- twoToMiSiYip_uid240_vecTranslateTest(BITSELECT,239)@3
    twoToMiSiYip_uid240_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_12_uid233_vecTranslateTest_b(49 downto 12));

    -- invSignOfSelectionSignal_uid225_vecTranslateTest(LOGICAL,224)@3
    invSignOfSelectionSignal_uid225_vecTranslateTest_q <= not (xMSB_uid218_vecTranslateTest_b);

    -- twoToMiSiYip_uid223_vecTranslateTest(BITSELECT,222)@3
    twoToMiSiYip_uid223_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist20_yip1_11_uid216_vecTranslateTest_b_1_q(50 downto 11));

    -- xip1E_12_uid226_vecTranslateTest(ADDSUB,225)@3
    xip1E_12_uid226_vecTranslateTest_s <= invSignOfSelectionSignal_uid225_vecTranslateTest_q;
    xip1E_12_uid226_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & redist21_xip1_11_uid215_vecTranslateTest_b_1_q));
    xip1E_12_uid226_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 40 => twoToMiSiYip_uid223_vecTranslateTest_b(39)) & twoToMiSiYip_uid223_vecTranslateTest_b));
    xip1E_12_uid226_vecTranslateTest_combproc: PROCESS (xip1E_12_uid226_vecTranslateTest_a, xip1E_12_uid226_vecTranslateTest_b, xip1E_12_uid226_vecTranslateTest_s)
    BEGIN
        IF (xip1E_12_uid226_vecTranslateTest_s = "1") THEN
            xip1E_12_uid226_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_12_uid226_vecTranslateTest_a) + SIGNED(xip1E_12_uid226_vecTranslateTest_b));
        ELSE
            xip1E_12_uid226_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_12_uid226_vecTranslateTest_a) - SIGNED(xip1E_12_uid226_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_12_uid226_vecTranslateTest_q <= xip1E_12_uid226_vecTranslateTest_o(61 downto 0);

    -- xip1_12_uid232_vecTranslateTest(BITSELECT,231)@3
    xip1_12_uid232_vecTranslateTest_in <= xip1E_12_uid226_vecTranslateTest_q(59 downto 0);
    xip1_12_uid232_vecTranslateTest_b <= xip1_12_uid232_vecTranslateTest_in(59 downto 0);

    -- xip1E_13_uid243_vecTranslateTest(ADDSUB,242)@3
    xip1E_13_uid243_vecTranslateTest_s <= invSignOfSelectionSignal_uid242_vecTranslateTest_q;
    xip1E_13_uid243_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_12_uid232_vecTranslateTest_b));
    xip1E_13_uid243_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 38 => twoToMiSiYip_uid240_vecTranslateTest_b(37)) & twoToMiSiYip_uid240_vecTranslateTest_b));
    xip1E_13_uid243_vecTranslateTest_combproc: PROCESS (xip1E_13_uid243_vecTranslateTest_a, xip1E_13_uid243_vecTranslateTest_b, xip1E_13_uid243_vecTranslateTest_s)
    BEGIN
        IF (xip1E_13_uid243_vecTranslateTest_s = "1") THEN
            xip1E_13_uid243_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_13_uid243_vecTranslateTest_a) + SIGNED(xip1E_13_uid243_vecTranslateTest_b));
        ELSE
            xip1E_13_uid243_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_13_uid243_vecTranslateTest_a) - SIGNED(xip1E_13_uid243_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_13_uid243_vecTranslateTest_q <= xip1E_13_uid243_vecTranslateTest_o(61 downto 0);

    -- xip1_13_uid249_vecTranslateTest(BITSELECT,248)@3
    xip1_13_uid249_vecTranslateTest_in <= xip1E_13_uid243_vecTranslateTest_q(59 downto 0);
    xip1_13_uid249_vecTranslateTest_b <= xip1_13_uid249_vecTranslateTest_in(59 downto 0);

    -- twoToMiSiXip_uid256_vecTranslateTest(BITSELECT,255)@3
    twoToMiSiXip_uid256_vecTranslateTest_b <= xip1_13_uid249_vecTranslateTest_b(59 downto 13);

    -- twoToMiSiXip_uid239_vecTranslateTest(BITSELECT,238)@3
    twoToMiSiXip_uid239_vecTranslateTest_b <= xip1_12_uid232_vecTranslateTest_b(59 downto 12);

    -- yip1E_13_uid244_vecTranslateTest(ADDSUB,243)@3
    yip1E_13_uid244_vecTranslateTest_s <= xMSB_uid235_vecTranslateTest_b;
    yip1E_13_uid244_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((51 downto 50 => yip1_12_uid233_vecTranslateTest_b(49)) & yip1_12_uid233_vecTranslateTest_b));
    yip1E_13_uid244_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid239_vecTranslateTest_b));
    yip1E_13_uid244_vecTranslateTest_combproc: PROCESS (yip1E_13_uid244_vecTranslateTest_a, yip1E_13_uid244_vecTranslateTest_b, yip1E_13_uid244_vecTranslateTest_s)
    BEGIN
        IF (yip1E_13_uid244_vecTranslateTest_s = "1") THEN
            yip1E_13_uid244_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_13_uid244_vecTranslateTest_a) + SIGNED(yip1E_13_uid244_vecTranslateTest_b));
        ELSE
            yip1E_13_uid244_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_13_uid244_vecTranslateTest_a) - SIGNED(yip1E_13_uid244_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_13_uid244_vecTranslateTest_q <= yip1E_13_uid244_vecTranslateTest_o(50 downto 0);

    -- yip1_13_uid250_vecTranslateTest(BITSELECT,249)@3
    yip1_13_uid250_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_13_uid244_vecTranslateTest_q(48 downto 0));
    yip1_13_uid250_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_13_uid250_vecTranslateTest_in(48 downto 0));

    -- yip1E_14_uid261_vecTranslateTest(ADDSUB,260)@3
    yip1E_14_uid261_vecTranslateTest_s <= xMSB_uid252_vecTranslateTest_b;
    yip1E_14_uid261_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((50 downto 49 => yip1_13_uid250_vecTranslateTest_b(48)) & yip1_13_uid250_vecTranslateTest_b));
    yip1E_14_uid261_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid256_vecTranslateTest_b));
    yip1E_14_uid261_vecTranslateTest_combproc: PROCESS (yip1E_14_uid261_vecTranslateTest_a, yip1E_14_uid261_vecTranslateTest_b, yip1E_14_uid261_vecTranslateTest_s)
    BEGIN
        IF (yip1E_14_uid261_vecTranslateTest_s = "1") THEN
            yip1E_14_uid261_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_14_uid261_vecTranslateTest_a) + SIGNED(yip1E_14_uid261_vecTranslateTest_b));
        ELSE
            yip1E_14_uid261_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_14_uid261_vecTranslateTest_a) - SIGNED(yip1E_14_uid261_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_14_uid261_vecTranslateTest_q <= yip1E_14_uid261_vecTranslateTest_o(49 downto 0);

    -- yip1_14_uid267_vecTranslateTest(BITSELECT,266)@3
    yip1_14_uid267_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_14_uid261_vecTranslateTest_q(47 downto 0));
    yip1_14_uid267_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_14_uid267_vecTranslateTest_in(47 downto 0));

    -- xMSB_uid269_vecTranslateTest(BITSELECT,268)@3
    xMSB_uid269_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_14_uid267_vecTranslateTest_b(47 downto 47));

    -- invSignOfSelectionSignal_uid276_vecTranslateTest(LOGICAL,275)@3
    invSignOfSelectionSignal_uid276_vecTranslateTest_q <= not (xMSB_uid269_vecTranslateTest_b);

    -- twoToMiSiYip_uid274_vecTranslateTest(BITSELECT,273)@3
    twoToMiSiYip_uid274_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_14_uid267_vecTranslateTest_b(47 downto 14));

    -- invSignOfSelectionSignal_uid259_vecTranslateTest(LOGICAL,258)@3
    invSignOfSelectionSignal_uid259_vecTranslateTest_q <= not (xMSB_uid252_vecTranslateTest_b);

    -- twoToMiSiYip_uid257_vecTranslateTest(BITSELECT,256)@3
    twoToMiSiYip_uid257_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_13_uid250_vecTranslateTest_b(48 downto 13));

    -- xip1E_14_uid260_vecTranslateTest(ADDSUB,259)@3
    xip1E_14_uid260_vecTranslateTest_s <= invSignOfSelectionSignal_uid259_vecTranslateTest_q;
    xip1E_14_uid260_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_13_uid249_vecTranslateTest_b));
    xip1E_14_uid260_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 36 => twoToMiSiYip_uid257_vecTranslateTest_b(35)) & twoToMiSiYip_uid257_vecTranslateTest_b));
    xip1E_14_uid260_vecTranslateTest_combproc: PROCESS (xip1E_14_uid260_vecTranslateTest_a, xip1E_14_uid260_vecTranslateTest_b, xip1E_14_uid260_vecTranslateTest_s)
    BEGIN
        IF (xip1E_14_uid260_vecTranslateTest_s = "1") THEN
            xip1E_14_uid260_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_14_uid260_vecTranslateTest_a) + SIGNED(xip1E_14_uid260_vecTranslateTest_b));
        ELSE
            xip1E_14_uid260_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_14_uid260_vecTranslateTest_a) - SIGNED(xip1E_14_uid260_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_14_uid260_vecTranslateTest_q <= xip1E_14_uid260_vecTranslateTest_o(61 downto 0);

    -- xip1_14_uid266_vecTranslateTest(BITSELECT,265)@3
    xip1_14_uid266_vecTranslateTest_in <= xip1E_14_uid260_vecTranslateTest_q(59 downto 0);
    xip1_14_uid266_vecTranslateTest_b <= xip1_14_uid266_vecTranslateTest_in(59 downto 0);

    -- xip1E_15_uid277_vecTranslateTest(ADDSUB,276)@3
    xip1E_15_uid277_vecTranslateTest_s <= invSignOfSelectionSignal_uid276_vecTranslateTest_q;
    xip1E_15_uid277_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_14_uid266_vecTranslateTest_b));
    xip1E_15_uid277_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 34 => twoToMiSiYip_uid274_vecTranslateTest_b(33)) & twoToMiSiYip_uid274_vecTranslateTest_b));
    xip1E_15_uid277_vecTranslateTest_combproc: PROCESS (xip1E_15_uid277_vecTranslateTest_a, xip1E_15_uid277_vecTranslateTest_b, xip1E_15_uid277_vecTranslateTest_s)
    BEGIN
        IF (xip1E_15_uid277_vecTranslateTest_s = "1") THEN
            xip1E_15_uid277_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_15_uid277_vecTranslateTest_a) + SIGNED(xip1E_15_uid277_vecTranslateTest_b));
        ELSE
            xip1E_15_uid277_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_15_uid277_vecTranslateTest_a) - SIGNED(xip1E_15_uid277_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_15_uid277_vecTranslateTest_q <= xip1E_15_uid277_vecTranslateTest_o(61 downto 0);

    -- xip1_15_uid283_vecTranslateTest(BITSELECT,282)@3
    xip1_15_uid283_vecTranslateTest_in <= xip1E_15_uid277_vecTranslateTest_q(59 downto 0);
    xip1_15_uid283_vecTranslateTest_b <= xip1_15_uid283_vecTranslateTest_in(59 downto 0);

    -- redist15_xip1_15_uid283_vecTranslateTest_b_1(DELAY,565)
    redist15_xip1_15_uid283_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 60, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xip1_15_uid283_vecTranslateTest_b, xout => redist15_xip1_15_uid283_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- twoToMiSiXip_uid290_vecTranslateTest(BITSELECT,289)@4
    twoToMiSiXip_uid290_vecTranslateTest_b <= redist15_xip1_15_uid283_vecTranslateTest_b_1_q(59 downto 15);

    -- twoToMiSiXip_uid273_vecTranslateTest(BITSELECT,272)@3
    twoToMiSiXip_uid273_vecTranslateTest_b <= xip1_14_uid266_vecTranslateTest_b(59 downto 14);

    -- yip1E_15_uid278_vecTranslateTest(ADDSUB,277)@3
    yip1E_15_uid278_vecTranslateTest_s <= xMSB_uid269_vecTranslateTest_b;
    yip1E_15_uid278_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((49 downto 48 => yip1_14_uid267_vecTranslateTest_b(47)) & yip1_14_uid267_vecTranslateTest_b));
    yip1E_15_uid278_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid273_vecTranslateTest_b));
    yip1E_15_uid278_vecTranslateTest_combproc: PROCESS (yip1E_15_uid278_vecTranslateTest_a, yip1E_15_uid278_vecTranslateTest_b, yip1E_15_uid278_vecTranslateTest_s)
    BEGIN
        IF (yip1E_15_uid278_vecTranslateTest_s = "1") THEN
            yip1E_15_uid278_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_15_uid278_vecTranslateTest_a) + SIGNED(yip1E_15_uid278_vecTranslateTest_b));
        ELSE
            yip1E_15_uid278_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_15_uid278_vecTranslateTest_a) - SIGNED(yip1E_15_uid278_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_15_uid278_vecTranslateTest_q <= yip1E_15_uid278_vecTranslateTest_o(48 downto 0);

    -- yip1_15_uid284_vecTranslateTest(BITSELECT,283)@3
    yip1_15_uid284_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_15_uid278_vecTranslateTest_q(46 downto 0));
    yip1_15_uid284_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_15_uid284_vecTranslateTest_in(46 downto 0));

    -- redist14_yip1_15_uid284_vecTranslateTest_b_1(DELAY,564)
    redist14_yip1_15_uid284_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 47, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => yip1_15_uid284_vecTranslateTest_b, xout => redist14_yip1_15_uid284_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- yip1E_16_uid295_vecTranslateTest(ADDSUB,294)@4
    yip1E_16_uid295_vecTranslateTest_s <= xMSB_uid286_vecTranslateTest_b;
    yip1E_16_uid295_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((48 downto 47 => redist14_yip1_15_uid284_vecTranslateTest_b_1_q(46)) & redist14_yip1_15_uid284_vecTranslateTest_b_1_q));
    yip1E_16_uid295_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid290_vecTranslateTest_b));
    yip1E_16_uid295_vecTranslateTest_combproc: PROCESS (yip1E_16_uid295_vecTranslateTest_a, yip1E_16_uid295_vecTranslateTest_b, yip1E_16_uid295_vecTranslateTest_s)
    BEGIN
        IF (yip1E_16_uid295_vecTranslateTest_s = "1") THEN
            yip1E_16_uid295_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_16_uid295_vecTranslateTest_a) + SIGNED(yip1E_16_uid295_vecTranslateTest_b));
        ELSE
            yip1E_16_uid295_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_16_uid295_vecTranslateTest_a) - SIGNED(yip1E_16_uid295_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_16_uid295_vecTranslateTest_q <= yip1E_16_uid295_vecTranslateTest_o(47 downto 0);

    -- yip1_16_uid301_vecTranslateTest(BITSELECT,300)@4
    yip1_16_uid301_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_16_uid295_vecTranslateTest_q(45 downto 0));
    yip1_16_uid301_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_16_uid301_vecTranslateTest_in(45 downto 0));

    -- xMSB_uid303_vecTranslateTest(BITSELECT,302)@4
    xMSB_uid303_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_16_uid301_vecTranslateTest_b(45 downto 45));

    -- invSignOfSelectionSignal_uid310_vecTranslateTest(LOGICAL,309)@4
    invSignOfSelectionSignal_uid310_vecTranslateTest_q <= not (xMSB_uid303_vecTranslateTest_b);

    -- twoToMiSiYip_uid308_vecTranslateTest(BITSELECT,307)@4
    twoToMiSiYip_uid308_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_16_uid301_vecTranslateTest_b(45 downto 16));

    -- invSignOfSelectionSignal_uid293_vecTranslateTest(LOGICAL,292)@4
    invSignOfSelectionSignal_uid293_vecTranslateTest_q <= not (xMSB_uid286_vecTranslateTest_b);

    -- twoToMiSiYip_uid291_vecTranslateTest(BITSELECT,290)@4
    twoToMiSiYip_uid291_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist14_yip1_15_uid284_vecTranslateTest_b_1_q(46 downto 15));

    -- xip1E_16_uid294_vecTranslateTest(ADDSUB,293)@4
    xip1E_16_uid294_vecTranslateTest_s <= invSignOfSelectionSignal_uid293_vecTranslateTest_q;
    xip1E_16_uid294_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & redist15_xip1_15_uid283_vecTranslateTest_b_1_q));
    xip1E_16_uid294_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 32 => twoToMiSiYip_uid291_vecTranslateTest_b(31)) & twoToMiSiYip_uid291_vecTranslateTest_b));
    xip1E_16_uid294_vecTranslateTest_combproc: PROCESS (xip1E_16_uid294_vecTranslateTest_a, xip1E_16_uid294_vecTranslateTest_b, xip1E_16_uid294_vecTranslateTest_s)
    BEGIN
        IF (xip1E_16_uid294_vecTranslateTest_s = "1") THEN
            xip1E_16_uid294_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_16_uid294_vecTranslateTest_a) + SIGNED(xip1E_16_uid294_vecTranslateTest_b));
        ELSE
            xip1E_16_uid294_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_16_uid294_vecTranslateTest_a) - SIGNED(xip1E_16_uid294_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_16_uid294_vecTranslateTest_q <= xip1E_16_uid294_vecTranslateTest_o(61 downto 0);

    -- xip1_16_uid300_vecTranslateTest(BITSELECT,299)@4
    xip1_16_uid300_vecTranslateTest_in <= xip1E_16_uid294_vecTranslateTest_q(59 downto 0);
    xip1_16_uid300_vecTranslateTest_b <= xip1_16_uid300_vecTranslateTest_in(59 downto 0);

    -- xip1E_17_uid311_vecTranslateTest(ADDSUB,310)@4
    xip1E_17_uid311_vecTranslateTest_s <= invSignOfSelectionSignal_uid310_vecTranslateTest_q;
    xip1E_17_uid311_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_16_uid300_vecTranslateTest_b));
    xip1E_17_uid311_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 30 => twoToMiSiYip_uid308_vecTranslateTest_b(29)) & twoToMiSiYip_uid308_vecTranslateTest_b));
    xip1E_17_uid311_vecTranslateTest_combproc: PROCESS (xip1E_17_uid311_vecTranslateTest_a, xip1E_17_uid311_vecTranslateTest_b, xip1E_17_uid311_vecTranslateTest_s)
    BEGIN
        IF (xip1E_17_uid311_vecTranslateTest_s = "1") THEN
            xip1E_17_uid311_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_17_uid311_vecTranslateTest_a) + SIGNED(xip1E_17_uid311_vecTranslateTest_b));
        ELSE
            xip1E_17_uid311_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_17_uid311_vecTranslateTest_a) - SIGNED(xip1E_17_uid311_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_17_uid311_vecTranslateTest_q <= xip1E_17_uid311_vecTranslateTest_o(61 downto 0);

    -- xip1_17_uid317_vecTranslateTest(BITSELECT,316)@4
    xip1_17_uid317_vecTranslateTest_in <= xip1E_17_uid311_vecTranslateTest_q(59 downto 0);
    xip1_17_uid317_vecTranslateTest_b <= xip1_17_uid317_vecTranslateTest_in(59 downto 0);

    -- twoToMiSiXip_uid324_vecTranslateTest(BITSELECT,323)@4
    twoToMiSiXip_uid324_vecTranslateTest_b <= xip1_17_uid317_vecTranslateTest_b(59 downto 17);

    -- twoToMiSiXip_uid307_vecTranslateTest(BITSELECT,306)@4
    twoToMiSiXip_uid307_vecTranslateTest_b <= xip1_16_uid300_vecTranslateTest_b(59 downto 16);

    -- yip1E_17_uid312_vecTranslateTest(ADDSUB,311)@4
    yip1E_17_uid312_vecTranslateTest_s <= xMSB_uid303_vecTranslateTest_b;
    yip1E_17_uid312_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((47 downto 46 => yip1_16_uid301_vecTranslateTest_b(45)) & yip1_16_uid301_vecTranslateTest_b));
    yip1E_17_uid312_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid307_vecTranslateTest_b));
    yip1E_17_uid312_vecTranslateTest_combproc: PROCESS (yip1E_17_uid312_vecTranslateTest_a, yip1E_17_uid312_vecTranslateTest_b, yip1E_17_uid312_vecTranslateTest_s)
    BEGIN
        IF (yip1E_17_uid312_vecTranslateTest_s = "1") THEN
            yip1E_17_uid312_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_17_uid312_vecTranslateTest_a) + SIGNED(yip1E_17_uid312_vecTranslateTest_b));
        ELSE
            yip1E_17_uid312_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_17_uid312_vecTranslateTest_a) - SIGNED(yip1E_17_uid312_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_17_uid312_vecTranslateTest_q <= yip1E_17_uid312_vecTranslateTest_o(46 downto 0);

    -- yip1_17_uid318_vecTranslateTest(BITSELECT,317)@4
    yip1_17_uid318_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_17_uid312_vecTranslateTest_q(44 downto 0));
    yip1_17_uid318_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_17_uid318_vecTranslateTest_in(44 downto 0));

    -- yip1E_18_uid329_vecTranslateTest(ADDSUB,328)@4
    yip1E_18_uid329_vecTranslateTest_s <= xMSB_uid320_vecTranslateTest_b;
    yip1E_18_uid329_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((46 downto 45 => yip1_17_uid318_vecTranslateTest_b(44)) & yip1_17_uid318_vecTranslateTest_b));
    yip1E_18_uid329_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid324_vecTranslateTest_b));
    yip1E_18_uid329_vecTranslateTest_combproc: PROCESS (yip1E_18_uid329_vecTranslateTest_a, yip1E_18_uid329_vecTranslateTest_b, yip1E_18_uid329_vecTranslateTest_s)
    BEGIN
        IF (yip1E_18_uid329_vecTranslateTest_s = "1") THEN
            yip1E_18_uid329_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_18_uid329_vecTranslateTest_a) + SIGNED(yip1E_18_uid329_vecTranslateTest_b));
        ELSE
            yip1E_18_uid329_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_18_uid329_vecTranslateTest_a) - SIGNED(yip1E_18_uid329_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_18_uid329_vecTranslateTest_q <= yip1E_18_uid329_vecTranslateTest_o(45 downto 0);

    -- yip1_18_uid335_vecTranslateTest(BITSELECT,334)@4
    yip1_18_uid335_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_18_uid329_vecTranslateTest_q(43 downto 0));
    yip1_18_uid335_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_18_uid335_vecTranslateTest_in(43 downto 0));

    -- xMSB_uid337_vecTranslateTest(BITSELECT,336)@4
    xMSB_uid337_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_18_uid335_vecTranslateTest_b(43 downto 43));

    -- invSignOfSelectionSignal_uid344_vecTranslateTest(LOGICAL,343)@4
    invSignOfSelectionSignal_uid344_vecTranslateTest_q <= not (xMSB_uid337_vecTranslateTest_b);

    -- twoToMiSiYip_uid342_vecTranslateTest(BITSELECT,341)@4
    twoToMiSiYip_uid342_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_18_uid335_vecTranslateTest_b(43 downto 18));

    -- invSignOfSelectionSignal_uid327_vecTranslateTest(LOGICAL,326)@4
    invSignOfSelectionSignal_uid327_vecTranslateTest_q <= not (xMSB_uid320_vecTranslateTest_b);

    -- twoToMiSiYip_uid325_vecTranslateTest(BITSELECT,324)@4
    twoToMiSiYip_uid325_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_17_uid318_vecTranslateTest_b(44 downto 17));

    -- xip1E_18_uid328_vecTranslateTest(ADDSUB,327)@4
    xip1E_18_uid328_vecTranslateTest_s <= invSignOfSelectionSignal_uid327_vecTranslateTest_q;
    xip1E_18_uid328_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_17_uid317_vecTranslateTest_b));
    xip1E_18_uid328_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 28 => twoToMiSiYip_uid325_vecTranslateTest_b(27)) & twoToMiSiYip_uid325_vecTranslateTest_b));
    xip1E_18_uid328_vecTranslateTest_combproc: PROCESS (xip1E_18_uid328_vecTranslateTest_a, xip1E_18_uid328_vecTranslateTest_b, xip1E_18_uid328_vecTranslateTest_s)
    BEGIN
        IF (xip1E_18_uid328_vecTranslateTest_s = "1") THEN
            xip1E_18_uid328_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_18_uid328_vecTranslateTest_a) + SIGNED(xip1E_18_uid328_vecTranslateTest_b));
        ELSE
            xip1E_18_uid328_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_18_uid328_vecTranslateTest_a) - SIGNED(xip1E_18_uid328_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_18_uid328_vecTranslateTest_q <= xip1E_18_uid328_vecTranslateTest_o(61 downto 0);

    -- xip1_18_uid334_vecTranslateTest(BITSELECT,333)@4
    xip1_18_uid334_vecTranslateTest_in <= xip1E_18_uid328_vecTranslateTest_q(59 downto 0);
    xip1_18_uid334_vecTranslateTest_b <= xip1_18_uid334_vecTranslateTest_in(59 downto 0);

    -- xip1E_19_uid345_vecTranslateTest(ADDSUB,344)@4
    xip1E_19_uid345_vecTranslateTest_s <= invSignOfSelectionSignal_uid344_vecTranslateTest_q;
    xip1E_19_uid345_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_18_uid334_vecTranslateTest_b));
    xip1E_19_uid345_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 26 => twoToMiSiYip_uid342_vecTranslateTest_b(25)) & twoToMiSiYip_uid342_vecTranslateTest_b));
    xip1E_19_uid345_vecTranslateTest_combproc: PROCESS (xip1E_19_uid345_vecTranslateTest_a, xip1E_19_uid345_vecTranslateTest_b, xip1E_19_uid345_vecTranslateTest_s)
    BEGIN
        IF (xip1E_19_uid345_vecTranslateTest_s = "1") THEN
            xip1E_19_uid345_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_19_uid345_vecTranslateTest_a) + SIGNED(xip1E_19_uid345_vecTranslateTest_b));
        ELSE
            xip1E_19_uid345_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_19_uid345_vecTranslateTest_a) - SIGNED(xip1E_19_uid345_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_19_uid345_vecTranslateTest_q <= xip1E_19_uid345_vecTranslateTest_o(61 downto 0);

    -- xip1_19_uid351_vecTranslateTest(BITSELECT,350)@4
    xip1_19_uid351_vecTranslateTest_in <= xip1E_19_uid345_vecTranslateTest_q(59 downto 0);
    xip1_19_uid351_vecTranslateTest_b <= xip1_19_uid351_vecTranslateTest_in(59 downto 0);

    -- redist9_xip1_19_uid351_vecTranslateTest_b_1(DELAY,559)
    redist9_xip1_19_uid351_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 60, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xip1_19_uid351_vecTranslateTest_b, xout => redist9_xip1_19_uid351_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- twoToMiSiXip_uid358_vecTranslateTest(BITSELECT,357)@5
    twoToMiSiXip_uid358_vecTranslateTest_b <= redist9_xip1_19_uid351_vecTranslateTest_b_1_q(59 downto 19);

    -- twoToMiSiXip_uid341_vecTranslateTest(BITSELECT,340)@4
    twoToMiSiXip_uid341_vecTranslateTest_b <= xip1_18_uid334_vecTranslateTest_b(59 downto 18);

    -- yip1E_19_uid346_vecTranslateTest(ADDSUB,345)@4
    yip1E_19_uid346_vecTranslateTest_s <= xMSB_uid337_vecTranslateTest_b;
    yip1E_19_uid346_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((45 downto 44 => yip1_18_uid335_vecTranslateTest_b(43)) & yip1_18_uid335_vecTranslateTest_b));
    yip1E_19_uid346_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid341_vecTranslateTest_b));
    yip1E_19_uid346_vecTranslateTest_combproc: PROCESS (yip1E_19_uid346_vecTranslateTest_a, yip1E_19_uid346_vecTranslateTest_b, yip1E_19_uid346_vecTranslateTest_s)
    BEGIN
        IF (yip1E_19_uid346_vecTranslateTest_s = "1") THEN
            yip1E_19_uid346_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_19_uid346_vecTranslateTest_a) + SIGNED(yip1E_19_uid346_vecTranslateTest_b));
        ELSE
            yip1E_19_uid346_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_19_uid346_vecTranslateTest_a) - SIGNED(yip1E_19_uid346_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_19_uid346_vecTranslateTest_q <= yip1E_19_uid346_vecTranslateTest_o(44 downto 0);

    -- yip1_19_uid352_vecTranslateTest(BITSELECT,351)@4
    yip1_19_uid352_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_19_uid346_vecTranslateTest_q(42 downto 0));
    yip1_19_uid352_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_19_uid352_vecTranslateTest_in(42 downto 0));

    -- redist8_yip1_19_uid352_vecTranslateTest_b_1(DELAY,558)
    redist8_yip1_19_uid352_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 43, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => yip1_19_uid352_vecTranslateTest_b, xout => redist8_yip1_19_uid352_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- yip1E_20_uid363_vecTranslateTest(ADDSUB,362)@5
    yip1E_20_uid363_vecTranslateTest_s <= xMSB_uid354_vecTranslateTest_b;
    yip1E_20_uid363_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((44 downto 43 => redist8_yip1_19_uid352_vecTranslateTest_b_1_q(42)) & redist8_yip1_19_uid352_vecTranslateTest_b_1_q));
    yip1E_20_uid363_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid358_vecTranslateTest_b));
    yip1E_20_uid363_vecTranslateTest_combproc: PROCESS (yip1E_20_uid363_vecTranslateTest_a, yip1E_20_uid363_vecTranslateTest_b, yip1E_20_uid363_vecTranslateTest_s)
    BEGIN
        IF (yip1E_20_uid363_vecTranslateTest_s = "1") THEN
            yip1E_20_uid363_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_20_uid363_vecTranslateTest_a) + SIGNED(yip1E_20_uid363_vecTranslateTest_b));
        ELSE
            yip1E_20_uid363_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_20_uid363_vecTranslateTest_a) - SIGNED(yip1E_20_uid363_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_20_uid363_vecTranslateTest_q <= yip1E_20_uid363_vecTranslateTest_o(43 downto 0);

    -- yip1_20_uid369_vecTranslateTest(BITSELECT,368)@5
    yip1_20_uid369_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_20_uid363_vecTranslateTest_q(41 downto 0));
    yip1_20_uid369_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_20_uid369_vecTranslateTest_in(41 downto 0));

    -- xMSB_uid371_vecTranslateTest(BITSELECT,370)@5
    xMSB_uid371_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_20_uid369_vecTranslateTest_b(41 downto 41));

    -- invSignOfSelectionSignal_uid378_vecTranslateTest(LOGICAL,377)@5
    invSignOfSelectionSignal_uid378_vecTranslateTest_q <= not (xMSB_uid371_vecTranslateTest_b);

    -- twoToMiSiYip_uid376_vecTranslateTest(BITSELECT,375)@5
    twoToMiSiYip_uid376_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_20_uid369_vecTranslateTest_b(41 downto 20));

    -- invSignOfSelectionSignal_uid361_vecTranslateTest(LOGICAL,360)@5
    invSignOfSelectionSignal_uid361_vecTranslateTest_q <= not (xMSB_uid354_vecTranslateTest_b);

    -- twoToMiSiYip_uid359_vecTranslateTest(BITSELECT,358)@5
    twoToMiSiYip_uid359_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist8_yip1_19_uid352_vecTranslateTest_b_1_q(42 downto 19));

    -- xip1E_20_uid362_vecTranslateTest(ADDSUB,361)@5
    xip1E_20_uid362_vecTranslateTest_s <= invSignOfSelectionSignal_uid361_vecTranslateTest_q;
    xip1E_20_uid362_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & redist9_xip1_19_uid351_vecTranslateTest_b_1_q));
    xip1E_20_uid362_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 24 => twoToMiSiYip_uid359_vecTranslateTest_b(23)) & twoToMiSiYip_uid359_vecTranslateTest_b));
    xip1E_20_uid362_vecTranslateTest_combproc: PROCESS (xip1E_20_uid362_vecTranslateTest_a, xip1E_20_uid362_vecTranslateTest_b, xip1E_20_uid362_vecTranslateTest_s)
    BEGIN
        IF (xip1E_20_uid362_vecTranslateTest_s = "1") THEN
            xip1E_20_uid362_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_20_uid362_vecTranslateTest_a) + SIGNED(xip1E_20_uid362_vecTranslateTest_b));
        ELSE
            xip1E_20_uid362_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_20_uid362_vecTranslateTest_a) - SIGNED(xip1E_20_uid362_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_20_uid362_vecTranslateTest_q <= xip1E_20_uid362_vecTranslateTest_o(61 downto 0);

    -- xip1_20_uid368_vecTranslateTest(BITSELECT,367)@5
    xip1_20_uid368_vecTranslateTest_in <= xip1E_20_uid362_vecTranslateTest_q(59 downto 0);
    xip1_20_uid368_vecTranslateTest_b <= xip1_20_uid368_vecTranslateTest_in(59 downto 0);

    -- xip1E_21_uid379_vecTranslateTest(ADDSUB,378)@5
    xip1E_21_uid379_vecTranslateTest_s <= invSignOfSelectionSignal_uid378_vecTranslateTest_q;
    xip1E_21_uid379_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_20_uid368_vecTranslateTest_b));
    xip1E_21_uid379_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 22 => twoToMiSiYip_uid376_vecTranslateTest_b(21)) & twoToMiSiYip_uid376_vecTranslateTest_b));
    xip1E_21_uid379_vecTranslateTest_combproc: PROCESS (xip1E_21_uid379_vecTranslateTest_a, xip1E_21_uid379_vecTranslateTest_b, xip1E_21_uid379_vecTranslateTest_s)
    BEGIN
        IF (xip1E_21_uid379_vecTranslateTest_s = "1") THEN
            xip1E_21_uid379_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_21_uid379_vecTranslateTest_a) + SIGNED(xip1E_21_uid379_vecTranslateTest_b));
        ELSE
            xip1E_21_uid379_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_21_uid379_vecTranslateTest_a) - SIGNED(xip1E_21_uid379_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_21_uid379_vecTranslateTest_q <= xip1E_21_uid379_vecTranslateTest_o(61 downto 0);

    -- xip1_21_uid385_vecTranslateTest(BITSELECT,384)@5
    xip1_21_uid385_vecTranslateTest_in <= xip1E_21_uid379_vecTranslateTest_q(59 downto 0);
    xip1_21_uid385_vecTranslateTest_b <= xip1_21_uid385_vecTranslateTest_in(59 downto 0);

    -- twoToMiSiXip_uid392_vecTranslateTest(BITSELECT,391)@5
    twoToMiSiXip_uid392_vecTranslateTest_b <= xip1_21_uid385_vecTranslateTest_b(59 downto 21);

    -- twoToMiSiXip_uid375_vecTranslateTest(BITSELECT,374)@5
    twoToMiSiXip_uid375_vecTranslateTest_b <= xip1_20_uid368_vecTranslateTest_b(59 downto 20);

    -- yip1E_21_uid380_vecTranslateTest(ADDSUB,379)@5
    yip1E_21_uid380_vecTranslateTest_s <= xMSB_uid371_vecTranslateTest_b;
    yip1E_21_uid380_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((43 downto 42 => yip1_20_uid369_vecTranslateTest_b(41)) & yip1_20_uid369_vecTranslateTest_b));
    yip1E_21_uid380_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid375_vecTranslateTest_b));
    yip1E_21_uid380_vecTranslateTest_combproc: PROCESS (yip1E_21_uid380_vecTranslateTest_a, yip1E_21_uid380_vecTranslateTest_b, yip1E_21_uid380_vecTranslateTest_s)
    BEGIN
        IF (yip1E_21_uid380_vecTranslateTest_s = "1") THEN
            yip1E_21_uid380_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_21_uid380_vecTranslateTest_a) + SIGNED(yip1E_21_uid380_vecTranslateTest_b));
        ELSE
            yip1E_21_uid380_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_21_uid380_vecTranslateTest_a) - SIGNED(yip1E_21_uid380_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_21_uid380_vecTranslateTest_q <= yip1E_21_uid380_vecTranslateTest_o(42 downto 0);

    -- yip1_21_uid386_vecTranslateTest(BITSELECT,385)@5
    yip1_21_uid386_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_21_uid380_vecTranslateTest_q(40 downto 0));
    yip1_21_uid386_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_21_uid386_vecTranslateTest_in(40 downto 0));

    -- yip1E_22_uid397_vecTranslateTest(ADDSUB,396)@5
    yip1E_22_uid397_vecTranslateTest_s <= xMSB_uid388_vecTranslateTest_b;
    yip1E_22_uid397_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((42 downto 41 => yip1_21_uid386_vecTranslateTest_b(40)) & yip1_21_uid386_vecTranslateTest_b));
    yip1E_22_uid397_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid392_vecTranslateTest_b));
    yip1E_22_uid397_vecTranslateTest_combproc: PROCESS (yip1E_22_uid397_vecTranslateTest_a, yip1E_22_uid397_vecTranslateTest_b, yip1E_22_uid397_vecTranslateTest_s)
    BEGIN
        IF (yip1E_22_uid397_vecTranslateTest_s = "1") THEN
            yip1E_22_uid397_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_22_uid397_vecTranslateTest_a) + SIGNED(yip1E_22_uid397_vecTranslateTest_b));
        ELSE
            yip1E_22_uid397_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_22_uid397_vecTranslateTest_a) - SIGNED(yip1E_22_uid397_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_22_uid397_vecTranslateTest_q <= yip1E_22_uid397_vecTranslateTest_o(41 downto 0);

    -- yip1_22_uid403_vecTranslateTest(BITSELECT,402)@5
    yip1_22_uid403_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_22_uid397_vecTranslateTest_q(39 downto 0));
    yip1_22_uid403_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_22_uid403_vecTranslateTest_in(39 downto 0));

    -- xMSB_uid405_vecTranslateTest(BITSELECT,404)@5
    xMSB_uid405_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_22_uid403_vecTranslateTest_b(39 downto 39));

    -- invSignOfSelectionSignal_uid412_vecTranslateTest(LOGICAL,411)@5
    invSignOfSelectionSignal_uid412_vecTranslateTest_q <= not (xMSB_uid405_vecTranslateTest_b);

    -- twoToMiSiYip_uid410_vecTranslateTest(BITSELECT,409)@5
    twoToMiSiYip_uid410_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_22_uid403_vecTranslateTest_b(39 downto 22));

    -- invSignOfSelectionSignal_uid395_vecTranslateTest(LOGICAL,394)@5
    invSignOfSelectionSignal_uid395_vecTranslateTest_q <= not (xMSB_uid388_vecTranslateTest_b);

    -- twoToMiSiYip_uid393_vecTranslateTest(BITSELECT,392)@5
    twoToMiSiYip_uid393_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_21_uid386_vecTranslateTest_b(40 downto 21));

    -- xip1E_22_uid396_vecTranslateTest(ADDSUB,395)@5
    xip1E_22_uid396_vecTranslateTest_s <= invSignOfSelectionSignal_uid395_vecTranslateTest_q;
    xip1E_22_uid396_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_21_uid385_vecTranslateTest_b));
    xip1E_22_uid396_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 20 => twoToMiSiYip_uid393_vecTranslateTest_b(19)) & twoToMiSiYip_uid393_vecTranslateTest_b));
    xip1E_22_uid396_vecTranslateTest_combproc: PROCESS (xip1E_22_uid396_vecTranslateTest_a, xip1E_22_uid396_vecTranslateTest_b, xip1E_22_uid396_vecTranslateTest_s)
    BEGIN
        IF (xip1E_22_uid396_vecTranslateTest_s = "1") THEN
            xip1E_22_uid396_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_22_uid396_vecTranslateTest_a) + SIGNED(xip1E_22_uid396_vecTranslateTest_b));
        ELSE
            xip1E_22_uid396_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_22_uid396_vecTranslateTest_a) - SIGNED(xip1E_22_uid396_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_22_uid396_vecTranslateTest_q <= xip1E_22_uid396_vecTranslateTest_o(61 downto 0);

    -- xip1_22_uid402_vecTranslateTest(BITSELECT,401)@5
    xip1_22_uid402_vecTranslateTest_in <= xip1E_22_uid396_vecTranslateTest_q(59 downto 0);
    xip1_22_uid402_vecTranslateTest_b <= xip1_22_uid402_vecTranslateTest_in(59 downto 0);

    -- xip1E_23_uid413_vecTranslateTest(ADDSUB,412)@5
    xip1E_23_uid413_vecTranslateTest_s <= invSignOfSelectionSignal_uid412_vecTranslateTest_q;
    xip1E_23_uid413_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_22_uid402_vecTranslateTest_b));
    xip1E_23_uid413_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 18 => twoToMiSiYip_uid410_vecTranslateTest_b(17)) & twoToMiSiYip_uid410_vecTranslateTest_b));
    xip1E_23_uid413_vecTranslateTest_combproc: PROCESS (xip1E_23_uid413_vecTranslateTest_a, xip1E_23_uid413_vecTranslateTest_b, xip1E_23_uid413_vecTranslateTest_s)
    BEGIN
        IF (xip1E_23_uid413_vecTranslateTest_s = "1") THEN
            xip1E_23_uid413_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_23_uid413_vecTranslateTest_a) + SIGNED(xip1E_23_uid413_vecTranslateTest_b));
        ELSE
            xip1E_23_uid413_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_23_uid413_vecTranslateTest_a) - SIGNED(xip1E_23_uid413_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_23_uid413_vecTranslateTest_q <= xip1E_23_uid413_vecTranslateTest_o(61 downto 0);

    -- xip1_23_uid419_vecTranslateTest(BITSELECT,418)@5
    xip1_23_uid419_vecTranslateTest_in <= xip1E_23_uid413_vecTranslateTest_q(59 downto 0);
    xip1_23_uid419_vecTranslateTest_b <= xip1_23_uid419_vecTranslateTest_in(59 downto 0);

    -- redist3_xip1_23_uid419_vecTranslateTest_b_1(DELAY,553)
    redist3_xip1_23_uid419_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 60, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xip1_23_uid419_vecTranslateTest_b, xout => redist3_xip1_23_uid419_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- twoToMiSiXip_uid426_vecTranslateTest(BITSELECT,425)@6
    twoToMiSiXip_uid426_vecTranslateTest_b <= redist3_xip1_23_uid419_vecTranslateTest_b_1_q(59 downto 23);

    -- twoToMiSiXip_uid409_vecTranslateTest(BITSELECT,408)@5
    twoToMiSiXip_uid409_vecTranslateTest_b <= xip1_22_uid402_vecTranslateTest_b(59 downto 22);

    -- yip1E_23_uid414_vecTranslateTest(ADDSUB,413)@5
    yip1E_23_uid414_vecTranslateTest_s <= xMSB_uid405_vecTranslateTest_b;
    yip1E_23_uid414_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((41 downto 40 => yip1_22_uid403_vecTranslateTest_b(39)) & yip1_22_uid403_vecTranslateTest_b));
    yip1E_23_uid414_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid409_vecTranslateTest_b));
    yip1E_23_uid414_vecTranslateTest_combproc: PROCESS (yip1E_23_uid414_vecTranslateTest_a, yip1E_23_uid414_vecTranslateTest_b, yip1E_23_uid414_vecTranslateTest_s)
    BEGIN
        IF (yip1E_23_uid414_vecTranslateTest_s = "1") THEN
            yip1E_23_uid414_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_23_uid414_vecTranslateTest_a) + SIGNED(yip1E_23_uid414_vecTranslateTest_b));
        ELSE
            yip1E_23_uid414_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_23_uid414_vecTranslateTest_a) - SIGNED(yip1E_23_uid414_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_23_uid414_vecTranslateTest_q <= yip1E_23_uid414_vecTranslateTest_o(40 downto 0);

    -- yip1_23_uid420_vecTranslateTest(BITSELECT,419)@5
    yip1_23_uid420_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_23_uid414_vecTranslateTest_q(38 downto 0));
    yip1_23_uid420_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_23_uid420_vecTranslateTest_in(38 downto 0));

    -- redist2_yip1_23_uid420_vecTranslateTest_b_1(DELAY,552)
    redist2_yip1_23_uid420_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 39, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => yip1_23_uid420_vecTranslateTest_b, xout => redist2_yip1_23_uid420_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- yip1E_24_uid431_vecTranslateTest(ADDSUB,430)@6
    yip1E_24_uid431_vecTranslateTest_s <= xMSB_uid422_vecTranslateTest_b;
    yip1E_24_uid431_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((40 downto 39 => redist2_yip1_23_uid420_vecTranslateTest_b_1_q(38)) & redist2_yip1_23_uid420_vecTranslateTest_b_1_q));
    yip1E_24_uid431_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid426_vecTranslateTest_b));
    yip1E_24_uid431_vecTranslateTest_combproc: PROCESS (yip1E_24_uid431_vecTranslateTest_a, yip1E_24_uid431_vecTranslateTest_b, yip1E_24_uid431_vecTranslateTest_s)
    BEGIN
        IF (yip1E_24_uid431_vecTranslateTest_s = "1") THEN
            yip1E_24_uid431_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_24_uid431_vecTranslateTest_a) + SIGNED(yip1E_24_uid431_vecTranslateTest_b));
        ELSE
            yip1E_24_uid431_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_24_uid431_vecTranslateTest_a) - SIGNED(yip1E_24_uid431_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_24_uid431_vecTranslateTest_q <= yip1E_24_uid431_vecTranslateTest_o(39 downto 0);

    -- yip1_24_uid437_vecTranslateTest(BITSELECT,436)@6
    yip1_24_uid437_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_24_uid431_vecTranslateTest_q(37 downto 0));
    yip1_24_uid437_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_24_uid437_vecTranslateTest_in(37 downto 0));

    -- xMSB_uid439_vecTranslateTest(BITSELECT,438)@6
    xMSB_uid439_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_24_uid437_vecTranslateTest_b(37 downto 37));

    -- invSignOfSelectionSignal_uid446_vecTranslateTest(LOGICAL,445)@6
    invSignOfSelectionSignal_uid446_vecTranslateTest_q <= not (xMSB_uid439_vecTranslateTest_b);

    -- twoToMiSiYip_uid444_vecTranslateTest(BITSELECT,443)@6
    twoToMiSiYip_uid444_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_24_uid437_vecTranslateTest_b(37 downto 24));

    -- invSignOfSelectionSignal_uid429_vecTranslateTest(LOGICAL,428)@6
    invSignOfSelectionSignal_uid429_vecTranslateTest_q <= not (xMSB_uid422_vecTranslateTest_b);

    -- twoToMiSiYip_uid427_vecTranslateTest(BITSELECT,426)@6
    twoToMiSiYip_uid427_vecTranslateTest_b <= STD_LOGIC_VECTOR(redist2_yip1_23_uid420_vecTranslateTest_b_1_q(38 downto 23));

    -- xip1E_24_uid430_vecTranslateTest(ADDSUB,429)@6
    xip1E_24_uid430_vecTranslateTest_s <= invSignOfSelectionSignal_uid429_vecTranslateTest_q;
    xip1E_24_uid430_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & redist3_xip1_23_uid419_vecTranslateTest_b_1_q));
    xip1E_24_uid430_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 16 => twoToMiSiYip_uid427_vecTranslateTest_b(15)) & twoToMiSiYip_uid427_vecTranslateTest_b));
    xip1E_24_uid430_vecTranslateTest_combproc: PROCESS (xip1E_24_uid430_vecTranslateTest_a, xip1E_24_uid430_vecTranslateTest_b, xip1E_24_uid430_vecTranslateTest_s)
    BEGIN
        IF (xip1E_24_uid430_vecTranslateTest_s = "1") THEN
            xip1E_24_uid430_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_24_uid430_vecTranslateTest_a) + SIGNED(xip1E_24_uid430_vecTranslateTest_b));
        ELSE
            xip1E_24_uid430_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_24_uid430_vecTranslateTest_a) - SIGNED(xip1E_24_uid430_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_24_uid430_vecTranslateTest_q <= xip1E_24_uid430_vecTranslateTest_o(61 downto 0);

    -- xip1_24_uid436_vecTranslateTest(BITSELECT,435)@6
    xip1_24_uid436_vecTranslateTest_in <= xip1E_24_uid430_vecTranslateTest_q(59 downto 0);
    xip1_24_uid436_vecTranslateTest_b <= xip1_24_uid436_vecTranslateTest_in(59 downto 0);

    -- xip1E_25_uid447_vecTranslateTest(ADDSUB,446)@6
    xip1E_25_uid447_vecTranslateTest_s <= invSignOfSelectionSignal_uid446_vecTranslateTest_q;
    xip1E_25_uid447_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_24_uid436_vecTranslateTest_b));
    xip1E_25_uid447_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 14 => twoToMiSiYip_uid444_vecTranslateTest_b(13)) & twoToMiSiYip_uid444_vecTranslateTest_b));
    xip1E_25_uid447_vecTranslateTest_combproc: PROCESS (xip1E_25_uid447_vecTranslateTest_a, xip1E_25_uid447_vecTranslateTest_b, xip1E_25_uid447_vecTranslateTest_s)
    BEGIN
        IF (xip1E_25_uid447_vecTranslateTest_s = "1") THEN
            xip1E_25_uid447_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_25_uid447_vecTranslateTest_a) + SIGNED(xip1E_25_uid447_vecTranslateTest_b));
        ELSE
            xip1E_25_uid447_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_25_uid447_vecTranslateTest_a) - SIGNED(xip1E_25_uid447_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_25_uid447_vecTranslateTest_q <= xip1E_25_uid447_vecTranslateTest_o(61 downto 0);

    -- xip1_25_uid453_vecTranslateTest(BITSELECT,452)@6
    xip1_25_uid453_vecTranslateTest_in <= xip1E_25_uid447_vecTranslateTest_q(59 downto 0);
    xip1_25_uid453_vecTranslateTest_b <= xip1_25_uid453_vecTranslateTest_in(59 downto 0);

    -- twoToMiSiXip_uid460_vecTranslateTest(BITSELECT,459)@6
    twoToMiSiXip_uid460_vecTranslateTest_b <= xip1_25_uid453_vecTranslateTest_b(59 downto 25);

    -- twoToMiSiXip_uid443_vecTranslateTest(BITSELECT,442)@6
    twoToMiSiXip_uid443_vecTranslateTest_b <= xip1_24_uid436_vecTranslateTest_b(59 downto 24);

    -- yip1E_25_uid448_vecTranslateTest(ADDSUB,447)@6
    yip1E_25_uid448_vecTranslateTest_s <= xMSB_uid439_vecTranslateTest_b;
    yip1E_25_uid448_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((39 downto 38 => yip1_24_uid437_vecTranslateTest_b(37)) & yip1_24_uid437_vecTranslateTest_b));
    yip1E_25_uid448_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid443_vecTranslateTest_b));
    yip1E_25_uid448_vecTranslateTest_combproc: PROCESS (yip1E_25_uid448_vecTranslateTest_a, yip1E_25_uid448_vecTranslateTest_b, yip1E_25_uid448_vecTranslateTest_s)
    BEGIN
        IF (yip1E_25_uid448_vecTranslateTest_s = "1") THEN
            yip1E_25_uid448_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_25_uid448_vecTranslateTest_a) + SIGNED(yip1E_25_uid448_vecTranslateTest_b));
        ELSE
            yip1E_25_uid448_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_25_uid448_vecTranslateTest_a) - SIGNED(yip1E_25_uid448_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_25_uid448_vecTranslateTest_q <= yip1E_25_uid448_vecTranslateTest_o(38 downto 0);

    -- yip1_25_uid454_vecTranslateTest(BITSELECT,453)@6
    yip1_25_uid454_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_25_uid448_vecTranslateTest_q(36 downto 0));
    yip1_25_uid454_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_25_uid454_vecTranslateTest_in(36 downto 0));

    -- yip1E_26_uid465_vecTranslateTest(ADDSUB,464)@6
    yip1E_26_uid465_vecTranslateTest_s <= xMSB_uid456_vecTranslateTest_b;
    yip1E_26_uid465_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((38 downto 37 => yip1_25_uid454_vecTranslateTest_b(36)) & yip1_25_uid454_vecTranslateTest_b));
    yip1E_26_uid465_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("0000" & twoToMiSiXip_uid460_vecTranslateTest_b));
    yip1E_26_uid465_vecTranslateTest_combproc: PROCESS (yip1E_26_uid465_vecTranslateTest_a, yip1E_26_uid465_vecTranslateTest_b, yip1E_26_uid465_vecTranslateTest_s)
    BEGIN
        IF (yip1E_26_uid465_vecTranslateTest_s = "1") THEN
            yip1E_26_uid465_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_26_uid465_vecTranslateTest_a) + SIGNED(yip1E_26_uid465_vecTranslateTest_b));
        ELSE
            yip1E_26_uid465_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(yip1E_26_uid465_vecTranslateTest_a) - SIGNED(yip1E_26_uid465_vecTranslateTest_b));
        END IF;
    END PROCESS;
    yip1E_26_uid465_vecTranslateTest_q <= yip1E_26_uid465_vecTranslateTest_o(37 downto 0);

    -- yip1_26_uid471_vecTranslateTest(BITSELECT,470)@6
    yip1_26_uid471_vecTranslateTest_in <= STD_LOGIC_VECTOR(yip1E_26_uid465_vecTranslateTest_q(35 downto 0));
    yip1_26_uid471_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_26_uid471_vecTranslateTest_in(35 downto 0));

    -- xMSB_uid473_vecTranslateTest(BITSELECT,472)@6
    xMSB_uid473_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_26_uid471_vecTranslateTest_b(35 downto 35));

    -- invSignOfSelectionSignal_uid480_vecTranslateTest(LOGICAL,479)@6
    invSignOfSelectionSignal_uid480_vecTranslateTest_q <= not (xMSB_uid473_vecTranslateTest_b);

    -- GND(CONSTANT,0)
    GND_q <= "0";

    -- twoToMiSiYip_uid478_vecTranslateTest(BITSELECT,477)@6
    twoToMiSiYip_uid478_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_26_uid471_vecTranslateTest_b(35 downto 26));

    -- invSignOfSelectionSignal_uid463_vecTranslateTest(LOGICAL,462)@6
    invSignOfSelectionSignal_uid463_vecTranslateTest_q <= not (xMSB_uid456_vecTranslateTest_b);

    -- twoToMiSiYip_uid461_vecTranslateTest(BITSELECT,460)@6
    twoToMiSiYip_uid461_vecTranslateTest_b <= STD_LOGIC_VECTOR(yip1_25_uid454_vecTranslateTest_b(36 downto 25));

    -- xip1E_26_uid464_vecTranslateTest(ADDSUB,463)@6
    xip1E_26_uid464_vecTranslateTest_s <= invSignOfSelectionSignal_uid463_vecTranslateTest_q;
    xip1E_26_uid464_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_25_uid453_vecTranslateTest_b));
    xip1E_26_uid464_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 12 => twoToMiSiYip_uid461_vecTranslateTest_b(11)) & twoToMiSiYip_uid461_vecTranslateTest_b));
    xip1E_26_uid464_vecTranslateTest_combproc: PROCESS (xip1E_26_uid464_vecTranslateTest_a, xip1E_26_uid464_vecTranslateTest_b, xip1E_26_uid464_vecTranslateTest_s)
    BEGIN
        IF (xip1E_26_uid464_vecTranslateTest_s = "1") THEN
            xip1E_26_uid464_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_26_uid464_vecTranslateTest_a) + SIGNED(xip1E_26_uid464_vecTranslateTest_b));
        ELSE
            xip1E_26_uid464_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_26_uid464_vecTranslateTest_a) - SIGNED(xip1E_26_uid464_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_26_uid464_vecTranslateTest_q <= xip1E_26_uid464_vecTranslateTest_o(61 downto 0);

    -- xip1_26_uid470_vecTranslateTest(BITSELECT,469)@6
    xip1_26_uid470_vecTranslateTest_in <= xip1E_26_uid464_vecTranslateTest_q(59 downto 0);
    xip1_26_uid470_vecTranslateTest_b <= xip1_26_uid470_vecTranslateTest_in(59 downto 0);

    -- xip1E_27_uid481_vecTranslateTest(ADDSUB,480)@6
    xip1E_27_uid481_vecTranslateTest_s <= invSignOfSelectionSignal_uid480_vecTranslateTest_q;
    xip1E_27_uid481_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR("000" & xip1_26_uid470_vecTranslateTest_b));
    xip1E_27_uid481_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((62 downto 10 => twoToMiSiYip_uid478_vecTranslateTest_b(9)) & twoToMiSiYip_uid478_vecTranslateTest_b));
    xip1E_27_uid481_vecTranslateTest_combproc: PROCESS (xip1E_27_uid481_vecTranslateTest_a, xip1E_27_uid481_vecTranslateTest_b, xip1E_27_uid481_vecTranslateTest_s)
    BEGIN
        IF (xip1E_27_uid481_vecTranslateTest_s = "1") THEN
            xip1E_27_uid481_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_27_uid481_vecTranslateTest_a) + SIGNED(xip1E_27_uid481_vecTranslateTest_b));
        ELSE
            xip1E_27_uid481_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(xip1E_27_uid481_vecTranslateTest_a) - SIGNED(xip1E_27_uid481_vecTranslateTest_b));
        END IF;
    END PROCESS;
    xip1E_27_uid481_vecTranslateTest_q <= xip1E_27_uid481_vecTranslateTest_o(61 downto 0);

    -- xip1_27_uid487_vecTranslateTest(BITSELECT,486)@6
    xip1_27_uid487_vecTranslateTest_in <= xip1E_27_uid481_vecTranslateTest_q(59 downto 0);
    xip1_27_uid487_vecTranslateTest_b <= xip1_27_uid487_vecTranslateTest_in(59 downto 0);

    -- outMagPreRnd_uid543_vecTranslateTest(BITSELECT,542)@6
    outMagPreRnd_uid543_vecTranslateTest_b <= xip1_27_uid487_vecTranslateTest_b(59 downto 32);

    -- redist1_outMagPreRnd_uid543_vecTranslateTest_b_1(DELAY,551)
    redist1_outMagPreRnd_uid543_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 28, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => outMagPreRnd_uid543_vecTranslateTest_b, xout => redist1_outMagPreRnd_uid543_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- outMagPostRnd_uid546_vecTranslateTest(ADD,545)@7
    outMagPostRnd_uid546_vecTranslateTest_a <= STD_LOGIC_VECTOR("0" & redist1_outMagPreRnd_uid543_vecTranslateTest_b_1_q);
    outMagPostRnd_uid546_vecTranslateTest_b <= STD_LOGIC_VECTOR("0000000000000000000000000000" & VCC_q);
    outMagPostRnd_uid546_vecTranslateTest_o <= STD_LOGIC_VECTOR(UNSIGNED(outMagPostRnd_uid546_vecTranslateTest_a) + UNSIGNED(outMagPostRnd_uid546_vecTranslateTest_b));
    outMagPostRnd_uid546_vecTranslateTest_q <= outMagPostRnd_uid546_vecTranslateTest_o(28 downto 0);

    -- outMag_uid547_vecTranslateTest(BITSELECT,546)@7
    outMag_uid547_vecTranslateTest_in <= outMagPostRnd_uid546_vecTranslateTest_q(27 downto 0);
    outMag_uid547_vecTranslateTest_b <= outMag_uid547_vecTranslateTest_in(27 downto 1);

    -- constPi_uid534_vecTranslateTest(CONSTANT,533)
    constPi_uid534_vecTranslateTest_q <= "1100100100001111110110101010";

    -- constPiP2uE_uid525_vecTranslateTest(CONSTANT,524)
    constPiP2uE_uid525_vecTranslateTest_q <= "110010010000111111011010111";

    -- constPio2P2u_mergedSignalTM_uid528_vecTranslateTest(BITJOIN,527)@7
    constPio2P2u_mergedSignalTM_uid528_vecTranslateTest_q <= GND_q & constPiP2uE_uid525_vecTranslateTest_q;

    -- cstZeroOutFormat_uid524_vecTranslateTest(CONSTANT,523)
    cstZeroOutFormat_uid524_vecTranslateTest_q <= "0000000000000000000000000010";

    -- redist35_xMSB_uid32_vecTranslateTest_b_6(DELAY,585)
    redist35_xMSB_uid32_vecTranslateTest_b_6 : dspba_delay
    GENERIC MAP ( width => 1, depth => 6, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid32_vecTranslateTest_b, xout => redist35_xMSB_uid32_vecTranslateTest_b_6_q, ena => en(0), clk => clk, aclr => areset );

    -- redist34_xMSB_uid51_vecTranslateTest_b_6(DELAY,584)
    redist34_xMSB_uid51_vecTranslateTest_b_6 : dspba_delay
    GENERIC MAP ( width => 1, depth => 6, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid51_vecTranslateTest_b, xout => redist34_xMSB_uid51_vecTranslateTest_b_6_q, ena => en(0), clk => clk, aclr => areset );

    -- redist31_xMSB_uid70_vecTranslateTest_b_5(DELAY,581)
    redist31_xMSB_uid70_vecTranslateTest_b_5 : dspba_delay
    GENERIC MAP ( width => 1, depth => 5, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid70_vecTranslateTest_b, xout => redist31_xMSB_uid70_vecTranslateTest_b_5_q, ena => en(0), clk => clk, aclr => areset );

    -- redist30_xMSB_uid89_vecTranslateTest_b_5(DELAY,580)
    redist30_xMSB_uid89_vecTranslateTest_b_5 : dspba_delay
    GENERIC MAP ( width => 1, depth => 5, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid89_vecTranslateTest_b, xout => redist30_xMSB_uid89_vecTranslateTest_b_5_q, ena => en(0), clk => clk, aclr => areset );

    -- redist29_xMSB_uid108_vecTranslateTest_b_5(DELAY,579)
    redist29_xMSB_uid108_vecTranslateTest_b_5 : dspba_delay
    GENERIC MAP ( width => 1, depth => 5, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid108_vecTranslateTest_b, xout => redist29_xMSB_uid108_vecTranslateTest_b_5_q, ena => en(0), clk => clk, aclr => areset );

    -- redist28_xMSB_uid127_vecTranslateTest_b_5(DELAY,578)
    redist28_xMSB_uid127_vecTranslateTest_b_5 : dspba_delay
    GENERIC MAP ( width => 1, depth => 5, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid127_vecTranslateTest_b, xout => redist28_xMSB_uid127_vecTranslateTest_b_5_q, ena => en(0), clk => clk, aclr => areset );

    -- redist25_xMSB_uid146_vecTranslateTest_b_4(DELAY,575)
    redist25_xMSB_uid146_vecTranslateTest_b_4 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid146_vecTranslateTest_b, xout => redist25_xMSB_uid146_vecTranslateTest_b_4_q, ena => en(0), clk => clk, aclr => areset );

    -- redist24_xMSB_uid167_vecTranslateTest_b_4(DELAY,574)
    redist24_xMSB_uid167_vecTranslateTest_b_4 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid167_vecTranslateTest_b, xout => redist24_xMSB_uid167_vecTranslateTest_b_4_q, ena => en(0), clk => clk, aclr => areset );

    -- redist23_xMSB_uid184_vecTranslateTest_b_4(DELAY,573)
    redist23_xMSB_uid184_vecTranslateTest_b_4 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid184_vecTranslateTest_b, xout => redist23_xMSB_uid184_vecTranslateTest_b_4_q, ena => en(0), clk => clk, aclr => areset );

    -- redist22_xMSB_uid201_vecTranslateTest_b_4(DELAY,572)
    redist22_xMSB_uid201_vecTranslateTest_b_4 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid201_vecTranslateTest_b, xout => redist22_xMSB_uid201_vecTranslateTest_b_4_q, ena => en(0), clk => clk, aclr => areset );

    -- redist19_xMSB_uid218_vecTranslateTest_b_3(DELAY,569)
    redist19_xMSB_uid218_vecTranslateTest_b_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid218_vecTranslateTest_b, xout => redist19_xMSB_uid218_vecTranslateTest_b_3_q, ena => en(0), clk => clk, aclr => areset );

    -- redist18_xMSB_uid235_vecTranslateTest_b_3(DELAY,568)
    redist18_xMSB_uid235_vecTranslateTest_b_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid235_vecTranslateTest_b, xout => redist18_xMSB_uid235_vecTranslateTest_b_3_q, ena => en(0), clk => clk, aclr => areset );

    -- redist17_xMSB_uid252_vecTranslateTest_b_3(DELAY,567)
    redist17_xMSB_uid252_vecTranslateTest_b_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid252_vecTranslateTest_b, xout => redist17_xMSB_uid252_vecTranslateTest_b_3_q, ena => en(0), clk => clk, aclr => areset );

    -- redist16_xMSB_uid269_vecTranslateTest_b_3(DELAY,566)
    redist16_xMSB_uid269_vecTranslateTest_b_3 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid269_vecTranslateTest_b, xout => redist16_xMSB_uid269_vecTranslateTest_b_3_q, ena => en(0), clk => clk, aclr => areset );

    -- redist13_xMSB_uid286_vecTranslateTest_b_2(DELAY,563)
    redist13_xMSB_uid286_vecTranslateTest_b_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid286_vecTranslateTest_b, xout => redist13_xMSB_uid286_vecTranslateTest_b_2_q, ena => en(0), clk => clk, aclr => areset );

    -- redist12_xMSB_uid303_vecTranslateTest_b_2(DELAY,562)
    redist12_xMSB_uid303_vecTranslateTest_b_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid303_vecTranslateTest_b, xout => redist12_xMSB_uid303_vecTranslateTest_b_2_q, ena => en(0), clk => clk, aclr => areset );

    -- redist11_xMSB_uid320_vecTranslateTest_b_2(DELAY,561)
    redist11_xMSB_uid320_vecTranslateTest_b_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid320_vecTranslateTest_b, xout => redist11_xMSB_uid320_vecTranslateTest_b_2_q, ena => en(0), clk => clk, aclr => areset );

    -- redist10_xMSB_uid337_vecTranslateTest_b_2(DELAY,560)
    redist10_xMSB_uid337_vecTranslateTest_b_2 : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid337_vecTranslateTest_b, xout => redist10_xMSB_uid337_vecTranslateTest_b_2_q, ena => en(0), clk => clk, aclr => areset );

    -- redist7_xMSB_uid354_vecTranslateTest_b_1(DELAY,557)
    redist7_xMSB_uid354_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid354_vecTranslateTest_b, xout => redist7_xMSB_uid354_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- redist6_xMSB_uid371_vecTranslateTest_b_1(DELAY,556)
    redist6_xMSB_uid371_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid371_vecTranslateTest_b, xout => redist6_xMSB_uid371_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- redist5_xMSB_uid388_vecTranslateTest_b_1(DELAY,555)
    redist5_xMSB_uid388_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid388_vecTranslateTest_b, xout => redist5_xMSB_uid388_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- redist4_xMSB_uid405_vecTranslateTest_b_1(DELAY,554)
    redist4_xMSB_uid405_vecTranslateTest_b_1 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xMSB_uid405_vecTranslateTest_b, xout => redist4_xMSB_uid405_vecTranslateTest_b_1_q, ena => en(0), clk => clk, aclr => areset );

    -- concSignVector_uid490_vecTranslateTest(BITJOIN,489)@6
    concSignVector_uid490_vecTranslateTest_q <= GND_q & redist35_xMSB_uid32_vecTranslateTest_b_6_q & redist34_xMSB_uid51_vecTranslateTest_b_6_q & redist31_xMSB_uid70_vecTranslateTest_b_5_q & redist30_xMSB_uid89_vecTranslateTest_b_5_q & redist29_xMSB_uid108_vecTranslateTest_b_5_q & redist28_xMSB_uid127_vecTranslateTest_b_5_q & redist25_xMSB_uid146_vecTranslateTest_b_4_q & redist24_xMSB_uid167_vecTranslateTest_b_4_q & redist23_xMSB_uid184_vecTranslateTest_b_4_q & redist22_xMSB_uid201_vecTranslateTest_b_4_q & redist19_xMSB_uid218_vecTranslateTest_b_3_q & redist18_xMSB_uid235_vecTranslateTest_b_3_q & redist17_xMSB_uid252_vecTranslateTest_b_3_q & redist16_xMSB_uid269_vecTranslateTest_b_3_q & redist13_xMSB_uid286_vecTranslateTest_b_2_q & redist12_xMSB_uid303_vecTranslateTest_b_2_q & redist11_xMSB_uid320_vecTranslateTest_b_2_q & redist10_xMSB_uid337_vecTranslateTest_b_2_q & redist7_xMSB_uid354_vecTranslateTest_b_1_q & redist6_xMSB_uid371_vecTranslateTest_b_1_q & redist5_xMSB_uid388_vecTranslateTest_b_1_q & redist4_xMSB_uid405_vecTranslateTest_b_1_q & xMSB_uid422_vecTranslateTest_b & xMSB_uid439_vecTranslateTest_b & xMSB_uid456_vecTranslateTest_b & xMSB_uid473_vecTranslateTest_b;

    -- is0_uid491_vecTranslateTest_merged_bit_select(BITSELECT,549)@6
    is0_uid491_vecTranslateTest_merged_bit_select_b <= concSignVector_uid490_vecTranslateTest_q(26 downto 21);
    is0_uid491_vecTranslateTest_merged_bit_select_c <= concSignVector_uid490_vecTranslateTest_q(20 downto 15);
    is0_uid491_vecTranslateTest_merged_bit_select_d <= concSignVector_uid490_vecTranslateTest_q(14 downto 9);
    is0_uid491_vecTranslateTest_merged_bit_select_e <= concSignVector_uid490_vecTranslateTest_q(8 downto 3);
    is0_uid491_vecTranslateTest_merged_bit_select_f <= concSignVector_uid490_vecTranslateTest_q(2 downto 0);

    -- redist0_is0_uid491_vecTranslateTest_merged_bit_select_f_1(DELAY,550)
    redist0_is0_uid491_vecTranslateTest_merged_bit_select_f_1 : dspba_delay
    GENERIC MAP ( width => 3, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => is0_uid491_vecTranslateTest_merged_bit_select_f, xout => redist0_is0_uid491_vecTranslateTest_merged_bit_select_f_1_q, ena => en(0), clk => clk, aclr => areset );

    -- table_l26_uid516_vecTranslateTest(LOOKUP,515)@7
    table_l26_uid516_vecTranslateTest_combproc: PROCESS (redist0_is0_uid491_vecTranslateTest_merged_bit_select_f_1_q)
    BEGIN
        -- Begin reserved scope level
        CASE (redist0_is0_uid491_vecTranslateTest_merged_bit_select_f_1_q) IS
            WHEN "000" => table_l26_uid516_vecTranslateTest_q <= "011100000";
            WHEN "001" => table_l26_uid516_vecTranslateTest_q <= "010100000";
            WHEN "010" => table_l26_uid516_vecTranslateTest_q <= "001100000";
            WHEN "011" => table_l26_uid516_vecTranslateTest_q <= "000100000";
            WHEN "100" => table_l26_uid516_vecTranslateTest_q <= "111100000";
            WHEN "101" => table_l26_uid516_vecTranslateTest_q <= "110100000";
            WHEN "110" => table_l26_uid516_vecTranslateTest_q <= "101100000";
            WHEN "111" => table_l26_uid516_vecTranslateTest_q <= "100100000";
            WHEN OTHERS => -- unreachable
                           table_l26_uid516_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l23_uid512_vecTranslateTest(LOOKUP,511)@6
    table_l23_uid512_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_e)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_e) IS
            WHEN "000000" => table_l23_uid512_vecTranslateTest_q <= "01111";
            WHEN "000001" => table_l23_uid512_vecTranslateTest_q <= "01111";
            WHEN "000010" => table_l23_uid512_vecTranslateTest_q <= "01110";
            WHEN "000011" => table_l23_uid512_vecTranslateTest_q <= "01110";
            WHEN "000100" => table_l23_uid512_vecTranslateTest_q <= "01101";
            WHEN "000101" => table_l23_uid512_vecTranslateTest_q <= "01101";
            WHEN "000110" => table_l23_uid512_vecTranslateTest_q <= "01100";
            WHEN "000111" => table_l23_uid512_vecTranslateTest_q <= "01100";
            WHEN "001000" => table_l23_uid512_vecTranslateTest_q <= "01011";
            WHEN "001001" => table_l23_uid512_vecTranslateTest_q <= "01011";
            WHEN "001010" => table_l23_uid512_vecTranslateTest_q <= "01010";
            WHEN "001011" => table_l23_uid512_vecTranslateTest_q <= "01010";
            WHEN "001100" => table_l23_uid512_vecTranslateTest_q <= "01001";
            WHEN "001101" => table_l23_uid512_vecTranslateTest_q <= "01001";
            WHEN "001110" => table_l23_uid512_vecTranslateTest_q <= "01000";
            WHEN "001111" => table_l23_uid512_vecTranslateTest_q <= "01000";
            WHEN "010000" => table_l23_uid512_vecTranslateTest_q <= "00111";
            WHEN "010001" => table_l23_uid512_vecTranslateTest_q <= "00111";
            WHEN "010010" => table_l23_uid512_vecTranslateTest_q <= "00110";
            WHEN "010011" => table_l23_uid512_vecTranslateTest_q <= "00110";
            WHEN "010100" => table_l23_uid512_vecTranslateTest_q <= "00101";
            WHEN "010101" => table_l23_uid512_vecTranslateTest_q <= "00101";
            WHEN "010110" => table_l23_uid512_vecTranslateTest_q <= "00100";
            WHEN "010111" => table_l23_uid512_vecTranslateTest_q <= "00100";
            WHEN "011000" => table_l23_uid512_vecTranslateTest_q <= "00011";
            WHEN "011001" => table_l23_uid512_vecTranslateTest_q <= "00011";
            WHEN "011010" => table_l23_uid512_vecTranslateTest_q <= "00010";
            WHEN "011011" => table_l23_uid512_vecTranslateTest_q <= "00010";
            WHEN "011100" => table_l23_uid512_vecTranslateTest_q <= "00001";
            WHEN "011101" => table_l23_uid512_vecTranslateTest_q <= "00001";
            WHEN "011110" => table_l23_uid512_vecTranslateTest_q <= "00000";
            WHEN "011111" => table_l23_uid512_vecTranslateTest_q <= "00000";
            WHEN "100000" => table_l23_uid512_vecTranslateTest_q <= "11111";
            WHEN "100001" => table_l23_uid512_vecTranslateTest_q <= "11111";
            WHEN "100010" => table_l23_uid512_vecTranslateTest_q <= "11110";
            WHEN "100011" => table_l23_uid512_vecTranslateTest_q <= "11110";
            WHEN "100100" => table_l23_uid512_vecTranslateTest_q <= "11101";
            WHEN "100101" => table_l23_uid512_vecTranslateTest_q <= "11101";
            WHEN "100110" => table_l23_uid512_vecTranslateTest_q <= "11100";
            WHEN "100111" => table_l23_uid512_vecTranslateTest_q <= "11100";
            WHEN "101000" => table_l23_uid512_vecTranslateTest_q <= "11011";
            WHEN "101001" => table_l23_uid512_vecTranslateTest_q <= "11011";
            WHEN "101010" => table_l23_uid512_vecTranslateTest_q <= "11010";
            WHEN "101011" => table_l23_uid512_vecTranslateTest_q <= "11010";
            WHEN "101100" => table_l23_uid512_vecTranslateTest_q <= "11001";
            WHEN "101101" => table_l23_uid512_vecTranslateTest_q <= "11001";
            WHEN "101110" => table_l23_uid512_vecTranslateTest_q <= "11000";
            WHEN "101111" => table_l23_uid512_vecTranslateTest_q <= "11000";
            WHEN "110000" => table_l23_uid512_vecTranslateTest_q <= "10111";
            WHEN "110001" => table_l23_uid512_vecTranslateTest_q <= "10111";
            WHEN "110010" => table_l23_uid512_vecTranslateTest_q <= "10110";
            WHEN "110011" => table_l23_uid512_vecTranslateTest_q <= "10110";
            WHEN "110100" => table_l23_uid512_vecTranslateTest_q <= "10101";
            WHEN "110101" => table_l23_uid512_vecTranslateTest_q <= "10101";
            WHEN "110110" => table_l23_uid512_vecTranslateTest_q <= "10100";
            WHEN "110111" => table_l23_uid512_vecTranslateTest_q <= "10100";
            WHEN "111000" => table_l23_uid512_vecTranslateTest_q <= "10011";
            WHEN "111001" => table_l23_uid512_vecTranslateTest_q <= "10011";
            WHEN "111010" => table_l23_uid512_vecTranslateTest_q <= "10010";
            WHEN "111011" => table_l23_uid512_vecTranslateTest_q <= "10010";
            WHEN "111100" => table_l23_uid512_vecTranslateTest_q <= "10001";
            WHEN "111101" => table_l23_uid512_vecTranslateTest_q <= "10001";
            WHEN "111110" => table_l23_uid512_vecTranslateTest_q <= "10000";
            WHEN "111111" => table_l23_uid512_vecTranslateTest_q <= "10000";
            WHEN OTHERS => -- unreachable
                           table_l23_uid512_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l23_uid511_vecTranslateTest(LOOKUP,510)@6
    table_l23_uid511_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_e)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_e) IS
            WHEN "000000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "000001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "000010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "000011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "000100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "000101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "000110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "000111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "001000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "001001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "001010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "001011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "001100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "001101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "001110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "001111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "010000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "010001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "010010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "010011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "010100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "010101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "010110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "010111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "011000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "011001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "011010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "011011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "011100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "011101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "011110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "011111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "100000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "100001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "100010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "100011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "100100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "100101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "100110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "100111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "101000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "101001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "101010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "101011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "101100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "101101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "101110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "101111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "110000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "110001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "110010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "110011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "110100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "110101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "110110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "110111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "111000" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "111001" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "111010" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "111011" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "111100" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "111101" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN "111110" => table_l23_uid511_vecTranslateTest_q <= "1100000000";
            WHEN "111111" => table_l23_uid511_vecTranslateTest_q <= "0100000000";
            WHEN OTHERS => -- unreachable
                           table_l23_uid511_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- os_uid513_vecTranslateTest(BITJOIN,512)@6
    os_uid513_vecTranslateTest_q <= table_l23_uid512_vecTranslateTest_q & table_l23_uid511_vecTranslateTest_q;

    -- table_l17_uid507_vecTranslateTest(LOOKUP,506)@6
    table_l17_uid507_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_d)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_d) IS
            WHEN "000000" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "000001" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "000010" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "000011" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "000100" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "000101" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "000110" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "000111" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001000" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001001" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001010" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001011" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001100" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001101" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001110" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "001111" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010000" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010001" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010010" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010011" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010100" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010101" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010110" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "010111" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011000" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011001" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011010" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011011" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011100" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011101" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011110" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "011111" => table_l17_uid507_vecTranslateTest_q <= "0";
            WHEN "100000" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "100001" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "100010" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "100011" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "100100" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "100101" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "100110" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "100111" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101000" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101001" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101010" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101011" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101100" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101101" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101110" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "101111" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110000" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110001" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110010" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110011" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110100" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110101" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110110" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "110111" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111000" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111001" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111010" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111011" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111100" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111101" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111110" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN "111111" => table_l17_uid507_vecTranslateTest_q <= "1";
            WHEN OTHERS => -- unreachable
                           table_l17_uid507_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l17_uid506_vecTranslateTest(LOOKUP,505)@6
    table_l17_uid506_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_d)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_d) IS
            WHEN "000000" => table_l17_uid506_vecTranslateTest_q <= "1111110000";
            WHEN "000001" => table_l17_uid506_vecTranslateTest_q <= "1111010000";
            WHEN "000010" => table_l17_uid506_vecTranslateTest_q <= "1110110000";
            WHEN "000011" => table_l17_uid506_vecTranslateTest_q <= "1110010000";
            WHEN "000100" => table_l17_uid506_vecTranslateTest_q <= "1101110000";
            WHEN "000101" => table_l17_uid506_vecTranslateTest_q <= "1101010000";
            WHEN "000110" => table_l17_uid506_vecTranslateTest_q <= "1100110000";
            WHEN "000111" => table_l17_uid506_vecTranslateTest_q <= "1100010000";
            WHEN "001000" => table_l17_uid506_vecTranslateTest_q <= "1011110000";
            WHEN "001001" => table_l17_uid506_vecTranslateTest_q <= "1011010000";
            WHEN "001010" => table_l17_uid506_vecTranslateTest_q <= "1010110000";
            WHEN "001011" => table_l17_uid506_vecTranslateTest_q <= "1010010000";
            WHEN "001100" => table_l17_uid506_vecTranslateTest_q <= "1001110000";
            WHEN "001101" => table_l17_uid506_vecTranslateTest_q <= "1001010000";
            WHEN "001110" => table_l17_uid506_vecTranslateTest_q <= "1000110000";
            WHEN "001111" => table_l17_uid506_vecTranslateTest_q <= "1000010000";
            WHEN "010000" => table_l17_uid506_vecTranslateTest_q <= "0111110000";
            WHEN "010001" => table_l17_uid506_vecTranslateTest_q <= "0111010000";
            WHEN "010010" => table_l17_uid506_vecTranslateTest_q <= "0110110000";
            WHEN "010011" => table_l17_uid506_vecTranslateTest_q <= "0110010000";
            WHEN "010100" => table_l17_uid506_vecTranslateTest_q <= "0101110000";
            WHEN "010101" => table_l17_uid506_vecTranslateTest_q <= "0101010000";
            WHEN "010110" => table_l17_uid506_vecTranslateTest_q <= "0100110000";
            WHEN "010111" => table_l17_uid506_vecTranslateTest_q <= "0100010000";
            WHEN "011000" => table_l17_uid506_vecTranslateTest_q <= "0011110000";
            WHEN "011001" => table_l17_uid506_vecTranslateTest_q <= "0011010000";
            WHEN "011010" => table_l17_uid506_vecTranslateTest_q <= "0010110000";
            WHEN "011011" => table_l17_uid506_vecTranslateTest_q <= "0010010000";
            WHEN "011100" => table_l17_uid506_vecTranslateTest_q <= "0001110000";
            WHEN "011101" => table_l17_uid506_vecTranslateTest_q <= "0001010000";
            WHEN "011110" => table_l17_uid506_vecTranslateTest_q <= "0000110000";
            WHEN "011111" => table_l17_uid506_vecTranslateTest_q <= "0000010000";
            WHEN "100000" => table_l17_uid506_vecTranslateTest_q <= "1111110000";
            WHEN "100001" => table_l17_uid506_vecTranslateTest_q <= "1111010000";
            WHEN "100010" => table_l17_uid506_vecTranslateTest_q <= "1110110000";
            WHEN "100011" => table_l17_uid506_vecTranslateTest_q <= "1110010000";
            WHEN "100100" => table_l17_uid506_vecTranslateTest_q <= "1101110000";
            WHEN "100101" => table_l17_uid506_vecTranslateTest_q <= "1101010000";
            WHEN "100110" => table_l17_uid506_vecTranslateTest_q <= "1100110000";
            WHEN "100111" => table_l17_uid506_vecTranslateTest_q <= "1100010000";
            WHEN "101000" => table_l17_uid506_vecTranslateTest_q <= "1011110000";
            WHEN "101001" => table_l17_uid506_vecTranslateTest_q <= "1011010000";
            WHEN "101010" => table_l17_uid506_vecTranslateTest_q <= "1010110000";
            WHEN "101011" => table_l17_uid506_vecTranslateTest_q <= "1010010000";
            WHEN "101100" => table_l17_uid506_vecTranslateTest_q <= "1001110000";
            WHEN "101101" => table_l17_uid506_vecTranslateTest_q <= "1001010000";
            WHEN "101110" => table_l17_uid506_vecTranslateTest_q <= "1000110000";
            WHEN "101111" => table_l17_uid506_vecTranslateTest_q <= "1000010000";
            WHEN "110000" => table_l17_uid506_vecTranslateTest_q <= "0111110000";
            WHEN "110001" => table_l17_uid506_vecTranslateTest_q <= "0111010000";
            WHEN "110010" => table_l17_uid506_vecTranslateTest_q <= "0110110000";
            WHEN "110011" => table_l17_uid506_vecTranslateTest_q <= "0110010000";
            WHEN "110100" => table_l17_uid506_vecTranslateTest_q <= "0101110000";
            WHEN "110101" => table_l17_uid506_vecTranslateTest_q <= "0101010000";
            WHEN "110110" => table_l17_uid506_vecTranslateTest_q <= "0100110000";
            WHEN "110111" => table_l17_uid506_vecTranslateTest_q <= "0100010000";
            WHEN "111000" => table_l17_uid506_vecTranslateTest_q <= "0011110000";
            WHEN "111001" => table_l17_uid506_vecTranslateTest_q <= "0011010000";
            WHEN "111010" => table_l17_uid506_vecTranslateTest_q <= "0010110000";
            WHEN "111011" => table_l17_uid506_vecTranslateTest_q <= "0010010000";
            WHEN "111100" => table_l17_uid506_vecTranslateTest_q <= "0001110000";
            WHEN "111101" => table_l17_uid506_vecTranslateTest_q <= "0001010000";
            WHEN "111110" => table_l17_uid506_vecTranslateTest_q <= "0000110000";
            WHEN "111111" => table_l17_uid506_vecTranslateTest_q <= "0000010000";
            WHEN OTHERS => -- unreachable
                           table_l17_uid506_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l17_uid505_vecTranslateTest_q_const(CONSTANT,548)
    table_l17_uid505_vecTranslateTest_q_const_q <= "0000000000";

    -- os_uid508_vecTranslateTest(BITJOIN,507)@6
    os_uid508_vecTranslateTest_q <= table_l17_uid507_vecTranslateTest_q & table_l17_uid506_vecTranslateTest_q & table_l17_uid505_vecTranslateTest_q_const_q;

    -- lev1_a1_uid520_vecTranslateTest(ADD,519)@6 + 1
    lev1_a1_uid520_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((21 downto 21 => os_uid508_vecTranslateTest_q(20)) & os_uid508_vecTranslateTest_q));
    lev1_a1_uid520_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((21 downto 15 => os_uid513_vecTranslateTest_q(14)) & os_uid513_vecTranslateTest_q));
    lev1_a1_uid520_vecTranslateTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            lev1_a1_uid520_vecTranslateTest_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                lev1_a1_uid520_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(lev1_a1_uid520_vecTranslateTest_a) + SIGNED(lev1_a1_uid520_vecTranslateTest_b));
            END IF;
        END IF;
    END PROCESS;
    lev1_a1_uid520_vecTranslateTest_q <= lev1_a1_uid520_vecTranslateTest_o(21 downto 0);

    -- table_l11_uid501_vecTranslateTest(LOOKUP,500)@6
    table_l11_uid501_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_c)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_c) IS
            WHEN "000000" => table_l11_uid501_vecTranslateTest_q <= "0111110";
            WHEN "000001" => table_l11_uid501_vecTranslateTest_q <= "0111100";
            WHEN "000010" => table_l11_uid501_vecTranslateTest_q <= "0111010";
            WHEN "000011" => table_l11_uid501_vecTranslateTest_q <= "0111000";
            WHEN "000100" => table_l11_uid501_vecTranslateTest_q <= "0110110";
            WHEN "000101" => table_l11_uid501_vecTranslateTest_q <= "0110100";
            WHEN "000110" => table_l11_uid501_vecTranslateTest_q <= "0110010";
            WHEN "000111" => table_l11_uid501_vecTranslateTest_q <= "0110000";
            WHEN "001000" => table_l11_uid501_vecTranslateTest_q <= "0101110";
            WHEN "001001" => table_l11_uid501_vecTranslateTest_q <= "0101100";
            WHEN "001010" => table_l11_uid501_vecTranslateTest_q <= "0101010";
            WHEN "001011" => table_l11_uid501_vecTranslateTest_q <= "0101000";
            WHEN "001100" => table_l11_uid501_vecTranslateTest_q <= "0100110";
            WHEN "001101" => table_l11_uid501_vecTranslateTest_q <= "0100100";
            WHEN "001110" => table_l11_uid501_vecTranslateTest_q <= "0100010";
            WHEN "001111" => table_l11_uid501_vecTranslateTest_q <= "0100000";
            WHEN "010000" => table_l11_uid501_vecTranslateTest_q <= "0011110";
            WHEN "010001" => table_l11_uid501_vecTranslateTest_q <= "0011100";
            WHEN "010010" => table_l11_uid501_vecTranslateTest_q <= "0011010";
            WHEN "010011" => table_l11_uid501_vecTranslateTest_q <= "0011000";
            WHEN "010100" => table_l11_uid501_vecTranslateTest_q <= "0010110";
            WHEN "010101" => table_l11_uid501_vecTranslateTest_q <= "0010100";
            WHEN "010110" => table_l11_uid501_vecTranslateTest_q <= "0010010";
            WHEN "010111" => table_l11_uid501_vecTranslateTest_q <= "0010000";
            WHEN "011000" => table_l11_uid501_vecTranslateTest_q <= "0001110";
            WHEN "011001" => table_l11_uid501_vecTranslateTest_q <= "0001100";
            WHEN "011010" => table_l11_uid501_vecTranslateTest_q <= "0001010";
            WHEN "011011" => table_l11_uid501_vecTranslateTest_q <= "0001000";
            WHEN "011100" => table_l11_uid501_vecTranslateTest_q <= "0000110";
            WHEN "011101" => table_l11_uid501_vecTranslateTest_q <= "0000100";
            WHEN "011110" => table_l11_uid501_vecTranslateTest_q <= "0000010";
            WHEN "011111" => table_l11_uid501_vecTranslateTest_q <= "0000000";
            WHEN "100000" => table_l11_uid501_vecTranslateTest_q <= "1111111";
            WHEN "100001" => table_l11_uid501_vecTranslateTest_q <= "1111101";
            WHEN "100010" => table_l11_uid501_vecTranslateTest_q <= "1111011";
            WHEN "100011" => table_l11_uid501_vecTranslateTest_q <= "1111001";
            WHEN "100100" => table_l11_uid501_vecTranslateTest_q <= "1110111";
            WHEN "100101" => table_l11_uid501_vecTranslateTest_q <= "1110101";
            WHEN "100110" => table_l11_uid501_vecTranslateTest_q <= "1110011";
            WHEN "100111" => table_l11_uid501_vecTranslateTest_q <= "1110001";
            WHEN "101000" => table_l11_uid501_vecTranslateTest_q <= "1101111";
            WHEN "101001" => table_l11_uid501_vecTranslateTest_q <= "1101101";
            WHEN "101010" => table_l11_uid501_vecTranslateTest_q <= "1101011";
            WHEN "101011" => table_l11_uid501_vecTranslateTest_q <= "1101001";
            WHEN "101100" => table_l11_uid501_vecTranslateTest_q <= "1100111";
            WHEN "101101" => table_l11_uid501_vecTranslateTest_q <= "1100101";
            WHEN "101110" => table_l11_uid501_vecTranslateTest_q <= "1100011";
            WHEN "101111" => table_l11_uid501_vecTranslateTest_q <= "1100001";
            WHEN "110000" => table_l11_uid501_vecTranslateTest_q <= "1011111";
            WHEN "110001" => table_l11_uid501_vecTranslateTest_q <= "1011101";
            WHEN "110010" => table_l11_uid501_vecTranslateTest_q <= "1011011";
            WHEN "110011" => table_l11_uid501_vecTranslateTest_q <= "1011001";
            WHEN "110100" => table_l11_uid501_vecTranslateTest_q <= "1010111";
            WHEN "110101" => table_l11_uid501_vecTranslateTest_q <= "1010101";
            WHEN "110110" => table_l11_uid501_vecTranslateTest_q <= "1010011";
            WHEN "110111" => table_l11_uid501_vecTranslateTest_q <= "1010001";
            WHEN "111000" => table_l11_uid501_vecTranslateTest_q <= "1001111";
            WHEN "111001" => table_l11_uid501_vecTranslateTest_q <= "1001101";
            WHEN "111010" => table_l11_uid501_vecTranslateTest_q <= "1001011";
            WHEN "111011" => table_l11_uid501_vecTranslateTest_q <= "1001001";
            WHEN "111100" => table_l11_uid501_vecTranslateTest_q <= "1000111";
            WHEN "111101" => table_l11_uid501_vecTranslateTest_q <= "1000101";
            WHEN "111110" => table_l11_uid501_vecTranslateTest_q <= "1000011";
            WHEN "111111" => table_l11_uid501_vecTranslateTest_q <= "1000001";
            WHEN OTHERS => -- unreachable
                           table_l11_uid501_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l11_uid500_vecTranslateTest(LOOKUP,499)@6
    table_l11_uid500_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_c)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_c) IS
            WHEN "000000" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "000001" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "000010" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "000011" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "000100" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "000101" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "000110" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "000111" => table_l11_uid500_vecTranslateTest_q <= "1111111100";
            WHEN "001000" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "001001" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "001010" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "001011" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "001100" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "001101" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "001110" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "001111" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010000" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010001" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010010" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010011" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010100" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010101" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010110" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "010111" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011000" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011001" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011010" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011011" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011100" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011101" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011110" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "011111" => table_l11_uid500_vecTranslateTest_q <= "1111111101";
            WHEN "100000" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "100001" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "100010" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "100011" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "100100" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "100101" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "100110" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "100111" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101000" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101001" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101010" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101011" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101100" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101101" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101110" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "101111" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110000" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110001" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110010" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110011" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110100" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110101" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110110" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "110111" => table_l11_uid500_vecTranslateTest_q <= "0000000010";
            WHEN "111000" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN "111001" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN "111010" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN "111011" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN "111100" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN "111101" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN "111110" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN "111111" => table_l11_uid500_vecTranslateTest_q <= "0000000011";
            WHEN OTHERS => -- unreachable
                           table_l11_uid500_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l11_uid499_vecTranslateTest(LOOKUP,498)@6
    table_l11_uid499_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_c)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_c) IS
            WHEN "000000" => table_l11_uid499_vecTranslateTest_q <= "1111010000";
            WHEN "000001" => table_l11_uid499_vecTranslateTest_q <= "1111010000";
            WHEN "000010" => table_l11_uid499_vecTranslateTest_q <= "1111010001";
            WHEN "000011" => table_l11_uid499_vecTranslateTest_q <= "1111010001";
            WHEN "000100" => table_l11_uid499_vecTranslateTest_q <= "1111011010";
            WHEN "000101" => table_l11_uid499_vecTranslateTest_q <= "1111011010";
            WHEN "000110" => table_l11_uid499_vecTranslateTest_q <= "1111011100";
            WHEN "000111" => table_l11_uid499_vecTranslateTest_q <= "1111011100";
            WHEN "001000" => table_l11_uid499_vecTranslateTest_q <= "0000100101";
            WHEN "001001" => table_l11_uid499_vecTranslateTest_q <= "0000100101";
            WHEN "001010" => table_l11_uid499_vecTranslateTest_q <= "0000100110";
            WHEN "001011" => table_l11_uid499_vecTranslateTest_q <= "0000100110";
            WHEN "001100" => table_l11_uid499_vecTranslateTest_q <= "0000110000";
            WHEN "001101" => table_l11_uid499_vecTranslateTest_q <= "0000110000";
            WHEN "001110" => table_l11_uid499_vecTranslateTest_q <= "0000110001";
            WHEN "001111" => table_l11_uid499_vecTranslateTest_q <= "0000110001";
            WHEN "010000" => table_l11_uid499_vecTranslateTest_q <= "1001111010";
            WHEN "010001" => table_l11_uid499_vecTranslateTest_q <= "1001111010";
            WHEN "010010" => table_l11_uid499_vecTranslateTest_q <= "1001111100";
            WHEN "010011" => table_l11_uid499_vecTranslateTest_q <= "1001111100";
            WHEN "010100" => table_l11_uid499_vecTranslateTest_q <= "1010000101";
            WHEN "010101" => table_l11_uid499_vecTranslateTest_q <= "1010000101";
            WHEN "010110" => table_l11_uid499_vecTranslateTest_q <= "1010000110";
            WHEN "010111" => table_l11_uid499_vecTranslateTest_q <= "1010000110";
            WHEN "011000" => table_l11_uid499_vecTranslateTest_q <= "1011010000";
            WHEN "011001" => table_l11_uid499_vecTranslateTest_q <= "1011010000";
            WHEN "011010" => table_l11_uid499_vecTranslateTest_q <= "1011010001";
            WHEN "011011" => table_l11_uid499_vecTranslateTest_q <= "1011010001";
            WHEN "011100" => table_l11_uid499_vecTranslateTest_q <= "1011011010";
            WHEN "011101" => table_l11_uid499_vecTranslateTest_q <= "1011011010";
            WHEN "011110" => table_l11_uid499_vecTranslateTest_q <= "1011011100";
            WHEN "011111" => table_l11_uid499_vecTranslateTest_q <= "1011011100";
            WHEN "100000" => table_l11_uid499_vecTranslateTest_q <= "0100100100";
            WHEN "100001" => table_l11_uid499_vecTranslateTest_q <= "0100100100";
            WHEN "100010" => table_l11_uid499_vecTranslateTest_q <= "0100100110";
            WHEN "100011" => table_l11_uid499_vecTranslateTest_q <= "0100100110";
            WHEN "100100" => table_l11_uid499_vecTranslateTest_q <= "0100101111";
            WHEN "100101" => table_l11_uid499_vecTranslateTest_q <= "0100101111";
            WHEN "100110" => table_l11_uid499_vecTranslateTest_q <= "0100110000";
            WHEN "100111" => table_l11_uid499_vecTranslateTest_q <= "0100110000";
            WHEN "101000" => table_l11_uid499_vecTranslateTest_q <= "0101111010";
            WHEN "101001" => table_l11_uid499_vecTranslateTest_q <= "0101111010";
            WHEN "101010" => table_l11_uid499_vecTranslateTest_q <= "0101111011";
            WHEN "101011" => table_l11_uid499_vecTranslateTest_q <= "0101111011";
            WHEN "101100" => table_l11_uid499_vecTranslateTest_q <= "0110000100";
            WHEN "101101" => table_l11_uid499_vecTranslateTest_q <= "0110000100";
            WHEN "101110" => table_l11_uid499_vecTranslateTest_q <= "0110000110";
            WHEN "101111" => table_l11_uid499_vecTranslateTest_q <= "0110000110";
            WHEN "110000" => table_l11_uid499_vecTranslateTest_q <= "1111001111";
            WHEN "110001" => table_l11_uid499_vecTranslateTest_q <= "1111001111";
            WHEN "110010" => table_l11_uid499_vecTranslateTest_q <= "1111010000";
            WHEN "110011" => table_l11_uid499_vecTranslateTest_q <= "1111010000";
            WHEN "110100" => table_l11_uid499_vecTranslateTest_q <= "1111011010";
            WHEN "110101" => table_l11_uid499_vecTranslateTest_q <= "1111011010";
            WHEN "110110" => table_l11_uid499_vecTranslateTest_q <= "1111011011";
            WHEN "110111" => table_l11_uid499_vecTranslateTest_q <= "1111011011";
            WHEN "111000" => table_l11_uid499_vecTranslateTest_q <= "0000100100";
            WHEN "111001" => table_l11_uid499_vecTranslateTest_q <= "0000100100";
            WHEN "111010" => table_l11_uid499_vecTranslateTest_q <= "0000100110";
            WHEN "111011" => table_l11_uid499_vecTranslateTest_q <= "0000100110";
            WHEN "111100" => table_l11_uid499_vecTranslateTest_q <= "0000101111";
            WHEN "111101" => table_l11_uid499_vecTranslateTest_q <= "0000101111";
            WHEN "111110" => table_l11_uid499_vecTranslateTest_q <= "0000110000";
            WHEN "111111" => table_l11_uid499_vecTranslateTest_q <= "0000110000";
            WHEN OTHERS => -- unreachable
                           table_l11_uid499_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- os_uid502_vecTranslateTest(BITJOIN,501)@6
    os_uid502_vecTranslateTest_q <= table_l11_uid501_vecTranslateTest_q & table_l11_uid500_vecTranslateTest_q & table_l11_uid499_vecTranslateTest_q;

    -- table_l5_uid495_vecTranslateTest(LOOKUP,494)@6
    table_l5_uid495_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_b)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_b) IS
            WHEN "000000" => table_l5_uid495_vecTranslateTest_q <= "011";
            WHEN "000001" => table_l5_uid495_vecTranslateTest_q <= "011";
            WHEN "000010" => table_l5_uid495_vecTranslateTest_q <= "011";
            WHEN "000011" => table_l5_uid495_vecTranslateTest_q <= "011";
            WHEN "000100" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "000101" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "000110" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "000111" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "001000" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "001001" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "001010" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "001011" => table_l5_uid495_vecTranslateTest_q <= "010";
            WHEN "001100" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "001101" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "001110" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "001111" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "010000" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "010001" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "010010" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "010011" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "010100" => table_l5_uid495_vecTranslateTest_q <= "001";
            WHEN "010101" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "010110" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "010111" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "011000" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "011001" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "011010" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "011011" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "011100" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "011101" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "011110" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "011111" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "100000" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "100001" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "100010" => table_l5_uid495_vecTranslateTest_q <= "000";
            WHEN "100011" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "100100" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "100101" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "100110" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "100111" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "101000" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "101001" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "101010" => table_l5_uid495_vecTranslateTest_q <= "111";
            WHEN "101011" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "101100" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "101101" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "101110" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "101111" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "110000" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "110001" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "110010" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "110011" => table_l5_uid495_vecTranslateTest_q <= "110";
            WHEN "110100" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "110101" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "110110" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "110111" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "111000" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "111001" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "111010" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "111011" => table_l5_uid495_vecTranslateTest_q <= "101";
            WHEN "111100" => table_l5_uid495_vecTranslateTest_q <= "100";
            WHEN "111101" => table_l5_uid495_vecTranslateTest_q <= "100";
            WHEN "111110" => table_l5_uid495_vecTranslateTest_q <= "100";
            WHEN "111111" => table_l5_uid495_vecTranslateTest_q <= "100";
            WHEN OTHERS => -- unreachable
                           table_l5_uid495_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l5_uid494_vecTranslateTest(LOOKUP,493)@6
    table_l5_uid494_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_b)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_b) IS
            WHEN "000000" => table_l5_uid494_vecTranslateTest_q <= "0110110010";
            WHEN "000001" => table_l5_uid494_vecTranslateTest_q <= "0100110010";
            WHEN "000010" => table_l5_uid494_vecTranslateTest_q <= "0010110010";
            WHEN "000011" => table_l5_uid494_vecTranslateTest_q <= "0000110010";
            WHEN "000100" => table_l5_uid494_vecTranslateTest_q <= "1110110100";
            WHEN "000101" => table_l5_uid494_vecTranslateTest_q <= "1100110100";
            WHEN "000110" => table_l5_uid494_vecTranslateTest_q <= "1010110101";
            WHEN "000111" => table_l5_uid494_vecTranslateTest_q <= "1000110101";
            WHEN "001000" => table_l5_uid494_vecTranslateTest_q <= "0111000110";
            WHEN "001001" => table_l5_uid494_vecTranslateTest_q <= "0101000110";
            WHEN "001010" => table_l5_uid494_vecTranslateTest_q <= "0011000111";
            WHEN "001011" => table_l5_uid494_vecTranslateTest_q <= "0001000111";
            WHEN "001100" => table_l5_uid494_vecTranslateTest_q <= "1111001001";
            WHEN "001101" => table_l5_uid494_vecTranslateTest_q <= "1101001001";
            WHEN "001110" => table_l5_uid494_vecTranslateTest_q <= "1011001001";
            WHEN "001111" => table_l5_uid494_vecTranslateTest_q <= "1001001001";
            WHEN "010000" => table_l5_uid494_vecTranslateTest_q <= "1001000111";
            WHEN "010001" => table_l5_uid494_vecTranslateTest_q <= "0111000111";
            WHEN "010010" => table_l5_uid494_vecTranslateTest_q <= "0101000111";
            WHEN "010011" => table_l5_uid494_vecTranslateTest_q <= "0011000111";
            WHEN "010100" => table_l5_uid494_vecTranslateTest_q <= "0001001001";
            WHEN "010101" => table_l5_uid494_vecTranslateTest_q <= "1111001001";
            WHEN "010110" => table_l5_uid494_vecTranslateTest_q <= "1101001010";
            WHEN "010111" => table_l5_uid494_vecTranslateTest_q <= "1011001010";
            WHEN "011000" => table_l5_uid494_vecTranslateTest_q <= "1001011011";
            WHEN "011001" => table_l5_uid494_vecTranslateTest_q <= "0111011011";
            WHEN "011010" => table_l5_uid494_vecTranslateTest_q <= "0101011100";
            WHEN "011011" => table_l5_uid494_vecTranslateTest_q <= "0011011100";
            WHEN "011100" => table_l5_uid494_vecTranslateTest_q <= "0001011110";
            WHEN "011101" => table_l5_uid494_vecTranslateTest_q <= "1111011110";
            WHEN "011110" => table_l5_uid494_vecTranslateTest_q <= "1101011110";
            WHEN "011111" => table_l5_uid494_vecTranslateTest_q <= "1011011110";
            WHEN "100000" => table_l5_uid494_vecTranslateTest_q <= "0100100001";
            WHEN "100001" => table_l5_uid494_vecTranslateTest_q <= "0010100001";
            WHEN "100010" => table_l5_uid494_vecTranslateTest_q <= "0000100001";
            WHEN "100011" => table_l5_uid494_vecTranslateTest_q <= "1110100001";
            WHEN "100100" => table_l5_uid494_vecTranslateTest_q <= "1100100011";
            WHEN "100101" => table_l5_uid494_vecTranslateTest_q <= "1010100011";
            WHEN "100110" => table_l5_uid494_vecTranslateTest_q <= "1000100100";
            WHEN "100111" => table_l5_uid494_vecTranslateTest_q <= "0110100100";
            WHEN "101000" => table_l5_uid494_vecTranslateTest_q <= "0100110101";
            WHEN "101001" => table_l5_uid494_vecTranslateTest_q <= "0010110101";
            WHEN "101010" => table_l5_uid494_vecTranslateTest_q <= "0000110110";
            WHEN "101011" => table_l5_uid494_vecTranslateTest_q <= "1110110110";
            WHEN "101100" => table_l5_uid494_vecTranslateTest_q <= "1100111000";
            WHEN "101101" => table_l5_uid494_vecTranslateTest_q <= "1010111000";
            WHEN "101110" => table_l5_uid494_vecTranslateTest_q <= "1000111000";
            WHEN "101111" => table_l5_uid494_vecTranslateTest_q <= "0110111000";
            WHEN "110000" => table_l5_uid494_vecTranslateTest_q <= "0110110110";
            WHEN "110001" => table_l5_uid494_vecTranslateTest_q <= "0100110110";
            WHEN "110010" => table_l5_uid494_vecTranslateTest_q <= "0010110110";
            WHEN "110011" => table_l5_uid494_vecTranslateTest_q <= "0000110110";
            WHEN "110100" => table_l5_uid494_vecTranslateTest_q <= "1110111000";
            WHEN "110101" => table_l5_uid494_vecTranslateTest_q <= "1100111000";
            WHEN "110110" => table_l5_uid494_vecTranslateTest_q <= "1010111001";
            WHEN "110111" => table_l5_uid494_vecTranslateTest_q <= "1000111001";
            WHEN "111000" => table_l5_uid494_vecTranslateTest_q <= "0111001010";
            WHEN "111001" => table_l5_uid494_vecTranslateTest_q <= "0101001010";
            WHEN "111010" => table_l5_uid494_vecTranslateTest_q <= "0011001011";
            WHEN "111011" => table_l5_uid494_vecTranslateTest_q <= "0001001011";
            WHEN "111100" => table_l5_uid494_vecTranslateTest_q <= "1111001101";
            WHEN "111101" => table_l5_uid494_vecTranslateTest_q <= "1101001101";
            WHEN "111110" => table_l5_uid494_vecTranslateTest_q <= "1011001101";
            WHEN "111111" => table_l5_uid494_vecTranslateTest_q <= "1001001101";
            WHEN OTHERS => -- unreachable
                           table_l5_uid494_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l5_uid493_vecTranslateTest(LOOKUP,492)@6
    table_l5_uid493_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_b)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_b) IS
            WHEN "000000" => table_l5_uid493_vecTranslateTest_q <= "0100000100";
            WHEN "000001" => table_l5_uid493_vecTranslateTest_q <= "0100101110";
            WHEN "000010" => table_l5_uid493_vecTranslateTest_q <= "1001011000";
            WHEN "000011" => table_l5_uid493_vecTranslateTest_q <= "1010000011";
            WHEN "000100" => table_l5_uid493_vecTranslateTest_q <= "1110010101";
            WHEN "000101" => table_l5_uid493_vecTranslateTest_q <= "1111000000";
            WHEN "000110" => table_l5_uid493_vecTranslateTest_q <= "0011101010";
            WHEN "000111" => table_l5_uid493_vecTranslateTest_q <= "0100010100";
            WHEN "001000" => table_l5_uid493_vecTranslateTest_q <= "1101001001";
            WHEN "001001" => table_l5_uid493_vecTranslateTest_q <= "1101110011";
            WHEN "001010" => table_l5_uid493_vecTranslateTest_q <= "0010011101";
            WHEN "001011" => table_l5_uid493_vecTranslateTest_q <= "0011001000";
            WHEN "001100" => table_l5_uid493_vecTranslateTest_q <= "0111011010";
            WHEN "001101" => table_l5_uid493_vecTranslateTest_q <= "1000000101";
            WHEN "001110" => table_l5_uid493_vecTranslateTest_q <= "1100101111";
            WHEN "001111" => table_l5_uid493_vecTranslateTest_q <= "1101011001";
            WHEN "010000" => table_l5_uid493_vecTranslateTest_q <= "0010011101";
            WHEN "010001" => table_l5_uid493_vecTranslateTest_q <= "0011000111";
            WHEN "010010" => table_l5_uid493_vecTranslateTest_q <= "0111110001";
            WHEN "010011" => table_l5_uid493_vecTranslateTest_q <= "1000011100";
            WHEN "010100" => table_l5_uid493_vecTranslateTest_q <= "1100101110";
            WHEN "010101" => table_l5_uid493_vecTranslateTest_q <= "1101011001";
            WHEN "010110" => table_l5_uid493_vecTranslateTest_q <= "0010000010";
            WHEN "010111" => table_l5_uid493_vecTranslateTest_q <= "0010101101";
            WHEN "011000" => table_l5_uid493_vecTranslateTest_q <= "1011100010";
            WHEN "011001" => table_l5_uid493_vecTranslateTest_q <= "1100001100";
            WHEN "011010" => table_l5_uid493_vecTranslateTest_q <= "0000110110";
            WHEN "011011" => table_l5_uid493_vecTranslateTest_q <= "0001100001";
            WHEN "011100" => table_l5_uid493_vecTranslateTest_q <= "0101110011";
            WHEN "011101" => table_l5_uid493_vecTranslateTest_q <= "0110011110";
            WHEN "011110" => table_l5_uid493_vecTranslateTest_q <= "1011001000";
            WHEN "011111" => table_l5_uid493_vecTranslateTest_q <= "1011110010";
            WHEN "100000" => table_l5_uid493_vecTranslateTest_q <= "0100001101";
            WHEN "100001" => table_l5_uid493_vecTranslateTest_q <= "0100111000";
            WHEN "100010" => table_l5_uid493_vecTranslateTest_q <= "1001100010";
            WHEN "100011" => table_l5_uid493_vecTranslateTest_q <= "1010001100";
            WHEN "100100" => table_l5_uid493_vecTranslateTest_q <= "1110011110";
            WHEN "100101" => table_l5_uid493_vecTranslateTest_q <= "1111001001";
            WHEN "100110" => table_l5_uid493_vecTranslateTest_q <= "0011110011";
            WHEN "100111" => table_l5_uid493_vecTranslateTest_q <= "0100011110";
            WHEN "101000" => table_l5_uid493_vecTranslateTest_q <= "1101010010";
            WHEN "101001" => table_l5_uid493_vecTranslateTest_q <= "1101111101";
            WHEN "101010" => table_l5_uid493_vecTranslateTest_q <= "0010100111";
            WHEN "101011" => table_l5_uid493_vecTranslateTest_q <= "0011010001";
            WHEN "101100" => table_l5_uid493_vecTranslateTest_q <= "0111100011";
            WHEN "101101" => table_l5_uid493_vecTranslateTest_q <= "1000001110";
            WHEN "101110" => table_l5_uid493_vecTranslateTest_q <= "1100111000";
            WHEN "101111" => table_l5_uid493_vecTranslateTest_q <= "1101100011";
            WHEN "110000" => table_l5_uid493_vecTranslateTest_q <= "0010100110";
            WHEN "110001" => table_l5_uid493_vecTranslateTest_q <= "0011010001";
            WHEN "110010" => table_l5_uid493_vecTranslateTest_q <= "0111111010";
            WHEN "110011" => table_l5_uid493_vecTranslateTest_q <= "1000100101";
            WHEN "110100" => table_l5_uid493_vecTranslateTest_q <= "1100110111";
            WHEN "110101" => table_l5_uid493_vecTranslateTest_q <= "1101100010";
            WHEN "110110" => table_l5_uid493_vecTranslateTest_q <= "0010001100";
            WHEN "110111" => table_l5_uid493_vecTranslateTest_q <= "0010110110";
            WHEN "111000" => table_l5_uid493_vecTranslateTest_q <= "1011101011";
            WHEN "111001" => table_l5_uid493_vecTranslateTest_q <= "1100010110";
            WHEN "111010" => table_l5_uid493_vecTranslateTest_q <= "0001000000";
            WHEN "111011" => table_l5_uid493_vecTranslateTest_q <= "0001101010";
            WHEN "111100" => table_l5_uid493_vecTranslateTest_q <= "0101111100";
            WHEN "111101" => table_l5_uid493_vecTranslateTest_q <= "0110100111";
            WHEN "111110" => table_l5_uid493_vecTranslateTest_q <= "1011010001";
            WHEN "111111" => table_l5_uid493_vecTranslateTest_q <= "1011111011";
            WHEN OTHERS => -- unreachable
                           table_l5_uid493_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- table_l5_uid492_vecTranslateTest(LOOKUP,491)@6
    table_l5_uid492_vecTranslateTest_combproc: PROCESS (is0_uid491_vecTranslateTest_merged_bit_select_b)
    BEGIN
        -- Begin reserved scope level
        CASE (is0_uid491_vecTranslateTest_merged_bit_select_b) IS
            WHEN "000000" => table_l5_uid492_vecTranslateTest_q <= "0010001000";
            WHEN "000001" => table_l5_uid492_vecTranslateTest_q <= "1100011001";
            WHEN "000010" => table_l5_uid492_vecTranslateTest_q <= "1010101100";
            WHEN "000011" => table_l5_uid492_vecTranslateTest_q <= "0100111101";
            WHEN "000100" => table_l5_uid492_vecTranslateTest_q <= "0111101101";
            WHEN "000101" => table_l5_uid492_vecTranslateTest_q <= "0001111110";
            WHEN "000110" => table_l5_uid492_vecTranslateTest_q <= "0000010001";
            WHEN "000111" => table_l5_uid492_vecTranslateTest_q <= "1010100010";
            WHEN "001000" => table_l5_uid492_vecTranslateTest_q <= "0010010101";
            WHEN "001001" => table_l5_uid492_vecTranslateTest_q <= "1100100110";
            WHEN "001010" => table_l5_uid492_vecTranslateTest_q <= "1010111010";
            WHEN "001011" => table_l5_uid492_vecTranslateTest_q <= "0101001011";
            WHEN "001100" => table_l5_uid492_vecTranslateTest_q <= "0111111011";
            WHEN "001101" => table_l5_uid492_vecTranslateTest_q <= "0010001100";
            WHEN "001110" => table_l5_uid492_vecTranslateTest_q <= "0000011111";
            WHEN "001111" => table_l5_uid492_vecTranslateTest_q <= "1010110000";
            WHEN "010000" => table_l5_uid492_vecTranslateTest_q <= "0001110010";
            WHEN "010001" => table_l5_uid492_vecTranslateTest_q <= "1100000011";
            WHEN "010010" => table_l5_uid492_vecTranslateTest_q <= "1010010110";
            WHEN "010011" => table_l5_uid492_vecTranslateTest_q <= "0100101000";
            WHEN "010100" => table_l5_uid492_vecTranslateTest_q <= "0111010111";
            WHEN "010101" => table_l5_uid492_vecTranslateTest_q <= "0001101000";
            WHEN "010110" => table_l5_uid492_vecTranslateTest_q <= "1111111100";
            WHEN "010111" => table_l5_uid492_vecTranslateTest_q <= "1010001101";
            WHEN "011000" => table_l5_uid492_vecTranslateTest_q <= "0010000000";
            WHEN "011001" => table_l5_uid492_vecTranslateTest_q <= "1100010001";
            WHEN "011010" => table_l5_uid492_vecTranslateTest_q <= "1010100100";
            WHEN "011011" => table_l5_uid492_vecTranslateTest_q <= "0100110101";
            WHEN "011100" => table_l5_uid492_vecTranslateTest_q <= "0111100101";
            WHEN "011101" => table_l5_uid492_vecTranslateTest_q <= "0001110110";
            WHEN "011110" => table_l5_uid492_vecTranslateTest_q <= "0000001001";
            WHEN "011111" => table_l5_uid492_vecTranslateTest_q <= "1010011011";
            WHEN "100000" => table_l5_uid492_vecTranslateTest_q <= "0111100101";
            WHEN "100001" => table_l5_uid492_vecTranslateTest_q <= "0001110111";
            WHEN "100010" => table_l5_uid492_vecTranslateTest_q <= "0000001010";
            WHEN "100011" => table_l5_uid492_vecTranslateTest_q <= "1010011011";
            WHEN "100100" => table_l5_uid492_vecTranslateTest_q <= "1101001011";
            WHEN "100101" => table_l5_uid492_vecTranslateTest_q <= "0111011100";
            WHEN "100110" => table_l5_uid492_vecTranslateTest_q <= "0101101111";
            WHEN "100111" => table_l5_uid492_vecTranslateTest_q <= "0000000000";
            WHEN "101000" => table_l5_uid492_vecTranslateTest_q <= "0111110011";
            WHEN "101001" => table_l5_uid492_vecTranslateTest_q <= "0010000100";
            WHEN "101010" => table_l5_uid492_vecTranslateTest_q <= "0000011000";
            WHEN "101011" => table_l5_uid492_vecTranslateTest_q <= "1010101001";
            WHEN "101100" => table_l5_uid492_vecTranslateTest_q <= "1101011000";
            WHEN "101101" => table_l5_uid492_vecTranslateTest_q <= "0111101010";
            WHEN "101110" => table_l5_uid492_vecTranslateTest_q <= "0101111101";
            WHEN "101111" => table_l5_uid492_vecTranslateTest_q <= "0000001110";
            WHEN "110000" => table_l5_uid492_vecTranslateTest_q <= "0111010000";
            WHEN "110001" => table_l5_uid492_vecTranslateTest_q <= "0001100001";
            WHEN "110010" => table_l5_uid492_vecTranslateTest_q <= "1111110100";
            WHEN "110011" => table_l5_uid492_vecTranslateTest_q <= "1010000101";
            WHEN "110100" => table_l5_uid492_vecTranslateTest_q <= "1100110101";
            WHEN "110101" => table_l5_uid492_vecTranslateTest_q <= "0111000110";
            WHEN "110110" => table_l5_uid492_vecTranslateTest_q <= "0101011010";
            WHEN "110111" => table_l5_uid492_vecTranslateTest_q <= "1111101011";
            WHEN "111000" => table_l5_uid492_vecTranslateTest_q <= "0111011110";
            WHEN "111001" => table_l5_uid492_vecTranslateTest_q <= "0001101111";
            WHEN "111010" => table_l5_uid492_vecTranslateTest_q <= "0000000010";
            WHEN "111011" => table_l5_uid492_vecTranslateTest_q <= "1010010011";
            WHEN "111100" => table_l5_uid492_vecTranslateTest_q <= "1101000011";
            WHEN "111101" => table_l5_uid492_vecTranslateTest_q <= "0111010100";
            WHEN "111110" => table_l5_uid492_vecTranslateTest_q <= "0101100111";
            WHEN "111111" => table_l5_uid492_vecTranslateTest_q <= "1111111000";
            WHEN OTHERS => -- unreachable
                           table_l5_uid492_vecTranslateTest_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- os_uid496_vecTranslateTest(BITJOIN,495)@6
    os_uid496_vecTranslateTest_q <= table_l5_uid495_vecTranslateTest_q & table_l5_uid494_vecTranslateTest_q & table_l5_uid493_vecTranslateTest_q & table_l5_uid492_vecTranslateTest_q;

    -- lev1_a0_uid519_vecTranslateTest(ADD,518)@6 + 1
    lev1_a0_uid519_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((33 downto 33 => os_uid496_vecTranslateTest_q(32)) & os_uid496_vecTranslateTest_q));
    lev1_a0_uid519_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((33 downto 27 => os_uid502_vecTranslateTest_q(26)) & os_uid502_vecTranslateTest_q));
    lev1_a0_uid519_vecTranslateTest_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            lev1_a0_uid519_vecTranslateTest_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (en = "1") THEN
                lev1_a0_uid519_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(lev1_a0_uid519_vecTranslateTest_a) + SIGNED(lev1_a0_uid519_vecTranslateTest_b));
            END IF;
        END IF;
    END PROCESS;
    lev1_a0_uid519_vecTranslateTest_q <= lev1_a0_uid519_vecTranslateTest_o(33 downto 0);

    -- lev2_a0_uid521_vecTranslateTest(ADD,520)@7
    lev2_a0_uid521_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((34 downto 34 => lev1_a0_uid519_vecTranslateTest_q(33)) & lev1_a0_uid519_vecTranslateTest_q));
    lev2_a0_uid521_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((34 downto 22 => lev1_a1_uid520_vecTranslateTest_q(21)) & lev1_a1_uid520_vecTranslateTest_q));
    lev2_a0_uid521_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(lev2_a0_uid521_vecTranslateTest_a) + SIGNED(lev2_a0_uid521_vecTranslateTest_b));
    lev2_a0_uid521_vecTranslateTest_q <= lev2_a0_uid521_vecTranslateTest_o(34 downto 0);

    -- lev3_a0_uid522_vecTranslateTest(ADD,521)@7
    lev3_a0_uid522_vecTranslateTest_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((35 downto 35 => lev2_a0_uid521_vecTranslateTest_q(34)) & lev2_a0_uid521_vecTranslateTest_q));
    lev3_a0_uid522_vecTranslateTest_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((35 downto 9 => table_l26_uid516_vecTranslateTest_q(8)) & table_l26_uid516_vecTranslateTest_q));
    lev3_a0_uid522_vecTranslateTest_o <= STD_LOGIC_VECTOR(SIGNED(lev3_a0_uid522_vecTranslateTest_a) + SIGNED(lev3_a0_uid522_vecTranslateTest_b));
    lev3_a0_uid522_vecTranslateTest_q <= lev3_a0_uid522_vecTranslateTest_o(35 downto 0);

    -- atanRes_uid523_vecTranslateTest(BITSELECT,522)@7
    atanRes_uid523_vecTranslateTest_in <= lev3_a0_uid522_vecTranslateTest_q(32 downto 0);
    atanRes_uid523_vecTranslateTest_b <= atanRes_uid523_vecTranslateTest_in(32 downto 5);

    -- xNotZero_uid17_vecTranslateTest(LOGICAL,16)@0 + 1
    xNotZero_uid17_vecTranslateTest_qi <= "1" WHEN x /= "00000000000000000000000000000000" ELSE "0";
    xNotZero_uid17_vecTranslateTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => xNotZero_uid17_vecTranslateTest_qi, xout => xNotZero_uid17_vecTranslateTest_q, ena => en(0), clk => clk, aclr => areset );

    -- redist36_xNotZero_uid17_vecTranslateTest_q_7(DELAY,586)
    redist36_xNotZero_uid17_vecTranslateTest_q_7 : dspba_delay
    GENERIC MAP ( width => 1, depth => 6, reset_kind => "ASYNC" )
    PORT MAP ( xin => xNotZero_uid17_vecTranslateTest_q, xout => redist36_xNotZero_uid17_vecTranslateTest_q_7_q, ena => en(0), clk => clk, aclr => areset );

    -- xZero_uid18_vecTranslateTest(LOGICAL,17)@7
    xZero_uid18_vecTranslateTest_q <= not (redist36_xNotZero_uid17_vecTranslateTest_q_7_q);

    -- yNotZero_uid15_vecTranslateTest(LOGICAL,14)@0 + 1
    yNotZero_uid15_vecTranslateTest_qi <= "1" WHEN y /= "00000000000000000000000000000000" ELSE "0";
    yNotZero_uid15_vecTranslateTest_delay : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => yNotZero_uid15_vecTranslateTest_qi, xout => yNotZero_uid15_vecTranslateTest_q, ena => en(0), clk => clk, aclr => areset );

    -- redist37_yNotZero_uid15_vecTranslateTest_q_7(DELAY,587)
    redist37_yNotZero_uid15_vecTranslateTest_q_7 : dspba_delay
    GENERIC MAP ( width => 1, depth => 6, reset_kind => "ASYNC" )
    PORT MAP ( xin => yNotZero_uid15_vecTranslateTest_q, xout => redist37_yNotZero_uid15_vecTranslateTest_q_7_q, ena => en(0), clk => clk, aclr => areset );

    -- yZero_uid16_vecTranslateTest(LOGICAL,15)@7
    yZero_uid16_vecTranslateTest_q <= not (redist37_yNotZero_uid15_vecTranslateTest_q_7_q);

    -- concXZeroYZero_uid530_vecTranslateTest(BITJOIN,529)@7
    concXZeroYZero_uid530_vecTranslateTest_q <= xZero_uid18_vecTranslateTest_q & yZero_uid16_vecTranslateTest_q;

    -- atanResPostExc_uid531_vecTranslateTest(MUX,530)@7
    atanResPostExc_uid531_vecTranslateTest_s <= concXZeroYZero_uid530_vecTranslateTest_q;
    atanResPostExc_uid531_vecTranslateTest_combproc: PROCESS (atanResPostExc_uid531_vecTranslateTest_s, en, atanRes_uid523_vecTranslateTest_b, cstZeroOutFormat_uid524_vecTranslateTest_q, constPio2P2u_mergedSignalTM_uid528_vecTranslateTest_q)
    BEGIN
        CASE (atanResPostExc_uid531_vecTranslateTest_s) IS
            WHEN "00" => atanResPostExc_uid531_vecTranslateTest_q <= atanRes_uid523_vecTranslateTest_b;
            WHEN "01" => atanResPostExc_uid531_vecTranslateTest_q <= cstZeroOutFormat_uid524_vecTranslateTest_q;
            WHEN "10" => atanResPostExc_uid531_vecTranslateTest_q <= constPio2P2u_mergedSignalTM_uid528_vecTranslateTest_q;
            WHEN "11" => atanResPostExc_uid531_vecTranslateTest_q <= cstZeroOutFormat_uid524_vecTranslateTest_q;
            WHEN OTHERS => atanResPostExc_uid531_vecTranslateTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- constantZeroOutFormat_uid535_vecTranslateTest(CONSTANT,534)
    constantZeroOutFormat_uid535_vecTranslateTest_q <= "0000000000000000000000000000";

    -- redist39_signX_uid7_vecTranslateTest_b_7(DELAY,589)
    redist39_signX_uid7_vecTranslateTest_b_7 : dspba_delay
    GENERIC MAP ( width => 1, depth => 7, reset_kind => "ASYNC" )
    PORT MAP ( xin => signX_uid7_vecTranslateTest_b, xout => redist39_signX_uid7_vecTranslateTest_b_7_q, ena => en(0), clk => clk, aclr => areset );

    -- redist38_signY_uid8_vecTranslateTest_b_7(DELAY,588)
    redist38_signY_uid8_vecTranslateTest_b_7 : dspba_delay
    GENERIC MAP ( width => 1, depth => 7, reset_kind => "ASYNC" )
    PORT MAP ( xin => signY_uid8_vecTranslateTest_b, xout => redist38_signY_uid8_vecTranslateTest_b_7_q, ena => en(0), clk => clk, aclr => areset );

    -- concSigns_uid532_vecTranslateTest(BITJOIN,531)@7
    concSigns_uid532_vecTranslateTest_q <= redist39_signX_uid7_vecTranslateTest_b_7_q & redist38_signY_uid8_vecTranslateTest_b_7_q;

    -- secondOperand_uid539_vecTranslateTest(MUX,538)@7
    secondOperand_uid539_vecTranslateTest_s <= concSigns_uid532_vecTranslateTest_q;
    secondOperand_uid539_vecTranslateTest_combproc: PROCESS (secondOperand_uid539_vecTranslateTest_s, en, constantZeroOutFormat_uid535_vecTranslateTest_q, atanResPostExc_uid531_vecTranslateTest_q, constPi_uid534_vecTranslateTest_q)
    BEGIN
        CASE (secondOperand_uid539_vecTranslateTest_s) IS
            WHEN "00" => secondOperand_uid539_vecTranslateTest_q <= constantZeroOutFormat_uid535_vecTranslateTest_q;
            WHEN "01" => secondOperand_uid539_vecTranslateTest_q <= atanResPostExc_uid531_vecTranslateTest_q;
            WHEN "10" => secondOperand_uid539_vecTranslateTest_q <= atanResPostExc_uid531_vecTranslateTest_q;
            WHEN "11" => secondOperand_uid539_vecTranslateTest_q <= constPi_uid534_vecTranslateTest_q;
            WHEN OTHERS => secondOperand_uid539_vecTranslateTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- constPiP2u_uid533_vecTranslateTest(CONSTANT,532)
    constPiP2u_uid533_vecTranslateTest_q <= "1100100100001111110110101110";

    -- constantZeroOutFormatP2u_uid536_vecTranslateTest(CONSTANT,535)
    constantZeroOutFormatP2u_uid536_vecTranslateTest_q <= "0000000000000000000000000100";

    -- firstOperand_uid538_vecTranslateTest(MUX,537)@7
    firstOperand_uid538_vecTranslateTest_s <= concSigns_uid532_vecTranslateTest_q;
    firstOperand_uid538_vecTranslateTest_combproc: PROCESS (firstOperand_uid538_vecTranslateTest_s, en, atanResPostExc_uid531_vecTranslateTest_q, constantZeroOutFormatP2u_uid536_vecTranslateTest_q, constPiP2u_uid533_vecTranslateTest_q)
    BEGIN
        CASE (firstOperand_uid538_vecTranslateTest_s) IS
            WHEN "00" => firstOperand_uid538_vecTranslateTest_q <= atanResPostExc_uid531_vecTranslateTest_q;
            WHEN "01" => firstOperand_uid538_vecTranslateTest_q <= constantZeroOutFormatP2u_uid536_vecTranslateTest_q;
            WHEN "10" => firstOperand_uid538_vecTranslateTest_q <= constPiP2u_uid533_vecTranslateTest_q;
            WHEN "11" => firstOperand_uid538_vecTranslateTest_q <= atanResPostExc_uid531_vecTranslateTest_q;
            WHEN OTHERS => firstOperand_uid538_vecTranslateTest_q <= (others => '0');
        END CASE;
    END PROCESS;

    -- outResExtended_uid540_vecTranslateTest(SUB,539)@7
    outResExtended_uid540_vecTranslateTest_a <= STD_LOGIC_VECTOR("0" & firstOperand_uid538_vecTranslateTest_q);
    outResExtended_uid540_vecTranslateTest_b <= STD_LOGIC_VECTOR("0" & secondOperand_uid539_vecTranslateTest_q);
    outResExtended_uid540_vecTranslateTest_o <= STD_LOGIC_VECTOR(UNSIGNED(outResExtended_uid540_vecTranslateTest_a) - UNSIGNED(outResExtended_uid540_vecTranslateTest_b));
    outResExtended_uid540_vecTranslateTest_q <= outResExtended_uid540_vecTranslateTest_o(28 downto 0);

    -- atanResPostRR_uid541_vecTranslateTest(BITSELECT,540)@7
    atanResPostRR_uid541_vecTranslateTest_b <= STD_LOGIC_VECTOR(outResExtended_uid540_vecTranslateTest_q(28 downto 2));

    -- xOut(GPOUT,4)@7
    q <= atanResPostRR_uid541_vecTranslateTest_b;
    r <= outMag_uid547_vecTranslateTest_b;

END normal;
