# https://raw.githubusercontent.com/topology-gg/caistring/9980eb42a889beaf1ebadb21965a92471fcb1f92/contracts/Svg.cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt, assert_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.math_cmp import is_le, is_nn
from starkware.cairo.common.registers import get_label_location

from src.util.str import string, literal_from_number, str_from_literal, str_concat

struct Cell:
    member row : felt
    member col : felt
end

struct SvgRect:
    member x : felt
    member y : felt
    member fill : felt
end

###########################

func return_svg_header{range_check_ptr}(w : felt, h : felt) -> (str : string):
    alloc_locals

    # Format:
    # <svg width="300" height="300" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" shape-rendering="crispEdges">

    let (w_literal : felt) = literal_from_number(w)
    let (h_literal : felt) = literal_from_number(h)

    let (arr) = alloc()
    assert arr[0] = '<svg width=\"'
    assert arr[1] = '300'
    assert arr[2] = '\" height=\"'
    assert arr[3] = '300'
    assert arr[4] = '\" xmlns=\"http://www.w3.org/'
    assert arr[5] = '2000/svg\" viewBox=\"0 0 '
    assert arr[6] = w_literal
    assert arr[7] = ' '
    assert arr[8] = h_literal
    assert arr[9] = '\" shape-rendering='
    assert arr[10] = '\"crispEdges\">'

    return (string(11, arr))
end

func str_from_svg_rect{range_check_ptr}(svg_rect : SvgRect) -> (str : string):
    alloc_locals

    # Format:
    # <rect x="<x>" y="<y>" w="1" h="1" attribute_0="<attribute_0>" ... />

    let (x_literal : felt) = literal_from_number(svg_rect.x)
    let (y_literal : felt) = literal_from_number(svg_rect.y)

    let (arr) = alloc()
    assert arr[0] = '<rect x=\"'
    assert arr[1] = x_literal
    assert arr[2] = '\" y=\"'
    assert arr[3] = y_literal
    assert arr[4] = '\" width=\"1\"'
    assert arr[6] = '\" height=\"1\"'
    assert arr[8] = '\" fill=\"'
    assert arr[9] = svg_rect.fill
    assert arr[10] = '\" />'

    return (string(11, arr))
end

func init_dict{range_check_ptr}(seed, n_steps, dict : DictAccess*) -> (
    dict : DictAccess*
):
    if n_steps == 0:
        return (dict=dict)
    end

    let (prob, _) = unsigned_div_rem(seed, n_steps + 1)
    let (_, event) = unsigned_div_rem(prob, 2)

    assert dict.key = 32 - n_steps

    if event == 0:
        assert dict.prev_value = 1
        assert dict.new_value = 1
    else:
        assert dict.prev_value = 0
        assert dict.new_value = 0
    end

    return init_dict(
        seed=seed, n_steps=n_steps - 1, dict=dict + DictAccess.SIZE
    )
end

func num_neighbors{range_check_ptr}(cell_list : Cell*, n_steps, dict : DictAccess*) -> (num: felt):
    alloc_locals

    local above
    local below
    local left
    local right

    let (check_above) = is_le(n_steps, 3)
    if check_above != 0:
        let cell : DictAccess* = dict + (DictAccess.SIZE * 4)
        above = cell.prev_value
    end

    let (check_below) = is_le(28, n_steps)
    if check_below != 0:
        let cell : DictAccess* = dict - (DictAccess.SIZE * 4)
        below = cell.prev_value
    end
    
    let (_, x) = unsigned_div_rem(n_steps, 4)

    let (check_left) = is_le(0, x)
    if check_left != 0:
        let cell : DictAccess* = dict - DictAccess.SIZE
        left = cell.prev_value
    end

    let (check_right) = is_le(x, 3)
    if check_right != 0:
        let cell : DictAccess* = dict + DictAccess.SIZE
        right = cell.prev_value
    end

    let n = above + below + left + right
    return (num=n)
end

func grow{range_check_ptr}(cell_list : Cell*, n_steps, dict : DictAccess*) -> (
    dict : DictAccess*
):
    if n_steps == 0:
        return (dict=dict)
    end

    let (prob, _) = unsigned_div_rem(0, n_steps + 1)
    let (_, event) = unsigned_div_rem(prob, 2)

    assert dict.key = 32 - n_steps

    if event == 0:
        assert dict.prev_value = 1
        assert dict.new_value = 1
        tempvar range_check_ptr = range_check_ptr
    else:
        assert dict.prev_value = 0
        assert dict.new_value = 0
        tempvar range_check_ptr = range_check_ptr
    end

    return grow(
        cell_list=cell_list + Cell.SIZE, n_steps=n_steps - 1, dict=dict + DictAccess.SIZE
    )
end

