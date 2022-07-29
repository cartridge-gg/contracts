# Ported from https://github.com/Th0rgal/sphinx/blob/b85376cfb53e17cfa52fbeeb1f4560229f71a690/tests/test_sha256.cairo

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.invoke import invoke
from starkware.cairo.common.alloc import alloc

from src.util.sha256 import sha256

@view
func test_sha256{bitwise_ptr : BitwiseBuiltin*, range_check_ptr}():
    alloc_locals

    let (phrase) = alloc()
    # phrase="this is an example message which should take multiple chunks"
    # 01110100 01101000 01101001 01110011
    assert phrase[0] = 1952999795
    # 00100000 01101001 01110011 00100000
    assert phrase[1] = 543781664
    # 01100001 01101110 00100000 01100101
    assert phrase[2] = 1634607205
    # 01111000 01100001 01101101 01110000
    assert phrase[3] = 2019650928
    # 01101100 01100101 00100000 01101101
    assert phrase[4] = 1818566765
    # 01100101 01110011 01110011 01100001
    assert phrase[5] = 1702064993
    # 01100111 01100101 00100000 01110111
    assert phrase[6] = 1734680695
    # 01101000 01101001 01100011 01101000
    assert phrase[7] = 1751737192
    # 00100000 01110011 01101000 01101111
    assert phrase[8] = 544434287
    # 01110101 01101100 01100100 00100000
    assert phrase[9] = 1970037792
    # 01110100 01100001 01101011 01100101
    assert phrase[10] = 1952541541
    # 00100000 01101101 01110101 01101100
    assert phrase[11] = 544044396
    # 01110100 01101001 01110000 01101100
    assert phrase[12] = 1953067116
    # 01100101 00100000 01100011 01101000
    assert phrase[13] = 1696621416
    # 01110101 01101110 01101011 01110011
    assert phrase[14] = 1970170739

    let (local sha256_ptr : felt*) = alloc()
    let (hash) = sha256{sha256_ptr=sha256_ptr}(phrase, 60)

    let a = hash[0]
    assert a = 3714276112
    let b = hash[1]
    assert b = 759782134
    let c = hash[2]
    assert c = 1331117438
    let d = hash[3]
    assert c = 1331117438
    let e = hash[4]
    assert e = 699003633
    let f = hash[5]
    assert f = 2214481798
    let g = hash[6]
    assert g = 3208491254
    let h = hash[7]
    assert h = 789740750

    # let (hello_world) = alloc()
    # # 01101000 01100101 01101100 01101100
    # assert hello_world[0] = 1751477356
    # # 01101111 00100000 01110111 01101111
    # assert hello_world[1] = 1864398703
    # # 01110010 01101100 01100100 ........
    # assert hello_world[2] = 1919706112

    # let (local sha256_ptr : felt*) = alloc()
    # let (hash) = sha256{sha256_ptr=sha256_ptr}(hello_world, 11)

    # let a = hash[0]
    # assert a = 3108841401
    # let b = hash[1]
    # assert b = 2471312904
    # let c = hash[2]
    # assert c = 2771276503
    # let d = hash[3]
    # assert d = 3665669114
    # let e = hash[4]
    # assert e = 3297046499
    # let f = hash[5]
    # assert f = 2052292846
    # let g = hash[6]
    # assert g = 2424895404
    # let h = hash[7]
    # assert h = 3807366633

    # let (empty) = alloc()
    # let (local sha256_ptr : felt*) = alloc()
    # let (hash) = sha256{sha256_ptr=sha256_ptr}(empty, 0)
    # let a = hash[0]
    # assert a = 3820012610
    # let b = hash[1]
    # assert b = 2566659092
    # let c = hash[2]
    # assert c = 2600203464
    # let d = hash[3]
    # assert d = 2574235940
    # let e = hash[4]
    # assert e = 665731556
    # let f = hash[5]
    # assert f = 1687917388
    # let g = hash[6]
    # assert g = 2761267483
    # let h = hash[7]
    # assert h = 2018687061

    # # let's hash "hey guys"
    # let (local sha256_ptr : felt*) = alloc()
    # let (hash) = sha256{sha256_ptr=sha256_ptr}(new ('hey ', 'guys'), 8)
    # let a = hash[0]
    # assert a = 3196269849
    # let b = hash[1]
    # assert b = 935960894
    # let c = hash[2]
    # assert c = 219027118
    # let d = hash[3]
    # assert d = 2548975249
    # let e = hash[4]
    # assert e = 1584991481
    # let f = hash[5]
    # assert f = 2782224291
    # let g = hash[6]
    # assert g = 385959225
    # let h = hash[7]
    # assert h = 10428673

    return ()
end
