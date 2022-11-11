%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_shr, assert_uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict import dict_write, dict_update, dict_read, dict_new
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.bool import TRUE, FALSE
from src.tokens.Avatar.Avatar import (
    IExperienceContract,
    IAvatarContract,
)
from src.tokens.Avatar.progress import (
    Progress,
    get_progress,
)
from src.tokens.Avatar.library import (
    init_character,
    generate_svg,
    get_fingerprint,
    create_grid, 
    init_dict, 
    grow, 
    num_neighbors, 
    check_above, 
    check_below, 
    check_left, 
    check_right,
    add_border,
    crop,
    Cell,
    CellType,
    MAX_STEPS,
    MAX_COL,
    MAX_ROW,
)

@external
func test_num_neighbor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    //     1 0 1 1 0 1 0   
    //     1 1 0 1 0 0 2 
    let (local dict) = default_dict_new(default_value=0);
    dict_write{dict_ptr=dict}(key=0, new_value=1);
    dict_write{dict_ptr=dict}(key=1, new_value=0);
    dict_write{dict_ptr=dict}(key=2, new_value=1);
    dict_write{dict_ptr=dict}(key=3, new_value=1);
    dict_write{dict_ptr=dict}(key=4, new_value=0);
    dict_write{dict_ptr=dict}(key=5, new_value=1);
    dict_write{dict_ptr=dict}(key=6, new_value=0);
    dict_write{dict_ptr=dict}(key=7, new_value=1);
    dict_write{dict_ptr=dict}(key=8, new_value=1);
    dict_write{dict_ptr=dict}(key=9, new_value=0);
    dict_write{dict_ptr=dict}(key=10, new_value=1);
    dict_write{dict_ptr=dict}(key=11, new_value=0);
    dict_write{dict_ptr=dict}(key=12, new_value=0);
    dict_write{dict_ptr=dict}(key=13, new_value=2);

    let (value, dict) = check_above(key=5, value=1, dict=dict);
    assert value = 0;
    let (value, dict) = check_above(key=7, value=1, dict=dict);
    assert value = 1;

    let (value, dict) = check_below(key=12, value=1, dict=dict);
    assert value = 0;
    let (value, dict) = check_below(key=0, value=1, dict=dict);
    assert value = 1;

    let (value, dict) = check_right(key=6, value=1, dict=dict);
    assert value = 0;
    let (value, dict) = check_right(key=9, value=1, dict=dict);
    assert value = 1;

    let(value, dict) = check_left(key=2, value=1, dict=dict);
    assert value = 0;
    let(value, dict) = check_left(key=11, value=1, dict=dict);
    assert value = 1;

    let (value, dict) = num_neighbors(key=1, value=1, dict=dict);
    assert value = 3;

    let (value, dict) = num_neighbors(key=4, value=1, dict=dict);
    assert value = 2;

    let (value, dict) = num_neighbors(key=6, value=2, dict=dict);
    assert value = 1;

    let (value, dict) = num_neighbors(key=11, value=1, dict=dict);
    assert value = 1;

    return ();
}

@external
func test_grow{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    //     1 0 1 1 0 1 0       0 0 0 1 0 0 0    
    //     1 0 0 1 0 0 1   >   0 1 0 0 1 0 0
    //     0 0 0 0 0 0 0       0 0 0 0 0 0 0  

    let (local output_start) = default_dict_new(default_value=0);
    let (local input_start) = default_dict_new(default_value=0);
    let input_end = input_start;
    let output_end = output_start;
    dict_write{dict_ptr=input_end}(key=0, new_value=1);
    dict_write{dict_ptr=input_end}(key=1, new_value=0);
    dict_write{dict_ptr=input_end}(key=2, new_value=1);
    dict_write{dict_ptr=input_end}(key=3, new_value=1);
    dict_write{dict_ptr=input_end}(key=4, new_value=0);
    dict_write{dict_ptr=input_end}(key=5, new_value=1);
    dict_write{dict_ptr=input_end}(key=6, new_value=0);
    dict_write{dict_ptr=input_end}(key=7, new_value=1);
    dict_write{dict_ptr=input_end}(key=8, new_value=0);
    dict_write{dict_ptr=input_end}(key=9, new_value=0);
    dict_write{dict_ptr=input_end}(key=10, new_value=1);
    dict_write{dict_ptr=input_end}(key=11, new_value=0);
    dict_write{dict_ptr=input_end}(key=12, new_value=0);
    dict_write{dict_ptr=input_end}(key=13, new_value=1);

    let (input_end, output_end) = grow(n_steps=14, input=input_end, output=output_end);

    let(finalized_output_start, finalized_output_end) = default_dict_finalize(output_start, output_end, 0);
    let(finalized_input_start, finalized_input_end) = default_dict_finalize(input_start, input_end, 0);

    let (alive) = dict_read{dict_ptr=finalized_output_end}(key=3);
    assert alive = 1;

    let (dead) = dict_read{dict_ptr=finalized_output_end}(key=13);
    assert dead = 0;

    let (rebirth) = dict_read{dict_ptr=finalized_output_end}(key=8);
    assert rebirth = 1;

    return ();
}

