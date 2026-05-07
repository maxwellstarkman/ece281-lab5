----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is
    type sm_state is (s_clear, s_load1, s_load2, s_result);
    signal s_state : sm_state := s_clear;
begin
    process(i_adv, i_reset)
    begin
        if i_reset = '1' then
            s_state <= s_clear;
        elsif rising_edge(i_adv) then
            case s_state is
                when s_clear  => s_state <= s_load1;
                when s_load1  => s_state <= s_load2;
                when s_load2  => s_state <= s_result;
                when s_result => s_state <= s_clear;
            end case;
        end if;
    end process;

    o_cycle <= "0001" when s_state = s_clear else
               "0010" when s_state = s_load1 else
               "0100" when s_state = s_load2 else
               "1000" when s_state = s_result else
               "0001";
end FSM;
