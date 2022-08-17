"""contract.cairo test file."""
import os
import pytest
import random

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files

from utils.deployment import deploy

# @pytest.mark.asyncio
# async def test_generate_character():
#     """Test generate_character method."""
#     # Create a new Starknet class that simulates the StarkNet
#     # system.
#     starknet = await Starknet.empty()

#     avatar, avatar_class = await deploy(starknet, "src/fixtures/Avatar.cairo")

#     # Check the result of get_balance().
#     character = await avatar.test_generate_character().call()
#     recovered_svg = felt_array_to_ascii(character.result.tokenURI)
#     print(f'> tpg::return_svg(): {recovered_svg}')

@pytest.mark.asyncio
async def test_generate_avatar_with_seed():
    """Test generate_character method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    avatar, avatar_class = await deploy(starknet, "src/fixtures/Avatar.cairo")



    f = open("avatars.html", "w")

    htmlStart = """
        <html>
            <head>
                <title>Avatars Test</title>
                <style>
                    svg {
                        height: 50px;
                        width: 50px;
                        margin: 10px;
                    }
                </style>
            </head>
            <body>"""

    htmlEnd = "</body></html>"


    f.write(htmlStart)

    for idx in range(20):
        character = await avatar.test_generate_character_with_seed(seed=random.randint(1337,5224073)).invoke()
        recovered_svg = felt_array_to_ascii(character.result.tokenURI)
        svg = recovered_svg.replace('\\"','\"')
        print(svg)
        f.write(svg)

    f.write(htmlEnd)
    f.close()
    



def felt_array_to_ascii(felt_array):
    ret = ""
    for felt in felt_array:
        ret += felt_to_ascii(felt)
    return ret

def felt_to_ascii(felt):
    bytes_object = bytes.fromhex(hex(felt)[2:])
    ascii_string = bytes_object.decode("ASCII")
    return ascii_string