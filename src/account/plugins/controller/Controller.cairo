# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.starknet.common.syscalls import get_tx_info
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.initializable import Initializable
from src.account.plugins.controller.library import Controller
from starkware.cairo.common.bool import (TRUE, FALSE)

from ec import EcPoint

const BASE = 2**86

struct CallArray:
    member to: felt
    member selector: felt
    member data_offset: felt
    member data_len: felt
end

@external
func initialize{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(pt: EcPoint, public_key: felt):
    Initializable.initialized()
    Controller.initializer(pt, public_key)
    return ()
end

#
# Getters
#

@view
func is_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(public_key: felt) -> (res: felt):
    let (res) = Controller.is_public_key(public_key)
    return (res=res)
end

#
# Setters
#

@external
func add_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(new_public_key: felt):
    Controller.add_public_key(new_public_key)
    return ()
end

@external
func remove_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(public_key: felt):    
    Controller.remove_public_key(public_key)
    return ()
end

#
# Business logic
#

@view
func is_valid_signature{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        ecdsa_ptr: SignatureBuiltin*,
        bitwise_ptr : BitwiseBuiltin*
    }(
        hash: felt,
        signature_len: felt,
        signature: felt*
    ) -> (is_valid: felt):
    alloc_locals

    let (is_valid) = Controller.is_valid_signature(hash, signature_len, signature)
    return (is_valid=is_valid)
end

@external
func validate{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        ecdsa_ptr: SignatureBuiltin*,
        bitwise_ptr : BitwiseBuiltin*
    }(
    plugin_data_len: felt,
    plugin_data: felt*,
    call_array_len: felt,
    call_array: CallArray*,
    calldata_len: felt,
    calldata: felt*
    ):
    let (tx_info) = get_tx_info()
    is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature)
    return ()
end
