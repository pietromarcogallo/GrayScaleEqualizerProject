library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity project_reti_logiche is
Port (
    i_clk: in std_logic;
    i_start: in std_logic;
    i_rst: in std_logic;
    i_data: in std_logic_vector(7 downto 0);
    o_address: out std_logic_vector(15 downto 0);
    o_done: out std_logic;
    o_en: out std_logic;
    o_we: out std_logic;
    o_data: out std_logic_vector(7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state_type is (IDLE, EXPECT_VALUE, WAIT_VALUE, RECEIVE_VALUE,
CHECK_MAX_MIN, CALC_DELTA, CALC_SHIFT, TEMP_PIXEL, NEW_PIXEL,
WRITE_OUT, DONE);

signal current_state, next_state: state_type;
signal o_done_next, o_en_next, o_we_next: std_logic := '0';
signal o_data_next: std_logic_vector(7 downto 0) := "00000000";
signal o_address_next: std_logic_vector(15 downto 0) := "0000000000000000";

signal first_scan, first_scan_next: boolean := false;
signal got_column, got_line, got_column_next, got_line_next: boolean := false;
signal multiplication, multiplication_next: boolean := false;

signal writing_time, writing_time_next: boolean := false;

signal reading_address, reading_address_next: std_logic_vector(15
downto 0) := "0000000000000000";
signal writing_address, writing_address_next: std_logic_vector(15
downto 0) := "0000000000000010";

signal dimension, dimension_next: std_logic_vector(15 downto 0) :=
(others => '0');
signal temp_value, temp_value_next: std_logic_vector(15 downto 0) :=
"0000000000000000";
signal new_pixel_value, new_pixel_value_next: std_logic_vector(7
downto 0) := "00000000";
signal column_num, column_num_next, line_num, line_num_next:
std_logic_vector(7 downto 0) := "00000000";

signal current_pixel, current_pixel_next: integer range 0 to 255 := 0;
signal min_value, min_value_next: integer range 0 to 255 := 255;
signal max_value, max_value_next: integer range 0 to 255 := 0;
signal delta_value, delta_value_next: integer range 0 to 255 := 0;
signal shift, shift_next: integer range 0 to 8 := 0;


begin

process (i_clk, i_rst)

begin
    if (i_rst = '1') then

        first_scan <= false;
        got_column <= false;
        got_line <= false;
        multiplication <= false;
        writing_time <= false;
       
        reading_address <= "0000000000000000";
        writing_address <= "0000000000000010";
        column_num <= "00000000";
        line_num <= "00000000";
        current_pixel <= 0;
        min_value <= 255;
        max_value <= 0;
        delta_value <= 0;
        shift <= 0;
        dimension <= "0000000000000000";
        temp_value <= "0000000000000000";
        new_pixel_value <= "00000000";

        current_state <= IDLE;
    elsif (i_clk'event and i_clk = '1') then
        o_done <= o_done_next;
        o_en <= o_en_next;
        o_we <= o_we_next;
        o_data <= o_data_next;
        o_address <= o_address_next;

        first_scan <= first_scan_next;
        got_column <= got_column_next;
        got_line <= got_line_next;
        multiplication <= multiplication_next;

        reading_address <= reading_address_next;
        writing_address <= writing_address_next;

        column_num <= column_num_next;
        line_num <= line_num_next;
        current_pixel <= current_pixel_next;
        min_value <= min_value_next;
        max_value <= max_value_next;
        delta_value <= delta_value_next;
        shift <= shift_next;
        dimension <= dimension_next;
        temp_value <= temp_value_next;
        new_pixel_value <= new_pixel_value_next;
        current_state <= next_state;
       
        writing_time <= writing_time_next;
   
       
    end if;
end process;

-- Processo che descrive il comportamento della FSM
process (current_state, i_data, i_start, first_scan, got_column, got_line,
         multiplication, reading_address, writing_address, column_num,
         line_num, dimension, current_pixel, min_value, max_value, delta_value, shift,
         temp_value, writing_time, new_pixel_value)
begin

    o_done_next <= '0';
    o_en_next <= '0';
    o_we_next <= '0';
    o_data_next <= new_pixel_value;
    if(not writing_time) then
        o_address_next <= reading_address;
    else
        o_address_next <= writing_address;
    end if;
    writing_time_next <= writing_time;
    got_column_next <= got_column;
    got_line_next <= got_line;
    column_num_next <= column_num;
    line_num_next <= line_num;
    multiplication_next <= multiplication;
    reading_address_next <= reading_address;
    writing_address_next <= writing_address;
    first_scan_next <= first_scan;
    current_pixel_next <= current_pixel;
    min_value_next <= min_value;
    max_value_next <= max_value;
    delta_value_next <= delta_value;
    shift_next <= shift;
    dimension_next <= dimension;
    temp_value_next <= temp_value;
    new_pixel_value_next <= new_pixel_value;
    next_state <= current_state;

    case current_state is

        when IDLE =>
            if (i_start = '1') then
                next_state <= EXPECT_VALUE;
            end if;

        when EXPECT_VALUE =>
            o_en_next <= '1';
            o_we_next <= '0';
            if (not got_column and not got_line) then
                next_state <= WAIT_VALUE;
            elsif (got_column and not got_line) then
                if (column_num = 0) then
                    next_state <= DONE;
                else
                    next_state <= WAIT_VALUE;
                end if;
            elsif (got_column and got_line) then
                if (line_num = 0) then
                    next_state <= DONE;
                else
                    next_state <= WAIT_VALUE;
                end if;
            end if;

        when WAIT_VALUE =>
            next_state <= RECEIVE_VALUE;

        when RECEIVE_VALUE =>
            if (not got_column) then
                column_num_next <= i_data;
                next_state <= EXPECT_VALUE;
                got_column_next <= true;
                reading_address_next <= reading_address + "0000000000000001";
            elsif (got_column and not got_line) then
                line_num_next <= i_data;
                next_state <= EXPECT_VALUE;
                got_line_next <= true;
                reading_address_next <= reading_address + "0000000000000001";
            else
                current_pixel_next <= conv_integer(i_data);
                if (not multiplication) then
                    dimension_next <= column_num * line_num;
                    multiplication_next <= true;
                end if;

                if (not first_scan) then
                    next_state <= CHECK_MAX_MIN;
                    reading_address_next <= reading_address + "0000000000000001";
                else
                    next_state <= TEMP_PIXEL;
                end if;
            end if;

        when CHECK_MAX_MIN =>
            if (reading_address = "0000000000000010") then
                min_value_next <= current_pixel;
                max_value_next <= current_pixel;
            else
                if (current_pixel > max_value) then
                    max_value_next <= current_pixel;
                end if;
                if (current_pixel < min_value) then
                    min_value_next <= current_pixel;
                end if;
            end if;
            if (reading_address = dimension + "0000000000000010") then
                next_state <= CALC_DELTA;
            else
                next_state <= EXPECT_VALUE;
            end if;

        when CALC_DELTA =>
            delta_value_next <= max_value - min_value;
            next_state <= CALC_SHIFT;

        when CALC_SHIFT =>
            if (delta_value = 0) then shift_next <= 8;
            elsif (delta_value >= 1 and delta_value <= 2) then shift_next <= 7;
            elsif (delta_value >= 3 and delta_value <= 6) then shift_next <= 6;
            elsif (delta_value >= 7 and delta_value <= 14) then shift_next <= 5;
            elsif (delta_value >= 15 and delta_value <= 30) then shift_next <= 4;
            elsif (delta_value >= 31 and delta_value <= 62) then shift_next <= 3;
            elsif (delta_value >= 63 and delta_value <= 126) then shift_next <= 2;
            elsif (delta_value >= 127 and delta_value <= 254) then shift_next <= 1;
            elsif (delta_value = 255) then shift_next <= 0;
            end if;
            first_scan_next <= true;
            reading_address_next <= "0000000000000010";
            writing_address_next <= dimension + "000000000000010";
            next_state <= EXPECT_VALUE;

        when TEMP_PIXEL =>
            temp_value_next <= std_logic_vector(shift_left(to_unsigned(current_pixel - min_value, 16),shift));
            next_state <= NEW_PIXEL;

        when NEW_PIXEL =>
            if (conv_integer(temp_value) >= 255) then
                new_pixel_value_next <= std_logic_vector(to_unsigned(255, 8));
            else
                new_pixel_value_next <= temp_value(7 downto 0);

            end if;
            writing_time_next <= true;
            next_state <= WRITE_OUT;

        when WRITE_OUT =>
            writing_time_next <= false;
            o_data_next <= new_pixel_value;
            o_en_next <= '1';
            o_we_next <= '1';
            if (conv_integer(writing_address) = dimension + dimension + 1) then
                next_state <= DONE;
            else
                reading_address_next <= reading_address + "0000000000000001";
                writing_address_next <= writing_address + "0000000000000001";
                next_state <= EXPECT_VALUE;
            end if;

        when DONE =>
            o_done_next <= '1';
            if (i_start = '0') then
                first_scan_next <= false;
                got_column_next <= false;
                got_line_next <= false;
                multiplication_next <= false;
                writing_time_next <= false;

                reading_address_next <= "0000000000000000";
                writing_address_next <= "0000000000000010";

                column_num_next <= "00000000";
                line_num_next <= "00000000";
                current_pixel_next <= 0;
                min_value_next <= 255;
                max_value_next <= 0;
                delta_value_next <= 0;
                shift_next <= 0;
                o_done_next <= '0';
                dimension_next <= "0000000000000000";
                temp_value_next <= "0000000000000000";
                new_pixel_value_next <= "00000000";
                next_state <= IDLE;
            end if;

    end case;
end process;
end Behavioral;
