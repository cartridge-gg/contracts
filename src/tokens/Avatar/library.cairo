// https://raw.githubusercontent.com/topology-gg/caistring/9980eb42a889beaf1ebadb21965a92471fcb1f92/contracts/Svg.cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt, assert_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.default_dict import default_dict_new, default_dict_finalize
from starkware.cairo.common.dict import dict_write, dict_update, dict_read
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE

from src.util.str import string, literal_from_number, str_from_literal, str_concat

struct Cell {
    row: felt,
    col: felt,
}

struct SvgRect {
    x: felt,
    y: felt,
    fill: felt,
}

const SCALE = 5;
const PADDING = 4;
const MAX_DIM = 14;
const BASE_DIM = 6;

//##########################

func return_svg_header{range_check_ptr}(bg_color: felt) -> (str: string) {
    alloc_locals;

    // Format:
    // <svg width={w*scale} height={h*scale} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" shape-rendering="crispEdges">
    let full_w = PADDING * 2 + MAX_DIM;
    let full_h = PADDING * 2 + MAX_DIM;
    let (w_literal: felt) = literal_from_number(full_w * SCALE);
    let (h_literal: felt) = literal_from_number(full_h * SCALE);
    let (vb_w_literal: felt) = literal_from_number(full_w);
    let (vb_h_literal: felt) = literal_from_number(full_h);

    let (arr) = alloc();
    assert arr[0] = '<svg width=\"';
    assert arr[1] = w_literal;
    assert arr[2] = '\" height=\"';
    assert arr[3] = h_literal;
    assert arr[4] = '\" xmlns=\"http://www.w3.org/';
    assert arr[5] = '2000/svg\" viewBox=\"0 0 ';
    assert arr[6] = vb_w_literal;
    assert arr[7] = ' ';
    assert arr[8] = vb_h_literal;
    assert arr[9] = '\" shape-rendering=';
    assert arr[10] = '\"crispEdges\">';
    assert arr[11] = '<rect x=\"0\" y=\"0\" width=\"';
    assert arr[12] = vb_w_literal;
    assert arr[13] = '\" height=\"';
    assert arr[14] = vb_h_literal;
    assert arr[15] = '\" fill=\"';
    assert arr[16] = bg_color;
    assert arr[17] = '\" />';

    return (string(18, arr),);
}

func str_from_svg_rect{range_check_ptr}(svg_rect: SvgRect) -> (str: string) {
    alloc_locals;

    // Format:
    // <rect x="<x>" y="<y>" w="1" h="1" attribute_0="<attribute_0>" ... />

    let (x_literal: felt) = literal_from_number(svg_rect.x + PADDING);
    let (y_literal: felt) = literal_from_number(svg_rect.y + PADDING);

    let (arr) = alloc();
    assert arr[0] = '<rect x=\"';
    assert arr[1] = x_literal;
    assert arr[2] = '\" y=\"';
    assert arr[3] = y_literal;
    assert arr[4] = '\" width=\"1\" height=\"1\" ';
    assert arr[5] = 'fill=\"';
    assert arr[6] = svg_rect.fill;
    assert arr[7] = '\" />';

    return (string(8, arr),);
}

func init_dict{range_check_ptr}(
    seed: felt, bias: felt, n_steps: felt, max_steps: felt, dict: DictAccess*
) -> (dict: DictAccess*) {
    if (n_steps == 0) {
        return (dict=dict);
    }

    let (prob, _) = unsigned_div_rem(seed, n_steps);
    let (_, event) = unsigned_div_rem(prob, bias);
    let key = max_steps - n_steps;
    
    if (event == 1) {
        dict_write{dict_ptr=dict}(key=key, new_value=1);
    } else {
        dict_write{dict_ptr=dict}(key=key, new_value=0);
    }

    return init_dict(
        seed=seed, bias=bias, n_steps=n_steps - 1, max_steps=max_steps, dict=dict
    );
}

func colors{range_check_ptr}() -> (primary: felt*, secondary: felt*, size: felt) {
    let (pri_addr) = get_label_location(pri_start);
    let (sec_addr) = get_label_location(sec_start);

    return (primary=cast(pri_addr, felt*), secondary=cast(sec_addr, felt*), size=5);

    pri_start:
    dw '#FBCB4A';
    dw '#A7E7A7';
    dw '#FBCB4A';
    dw '#7563A3';
    dw '#73C4FF';

    sec_start: 
    dw '#ED9D92';
    dw '#CAF1CA';
    dw '#FDE092';
    dw '#AD93EF';
    dw '#C8E8FF';
}

func random_color{range_check_ptr}(
    cell: Cell*, seed: felt, n_steps: felt
) -> (color: felt) {
    alloc_locals;

    let (primary, secondary, size) = colors();
    let (_, idx) = unsigned_div_rem(seed, size);

    let (prob, _) = unsigned_div_rem(seed, n_steps);
    let (_, color_event) = unsigned_div_rem(prob, 5); // ~20%
    let (_, primary_event) = unsigned_div_rem(prob, 3); // ~33%

    let (contains) = dim_contains(BASE_DIM, cell);
    
    if(contains == TRUE) {
        return (color='#fff');
    } 

    if(color_event == 0) {
        return (color='#fff');
    }
    
    if(primary_event == 0) {
        return (color=secondary[idx]);
    } 
    return (color=primary[idx]);
}

func dim_contains{range_check_ptr}(
    dim: felt, cell: Cell*
) -> (contains: felt) {

    let (padding, _) = unsigned_div_rem(MAX_DIM - dim, 2);
    let side = is_le(padding, cell.col - 1);
    let top = is_le(padding, cell.row - 1);
    let bottom = is_le(cell.row - 1, padding + dim - 1);

    if(top != 0 and bottom != 0 and side != 0) {
        return (contains=TRUE);
    }

    return (contains=FALSE);
}

