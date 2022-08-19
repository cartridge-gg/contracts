%lang starknet

from src.tokens.Avatar.library import Cell, generate_character
from src.util.str import string

@external
func test_generate_character{syscall_ptr: felt*, range_check_ptr}(seed: felt, dimension: felt) -> (tokenURI_len: felt, tokenURI: felt*):
    alloc_locals
    let (char) = generate_character(seed, dimension)
    return (tokenURI_len=char.arr_len, tokenURI=char.arr)
end
