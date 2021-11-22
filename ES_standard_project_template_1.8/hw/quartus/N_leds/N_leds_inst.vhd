	component N_leds is
		port (
			clk_clk                                : in  std_logic := 'X'; -- clk
			reset_reset_n                          : in  std_logic := 'X'; -- reset_n
			n_leds_controller_0_conduit_end_regout : out std_logic         -- regout
		);
	end component N_leds;

	u0 : component N_leds
		port map (
			clk_clk                                => CONNECTED_TO_clk_clk,                                --                             clk.clk
			reset_reset_n                          => CONNECTED_TO_reset_reset_n,                          --                           reset.reset_n
			n_leds_controller_0_conduit_end_regout => CONNECTED_TO_n_leds_controller_0_conduit_end_regout  -- n_leds_controller_0_conduit_end.regout
		);

