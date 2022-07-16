# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_tx_info
from starkware.cairo.common.alloc import alloc

from openzeppelin.security.initializable import Initializable
from src.account.plugins.controller.library import Controller
from starkware.cairo.common.bool import (TRUE, FALSE)

from ec import EcPoint
from bigint import BigInt3
from examples.ecdsa import verify_ecdsa

const BASE = 2**86

struct CallArray:
    member to: felt
    member selector: felt
    member data_offset: felt
    member data_len: felt
end

@storage_var
func ec_point() -> (res: EcPoint):
end

@external
func initialize{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(x: BigInt3, y: BigInt3, public_key: felt):
    Initializable.initialized()
    ec_point.write(EcPoint(x, y))
    Controller.initializer(public_key)
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
        ecdsa_ptr: SignatureBuiltin*
    }(
        hash: felt,
        signature_len: felt,
        signature: felt*
    ) -> (is_valid: felt):
    alloc_locals
    
    let (pub_point) = ec_point.read()
    
    # split signatures into 3 values
    let sig_r = BigInt3(0,0,0)
    %{
        x = divmod(ids.signature[0], BASE)
        y = divmod(x[1], BASE)
        ids.sig_r.x = x[1]
        ids.sig_r.y = y[1]
        ids.sig_r.y = y[0]
    %}
    

    let sig_s = BigInt3(0,0,0)
    %{
        x = divmod(ids.signature[1], BASE)
        y = divmod(x[1], BASE)
        ids.sig_s.x = x[1]
        ids.sig_s.y = y[1]
        ids.sig_s.y = y[0]
    %}

    let hash_bigint3 = BigInt3(0,0,0)
    %{
        x = divmod(ids.hash, BASE)
        y = divmod(x[1], BASE)
        ids.sig_s.x = x[1]
        ids.sig_s.y = y[1]
        ids.sig_s.y = y[0]
    %}

    verify_ecdsa(
        public_key_pt=pub_point,
        msg_hash=hash_bigint3,
        r=sig_r,
        s=sig_s)

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
    alloc_locals

    # get the tx info
    let (tx_info) = get_tx_info()
    
    let (pub_point) = ec_point.read()

    # split signatures into 3 values
    let sig_r = BigInt3(0,0,0)
    %{
        x = divmod(ids.signature[0], BASE)
        y = divmod(x[1], BASE)
        ids.sig_r.x = x[1]
        ids.sig_r.y = y[1]
        ids.sig_r.y = y[0]
    %}
    

    let sig_s = BigInt3(0,0,0)
    %{
        x = divmod(ids.signature[1], BASE)
        y = divmod(x[1], BASE)
        ids.sig_s.x = x[1]
        ids.sig_s.y = y[1]
        ids.sig_s.y = y[0]
    %}

    let hash_bigint3 = BigInt3(0,0,0)
    # todo: hash transaction into sha256 and split
    # %{
    #     x = divmod(hash, BASE)
    #     y = divmod(x[1], BASE)
    #     ids.sig_s.x = x[1]
    #     ids.sig_s.y = y[1]
    #     ids.sig_s.y = y[0]
    # %}

    verify_ecdsa(
        public_key_pt=pub_point,
        msg_hash=hash_bigint3,
        r=sig_r,
        s=sig_s)

    return ()
end
