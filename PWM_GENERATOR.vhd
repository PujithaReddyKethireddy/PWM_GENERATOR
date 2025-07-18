library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        clk_100MHz : in std_logic;          -- from Basys 3
        rows       : in std_logic_vector(3 downto 0); -- Pmod JB pins 10 to 7
        cols       : out std_logic_vector(3 downto 0); -- Pmod JB pins 4 to 1
        an         : out std_logic_vector(3 downto 0); -- 7 segment anodes
        seg        : out std_logic_vector(6 downto 0); -- 7 segment cathodes
        pwm_out    : out std_logic                      -- PWM signal output
    );
end top;

architecture Behavioral of top is
    signal w_out : std_logic_vector(3 downto 0);  -- Decoded key value or duty cycle
begin
    -- Instantiate PWM generator
    u1: entity work.pwm_generator
        port map (
            clk_100MHz => clk_100MHz,
            row        => rows,
            col        => cols,
            pwm_out    => pwm_out,
            duty_cycle_out => w_out
        );

    -- Instantiate 7-segment control
    u2: entity work.seg7_control
        port map (
            dec => w_out,
            an  => an,
            seg => seg
        );
end Behavioral;
----------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_generator is
    Port (
        clk_100MHz : in std_logic;                     -- 100 MHz clock
        row        : in std_logic_vector(3 downto 0);  -- 4 rows from keypad
        col        : out std_logic_vector(3 downto 0); -- 4 columns to keypad
        pwm_out    : out std_logic;                    -- PWM signal output
        duty_cycle_out : out std_logic_vector(3 downto 0)  -- Duty cycle value for display
    );
end pwm_generator;

architecture Behavioral of pwm_generator is
    -- Parameters and signals
    constant CLK_FREQ   : integer := 100_000_000;      -- 100 MHz clock frequency
    constant PWM_PERIOD : integer := 1000;             -- 1ms period (1kHz PWM)
    signal duty_cycle   : integer range 0 to 100 := 10; -- Default 10% duty cycle
    signal pwm_counter  : integer range 0 to PWM_PERIOD - 1 := 0; -- PWM counter
    signal scan_timer   : integer range 0 to 99999 := 0;  -- Scan timer
    signal col_select   : std_logic_vector(1 downto 0) := "00";  -- Column selector
    signal key_value    : std_logic_vector(3 downto 0) := "0000"; -- Decoded value
    signal pwm_signal   : std_logic := '0';            -- Internal PWM signal
begin

    -- Scan timer and column selection
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if scan_timer = 99999 then
                scan_timer <= 0;
                col_select <= std_logic_vector(unsigned(col_select) + 1);
            else
                scan_timer <= scan_timer + 1;
            end if;
        end if;
    end process;

    -- Column scanning and row checking
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            case col_select is
                when "00" =>
                    col <= "0111";  -- Enable column 0
                    if scan_timer = 10 then
                        case row is
                            when "0111" => key_value <= "0001"; duty_cycle <= 10;  -- 10%
                            when "1011" => key_value <= "0100"; duty_cycle <= 40;  -- 40%
                            when "1101" => key_value <= "0111"; duty_cycle <= 70;  -- 70%
                            when "1110" => key_value <= "0000"; duty_cycle <= 0;   -- 0%
                            when others => null; -- No press
                        end case;
                    end if;

                when "01" =>
                    col <= "1011";  -- Enable column 1
                    if scan_timer = 10 then
                        case row is
                            when "0111" => key_value <= "0010"; duty_cycle <= 20;  -- 20%
                            when "1011" => key_value <= "0101"; duty_cycle <= 50;  -- 50%
                            when "1101" => key_value <= "1000"; duty_cycle <= 80;  -- 80%
                            when "1110" => key_value <= "1111"; duty_cycle <= 100; -- 100%
                            when others => null; -- No press
                        end case;
                    end if;

                when "10" =>
                    col <= "1101";  -- Enable column 2
                    if scan_timer = 10 then
                        case row is
                            when "0111" => key_value <= "0011"; duty_cycle <= 30;  -- 30%
                            when "1011" => key_value <= "0110"; duty_cycle <= 60;  -- 60%
                            when "1101" => key_value <= "1001"; duty_cycle <= 90;  -- 90%
                            when "1110" => key_value <= "1110"; duty_cycle <= 95; -- E (100%)
                            when others => null; -- No press
                        end case;
                    end if;
                when "11" =>
                    col <= "1110";  -- Enable column 3
                    if scan_timer = 10 then
                        case row is
                            when "0111" => key_value <= "1010"; duty_cycle <= 5;  -- 20%
                            when "1011" => key_value <= "1011"; duty_cycle <= 15;  -- 50%
                            when "1101" => key_value <= "1100"; duty_cycle <= 25;  -- 80%
                            when "1110" => key_value <= "1101"; duty_cycle <= 75; -- 100%
                            when others => null; -- No press
                        end case;
                    end if;

                when others =>
                    col <= "1110";  -- Enable column 3
            end case;
        end if;
    end process;

    -- PWM generation process
    process(clk_100MHz)
    begin
        if rising_edge(clk_100MHz) then
            if pwm_counter < PWM_PERIOD - 1 then
                pwm_counter <= pwm_counter + 1;
            else
                pwm_counter <= 0;
            end if;

            -- Compare counter to duty cycle percentage
            if pwm_counter < (PWM_PERIOD * duty_cycle / 100) then
                pwm_signal <= '1';  -- High for duty cycle period
            else
                pwm_signal <= '0';  -- Low for the rest of the period
            end if;
        end if;
    end process;

    pwm_out <= pwm_signal;                 -- Output PWM signal
    duty_cycle_out <= key_value;           -- Send duty cycle value to display
end Behavioral;
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seg7_control is
    Port (
        dec : in std_logic_vector(3 downto 0);   -- Input from decoder
        an  : out std_logic_vector(3 downto 0);  -- Anode control (active low)
        seg : out std_logic_vector(6 downto 0)   -- Cathode pattern for 7-segment
    );
end seg7_control;

architecture Behavioral of seg7_control is
begin
    -- Anode control: Only the far-right digit is enabled
    an <= "1110";  -- Active low (far right digit enabled)

    -- Segment control: Decodes to 7-segment pattern
    process(dec)
    begin
        case dec is
            when "0000" => seg <= "1000000"; -- 0
            when "0001" => seg <= "1111001"; -- 1
            when "0010" => seg <= "0100100"; -- 2
            when "0011" => seg <= "0110000"; -- 3
            when "0100" => seg <= "0011001"; -- 4
            when "0101" => seg <= "0010010"; -- 5
            when "0110" => seg <= "0000010"; -- 6
            when "0111" => seg <= "1111000"; -- 7
            when "1000" => seg <= "0000000"; -- 8
            when "1001" => seg <= "0010000"; -- 9
            when "1010" => seg <= "0001000"; -- A
            when "1011" => seg <= "0000011"; -- B
            when "1100" => seg <= "1000110"; -- C
            when "1101" => seg <= "0100001"; -- D
            when "1110" => seg <= "0000110"; -- E
            when "1111" => seg <= "0001110"; -- F
            when others => seg <= "1111111"; -- Default (all off)
        end case;
    end process;
end Behavioral;
