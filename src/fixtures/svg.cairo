%lang starknet

from src.util.svg import Cell, generate_character
from src.util.str import string

@view
func test_generate_character{syscall_ptr : felt*, range_check_ptr}() -> (tokenURI_len : felt, tokenURI : felt*):
    alloc_locals
    let (char) = generate_character(100)
    return (tokenURI_len=char.arr_len, tokenURI=char.arr)
end