func render{range_check_ptr}(
    dict: DictAccess*, dimension: felt, grid: Cell*, seed: felt, svg_str: string, n_steps: felt
) -> (svg_str: string) {
    alloc_locals;

    if (n_steps == 0) {
        return (svg_str=svg_str);
    }

    let key = n_steps - 1;
    let (local event) = dict_read{dict_ptr=dict}(key=key);
    let cell: Cell* = grid + (Cell.SIZE * key);
    let (contains) = dim_contains(dimension, cell);
    
    if (event == TRUE and contains == TRUE) {
        //let (color) = random_color(cell, seed, n_steps);
        let color = '#fff';
        let svg_rect_left = SvgRect(x=cell.col - 1, y=cell.row - 1, fill=color);
        let (rect_str: string) = str_from_svg_rect(svg_rect_left);
        let (next_svg_str) = str_concat(svg_str, rect_str);

        let mirror_x = (MAX_DIM + 1) - cell.col;

        let svg_rect_right = SvgRect(x=mirror_x - 1, y=cell.row - 1, fill=color);
        let (rect_str: string) = str_from_svg_rect(svg_rect_right);
        let (final_svg_str) = str_concat(next_svg_str, rect_str);
        return render(
            dict=dict, dimension=dimension, grid=grid, seed=seed, svg_str=final_svg_str, n_steps=n_steps - 1
        );
    } 

    return render(
        dict=dict, dimension=dimension, grid=grid, seed=seed, svg_str=svg_str, n_steps=n_steps - 1
    );
}

func create_grid{syscall_ptr: felt*, range_check_ptr}(row: felt, col: felt) -> (grid: Cell*) {
    alloc_locals;

    let (local grid_start: Cell*) = alloc();
    grid_recurse(row_max=row, row=row, col=col, grid=grid_start);

    return (grid_start,);
}

func grid_recurse{syscall_ptr: felt*, range_check_ptr}(
    row_max: felt, row: felt, col: felt, grid: Cell*
) -> (grid_end: Cell*) {
    alloc_locals;

    if (row == 0 and col == 1) {
        return (grid_end=grid);
    }

    if (row != 0) {
        assert grid[0] = Cell(row=row, col=col);
        return grid_recurse(row_max=row_max, row=row - 1, col=col, grid=grid + Cell.SIZE);
    }

    if (col != 1) {
        assert grid[0] = Cell(row=row_max, col=col - 1);
        return grid_recurse(row_max=row_max, row=row_max - 1, col=col - 1, grid=grid + Cell.SIZE);
    }

    // unreachable code but return required.
    // 'else' is not yet supported in base case condition's boolean expression
    return (grid_end=grid);
}

func generate_character{syscall_ptr: felt*, range_check_ptr}(
    seed: felt, dimension: felt, bias: felt, bg_color: felt
) -> (svg_str: string) {
    alloc_locals;

    assert_not_zero(seed);
    assert_not_zero(bias);

    let (q_col, r_col) = unsigned_div_rem(MAX_DIM, 2);
    let col = q_col + r_col;
    let row = MAX_DIM;
    let n_steps = col * row;

    let (grid: Cell*) = create_grid(row=row, col=col);

    let (local dict_start) = default_dict_new(default_value=0);

    let (dict_end) = init_dict(
        seed=seed, bias=bias, n_steps=n_steps, max_steps=n_steps, dict=dict_start
    );

    let (finalized_dict_start, finalized_dict_end) = default_dict_finalize(dict_start, dict_end, 0);

    let (header_str: string) = return_svg_header(bg_color);
    let (render_str: string) = render(
        dict=finalized_dict_end, dimension=dimension ,grid=grid, seed=seed, svg_str=header_str, n_steps=n_steps
    );
    let (close_str: string) = str_from_literal('</svg>');
    let (svg_str) = str_concat(render_str, close_str);
    return (svg_str,);
}

func create_tokenURI{syscall_ptr: felt*, range_check_ptr}(seed: felt) -> (json_str: string) {
    alloc_locals;

    let (svg_str) = generate_character(
        seed=seed, dimension=BASE_DIM, bias=3, bg_color='#1E221F'
    );

    let (data_prefix_label) = get_label_location(dw_prefix);
    tempvar data_prefix = string(1, cast(data_prefix_label, felt*));

    let (data_xml_header_label) = get_label_location(dw_xml_header);
    tempvar data_xml_header = string(2, cast(data_xml_header_label, felt*));

    let (data_content_label) = get_label_location(dw_content);
    tempvar data_content = string(5, cast(data_content_label, felt*));

    let (data_end_label) = get_label_location(dw_end);
    tempvar data_end = string(1, cast(data_end_label, felt*));

    let (result) = str_concat(data_prefix, data_content);
    let (result) = str_concat(string(result.arr_len, result.arr), data_xml_header);
    let (result) = str_concat(string(result.arr_len, result.arr), svg_str);
    let (result) = str_concat(string(result.arr_len, result.arr), data_end);

    return (result,);

    dw_prefix:
    dw 'data:application/json,';

    dw_content:
    dw '{"name":"Cartridge Avatar",';
    dw '"description":"Starknet ';
    dw 'experience tracker",';
    dw '"image":';
    dw '"data:image/svg+xml,';

    dw_xml_header:
    dw '<?xml version=\"1.0\"';
    dw ' encoding=\"UTF-8\"?>';

    dw_end:
    dw '"}';
}
