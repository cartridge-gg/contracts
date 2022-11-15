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
from starkware.cairo.common.math_cmp import is_le, is_nn, is_in_range
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.bool import TRUE, FALSE

from src.util.str import string, literal_from_number, str_from_literal, str_concat
from src.tokens.Avatar.progress import get_progress, Progress

struct CellType {
    EMPTY: felt,
    BASE: felt,
    BORDER: felt,
}

struct Cell {
    row: felt,
    col: felt,
}

struct SvgRect {
    x: felt,
    y: felt,
    fill: felt,
}

const BIAS = 3;         // approx area filled: 2 ~ 50%, 3 ~ 33%...
const SCALE = 10;       // scales avatar + padding
const PADDING = 4;      // padding around avatar
const MAX_ROW = 14;     // max px height of avatar
const MAX_COL = 7;      // max px width of avatar (half) 
const MAX_STEPS = MAX_ROW * MAX_COL;

//##########################

func return_svg_header{range_check_ptr}(bg_color: felt) -> (str: string) {
    alloc_locals;

    // Format:
    // <svg width={w*scale} height={h*scale} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" shape-rendering="crispEdges">
    let full_w = PADDING * 2 + MAX_ROW;
    let full_h = PADDING * 2 + MAX_ROW;
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
    seed: felt, n_steps: felt,  dict: DictAccess*
) -> (dict: DictAccess*) {

    if (n_steps == 0) {
        return (dict=dict);
    }

    let (prob, _) = unsigned_div_rem(seed, n_steps);
    let (_, event) = unsigned_div_rem(prob, BIAS);
    let key = MAX_STEPS - n_steps;
    
    if (event == 1) {
        dict_write{dict_ptr=dict}(key=key, new_value=CellType.BASE);
    } else {
        dict_write{dict_ptr=dict}(key=key, new_value=CellType.EMPTY);
    }

    return init_dict(
        seed=seed, n_steps=n_steps - 1, dict=dict
    );
}

func check_above{range_check_ptr}(
    key: felt, value: felt, dict: DictAccess*
) -> (above: felt, dict: DictAccess*) {

    let check = is_le(MAX_COL, key);
    if(check != 0) {
        let (above) = dict_read{dict_ptr=dict}(key=key - MAX_COL);
        if(above == value) {
            return (above=1, dict=dict);
        }
        return (above=0, dict=dict);
    }

    return (above=0, dict=dict);
}

func check_below{range_check_ptr}(
    key: felt, value: felt, dict: DictAccess*
) -> (below: felt, dict: DictAccess*) {

    let check = is_le(key, MAX_STEPS - MAX_COL);
    if(check != 0) {
        let (below) = dict_read{dict_ptr=dict}(key=key + MAX_COL);
        if(below == value) {
            return (below=1, dict=dict);
        }
        return (below=0, dict=dict);
    }

    return (below=0, dict=dict);
}

func check_left{range_check_ptr}(
    key: felt, value: felt, dict: DictAccess*
) -> (left: felt, dict: DictAccess*) {

    let (_, x) = unsigned_div_rem(key + MAX_COL, MAX_COL);
    if(x != 0) {
        let (left) = dict_read{dict_ptr=dict}(key=key - 1);
        if(left == value) {
            return (left=1, dict=dict);
        }
        return (left=0, dict=dict);
    }

    return (left=0, dict=dict);
}

func check_right{range_check_ptr}(
    key: felt, value: felt, dict: DictAccess*
) -> (right: felt, dict: DictAccess*) {

    let (_, x) = unsigned_div_rem(key + 1, MAX_COL);
    if(x != 0) {
        let (right) = dict_read{dict_ptr=dict}(key=key + 1);
        if(value == right) {
            return (right=1, dict=dict);
        }
        return (right=0, dict=dict);
    }

    return (right=0, dict=dict);
}

