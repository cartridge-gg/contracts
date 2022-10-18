%lang starknet

from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.uint256 import Uint256

// level 0 (0pts)           6x6
// level 1 (100pts)        border
// level 2 (200pts)        8x8
// level 3 (300pts)        10x10
// level 4 (400pts)        12x12

struct Progress {
    dimension: felt,
    color: felt,
    border_color: felt,
    bg_color: felt,
}

// reduce to 100 for testing
const LVL_PTS = 100;

func get_progress{range_check_ptr}(
    points: Uint256
) -> (progress: Progress) {
    alloc_locals;

    let (level, _) = unsigned_div_rem(points.low, LVL_PTS);
    
    if(level == 1) {
        let (progress) = LEVEL_1();
        return (progress=progress);
    } 

    if(level == 2) {
        let (progress) = LEVEL_2();
        return (progress=progress);
    }

    if(level == 3) {
        let (progress) = LEVEL_3();
        return (progress=progress);
    }

    if(level == 4) {
        let (progress) = LEVEL_4();
        return (progress=progress);
    }

    let (progress) = BASE();
    return (progress=progress);
}

func BASE{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=6,
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
            border_color='#888',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_2{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=8,
            color='#fff',
            border_color='#888',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_3{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=10,
            color='#fff',
            border_color='#888',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_4{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=12,
            color='#fff',
            border_color='#888',
            bg_color='#1E221F',
        )
    );
}
