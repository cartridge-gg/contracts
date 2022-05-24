%lang starknet

from src.util.svg import Cell
from src.util.str import string

@contract_interface
namespace SVGContract:
    func test_generate_character() -> (tokenURI_len : felt, tokenURI : felt*):
    end
end

@external
func test_example{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_a_address : felt
    %{ ids.contract_a_address = deploy_contract("./tests/fixtures/svg.cairo").contract_address %}

    let (arr_len, arr) = SVGContract.test_generate_character(contract_address=contract_a_address)
    let (first) = arr[0]
    %{
        print(ids.arr_len)
        # bytes_object = bytes.fromhex(hex(ids.arr[0])[2:])
        # ascii_string = bytes_object.decode("ASCII")
        print(hex(ids.first))
    %}
    return ()
end