func num_neighbors{range_check_ptr}(
    key: felt, value: felt, dict: DictAccess*
) -> (neighbors: felt, dict: DictAccess*) {
    alloc_locals;

    let (above, dict) = check_above(key=key, value=value, dict=dict);
    let (below, dict) = check_below(key=key, value=value, dict=dict);
    let (left, dict) = check_left(key=key, value=value, dict=dict);
    let (right, dict) = check_right(key=key, value=value, dict=dict);

    return(neighbors=above + below + left + right, dict=dict);
}

func grow{range_check_ptr}(
    n_steps: felt, input: DictAccess*, output: DictAccess*
) -> (input: DictAccess*, output: DictAccess*) {
    if (n_steps == 0) {
        return (input=input, output=output);
    }

    let key = n_steps - 1;
    let (neighbors, input) = num_neighbors(key=key, value=1, dict=input);
    let (alive) = dict_read{dict_ptr=input}(key=key);

    if(alive == TRUE) {
        let continue = is_in_range(neighbors, 2, 4);

        if(continue == TRUE) {
            dict_write{dict_ptr=output}(key=key, new_value=CellType.BASE);
            return grow(n_steps=n_steps - 1, input=input, output=output);
        }

        dict_write{dict_ptr=output}(key=key, new_value=CellType.EMPTY);
        return grow(n_steps=n_steps - 1, input=input, output=output);
    } else {
        let rebirth = is_le(neighbors, 1);

        if(rebirth == TRUE) {
            dict_write{dict_ptr=output}(key=key, new_value=CellType.BASE);
            return grow(n_steps=n_steps - 1, input=input, output=output);
        }

        return grow(n_steps=n_steps - 1, input=input, output=output);
    }
}

func colors{range_check_ptr}() -> (base: felt*, size: felt) {
    let (base_addr) = get_label_location(base_start);
    return (base=cast(base_addr, felt*), size=8);

    base_start:
    dw '#EBBCFB';
    dw '#A7E7DB';
    dw '#EE985F';
    dw '#B5EE5F';
    dw '#5FEEBB';
    dw '#EC5146';
    dw '#EE5FA4';
}

func get_color{range_check_ptr}(
    seed: felt, event: felt
) -> (color: felt) {
    alloc_locals;

    let (base, size) = colors();
    let (_, idx) = unsigned_div_rem(seed, size);

    if(event == CellType.BORDER) {
        return (color='rgba(255,255,255,0.08)');
    }
    return (color=base[idx]);
}

func contains{range_check_ptr}(
    dimension: felt, cell: Cell*
) -> (inside: felt) {

    let (padding, _) = unsigned_div_rem(MAX_ROW - dimension, 2);
    let side = is_le(padding, cell.col - 1);
    let top = is_le(padding, cell.row - 1);
    let bottom = is_le(cell.row - 1, padding + dimension - 1);

    if(top != 0 and bottom != 0 and side != 0) {
        return (inside=TRUE);
    }

    return (inside=FALSE);
}

func crop{range_check_ptr}(
    dict: DictAccess*, dimension: felt, grid: Cell*, n_steps: felt
) -> (dict: DictAccess*) {
    alloc_locals;

    if(n_steps == 0) {
        return(dict=dict);
    }

    let key = n_steps - 1;
    let (local event) = dict_read{dict_ptr=dict}(key=key);
    let cell: Cell* = grid + (Cell.SIZE * key);
    let (inside) = contains(dimension, cell);

    if(event == CellType.BASE and inside != TRUE) {
        dict_write{dict_ptr=dict}(key=key, new_value=0);
        return crop(dict=dict, dimension=dimension, grid=grid, n_steps=n_steps - 1);
    }

    return crop(dict=dict, dimension=dimension, grid=grid, n_steps=n_steps - 1);
}

func add_border{range_check_ptr}(
    dict: DictAccess*, n_steps: felt, border: felt
) -> (dict: DictAccess*) {
    alloc_locals; 

    if(border == FALSE) {
        return (dict=dict);
    }

    if(n_steps == 0) {
        return (dict=dict);
    }
    
    let key = n_steps - 1;

    let (local event) = dict_read{dict_ptr=dict}(key=key);
    let (neighbors, dict) = num_neighbors(key=key, value=1, dict=dict);

    if(event == CellType.EMPTY and neighbors != 0) {
        dict_write{dict_ptr=dict}(key=key, new_value=CellType.BORDER);
        return add_border(dict=dict, n_steps=n_steps - 1, border=border);
    }

    return add_border(dict=dict, n_steps=n_steps - 1, border=border);
}

