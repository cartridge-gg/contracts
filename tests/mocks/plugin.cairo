# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.bool import TRUE

from openzeppelin.security.initializable.library import Initializable

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
    }():
    return ()
end

#
# Getters
#

@view
func get_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    return (res=1)
end

#
# Setters
#

@external
func set_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(new_public_key: felt):
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
        ecdsa_ptr: SignatureBuiltin*
    }(
        hash: felt,
        signature_len: felt,
        signature: felt*
    ) -> (is_valid: felt):
    return (is_valid=TRUE)
end

@external
func validate{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        ecdsa_ptr: SignatureBuiltin*
    }(
    plugin_data_len: felt,
    plugin_data: felt*,
    call_array_len: felt,
    call_array: CallArray*,
    calldata_len: felt,
    calldata: felt*
    ):
    return()
end
