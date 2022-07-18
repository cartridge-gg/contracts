%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_tx_info
from starkware.cairo.common.bool import (TRUE, FALSE)
from starkware.cairo.common.math import assert_not_zero

from src.account.IPlugin import IPlugin
from ec import EcPoint
from bigint import BigInt3
from examples.ecdsa import verify_ecdsa

const BASE = 2**86

#
# Storage
#

@storage_var
func Controller_public_key(pub: felt) -> (res: felt):
end

@storage_var
func Controller_p256_point() -> (res: EcPoint):
end


namespace Controller:

    #
    # Initializer
    #

    func initializer{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(_pt: EcPoint, _public_key: felt):
        Controller_p256_point.write(_pt)
        Controller_public_key.write(_public_key, 1)
        return()
    end

    #
    # Guards
    #

    func assert_only_self{syscall_ptr : felt*}():
        let (self) = get_contract_address()
        let (caller) = get_caller_address()
        with_attr error_message("Account: caller is not this account"):
            assert self = caller
        end
        return ()
    end

    #
    # Getters
    #

    func is_public_key{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(public_key: felt) -> (res: felt):
        let (res) = Controller_public_key.read(public_key)
        return (res=res)
    end

    #
    # Setters
    #

    func add_public_key{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(new_public_key: felt):
        assert_only_self()
        Controller_public_key.write(new_public_key, 1)
        return ()
    end

    func remove_public_key{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(public_key: felt):
        assert_only_self()
        
        with_attr error_message("invalid public key"):
            let (valid) = is_public_key(public_key)
            assert_not_zero(valid)
        end

        Controller_public_key.write(public_key, 0)
        return ()
    end

    #
    # Business logic
    #

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

        if signature[0] == 0:
            let (pub_pt) = Controller_p256_point.read()

            # split signatures into 3 values
            let sig_r0 = BigInt3(signature[1], signature[2], signature[3])
            let sig_s0 = BigInt3(signature[4], signature[5], signature[6])

            let hash_bigint3 = BigInt3(0, 0, 0)
            # %{
            #     x = divmod(ids.hash, BASE)
            #     y = divmod(x[1], BASE)
            #     ids.sig_s0.x = x[1]
            #     ids.sig_s0.y = y[1]
            #     ids.sig_s0.y = y[0]
            # %}

            verify_ecdsa(
                public_key_pt=pub_pt,
                msg_hash=hash_bigint3,
                r=sig_r0,
                s=sig_s0)

            return (is_valid=TRUE)
        else:

            # This interface expects a signature pointer and length to make
            # no assumption about signature validation schemes.
            # But this implementation does, and it expects a (pub, sig_r, sig_s) tuple.
            let public_key = signature[0]
            let sig_r = signature[1]
            let sig_s = signature[2]

            let (is_pub) = Controller_public_key.read(public_key)

            if is_pub == TRUE:
                verify_ecdsa_signature(
                    message=hash,
                    public_key=public_key,
                    signature_r=sig_r,
                    signature_s=sig_s)
                return (is_valid=TRUE)
            end

            return (is_valid=FALSE)
        end
    end
end
