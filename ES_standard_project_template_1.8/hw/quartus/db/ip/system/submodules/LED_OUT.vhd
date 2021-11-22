library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ParallelPort is

	port(
		clk 			: in std_logic;
		nReset 		: in std_logic;
		
		-- Internal interface (i.e. Avalon slave).
		address 		: in std_logic_vector(2 downto 0);
		write 		: in std_logic;
		writedata 	: in std_logic_vector(31 downto 0);
		
		-- External interface: connection to LEDs.
		RegOut 		: out std_logic
	);
end ParallelPort;

architecture comp of ParallelPort is
	--constant REFRESH_TIME : integer := 1000;
	signal refresh_time		: integer range 0 to 65535;		-- 16 bits
	signal iRegData 			: std_logic_vector(23 downto 0);
	signal clk_counter		: integer range 0 to 59;
	signal duty_cycle 		: integer range 0 to 59;
	signal led_counter		: integer range 0 to 24;
	signal refresh_counter	: integer range 0 to 65535;
	signal send_data			: integer range 0 to 1;
	signal start_refresh		: integer range 0 to 1;
	
begin

	-- LED: loops through all bits of iRegData and sets corresponding duty_cycle
	-- 	  every time the clk_counter is reset
	process(clk)
	begin
		if rising_edge(clk) then
			if nReset = '0' then		-- reset clk_counter
				led_counter <= 24;
			elsif send_data = 1 then 	-- send_data tells that were are in a refresh state
				if clk_counter = 0 then
					-- led_counter loops through all bits in iRegData: start with highest bit
					if led_counter = 0 then			-- We have written to all leds
						led_counter <= 24;
						start_refresh <= 1;		-- Disable data output until refresh timer enables again
					end if;
					led_counter <= led_counter - 1;
					-- set duty_cycle
					if iRegData(led_counter) = '0' then
						duty_cycle <= 18;							-- 33/59 corresponds to logical 1
					else
						duty_cycle <= 33;							-- 18/59 corresponds to logical 0
					end if;
				end if;
			else
				duty_cycle <= 0;
				start_refresh <= 0;
			end if;
		end if;
	end process;
	
	process(clk)
	begin 
		if rising_edge(clk) then
			if nReset = '0' then		-- reset clk_counter
				refresh_counter <= 0;
			else
				if refresh_counter >= refresh_time then
					refresh_counter <= 0;
					send_data <= 1;				-- Activate new refresh cycle
				else
					refresh_counter <= refresh_counter + 1;
				end if;
				if start_refresh = 1 then
					send_data <= 0;
				end if;
			end if;
		end if;
	end process;
	
	-- PWM: generates PWM output for the leds
	process(clk)
	begin
		if rising_edge(clk) then
			if nReset = '0' then		-- reset clk_counter
				RegOut <= '0';
			else
				if clk_counter < duty_cycle then
					RegOut <= '1';							-- set output for time up to duty_cycle
				else
					RegOut <= '0';							-- clear output for the rest of the periode
				end if;
			end if;
		end if;
	end process;

	-- Clock Counter: counts at default frequency (50MHz, 20ns)
	process(clk)
	begin
		if rising_edge(clk) then
			if nReset = '0' then		-- reset clk_counter
				clk_counter <= 0;
			else							-- count from 0 to 59 to generate PWM-periode of 1.2us				
				if clk_counter < 60 then
					clk_counter <= clk_counter + 1;
				else
					clk_counter <= 0;
				end if;
			end if;
		end if;
	end process;
	
		
	-- Avalon slave write to registers.
	process(clk, nReset)
	begin
		if nReset = '0' then
			iRegData 	<= (others => '0');
			refresh_time <= 0;
		elsif rising_edge(clk) then
			if write = '1' then
				case Address is
					when "001" => iRegData 	<= writedata(23 downto 0);
					when "010" => refresh_time <= to_integer(unsigned(writedata(15 downto 0)));
					when others => null;
				end case;
			end if;
		end if;
	end process;

end comp;