func render{range_check_ptr}(
    dict: DictAccess*, grid: Cell*, seed: felt, svg_str: string, n_steps: felt
) -> (svg_str: string) {
    alloc_locals;

    if (n_steps == 0) {
        return (svg_str=svg_str);
    }

    let key = n_steps - 1;
    let (local event) = dict_read{dict_ptr=dict}(key=key);
    let cell: Cell* = grid + (Cell.SIZE * key);
    
    if(event != CellType.EMPTY) {
        let (color) = get_color(seed, event);

        let svg_rect_left = SvgRect(x=cell.col - 1, y=cell.row - 1, fill=color);
        let (rect_str: string) = str_from_svg_rect(svg_rect_left);
        let (next_svg_str) = str_concat(svg_str, rect_str);

        let mirror_x = (MAX_ROW + 1) - cell.col;

        let svg_rect_right = SvgRect(x=mirror_x - 1, y=cell.row - 1, fill=color);
        let (rect_str: string) = str_from_svg_rect(svg_rect_right);
        let (final_svg_str) = str_concat(next_svg_str, rect_str);
        return render(
            dict=dict, grid=grid, seed=seed, svg_str=final_svg_str, n_steps=n_steps - 1
        );
    }

    return render(
        dict=dict, grid=grid, seed=seed, svg_str=svg_str, n_steps=n_steps - 1
    );
}

func create_grid{syscall_ptr: felt*, range_check_ptr}(row: felt, col: felt) -> (grid: Cell*) {
    alloc_locals;

    let (local grid_start: Cell*) = alloc();
    grid_loop(col_max=col, row=row, col=col, grid=grid_start);

    return (grid_start,);
}

func grid_loop{syscall_ptr: felt*, range_check_ptr}(
    col_max: felt, row: felt, col: felt, grid: Cell*
) -> (grid_end: Cell*) {
    alloc_locals;

    if (col == 0 and row == 1) {
        return (grid_end=grid);
    }

    if (col != 0) {
        assert grid[0] = Cell(row=row, col=col);
        return grid_loop(col_max=col_max, row=row, col=col - 1, grid=grid + Cell.SIZE);
    }

    if (row != 1) {
        assert grid[0] = Cell(row=row - 1, col=col_max);
        return grid_loop(col_max=col_max, row=row - 1, col=col_max - 1, grid=grid + Cell.SIZE);
    }

    return (grid_end=grid);
}

func get_fingerprint{syscall_ptr: felt*, range_check_ptr}(
    dict: DictAccess*,
    data: felt,
    n_steps: felt,
) -> (dict: DictAccess*, fingerprint: felt) {

    if (n_steps == 0) {
        return (dict=dict, fingerprint=data);
    }

    let key = MAX_STEPS - n_steps;
    let (event) = dict_read{dict_ptr=dict}(key=key);
    let data = (data * 2) + event;  // shift right one bit

    return get_fingerprint(dict=dict, data=data, n_steps=n_steps-1);
}

func evolve{syscall_ptr: felt*, range_check_ptr}(
    iterations: felt, input: DictAccess*, output: DictAccess*
) -> (input: DictAccess*, output: DictAccess*) {
    if(iterations == 0) {
        return(input=output, output=input);
    }
    
    let (input, output) = grow(
        n_steps=MAX_STEPS, input=input, output=output
    );

    return evolve(iterations=iterations-1, input=output, output=input);
}

