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
    signal w_result  : std_logic_vector(7 downto 0) := (others => '0');
begin
    process(i_A, i_B, i_op)
    begin
        case i_op is
            when "000" => -- add
                w_add_sub <= unsigned('0' & i_A) + unsigned('0' & i_B);
            when "001" => -- subtract
                w_add_sub <= unsigned('0' & i_A) - unsigned('0' & i_B);
            when others =>
                w_add_sub <= (others => '0');
        end case;
    end process;

    process(i_A, i_B, i_op, w_add_sub)
    begin
        case i_op is
            when "000" | "001" => w_result <= std_logic_vector(w_add_sub(7 downto 0));
            when "010" =>         w_result <= i_A and i_B;
            when "011" =>         w_result <= i_A or i_B;
            when others =>        w_result <= (others => '0');
        end case;
    end process;

    o_result <= w_result;

    -- NZCV
    o_flags(3) <= w_result(7); -- negative
    o_flags(2) <= '1' when w_result = "00000000" else '0'; -- zero
    o_flags(1) <= w_add_sub(8); -- carry
    -- overflow
    o_flags(0) <= '1' when (i_op = "000" and (i_A(7) = i_B(7)) and (w_result(7) /= i_A(7))) or
                           (i_op = "001" and (i_A(7) /= i_B(7)) and (w_result(7) /= i_A(7)))
                  else '0';

end Behavioral;
