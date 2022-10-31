%lang starknet

from src.tokens.Avatar.library import Cell, generate_svg
from src.util.str import string

@external
func test_generate_svg{syscall_ptr: felt*, range_check_ptr}(
    seed: felt, border: felt, dimension: felt
) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;
    let (svg) = generate_svg(seed, dimension, border_color='#888', bg_color='#1E221F');
    return (tokenURI_len=svg.arr_len, tokenURI=svg.arr);
}
