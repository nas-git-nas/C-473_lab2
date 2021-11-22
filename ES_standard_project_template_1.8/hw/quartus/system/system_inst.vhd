	component system is
		port (
			clk_clk                                : in  std_logic := 'X'; -- clk
			reset_reset_n                          : in  std_logic := 'X'; -- reset_n
			ws2812_controller_0_conduit_end_regout : out std_logic         -- regout
		);
	end component system;

	u0 : component system
		port map (
			clk_clk                                => CONNECTED_TO_clk_clk,                                --                             clk.clk
			reset_reset_n                          => CONNECTED_TO_reset_reset_n,                          --                           reset.reset_n
			ws2812_controller_0_conduit_end_regout => CONNECTED_TO_ws2812_controller_0_conduit_end_regout  -- ws2812_controller_0_conduit_end.regout
		);