func init_character{syscall_ptr: felt*, range_check_ptr}(
    seed: felt, evolution: felt
) -> (dict: DictAccess*) {
    alloc_locals;

    let (local one_start) = default_dict_new(default_value=CellType.EMPTY);
    let (local two_start) = default_dict_new(default_value=CellType.EMPTY);

    let two_end = two_start;
    let (one_end) = init_dict(
        seed=seed, n_steps=MAX_STEPS, dict=one_start
    );

    let (_, output) = evolve(iterations=evolution, input=one_end, output=two_end);

    return (dict=output);
}

func generate_str{syscall_ptr: felt*, range_check_ptr}(
    seed: felt, evolution: felt, dimension: felt, border: felt, bg_color: felt
) -> (svg_str: string, attr_str: string) {
    alloc_locals;

    let (grid: Cell*) = create_grid(row=MAX_ROW, col=MAX_COL);

    let (dict: DictAccess*) = init_character(seed=seed, evolution=evolution);
    let (dict: DictAccess*) = crop(dict=dict, dimension=dimension, grid=grid, n_steps=MAX_STEPS);
    let (dict: DictAccess*) = add_border(dict=dict, n_steps=MAX_STEPS, border=border);
    let (dict, fingerprint) = get_fingerprint(dict=dict, data=0, n_steps=MAX_STEPS);

    let (dimension_) = literal_from_number(dimension);
    let (fingerprint_) = literal_from_number(fingerprint);

    let (header_str: string) = return_svg_header(bg_color=bg_color);
    let (body_str: string) = render(
        dict=dict, 
        grid=grid, 
        seed=seed, 
        svg_str=header_str, 
        n_steps=MAX_STEPS
    );

    let (close_str: string) = str_from_literal('</svg>');
    let (svg_str: string) = str_concat(body_str, close_str);

    let (base_color) = get_color(seed, CellType.BASE);
    local border_color;
    if(border == FALSE) {
        border_color = 'none';
    } else {
        let (b) = get_color(seed, CellType.BORDER);
        border_color = b;
    }
    
    let (attr_str) = alloc();
    assert attr_str[0] = '","attributes":[{"trait_type":';
    assert attr_str[1] = '"Base Color","value":"';
    assert attr_str[2] = base_color;
    assert attr_str[3] = '"},{"trait_type":"Border Color"';
    assert attr_str[4] = ',"value":"';
    assert attr_str[5] = border_color;
    assert attr_str[6] = '"},{"trait_type":"Background ';
    assert attr_str[7] = 'Color", "value":"';
    assert attr_str[8] = bg_color;
    assert attr_str[9] = '"},{"trait_type":"Dimension"';
    assert attr_str[10] = ',"value":"';
    assert attr_str[11] = dimension_;
    assert attr_str[12] = '"},{"trait_type":"Fingerprint"';
    assert attr_str[13] = ',"value":"';
    assert attr_str[14] = fingerprint_;
    assert attr_str[15] = '"}]';

    return (svg_str=svg_str, attr_str=string(16,attr_str));
}

func create_tokenURI{syscall_ptr: felt*, range_check_ptr}(
    seed: felt, 
    progress: Progress
) -> (
    json_str: string
) {
    alloc_locals;
    
    assert_not_zero(seed);

    let (svg_str, attr_str) = generate_str(
        seed=seed, 
        evolution=progress.evolution,
        dimension=progress.dimension, 
        border=progress.border,
        bg_color=progress.bg_color,
    );

    let (data_prefix_label) = get_label_location(dw_prefix);
    tempvar data_prefix = string(1, cast(data_prefix_label, felt*));

    let (data_xml_header_label) = get_label_location(dw_xml_header);
    tempvar data_xml_header = string(2, cast(data_xml_header_label, felt*));

    let (data_content_label) = get_label_location(dw_content);
    tempvar data_content = string(5, cast(data_content_label, felt*));

    let (end_str) = str_from_literal('}');

    let (result) = str_concat(data_prefix, data_content);
    let (result) = str_concat(string(result.arr_len, result.arr), data_xml_header);
    let (result) = str_concat(string(result.arr_len, result.arr), svg_str);
    let (result) = str_concat(string(result.arr_len, result.arr), attr_str);
    let (result) = str_concat(string(result.arr_len, result.arr), end_str);

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
}
