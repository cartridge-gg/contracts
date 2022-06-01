# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_tx_info

from openzeppelin.account.library import AccountCallArray
from src.account.plugins.signer.library import Signer
from openzeppelin.security.initializable import Initializable

@external
func initialize{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(public_key: felt):
    Initializable.initialize()
    Signer.initializer(public_key)
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
    let (res) = Signer.get_public_key()
    return (res=res)
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
    Signer.set_public_key(new_public_key)
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
    ) -> ():
    Signer.is_valid_signature(hash, signature_len, signature)
    return ()
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
    call_array: AccountCallArray*,
    calldata_len: felt,
    calldata: felt*
    ):
    alloc_locals

    # get the tx info
    let (tx_info) = get_tx_info()
    is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature)

    return()
end
