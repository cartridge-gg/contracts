%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict import dict_write, dict_update, dict_read, dict_new
from starkware.cairo.common.dict_access import DictAccess
from src.tokens.Avatar.library import (
    create_grid, 
    init_dict, 
    evolve, 
    num_neighbors, 
    check_above, 
    check_below, 
    check_left, 
    check_right,
    MAX_STEPS
)

@external
func test_num_neighbor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    // init first two rows of grid (2 x 7)
    let (local dict) = default_dict_new(default_value=0);
    dict_write{dict_ptr=dict}(key=0, new_value=1);
    dict_write{dict_ptr=dict}(key=1, new_value=0);
    dict_write{dict_ptr=dict}(key=2, new_value=1);
    dict_write{dict_ptr=dict}(key=3, new_value=1);
    dict_write{dict_ptr=dict}(key=4, new_value=0);
    dict_write{dict_ptr=dict}(key=5, new_value=1);
    dict_write{dict_ptr=dict}(key=6, new_value=0);
    dict_write{dict_ptr=dict}(key=7, new_value=1);
    dict_write{dict_ptr=dict}(key=8, new_value=0);
    dict_write{dict_ptr=dict}(key=9, new_value=0);
    dict_write{dict_ptr=dict}(key=10, new_value=1);
    dict_write{dict_ptr=dict}(key=11, new_value=0);
    dict_write{dict_ptr=dict}(key=12, new_value=0);
    dict_write{dict_ptr=dict}(key=13, new_value=1);

    let (above, dict) = check_above(n_steps=5, dict=dict);
    assert above = 0;
    let (above, dict) = check_above(n_steps=7, dict=dict);
    assert above = 1;

    let (below, dict) = check_below(n_steps=12, dict=dict);
    assert below = 0;
    let (below, dict) = check_below(n_steps=0, dict=dict);
    assert below = 1;

    let (right, dict) = check_right(n_steps=6, dict=dict);
    assert right = 0;
    let (right, dict) = check_right(n_steps=9, dict=dict);
    assert right = 1;

    let(left, dict) = check_left(n_steps=2, dict=dict);
    assert left = 0;
    let(left, dict) = check_left(n_steps=11, dict=dict);
    assert left = 1;

    let (num, dict) = num_neighbors(n_steps=0, dict=dict);
    assert num = 1;

    let (num, dict) = num_neighbors(n_steps=6, dict=dict);
    assert num = 2;

    let (num, dict) = num_neighbors(n_steps=11, dict=dict);
    assert num = 1;

    return ();
}

@external
func test_evolve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local dict) = default_dict_new(default_value=0);
    dict_write{dict_ptr=dict}(key=0, new_value=1);
    dict_write{dict_ptr=dict}(key=1, new_value=0);
    dict_write{dict_ptr=dict}(key=2, new_value=1);
    dict_write{dict_ptr=dict}(key=3, new_value=1);
    dict_write{dict_ptr=dict}(key=4, new_value=0);
    dict_write{dict_ptr=dict}(key=5, new_value=1);
    dict_write{dict_ptr=dict}(key=6, new_value=0);
    dict_write{dict_ptr=dict}(key=7, new_value=1);
    dict_write{dict_ptr=dict}(key=8, new_value=0);
    dict_write{dict_ptr=dict}(key=9, new_value=0);
    dict_write{dict_ptr=dict}(key=10, new_value=1);
    dict_write{dict_ptr=dict}(key=11, new_value=0);
    dict_write{dict_ptr=dict}(key=12, new_value=0);
    dict_write{dict_ptr=dict}(key=13, new_value=1);

    let (dict) = evolve(n_steps=0, dict=dict);
    let (alive) = dict_read{dict_ptr=dict}(key=3);
    assert alive = 1;

    let (dead) = dict_read{dict_ptr=dict}(key=13);
    assert dead = 0;

    let (rebirth) = dict_read{dict_ptr=dict}(key=8);
    assert rebirth = 1;
    
    return ();
}