func render{range_check_ptr}(dict : DictAccess*, grid : Cell*, svg_str : string, n_steps) -> (
    svg_str : string
):
    alloc_locals

    if n_steps == 0:
        return (svg_str=svg_str)
    end

    let cell : Cell* = grid + (Cell.SIZE * dict.key)

    if dict.prev_value == 0:
        let fill = '#FBCB4A' # brand color

        # let svg_rect_left = SvgRect(x=cell.row, y=cell.col, fill=fill)
        # let (rect_str : string) = str_from_svg_rect(svg_rect_left)
        # let (next_svg_str) = str_concat(svg_str, rect_str)

        # let mirror_x = 7 - cell.col

        # let svg_rect_right = SvgRect(x=mirror_x, y=cell.col, fill=fill)
        # let (rect_str : string) = str_from_svg_rect(svg_rect_right)
        # let (final_svg_str) = str_concat(next_svg_str, rect_str)
        return render(
            dict=dict + DictAccess.SIZE, grid=grid, svg_str=svg_str, n_steps=n_steps - 1
        )
    else:
        return render(
            dict=dict + DictAccess.SIZE, grid=grid, svg_str=svg_str, n_steps=n_steps - 1
        )
    end
end

func create_grid{syscall_ptr : felt*, range_check_ptr}(row: felt, col: felt, grid: Cell*, grid_start: Cell*) -> (
    grid_end : Cell*
):
    alloc_locals

    if row == 0 and col == 0:
        return (grid_end=grid)
    end
    
    if row != 0:
        assert grid[0] = Cell(row=row, col=col)
        return create_grid(row=row - 1, col=col, grid=grid + Cell.SIZE, grid_start=grid_start)
    end

    if col != 0:
        assert grid[0] = Cell(row=grid_start.row, col=col)
        return create_grid(row=grid_start.row, col=col - 1, grid=grid + Cell.SIZE, grid_start=grid_start)
    end

    # unreachable code but required as 'else' is not yet supported in base case condition
    return (grid_end=grid)
end

func generate_character{syscall_ptr : felt*, range_check_ptr}(seed: felt) -> (svg_str : string):
    alloc_locals
    
    let (__fp__, _) = get_fp_and_pc()

    let (local dict_start : DictAccess*) = alloc()
    let (local squashed_dict : DictAccess*) = alloc()
    let (local grid_start : Cell*) = alloc()

    let (dict_end) = init_dict(
        seed=seed, n_steps=32, dict=dict_start
    )

    let (squashed_dict_end : DictAccess*) = squash_dict(
        dict_accesses=dict_start, dict_accesses_end=dict_end, squashed_dict=squashed_dict
    )

    assert squashed_dict_end - squashed_dict = 32 *
        DictAccess.SIZE

    let (grid_end : Cell*) = create_grid(row=8, col=4, grid=grid_start, grid_start=grid_start)

    # On a canvas of 300 x 300,
    let (header_str : string) = return_svg_header(8, 8)
    let (render_str : string) = render(
        dict=squashed_dict, grid=grid_start, svg_str=header_str, n_steps=32
    )
    let (close_str : string) = str_from_literal('</svg>')
    let (svg_str) = str_concat(render_str, close_str)
    return (svg_str)
end



func create_tokenURI{
    syscall_ptr : felt*, 
    range_check_ptr}(seed: felt
) -> (
    json_str: string):
    alloc_locals

    assert_not_zero(seed)
 
    let (svg_str) = generate_character(seed)

    let (data_prefix_label) = get_label_location(dw_prefix)
    tempvar data_prefix = string(1, cast(data_prefix_label, felt*))

    let (data_xml_header_label) = get_label_location(dw_xml_header)
    tempvar data_xml_header = string(2, cast(data_xml_header_label, felt*))

    let (data_content_label) = get_label_location(dw_content)
    tempvar data_content = string(6, cast(data_content_label, felt*))

    let (data_end_label) = get_label_location(dw_end)
    tempvar data_end = string(1, cast(data_end_label, felt*))

    let (result) = str_concat(data_prefix, data_content)
    let (result) = str_concat(string(result.arr_len, result.arr), data_xml_header)
    let (result) = str_concat(string(result.arr_len, result.arr), svg_str)
    let (result) = str_concat(string(result.arr_len, result.arr), data_end)

    return (result)

    dw_prefix:
    dw 'data:application/json,'

    dw_content:
    # TODO: official name and description
    # dw '{"name":"Cartridge '
    # dw 'Profile Avatar",'
    # dw '"description":"A '
    # dw 'progressive Avatar NFT",'
    dw '{"name":"test",'
    dw '"description":"test",'
    dw '"image":'
    dw '"data:image/svg+xml,'

    dw_xml_header:
    dw '<?xml version=\"1.0\"'
    dw ' encoding=\"UTF-8\"?>'

    dw_end:
    dw '"}'

end