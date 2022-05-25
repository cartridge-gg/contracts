"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files

# The path to the contract source code.
CONTRACT_FILE = os.path.join("src", "fixtures", "svg.cairo")

# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_generate_character():
    """Test generate_character method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    contract_def = compile_starknet_files(
        files=[CONTRACT_FILE], disable_hint_validation=True
    )

    # Deploy the contract.
    contract = await starknet.deploy(
        contract_def=contract_def,
    )

    # Check the result of get_balance().
    character = await contract.test_generate_character().call()
    recovered_svg = felt_array_to_ascii(character.result.tokenURI)
    print(f'> tpg::return_svg(): {recovered_svg}')

def felt_array_to_ascii (felt_array):
    ret = ""
    for felt in felt_array:
        ret += felt_to_ascii (felt)
    return ret


def felt_to_ascii (felt):
    bytes_object = bytes.fromhex( hex(felt)[2:] )
    ascii_string = bytes_object.decode("ASCII")
    return ascii_string