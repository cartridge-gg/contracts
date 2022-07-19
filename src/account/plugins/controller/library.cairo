%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_tx_info
from starkware.cairo.common.bool import (TRUE, FALSE)
from starkware.cairo.common.math import assert_not_zero, unsigned_div_rem, split_felt
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.serialize import serialize_word

from src.account.IPlugin import IPlugin
from src.util.sha256 import finalize_sha256, sha256
from src.util.pow2 import pow2

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
            ecdsa_ptr : SignatureBuiltin*,
            bitwise_ptr : BitwiseBuiltin*
        }(
            hash: felt,
            signature_len: felt,
            signature: felt*
        ) -> (is_valid: felt):
        alloc_locals

        if signature[0] == 0:
            let (pub_pt) = Controller_p256_point.read()

            # Implementation expects the r, s components decomposed into their limbs.
            let sig_r0 = BigInt3(signature[1], signature[2], signature[3])
            let sig_s0 = BigInt3(signature[4], signature[5], signature[6])

            let (local sha256_ptr_start : felt*) = alloc()
            let sha256_ptr = sha256_ptr_start

            let (local input: felt*) = alloc()

            let (high, low) = split_felt(hash)

            # Extract words
            let (b0) = bitwise_and(low, 4294967295)

            let (q1, r1) = unsigned_div_rem(low, 4294967296)
            let (b1) = bitwise_and(q1, 4294967295)

            let (q2, r2) = unsigned_div_rem(q1, 4294967296)
            let (b2) = bitwise_and(q2, 4294967295)

            let (q3, r3) = unsigned_div_rem(q2, 4294967296)
            let (b3) = bitwise_and(q3, 4294967295)

            let (b4) = bitwise_and(high, 4294967295)

            let (q5, r5) = unsigned_div_rem(high, 4294967296)
            let (b5) = bitwise_and(q5, 4294967295)

            let (q6, r6) = unsigned_div_rem(q5, 4294967296)
            let (b6) = bitwise_and(q6, 4294967295)

            let (q7, r7) = unsigned_div_rem(q6, 4294967296)
            let (b7) = bitwise_and(q7, 4294967295)

            assert [input + 0] = b7
            assert [input + 1] = b6
            assert [input + 2] = b5
            assert [input + 3] = b4
            assert [input + 4] = b3
            assert [input + 5] = b2
            assert [input + 6] = b1
            assert [input + 7] = b0

            let (output: felt*) = sha256{sha256_ptr=sha256_ptr}(input, 32)
            finalize_sha256(sha256_ptr, sha256_ptr)

            # Construct 86bit hash limbs
            let (h02) = bitwise_and(output[5], 4194303)
            let h0 = output[7] + 2 ** 32 * output[6] + 2 ** 64 * h02

            let (h10, r10) = unsigned_div_rem(output[5], 4194304)
            let (h13) = bitwise_and(output[2], 4095)
            let h1 = h10 + output[4] * 2 ** 10 + output[3] * 2 ** 42 + h13 * 2 ** 74

            let (h20, r20) = unsigned_div_rem(output[2], 4096)
            let h2 = h20 + output[1] * 2 ** 20 + output[0] * 2 ** 52

            let hash_bigint3 = BigInt3(h0, h1, h2)
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
