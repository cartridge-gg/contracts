%lang starknet

from starkware.cairo.common.math import unsigned_div_rem

// level 0 (0pts)           6x6
// level 1 (1000pts)        border
// level 2 (2000pts)        8x8
// level 3 (3000pts)        primary color
// level 4 (4000pts)        10x10
// level 5 (5000pts)        secondary color
// level 6 (6000pts)        12x12

struct Progress {
    dimension: felt,
    primary_color: felt,
    secondary_color: felt,
    border_color: felt,
    bg_color: felt,
}

const LVL_PTS = 1000;

func get_progress{range_check_ptr}(
) -> (progress: Progress) {
    alloc_locals;

    let pts = 0;
    let (level, _) = unsigned_div_rem(pts, LVL_PTS);
    
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

    if(level == 5) {
        let (progress) = LEVEL_5();
        return (progress=progress);
    }

    if(level == 6) {
        let (progress) = LEVEL_6();
        return (progress=progress);
    }

    let (progress) = BASE();
    return (progress=progress);
}

func BASE{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=6,
            primary_color=-1,
            secondary_color=-1,
            border_color=-1,
            bg_color='#1E221F',
        )
    );
}

func LEVEL_1{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=6,
            primary_color=-1,
            secondary_color=-1,
            border_color='#555',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_2{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=8,
            primary_color=-1,
            secondary_color=-1,
            border_color='#555',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_3{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=8,
            primary_color='#fff',
            secondary_color=-1,
            border_color='#555',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_4{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=10,
            primary_color='#fff',
            secondary_color=-1,
            border_color='#555',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_5{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=10,
            primary_color='#fff',
            secondary_color='#fff',
            border_color='#555',
            bg_color='#1E221F',
        )
    );
}

func LEVEL_6{range_check_ptr}() -> (progress: Progress) {
    return (
        progress=Progress(
            dimension=12,
            primary_color='#fff',
            secondary_color='#fff',
            border_color='#555',
            bg_color='#1E221F',
        )
    );
}