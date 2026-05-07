--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity top_basys3 is
    port(
        clk     : in std_logic;
        sw      : in std_logic_vector(7 downto 0);
        btnU    : in std_logic; -- master synchronous reset
        btnC    : in std_logic; -- fsm advance
        btnL    : in std_logic; -- clock divider asynchronous reset
        
        led     : out std_logic_vector(15 downto 0);
        seg     : out std_logic_vector(6 downto 0);
        an      : out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
    -- Components
    component controller_fsm is
        port ( i_reset : in std_logic;
               i_adv   : in std_logic;
               o_cycle : out std_logic_vector (3 downto 0));
    end component;

    component ALU is
        port ( i_A : in std_logic_vector (7 downto 0);
               i_B : in std_logic_vector (7 downto 0);
               i_op : in std_logic_vector (2 downto 0);
               o_result : out std_logic_vector (7 downto 0);
               o_flags : out std_logic_vector (3 downto 0));
    end component;

    component clock_divider is
        generic ( k_DIV : natural );
        port ( i_clk : in std_logic; i_reset : in std_logic; o_clk : out std_logic );
    end component;

    component twos_comp is
        port ( i_bin : in std_logic_vector(7 downto 0);
               o_sign : out std_logic;
               o_hund, o_tens, o_ones : out std_logic_vector(3 downto 0));
    end component;

    component TDM4 is
        generic ( k_WIDTH : natural );
        port ( i_clk, i_reset : in std_logic;
               i_D3, i_D2, i_D1, i_D0 : in std_logic_vector(k_WIDTH-1 downto 0);
               o_data : out std_logic_vector(k_WIDTH-1 downto 0);
               o_sel : out std_logic_vector(3 downto 0));
    end component;

    component sevenseg_decoder is
        Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
               o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component;

    -- Signals
    signal w_cycle : std_logic_vector(3 downto 0);
    signal w_regA, w_regB : std_logic_vector(7 downto 0) := (others => '0');
    signal w_alu_result : std_logic_vector(7 downto 0);
    signal w_mux_out : std_logic_vector(7 downto 0);
    signal w_alu_flags : std_logic_vector(3 downto 0);
    signal w_clk_slow : std_logic;
    
    signal w_sign : std_logic;
    signal w_hund, w_tens, w_ones : std_logic_vector(3 downto 0);
    signal w_tdm_data : std_logic_vector(3 downto 0);
    signal w_sel : std_logic_vector(3 downto 0);
    signal w_seg_n_decoder : std_logic_vector(6 downto 0);

begin

    -- Port Mapping
    clk_div_inst : clock_divider
        generic map ( k_DIV => 100000 )
        port map ( i_clk => clk, i_reset => btnL, o_clk => w_clk_slow );

    controller_inst : controller_fsm
        port map ( i_reset => btnU, i_adv => btnC, o_cycle => w_cycle );

    alu_inst : ALU
        port map ( i_A => w_regA, i_B => w_regB, i_op => sw(2 downto 0), 
                   o_result => w_alu_result, o_flags => w_alu_flags );

    twos_comp_inst : twos_comp
        port map ( i_bin => w_mux_out, o_sign => w_sign, 
                   o_hund => w_hund, o_tens => w_tens, o_ones => w_ones );

    tdm_inst : TDM4
        generic map ( k_WIDTH => 4 )
        port map ( i_clk => w_clk_slow, i_reset => btnU,
                   i_D3 => "1111",
                   i_D2 => w_hund, i_D1 => w_tens, i_D0 => w_ones,
                   o_data => w_tdm_data, o_sel => w_sel );

    decoder_inst : sevenseg_decoder
        port map ( i_Hex => w_tdm_data, o_seg_n => w_seg_n_decoder );

    process(clk)
    begin
        if rising_edge(clk) then
            if btnU = '1' then
                w_regA <= (others => '0');
                w_regB <= (others => '0');
            elsif w_cycle(0) = '1' then
                w_regA <= sw;
            elsif w_cycle(1) = '1' then
                w_regB <= sw;
            end if;
        end if;
    end process;

    with w_cycle select
        w_mux_out <= w_regA       when "0010", -- State 2
                     w_regB       when "0100", -- State 3
                     w_alu_result when "1000", -- State 4
                     "00000000"   when others; -- State 1 (Clear)

    an <= "1111" when w_cycle(0) = '1' else w_sel;
    
    process(w_seg_n_decoder, w_sign, w_sel)
    begin
        if w_sel = "0111" then
            if w_sign = '1' then
                seg <= "0111111";
            else
                seg <= "1111111";
            end if;
        else
            seg <= w_seg_n_decoder;
        end if;
    end process;

    led(3 downto 0)   <= w_cycle;     -- One-hot state
    led(15 downto 12) <= w_alu_flags; -- NZCV
    led(11 downto 4)  <= (others => '0');
    
end top_basys3_arch;