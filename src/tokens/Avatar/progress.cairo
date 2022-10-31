%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256, uint256_lt

// base (0pts)            4x4
// level 1 (20pts)        6x6
// level 2 (50pts)        8x8
// level 3 (100pts)       10x10
// level 4 (200pts)       12x12

struct Progress {
    dimension: felt,
    color: felt,
    border_color: felt,
    bg_color: felt,
}

func get_progress{range_check_ptr}(
    points: Uint256
) -> (progress: Progress) {
    alloc_locals;

    let (res) = uint256_lt(points, Uint256(200, 0));
    if(res == 0) {
        let (progress) = LEVEL_4();
        return (progress=progress);
    } 

    let (res) = uint256_lt(points, Uint256(100, 0));
    if(res == 0) {
        let (progress) = LEVEL_3();
        return (progress=progress);
    } 

    let (res) = uint256_lt(points, Uint256(50, 0));
    if(res == 0) {
        let (progress) = LEVEL_2();
        return (progress=progress);
    } 

    let (res) = uint256_lt(points, Uint256(20, 0));
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
            dimension=4,
            color='#fff',
            border_color=-1,
            bg_color='#1E221F',
        )
    );
}

func LEVEL_1{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=6,
            color='#fff',
            border_color=-1,
            bg_color='#1E221F',
        )
    );
}

func LEVEL_2{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=8,
            color='#fff',
            border_color=-1,
            bg_color='#1E221F',
        )
    );
}

func LEVEL_3{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=10,
            color='#fff',
            border_color=-1,
            bg_color='#1E221F',
        )
    );
}

func LEVEL_4{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=12,
            color='#fff',
            border_color=-1,
            bg_color='#1E221F',
        )
    );
}

