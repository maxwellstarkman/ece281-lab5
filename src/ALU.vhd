----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    signal w_add_sub : unsigned(8 downto 0) := (others => '0');
begin
    process(i_A, i_B, i_op)
        variable v_res : std_logic_vector(7 downto 0);
    begin
        case i_op is
            when "000" => -- Add
                w_add_sub <= unsigned('0' & i_A) + unsigned('0' & i_B);
            when "001" => -- Subtract
                w_add_sub <= unsigned('1' & i_A) - unsigned('0' & i_B);
            when "010" => -- And
                w_add_sub <= '0' & unsigned(i_A and i_B);
            when "011" => -- Or
                w_add_sub <= '0' & unsigned(i_A or i_B);
            when others =>
                w_add_sub <= (others => '0');
        end case;

        v_res := std_logic_vector(w_add_sub(7 downto 0));
        o_result <= v_res;
        
        -- NZCV Flags 
        o_flags(3) <= v_res(7); -- Negative
        if v_res = "00000000" then
            o_flags(2) <= '1';
        else
            o_flags(2) <= '0';
        end if;
        
        o_flags(1) <= w_add_sub(8); -- Carry
        
        -- overflow
        if (i_op = "000" and (i_A(7) = i_B(7)) and (v_res(7) /= i_A(7))) or
           (i_op = "001" and (i_A(7) /= i_B(7)) and (v_res(7) /= i_A(7))) then
            o_flags(0) <= '1';
        else
            o_flags(0) <= '0';
        end if;
    end process;
end Behavioral;