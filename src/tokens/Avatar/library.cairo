# https://raw.githubusercontent.com/topology-gg/caistring/9980eb42a889beaf1ebadb21965a92471fcb1f92/contracts/Svg.cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt, assert_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.math_cmp import is_le

from src.util.str import string, literal_from_number, str_from_literal, str_concat

#
# fixed-point number with 2 decimal points
#
struct NumFp2:
    member val : felt
end

struct TupleNumFp2:
    member x : NumFp2
    member y : NumFp2
end

struct SvgRect:
    member x : NumFp2
    member y : NumFp2
    member w : NumFp2
    member h : NumFp2
    member fill : felt
end

###########################

func numfp2_from_felt{}(x : felt) -> (res : NumFp2):
    return (NumFp2(val=x * 100))
end

###########################

func return_svg_header{range_check_ptr}(w : felt, h : felt) -> (str : string):
    alloc_locals

    # Format:
    # <svg width="{w}" height="{h}" xmlns="http://www.w3.org/2000/svg">

    let (w_literal : felt) = literal_from_number(w)
    let (h_literal : felt) = literal_from_number(h)

    let (arr) = alloc()
    assert arr[0] = '<svg width="'
    assert arr[1] = w_literal
    assert arr[2] = '" height="'
    assert arr[3] = h_literal
    assert arr[4] = '" xmlns="http://www.w3.org/'
    assert arr[5] = '2000/svg">'

    return (string(6, arr))
end

func str_from_svg_rect{range_check_ptr}(svg_rect : SvgRect) -> (str : string):
    alloc_locals

    # Format:
    # <rect x="<x>" y="<y>" w="<w>" h="<h>" attribute_0="<attribute_0>" ... />

    let (x_rounded, _) = unsigned_div_rem(svg_rect.x.val, 100)
    let (y_rounded, _) = unsigned_div_rem(svg_rect.y.val, 100)
    let (w_rounded, _) = unsigned_div_rem(svg_rect.w.val, 100)
    let (h_rounded, _) = unsigned_div_rem(svg_rect.h.val, 100)

    let (x_literal) = literal_from_number(x_rounded)
    let (y_literal) = literal_from_number(y_rounded)
    let (w_literal) = literal_from_number(w_rounded)
    let (h_literal) = literal_from_number(h_rounded)

    let (arr) = alloc()
    assert arr[0] = '<rect x="'
    assert arr[1] = x_literal
    assert arr[2] = '" y="'
    assert arr[3] = y_literal
    assert arr[4] = '" width="'
    assert arr[5] = w_literal
    assert arr[6] = '" height="'
    assert arr[7] = h_literal
    assert arr[8] = '" fill="'
    assert arr[9] = svg_rect.fill
    assert arr[10] = '" />'

    return (string(11, arr))
end

struct Cell:
    member row : felt
    member col : felt
end

func init_cell_list{range_check_ptr}(cell_list : Cell*, seed, n_steps, dict : DictAccess*) -> (
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
        tempvar range_check_ptr = range_check_ptr
    else:
        assert dict.prev_value = 0
        assert dict.new_value = 0
        tempvar range_check_ptr = range_check_ptr
    end

    return init_cell_list(
        cell_list=cell_list + Cell.SIZE, seed=seed, n_steps=n_steps - 1, dict=dict + DictAccess.SIZE
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

func render{range_check_ptr}(dict : DictAccess*, cell_list : Cell*, svg_str : string, n_steps) -> (
    svg_str : string
):
    alloc_locals

    if n_steps == 0:
        return (svg_str=svg_str)
    end

    tempvar range_check_ptr = range_check_ptr

    let cell : Cell* = cell_list + (Cell.SIZE * dict.key)

    if dict.prev_value == 0:
        tempvar fill = '#000'
    else:
        tempvar fill = '#fff'
    end

    let (wh_fp2) = numfp2_from_felt(30)
    let y_offset = 30 * cell.row
    let (y_fp2) = numfp2_from_felt(y_offset)

    let x1_offset = 30 * cell.col
    let (x1_fp2) = numfp2_from_felt(x1_offset)

    tempvar fill = fill

    let svg_rect_left = SvgRect(x=x1_fp2, y=y_fp2, w=wh_fp2, h=wh_fp2, fill=fill)
    let (rect_str : string) = str_from_svg_rect(svg_rect_left)
    let (next_svg_str) = str_concat(svg_str, rect_str)

    let x2_offset = 270 - (30 * cell.col)
    let (x2_fp2) = numfp2_from_felt(x2_offset)

    let svg_rect_right = SvgRect(x=x2_fp2, y=y_fp2, w=wh_fp2, h=wh_fp2, fill=fill)
    let (rect_str : string) = str_from_svg_rect(svg_rect_right)
    let (final_svg_str) = str_concat(next_svg_str, rect_str)

    return render(
        dict=dict + DictAccess.SIZE, cell_list=cell_list, svg_str=final_svg_str, n_steps=n_steps - 1
    )
end

func generate_character{syscall_ptr : felt*, range_check_ptr}(seed: felt) -> (svg_str : string):
    alloc_locals

    local grid_tuple : (
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
        Cell,
    ) = (
        Cell(row=1, col=1), Cell(row=1, col=2), Cell(row=1, col=3), Cell(row=1, col=4),
        Cell(row=2, col=1), Cell(row=2, col=2), Cell(row=2, col=3), Cell(row=2, col=4),
        Cell(row=3, col=1), Cell(row=3, col=2), Cell(row=3, col=3), Cell(row=3, col=4),
        Cell(row=4, col=1), Cell(row=4, col=2), Cell(row=4, col=3), Cell(row=4, col=4),
        Cell(row=5, col=1), Cell(row=5, col=2), Cell(row=5, col=3), Cell(row=5, col=4),
        Cell(row=6, col=1), Cell(row=6, col=2), Cell(row=6, col=3), Cell(row=6, col=4),
        Cell(row=7, col=1), Cell(row=7, col=2), Cell(row=7, col=3), Cell(row=7, col=4),
        Cell(row=8, col=1), Cell(row=8, col=2), Cell(row=8, col=3), Cell(row=8, col=4),
        )

    let (__fp__, _) = get_fp_and_pc()

    let (local dict_start : DictAccess*) = alloc()
    let (local squashed_dict : DictAccess*) = alloc()

    assert_not_zero(seed)

    let (dict_end) = init_cell_list(
        cell_list=cast(&grid_tuple, Cell*), seed=seed, n_steps=32, dict=dict_start
    )

    let (squashed_dict_end : DictAccess*) = squash_dict(
        dict_accesses=dict_start, dict_accesses_end=dict_end, squashed_dict=squashed_dict
    )

    assert squashed_dict_end - squashed_dict = 32 *
        DictAccess.SIZE

    # On a canvas of 300 x 300,
    let (header_str : string) = return_svg_header(300, 300)
    let (render_str : string) = render(
        dict=squashed_dict, cell_list=cast(&grid_tuple, Cell*), svg_str=header_str, n_steps=32
    )
    let (close_str : string) = str_from_literal('</svg>')
    let (svg_str) = str_concat(render_str, close_str)
    return (svg_str)
end
