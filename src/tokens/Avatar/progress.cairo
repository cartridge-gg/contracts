%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256, uint256_lt
from starkware.cairo.common.bool import TRUE, FALSE

// base (0pts)              8x8
// level 1 (100pts)         10x10
// level 2 (200pts)         12x12

struct Progress {
    evolution: felt,
    dimension: felt,
    border: felt,
    bg_color: felt,
}

func get_progress{range_check_ptr}(
    xp: Uint256
) -> (progress: Progress) {
    alloc_locals;

    let (res) = uint256_lt(xp, Uint256(200, 0));
    if(res == 0) {
        let (progress) = LEVEL_2();
        return (progress=progress);
    } 

    let (res) = uint256_lt(xp, Uint256(100, 0));
    if(res == 0) {
        let (progress) = LEVEL_1();
        return (progress=progress);
    } 

    let (progress) = BASE();
    return (progress=progress);
}

func BASE{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            evolution=1,
            dimension=8,
            border=TRUE,
            bg_color='transparent',
        )
    );
}

func LEVEL_1{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            evolution=1,
            dimension=10,
            border=TRUE,
            bg_color='transparent',
        )
    );
}

func LEVEL_2{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            evolution=1,
            dimension=12,
            border=TRUE,
            bg_color='transparent',
        )
    );
}