@external
func test_border{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    alloc_locals;

    //     0 0 0 0 0 0 0        0 0 0 2 2 0 0
    //     0 0 0 1 1 0 0        0 0 2 1 1 2 0
    //     0 0 0 0 0 0 0   >    0 0 0 2 2 0 2
    //     0 0 0 0 0 0 1        0 0 0 0 0 2 1
    //     0 0 0 0 0 0 0        0 0 0 0 0 0 2

    let (local input_start) = default_dict_new(default_value=0);
    let input_end = input_start;
    dict_write{dict_ptr=input_end}(key=10, new_value=1);
    dict_write{dict_ptr=input_end}(key=11, new_value=1);
    dict_write{dict_ptr=input_end}(key=27, new_value=1);

    let (dict) = add_border(input_end, MAX_STEPS, border=TRUE);

    let (value) = dict_read{dict_ptr=dict}(key=3);
    assert value = CellType.BORDER;
    let (value) = dict_read{dict_ptr=dict}(key=17);
    assert value = CellType.BORDER;
    let (value) = dict_read{dict_ptr=dict}(key=9);
    assert value = CellType.BORDER;
    let (value) = dict_read{dict_ptr=dict}(key=12);
    assert value = CellType.BORDER;

    let (value) = dict_read{dict_ptr=dict}(key=20);
    assert value = CellType.BORDER;
    let (value) = dict_read{dict_ptr=dict}(key=26);
    assert value = CellType.BORDER;

    return();
}


@external
func test_progression{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local contract_address: felt;
    local xp_implementation: felt;

    %{
        from starkware.starknet.compiler.compile import get_selector_from_name
        ids.xp_implementation = declare("./src/tokens/experience/Experience.cairo").class_hash
        ids.contract_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/upgrades/presets/Proxy.cairo",[ids.xp_implementation, get_selector_from_name('initialize'), 1, 123]).contract_address
        stop_prank_callable = start_prank(123, target_contract_address=ids.contract_address)
    %}

    let (xp) = IExperienceContract.balanceOf(contract_address, 123);
    let (progress: Progress) = get_progress(xp);
    assert progress.dimension = 8;

    return ();
}

@external
func test_upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    local initial_implementation: felt;
    local fake_implementation: felt;
    local contract_address: felt;

    %{
        from starkware.starknet.compiler.compile import get_selector_from_name
        ids.initial_implementation = declare("./src/tokens/Avatar/Avatar.cairo").class_hash
        ids.fake_implementation = declare("./src/tokens/Avatar/Avatar.cairo").class_hash
        ids.contract_address = deploy_contract("./lib/cairo_contracts/src/openzeppelin/upgrades/presets/Proxy.cairo",[ids.initial_implementation, get_selector_from_name('initialize'), 1, 123]).contract_address
        stop_prank_callable = start_prank(123, target_contract_address=ids.contract_address)
    %}

    let (implementation) = IAvatarContract.implementation(contract_address);
    assert implementation = initial_implementation;

    IAvatarContract.upgrade(contract_address, fake_implementation);

    let (next_implementation) = IAvatarContract.implementation(contract_address);
    assert next_implementation = fake_implementation;

    %{
        stop_prank_callable()
    %}

    return ();
}