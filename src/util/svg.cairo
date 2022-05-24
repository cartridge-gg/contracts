# https://raw.githubusercontent.com/topology-gg/caistring/9980eb42a889beaf1ebadb21965a92471fcb1f92/contracts/Svg.cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import unsigned_div_rem, split_felt
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_caller_address

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

    # literal/str_from_number only supports integer for now
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
    assert arr[4] = '" w="'
    assert arr[5] = w_literal
    assert arr[6] = '" h="'
    assert arr[7] = h_literal
    assert arr[8] = '" fill="'
    assert arr[9] = svg_rect.fill
    assert arr[10] = '" />'

    return (string(11, arr))
end

struct Cell:
    member row : felt
    member col : felt
    member val : felt
end

func init_cell_list{range_check_ptr}(cell_list : Cell*, seed, n_steps, initialized_cell_list : Cell*) -> (initialized_cell_list : Cell*):
    if n_steps == 0:
        return (initialized_cell_list=initialized_cell_list)
    end

    let (prob, _) = unsigned_div_rem(seed, n_steps + 1)
    let (_, event) = unsigned_div_rem(prob, 2)

    assert initialized_cell_list.row = cell_list.row
    assert initialized_cell_list.col = cell_list.col


    # if event == 1:
    assert initialized_cell_list.val = 1
    tempvar range_check_ptr = range_check_ptr
    # else:
    #     tempvar range_check_ptr = range_check_ptr
    # end


    return init_cell_list(cell_list=cell_list + Cell.SIZE, seed=seed, n_steps=n_steps - 1, initialized_cell_list=initialized_cell_list + Cell.SIZE)
end

func render{range_check_ptr}(cell_list : Cell*, svg_str : string, n_steps) -> (svg_str : string):
    alloc_locals

    if n_steps == 0:
        return (svg_str=svg_str)
    end

    tempvar range_check_ptr = range_check_ptr

    if cell_list.val == 0:
        tempvar fill = '#000'
    else:
        tempvar fill = '#fff'
    end

    let x_offset = 40 * cell_list.row
    let y_offset = 40 * cell_list.col

    let (x_fp2) = numfp2_from_felt(x_offset)
    let (y_fp2) = numfp2_from_felt(y_offset)
    let (wh_fp2) = numfp2_from_felt(40)

    let svg_rect = SvgRect(x=x_fp2, y=y_fp2, w=wh_fp2, h=wh_fp2, fill=fill)
    let (rect_str : string) = str_from_svg_rect(svg_rect)
    let (next_svg_str) = str_concat(svg_str, rect_str)

    return render(cell_list=cell_list + Cell.SIZE, svg_str=next_svg_str, n_steps=n_steps - 1)
end

func generate_character{syscall_ptr : felt*, range_check_ptr}() -> (svg_str : string):
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
        Cell(row=0, col=0, val=0),
        Cell(row=0, col=1, val=0),
        Cell(row=0, col=2, val=0),
        Cell(row=0, col=3, val=0),
        Cell(row=1, col=0, val=0),
        Cell(row=1, col=1, val=0),
        Cell(row=1, col=2, val=0),
        Cell(row=1, col=3, val=0),
        Cell(row=2, col=0, val=0),
        Cell(row=2, col=1, val=0),
        Cell(row=2, col=2, val=0),
        Cell(row=2, col=3, val=0),
        Cell(row=3, col=0, val=0),
        Cell(row=3, col=1, val=0),
        Cell(row=3, col=2, val=0),
        Cell(row=3, col=3, val=0),
        Cell(row=4, col=0, val=0),
        Cell(row=4, col=1, val=0),
        Cell(row=4, col=2, val=0),
        Cell(row=4, col=3, val=0),
        Cell(row=5, col=0, val=0),
        Cell(row=5, col=1, val=0),
        Cell(row=5, col=2, val=0),
        Cell(row=5, col=3, val=0),
        Cell(row=6, col=0, val=0),
        Cell(row=6, col=1, val=0),
        Cell(row=6, col=2, val=0),
        Cell(row=6, col=3, val=0),
        Cell(row=7, col=0, val=0),
        Cell(row=7, col=1, val=0),
        Cell(row=7, col=2, val=0),
        Cell(row=7, col=3, val=0),
        )

    let (__fp__, _) = get_fp_and_pc()
    let (user_id) = get_caller_address()
    let (left, right) = split_felt(user_id)

    let (local empty_cell_list : Cell*) = alloc()

    let (initialized_cell_list) = init_cell_list(
        cell_list=cast(&grid_tuple, Cell*), seed=right, n_steps=30, initialized_cell_list=empty_cell_list
    )

    # On a canvas of 300 x 300,
    let (header_str : string) = return_svg_header(320, 320)
    let (render_str : string) = render(
        cell_list=initialized_cell_list, svg_str=header_str, n_steps=2
    )
    let (close_str : string) = str_from_literal('</svg>')
    let (svg_str) = str_concat(render_str, close_str)
    return (svg_str)
end
