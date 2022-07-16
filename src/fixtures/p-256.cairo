%lang starknet

from lib.sphinx.src.sphinx.sha256 import sha256
from lib.sphinx.src.sphinx.bits import Bits
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.syscalls import get_tx_info
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin, SignatureBuiltin

@external
func test_p256_verify_tx_hash{
    ecdsa_ptr : SignatureBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
    syscall_ptr : felt*, 
    range_check_ptr
    }():
    alloc_locals

    let (tx_info) = get_tx_info()

    # let (txn_hash: felt*) = alloc()
    # Bits.extract(cast(tx_info.transaction_hash, felt*), 0, 252, txn_hash)
    # let (txn_hash0) = Bits.rightshift(tx_info.transaction_hash, 32*7)
    # txn_hash[0] = txn_hash0
    # let (txn_hash1) = bitwise_and(Bits.rightshift(tx_info.transaction_hash, 32*6), 0xffffffff)
    # txn_hash[1] = txn_hash1
    # let (txn_hash2) = bitwise_and(Bits.rightshift(tx_info.transaction_hash, 32*5), 0xffffffff)
    # txn_hash[2] = txn_hash2
    # let (txn_hash3) = bitwise_and(Bits.rightshift(tx_info.transaction_hash, 32*4), 0xffffffff)
    # txn_hash[3] = txn_hash3
    # let (txn_hash4) = bitwise_and(Bits.rightshift(tx_info.transaction_hash, 32*3), 0xffffffff)
    # txn_hash[4] = txn_hash4
    # let (txn_hash5) = bitwise_and(Bits.rightshift(tx_info.transaction_hash, 32*2), 0xffffffff)
    # txn_hash[5] = txn_hash5
    # let (txn_hash6) = bitwise_and(Bits.rightshift(tx_info.transaction_hash, 32*1), 0xffffffff)
    # txn_hash[6] = txn_hash6
    # let (txn_hash7) = bitwise_and(tx_info.transaction_hash, 0xffffffff)
    # txn_hash[7] = txn_hash7

    # %{ print(ids.txn_hash) %}

    # let (txn_hash_sha256) = sha256(txn_hash, 252)

    %{ print(ids.tx_info.transaction_hash) %}

    verify_ecdsa_signature(
        message=tx_info.transaction_hash,
        public_key=tx_info.signature[0],
        signature_r=tx_info.signature[1],
        signature_s=tx_info.signature[2]
    )

    return ()
end
