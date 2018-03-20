library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.numeric_std.all;
use work.STD_LOGIC_UNSIGNED.ALL;
use work.aes128Pkg.all;

entity fault_injector is
  port (
	faulty : in std_logic;
	fault_round : in std_logic_vector (3 downto 0);
	fault_function : in std_logic_vector (1 downto 0);
	fault_word : in std_logic_vector (1 downto 0);
	fault_byte : in std_logic_vector (1 downto 0);
	fault_bit : in std_logic_vector (2 downto 0);
	fault_word2 : in std_logic_vector (1 downto 0);
	fault_byte2 : in std_logic_vector (1 downto 0);
	fault_bit2 : in std_logic_vector (2 downto 0);
	key_index_vector : in std_logic_vector (3 downto 0);
	keyXor_0_out : in Matrix;
	keyXor_10_out : in Matrix;
	keyXor_out : in Matrix;
	sbox_out : in Matrix;
	shiftRow_out : in Matrix;
	mixColumn_out : in Matrix;
	keyXor_0_out_eff : out Matrix;
	keyXor_10_out_eff : out Matrix;
	keyXor_out_eff : out Matrix;
	sbox_out_eff : out Matrix;
	shiftRow_out_eff : out Matrix;
	mixColumn_out_eff : out Matrix
	);
end entity fault_injector;

architecture Behavioral of fault_injector is

signal sbox_out_flt : Matrix;
signal shiftRow_out_flt : Matrix;
signal mixColumn_out_flt : Matrix;
signal keyXor_out_flt : Matrix;
signal keyXor_0_out_flt : Matrix;
signal keyXor_10_out_flt : Matrix;
signal temp_bit : std_logic;
signal key_index : integer range 0 to 11;
signal fault_round_index : integer range 0 to 10;
signal fault_function_index : integer range 0 to 3;
signal fault_word_index : integer range 0 to 3;
signal fault_byte_index : integer range 0 to 3;
signal fault_bit_index : integer range 0 to 7;
signal fault_word2_index : integer range 0 to 3;
signal fault_byte2_index : integer range 0 to 3;
signal fault_bit2_index : integer range 0 to 7;

begin

key_index <= to_integer(unsigned(key_index_vector));
fault_round_index <= to_integer(unsigned(fault_round));
fault_function_index <= to_integer(unsigned(fault_function));
fault_word_index <= to_integer(unsigned(fault_word));
fault_byte_index <= to_integer(unsigned(fault_byte));
fault_bit_index <= to_integer(unsigned(fault_bit));
fault_word2_index <= to_integer(unsigned(fault_word2));
fault_byte2_index <= to_integer(unsigned(fault_byte2));
fault_bit2_index <= to_integer(unsigned(fault_bit2));

process(keyXor_0_out, fault_word_index, fault_byte_index, fault_bit_index, fault_word2_index, fault_byte2_index, fault_bit2_index)
begin
	keyXor_0_out_flt <= keyXor_0_out;
	keyXor_0_out_flt(fault_word_index)(fault_byte_index)(7 - fault_bit_index) <= not keyXor_0_out(fault_word_index)(fault_byte_index)(7 - fault_bit_index);
	if (fault_word_index /= fault_word2_index or fault_byte_index /= fault_byte2_index or fault_bit_index /= fault_bit2_index) then
		keyXor_0_out_flt(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index) <= not keyXor_0_out(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index);
	end if;
end process;
keyXor_0_out_eff <= keyXor_0_out_flt when (faulty = '1' and key_index = fault_round_index and fault_function_index = 3) else
				  keyXor_0_out;
					  
process(keyXor_out, fault_word_index, fault_byte_index, fault_bit_index, fault_word2_index, fault_byte2_index, fault_bit2_index)
begin
	keyXor_out_flt <= keyXor_out;
	keyXor_out_flt(fault_word_index)(fault_byte_index)(7 - fault_bit_index) <= not keyXor_out(fault_word_index)(fault_byte_index)(7 - fault_bit_index);
	if (fault_word_index /= fault_word2_index or fault_byte_index /= fault_byte2_index or fault_bit_index /= fault_bit2_index) then
		keyXor_out_flt(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index) <= not keyXor_out(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index);
	end if;
end process;
keyXor_out_eff <= keyXor_out_flt when (faulty = '1' and key_index = fault_round_index and fault_function_index = 3) else
				  keyXor_out;
				  
process(sbox_out, fault_word_index, fault_byte_index, fault_bit_index, fault_word2_index, fault_byte2_index, fault_bit2_index)
begin
	sbox_out_flt <= sbox_out;
	sbox_out_flt(fault_word_index)(fault_byte_index)(7 - fault_bit_index) <= not sbox_out(fault_word_index)(fault_byte_index)(7 - fault_bit_index);
	if (fault_word_index /= fault_word2_index or fault_byte_index /= fault_byte2_index or fault_bit_index /= fault_bit2_index) then
		sbox_out_flt(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index) <= not sbox_out(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index);
	end if;
end process;
sbox_out_eff <= sbox_out_flt when (faulty = '1' and key_index = fault_round_index and fault_function_index = 0) else
				  sbox_out;
				  
process(shiftRow_out, fault_word_index, fault_byte_index, fault_bit_index, fault_word2_index, fault_byte2_index, fault_bit2_index)
begin
	shiftRow_out_flt <= shiftRow_out;
	shiftRow_out_flt(fault_word_index)(fault_byte_index)(7 - fault_bit_index) <= not shiftRow_out(fault_word_index)(fault_byte_index)(7 - fault_bit_index);
	if (fault_word_index /= fault_word2_index or fault_byte_index /= fault_byte2_index or fault_bit_index /= fault_bit2_index) then
		shiftRow_out_flt(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index) <= not shiftRow_out(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index);
	end if;
end process;
shiftRow_out_eff <= shiftRow_out_flt when (faulty = '1' and key_index = fault_round_index and fault_function_index = 1) else
				  shiftRow_out;
		  
process(mixColumn_out, fault_word_index, fault_byte_index, fault_bit_index, fault_word2_index, fault_byte2_index, fault_bit2_index)
begin
	mixColumn_out_flt <= mixColumn_out;
	mixColumn_out_flt(fault_word_index)(fault_byte_index)(7 - fault_bit_index) <= not mixColumn_out(fault_word_index)(fault_byte_index)(7 - fault_bit_index);
	if (fault_word_index /= fault_word2_index or fault_byte_index /= fault_byte2_index or fault_bit_index /= fault_bit2_index) then
		mixColumn_out_flt(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index) <= not mixColumn_out(fault_word2_index)(fault_byte2_index)(7 - fault_bit2_index);
	end if;
end process;
mixColumn_out_eff <= mixColumn_out_flt when (faulty = '1' and key_index = fault_round_index and fault_function_index = 2) else
				  mixColumn_out;			  
				  
end architecture Behavioral;