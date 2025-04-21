--         NAME: Ty Ahrens
--         DATE: 10/25/2023
--  DESCRIPTION: The purpose of this code is to demonstrate the use of the PCB board that was 
--               constructed by honors students at the Tennessee Tech University.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity board_function is 
    port (
        CLK         : IN std_logic;  -- 50 MHz Clock
        PM_BUTTON   : IN std_logic_vector(1 downto 0);  -- Pannel mounted buttons (MSB is leftmost button)
        BUTTON      : IN std_logic_vector(5 downto 0);  -- 6 buttons on the board (labeled U0-U5)
        ChA         : IN std_logic;  -- Encoder Channel A input 
        ChB         : IN std_logic;  -- Encoder Channel B input
        SWITCH      : IN std_logic_vector(9 downto 0);  -- 10 switches on the board
        BUZZER      : OUT std_logic; -- Buzzer output
        LED         : OUT std_logic_vector(9 downto 0); -- 10 LEDs on the board
        SEV_SEG     : OUT std_logic_vector(6 downto 0)  -- 7-segment display output 
    );
end board_function;

architecture behavioral of board_function is

    -- Rotary encoder signals
    constant scaling_factor : integer := 4;  -- Scaling factor for the rotary encoder
    signal counter          : unsigned(9 downto 0) := (OTHERS => '0');  -- counter for the rotary encoder
    signal prev_A           : std_logic := '0';  -- Previous state of Channel A
    signal prev_B           : std_logic := '0';  -- Previous state of Channel B
    signal ChA_Clean        : std_logic; -- Debounced signal for Channel A
    signal ChB_Clean        : std_logic; -- Debounced signal for Channel B

    -- 7-segment display signals
    -- signal SEV_SEG      : std_logic_vector(6 downto 0) := (others => '0');  -- 7-segment display output

BEGIN
    -- Process to handle the buzzer output based on button presses
    process(CLK, BUTTON)
    begin
        if rising_edge(CLK) then
            if BUTTON(4) = '1' then
                BUZZER <= '1';  -- Turn on buzzer when button U4 is pressed
            elsif BUTTON(5) = '1' then
                BUZZER <= '0';  -- Turn off buzzer when button U5 is pressed
            end if;
        end if;
    end process;

    -- Process to control the LEDs based on a counter for the rotary encoder
    rotary_encoder: process(CLK, ChA, ChB, SWITCH, BUTTON)
    BEGIN 
        if rising_edge(CLK)  then 
            if (SWITCH(9) = '1') then  -- Check if the switch is on
                if ((prev_A = '0') and (ChA_Clean = '1')) then
                    if (ChB_Clean = '0') then -- Clockwise rotation of encoder
                        if (counter = 1023) then
                            counter <=  (OTHERS => '0');  -- Reset counter if it exceeds 1023
                        else
                            counter <= counter + scaling_factor;  -- Increment counter on clockwise rotation
                        end if;
                    else -- Counter clockwise rotation of encoder
                        if (counter = 0) then
                            counter <= (OTHERS => '1');  -- Reset counter if it goes below 0
                        else
                            counter <= counter - scaling_factor;  -- Decrement counter on counter-clockwise rotation
                        end if;
                    end if;
                end if;
                prev_A <= ChA_Clean;  -- Update previous state of Channel A
                prev_B <= ChA_Clean;  -- Update previous state of Channel B
                
                for i in 0 to 9 loop
                    if (counter(i) = '1') then
                        LED(i) <= '1';  -- Turn on corresponding LED based on counter value
                    else
                        LED(i) <= '0';  -- Turn off other LEDs
                    end if;
                end loop;

            else 
                LED <= (others => '0');  -- Initialize all LEDs to off
                for i in 0 to 5 loop
                    if BUTTON(i) = '0' then
                        LED(i) <= '0';  -- Turn on corresponding LED when button is pressed
                    else 
                        LED(i) <= '1';  -- Turn off other LEDs
                    end if;
                end loop;
            end if;
        end if;
    end process rotary_encoder;

    -- Process to control the 7-segment display based on PM_BUTTON inputs
    process(CLK, PM_BUTTON)
    begin
        if rising_edge(CLK) then
            case PM_BUTTON is
                when "00" =>
                    SEV_SEG <= "0000001";  -- Display "0"
                when "01" =>
                    SEV_SEG <= "1001111";  -- Display "1"
                when "10" =>
                    SEV_SEG <= "0010010";  -- Display "2"
                when "11" =>
                    SEV_SEG <= "0000110";  -- Display "3"
                when others =>
                    SEV_SEG <= "1111111";  -- Turn off display for any other input
            end case;
        end if;
    end process;

    U0: entity work.Debounce port map (CLK, ChA, ChA_Clean);
    U1: entity work.Debounce port map (CLK, ChB, ChB_Clean);
end behavioral;




--Name: Ty Ahrens 
--Date: 4/12/2025
--Purpose: Debouncer for Channel A and B of rotary encoder. Takes in the noisy signal
--         and saves the signal input for each clock cycle to ensure that the signal
--         is stable.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Debounce is
    Port (
        clk     : in  STD_LOGIC; -- DE10-Lite clock 
        noisy   : in  STD_LOGIC; -- Input from rotary encoder
        clean   : out STD_LOGIC  -- Debounced signal from this
    );
end Debounce;

architecture Behavioral of Debounce is
    constant debounce_limit : integer := 50000;  -- 1ms at 50MHz
    signal counter          : integer range 0 to debounce_limit := 0;
    signal debounced        : STD_LOGIC := '0';
    signal last_state       : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if noisy /= last_state then
                counter <= 0;
            else
                if counter < debounce_limit then
                    counter <= counter + 1;
                else
                    debounced <= noisy;
                end if;
            end if;
            last_state <= noisy;
        end if;
    end process;

    clean <= debounced;  -- set the debounced signal to output back to top_entity
end Behavioral;