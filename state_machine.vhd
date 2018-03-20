library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.numeric_std.all;
use work.STD_LOGIC_UNSIGNED.ALL;
use work.aes128Pkg.all;

entity state_machine is
  port (
	clock_sm : in std_logic;
	reset_sm : in std_logic;
	keyXor_0_out_eff_sm : in Matrix;
	keyXor_out_eff_sm : in Matrix;
	keyXor_10_out_sm : in Matrix;
    data_reg_sm : out Matrix;
	done_sm : out std_logic;
	key_index_vector_sm : out std_logic_vector(3 downto 0)
	);
end entity state_machine;

architecture Behavioral of state_machine is

-- signals
signal data_reg_sig : Matrix;
signal done_sig, state, clock_sig, reset_sig : std_logic;
signal key_index : integer range 0 to 11;
signal key_index_vector_sig : std_logic_vector(3 downto 0);
signal keyXor_0_out_eff_sig : Matrix;
signal keyXor_out_eff_sig : Matrix;
signal keyXor_10_out_sig : Matrix;

begin

	-- output register
	T: process(clock_sig,reset_sig)
	begin
		if(reset_sig='1') then
			done_sig <= '0';
			key_index <= 0;
			state <= '0';
		elsif(clock_sig'event and clock_sig='1') then
			if(state='0') then
				if(key_index < 11) then
					if(key_index = 0) then
						data_reg_sig <= keyXor_0_out_eff_sig;
					elsif(key_index = 10) then
						data_reg_sig <= keyXor_10_out_sig;
						done_sig <= '1';
					else
						data_reg_sig <= keyXor_out_eff_sig;
					end if;
				end if;
				state <= '1';
			else
				if(done_sig='0') then
					key_index <= key_index + 1;
					state <= '0';
				end if;
			end if;
		end if;
	end process;
	
clock_sig <= clock_sm;
reset_sig <= reset_sm;
done_sm <= done_sig;
keyXor_0_out_eff_sig <= keyXor_0_out_eff_sm;
keyXor_out_eff_sig <= keyXor_out_eff_sm;
keyXor_10_out_sig <= keyXor_10_out_sm;
data_reg_sm <= data_reg_sig;
key_index_vector_sig <= std_logic_vector(to_unsigned(key_index, key_index_vector_sig'length));
key_index_vector_sm <= key_index_vector_sig;

end architecture Behavioral;