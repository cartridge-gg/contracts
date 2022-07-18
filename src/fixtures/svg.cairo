%lang starknet

from src.tokens.Avatar.library import Cell, generate_character
from src.util.str import string

from base64 import base64_encode

@view
func test_generate_character{syscall_ptr : felt*, range_check_ptr}() -> (tokenURI_len : felt, tokenURI : felt*):
    alloc_locals
    let (char) = generate_character(1337)
    let (encoded_len, encoded) = base64_encode(1, char.arr)
    return (tokenURI_len=encoded_len, tokenURI=encoded)
end
