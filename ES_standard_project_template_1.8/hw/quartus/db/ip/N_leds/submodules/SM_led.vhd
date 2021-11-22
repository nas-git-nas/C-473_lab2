library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity WS2812Controller is

	port(
		clk 			: in std_logic;
		nReset 		: in std_logic;
		
		-- Internal interface (i.e. Avalon slave).
		address 		: in std_logic_vector(7 downto 0);
		write 		: in std_logic;
		writedata 	: in std_logic_vector(31 downto 0);
		
		-- External interface: connection to LEDs.
		RegOut 		: out std_logic
	);
end WS2812Controller;


Architecture Comp of WS2812Controller is
	-- CONSTANTS
	constant PERIOD : integer := 60;					-- Period to make 800 kHz
	constant HIGH_ONE : integer := 35; 				-- Period to have the value set to one to write a one (700ns with period of 20ns --> 35)
	constant HIGH_ZERO : integer := 18;				-- (350 ns period 20ns --> 18 (ish) cycles)
	constant LOW_ONE : integer := 30;				-- (600ns period 20ns --> 30 cycles)
	constant LOW_ZERO : integer := 40;				-- (800ns persion 20ns --> 40 cycles)
	constant BITS_PER_LED : integer := 24;
	
	-- State machine
	TYPE State IS (Refresh, DutyCycle, H1, H0, L1, L0, LedCheck);		-- All different states we can be in
	Signal SM: State;
	
	-- Keep track of where in update cycle we are
	signal led_counter		: integer range 0 to 127;		-- Keep track on which led we are programming right now
	signal led_bit				: integer range 0 to 24;		-- Which bit in the current led is being programmed
	
	TYPE leds_array IS ARRAY(127 downto 0) OF std_logic_vector(23 downto 0);		-- Vector type to hold all colours
	signal led_data 			: leds_array := (others => X"000000");							-- Initialize all array to zero
	
	-- Counter during update
	signal high_low_counter 	: integer range 0 to 40;
	signal refresh_counter 		: integer range 0 to 65535;
	
	-- To be set by c-program
	signal num_of_leds 		: integer range 0 to 127 	:= 1;
	signal refresh_time		: integer range 0 to 65535	:= 10000;	-- Refresh time between each update cycle (10000steps at 50MHz = 200us)
																						-- max. refresh time = 65535steps at 50MHz = 1.31ms
Begin

	process(clk, nReset)
	Begin
	if nReset = '0' then
		-- Set all to zero/default
		refresh_counter <= 0;
		SM <= LedCheck;
		led_counter <= 0;
		led_bit <= BITS_PER_LED-1;
		high_low_counter <= 0;
		refresh_counter <= 0;
		RegOut <= '0';
		
	elsif rising_edge(clk) then
		
		-- Go through which state we are in 
		case SM is
		when Refresh =>
			if refresh_counter >= refresh_time then
				refresh_counter <= 0;
				SM <= DutyCycle;
			else
				refresh_counter <= refresh_counter + 1;
				RegOut <= '0';
			end if;
		when DutyCycle =>
			if led_data(led_counter)(led_bit) = '1' then
				SM <= H1;
			else
				SM <= H0;
			end if;
		when H1 => 
			high_low_counter <= high_low_counter + 1;
			RegOut <= '1';
			if high_low_counter >= HIGH_ONE then
				high_low_counter <= 0;
				SM <= L1;
			end if;
		when H0 =>
			high_low_counter <= high_low_counter + 1;
			RegOut <= '1';
			if high_low_counter >= HIGH_ZERO then
				high_low_counter <= 0;
				SM <= L0;
			end if;
		when L1 =>
			high_low_counter <= high_low_counter + 1;
			RegOut <= '0';
			if high_low_counter >= LOW_ONE then
				high_low_counter <= 0;
				SM <= LedCheck;
			end if;
		when L0 =>
			high_low_counter <= high_low_counter + 1;
			RegOut <= '0';
			if high_low_counter >= LOW_ZERO then
				high_low_counter <= 0;
				SM <= LedCheck;
			end if;
		when LedCheck => 
			if (led_counter = (num_of_leds - 1)) and (led_bit = 0) then -- index leds one lower than how many we have
				led_counter <= 0;		
				led_bit <= BITS_PER_LED - 1;
				SM <= Refresh;								-- Go to refresh cycle. Then restart update with the values now in led-coute
			elsif led_bit = 0 then		-- One light finished, start next one
				led_counter <= led_counter + 1;
				led_bit <= BITS_PER_LED - 1;
				SM <= DutyCycle;
			else
				led_bit <= led_bit - 1;
				SM <= DutyCycle;
			end if;
		end case;
		end if;	
	end process;

	process(clk, nReset)
		begin
			if nReset = '0' then
				led_data	<= (others => X"000000");
				num_of_leds <= 1;
			elsif rising_edge(clk) then
				if write = '1' then
					if to_integer(unsigned(address)) = 0 then -- Specify number of leds (max 127)
						num_of_leds <= to_integer(unsigned(writedata(6 downto 0)));
					elsif to_integer(unsigned(address)) = 1 then -- refresh time
						refresh_time <= to_integer(unsigned(writedata(15 downto 0)));
					elsif to_integer(unsigned(address)) <= 128 then		-- Register 2 to 128 correspoonding to each led register
						led_data(to_integer(unsigned(address)) - 2) <= writedata(23 downto 0);	-- Write to the appropriate led
					end if;
				end if;
			end if;	
	end process;
end Comp;			