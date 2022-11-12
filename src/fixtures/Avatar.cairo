%lang starknet

from src.tokens.Avatar.library import Cell, generate_svg
from src.util.str import string

@external
func test_generate_svg{syscall_ptr: felt*, range_check_ptr}(
    seed: felt, border: felt, dimension: felt, evolution: felt
) -> (tokenURI_len: felt, tokenURI: felt*) {
    alloc_locals;
    let (svg) = generate_svg(seed, evolution, dimension, border=border, bg_color='transparent');
    return (tokenURI_len=svg.arr_len, tokenURI=svg.arr);
}
