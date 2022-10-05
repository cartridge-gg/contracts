// https://raw.githubusercontent.com/topology-gg/caistring/9980eb42a889beaf1ebadb21965a92471fcb1f92/contracts/str.cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (
    unsigned_div_rem,
    sign,
    assert_nn,
    abs_value,
    assert_not_zero,
    sqrt,
)
from starkware.cairo.common.math_cmp import is_nn, is_le, is_not_zero
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc

from src.util.array import array_concat

//
// Define the string struct
//
struct string {
    arr_len: felt,
    arr: felt*,
}

//
// Concatenate two strings
//
func str_concat{range_check_ptr}(str1: string, str2: string) -> (res: string) {
    let (arr_res_len: felt, arr_res: felt*) = array_concat(
        arr1_len=str1.arr_len, arr1=str1.arr, arr2_len=str2.arr_len, arr2=str2.arr
    );

    return (string(arr_res_len, arr_res),);
}

func _recurse_str_concat_array{range_check_ptr}(
    arr_str_len: felt, arr_str: string*, arr_len: felt, arr: felt*, idx: felt
) -> (arr_final_len: felt, arr_final: felt*) {
    if (idx == arr_str_len) {
        return (arr_len, arr);
    }

    let (arr_nxt_len: felt, arr_nxt: felt*) = array_concat(
        arr1_len=arr_len, arr1=arr, arr2_len=arr_str[idx].arr_len, arr2=arr_str[idx].arr
    );

    //
    // Tail recursion
    //
    let (arr_final_len: felt, arr_final: felt*) = _recurse_str_concat_array(
        arr_str_len=arr_str_len, arr_str=arr_str, arr_len=arr_nxt_len, arr=arr_nxt, idx=idx + 1
    );

    return (arr_final_len, arr_final);
}

//
// Create an instance of string from single-felt string literal
//
func str_from_literal{range_check_ptr}(literal: felt) -> (str: string) {
    let len = 1;
    let (arr: felt*) = alloc();
    assert arr[0] = literal;

    return (string(len, arr),);
}

//
// Convert felt (decimal integer) into ascii-encoded felt representing str(felt); return a literal
// e.g. 7 => interpreted as '7', return 55
// e.g. 77 => interpreted as '77', return 55*256 + 55 = 14135
// fail if needed more than 31 characters
//
func literal_from_number{range_check_ptr}(num: felt) -> (literal: felt) {
    alloc_locals;

    //
    // Handle special case first
    //
    if (num == 0) {
        return ('0',);
    }

    let (arr_ascii) = alloc();
    let (arr_ascii_len: felt) = _recurse_ascii_array_from_number(
        remain=num, arr_ascii_len=0, arr_ascii=arr_ascii
    );

    let (ascii) = _recurse_ascii_from_ascii_array_inverse(
        ascii=0, len=arr_ascii_len, arr=arr_ascii, idx=0
    );

    return (ascii,);
}

func _recurse_ascii_array_from_number{range_check_ptr}(
    remain: felt, arr_ascii_len: felt, arr_ascii: felt*
) -> (arr_ascii_final_len: felt) {
    alloc_locals;

    if (remain == 0) {
        return (arr_ascii_len,);
    }

    let (remain_nxt, digit) = unsigned_div_rem(remain, 10);
    let (ascii) = ascii_from_digit(digit);
    assert arr_ascii[arr_ascii_len] = ascii;

    //
    // Tail recursion
    //
    let (arr_ascii_final_len) = _recurse_ascii_array_from_number(
        remain=remain_nxt, arr_ascii_len=arr_ascii_len + 1, arr_ascii=arr_ascii
    );
    return (arr_ascii_final_len,);
}

func _recurse_ascii_from_ascii_array_inverse{range_check_ptr}(
    ascii: felt, len: felt, arr: felt*, idx: felt
) -> (ascii_final: felt) {
    if (idx == len) {
        return (ascii,);
    }

    let ascii_nxt = ascii * 256 + arr[len - idx - 1];

    //
    // Tail recursion
    //
    let (ascii_final) = _recurse_ascii_from_ascii_array_inverse(
        ascii=ascii_nxt, len=len, arr=arr, idx=idx + 1
    );
    return (ascii_final,);
}

//
// Get ascii in decimal value from given digit
// note: does not check if input is indeed a digit
//
func ascii_from_digit(digit: felt) -> (ascii: felt) {
    return (digit + '0',);
}
