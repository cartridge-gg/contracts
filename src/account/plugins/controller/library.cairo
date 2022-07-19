%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_tx_info
from starkware.cairo.common.bool import (TRUE, FALSE)
from starkware.cairo.common.math import assert_not_zero
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

            # split signatures into 3 values
            let sig_r0 = BigInt3(signature[1], signature[2], signature[3])
            let sig_s0 = BigInt3(signature[4], signature[5], signature[6])

            %{ print(ids.hash) %}

            let (local sha256_ptr_start : felt*) = alloc()
            let sha256_ptr = sha256_ptr_start

            let (local input: felt*) = alloc()
            
            # Extract words
            let (b0) = bitwise_and(hash, 4294967295)
            let (b1) = bitwise_and(hash, 18446744069414584320)
            let (b2) = bitwise_and(hash, 79228162495817593519834398720)
            let (b3) = bitwise_and(hash, 340282366841710300949110269838224261120)
            let (b4) = bitwise_and(hash, 1461501636990620551282746369252908412224164331520)
            let (b5) = bitwise_and(hash, 6277101733925179126504886505003981583386072424808101969920)
            let (b6) = bitwise_and(hash, 26959946660873538059280334323183841250429478006438217036639575736320)
            let (b7) = bitwise_and(hash, 3618502787823632773638135787938152898945323562250106863028656610212797480960)

            assert [input + 0] = b0
            assert [input + 1] = b1 / 18446744069414584320
            assert [input + 2] = b2 / 79228162495817593519834398720
            assert [input + 3] = b3 / 340282366841710300949110269838224261120
            assert [input + 4] = b4 / 1461501636990620551282746369252908412224164331520
            assert [input + 5] = b5 / 6277101733925179126504886505003981583386072424808101969920
            assert [input + 6] = b6 / 26959946660873538059280334323183841250429478006438217036639575736320
            assert [input + 7] = b7 / 3618502787823632773638135787938152898945323562250106863028656610212797480960

            let (output: felt*) = sha256{sha256_ptr=sha256_ptr}(input, 31)
            finalize_sha256(sha256_ptr, sha256_ptr)

            let h0 = output[0]
            let h1 = output[1]
            let h2 = output[2]
            let h3 = output[3]
            let h4 = output[4]
            let h5 = output[5]
            let h6 = output[6]
            let h7 = output[7]

            let o0 = output[3] + 2 ** 32 * output[2] + 2 ** 64 * output[1] + 2 ** 96 * output[0]
            let o1 = output[7] + 2 ** 32 * output[6] + 2 ** 64 * output[5] + 2 ** 96 * output[4]

            %{ print("h0", hex(ids.h0)) %}
            %{ print("h1", hex(ids.h1)) %}
            %{ print("h2", hex(ids.h2)) %}
            %{ print("h3", hex(ids.h3)) %}
            %{ print("h4", hex(ids.h4)) %}
            %{ print("h5", hex(ids.h5)) %}
            %{ print("h6", hex(ids.h6)) %}
            %{ print("h7", hex(ids.h7)) %}
            %{ print("o0", hex(ids.o0)) %}
            %{ print("o1", hex(ids.o1)) %}

            let hash_bigint3 = BigInt3(0, 0, 0)
            # %{
            #     x = divmod(ids.hash, BASE)
            #     y = divmod(x[1], BASE)
            #     ids.sig_s0.x = x[1]
            #     ids.sig_s0.y = y[1]
            #     ids.sig_s0.y = y[0]
            # %}

            # verify_ecdsa(
            #     public_key_pt=pub_pt,
            #     msg_hash=hash_bigint3,
            #     r=sig_r0,
            #     s=sig_s0)

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
