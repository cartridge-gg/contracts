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
#     seed = random.randint(1337, 1000000)
#     character = await avatar.test_generate_character().invoke()
#     recovered_svg = felt_array_to_ascii(character.result.tokenURI)
#     print(f'> tpg::return_svg(): {recovered_svg}')

@pytest.mark.asyncio
async def test_generate_avatar_with_seed():
    """Test generate_character method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    avatar, avatar_class = await deploy(starknet, "src/fixtures/Avatar.cairo")

    f = open("avatars_preview.html", "w")

    html_start = """
<html>
    <head>
        <title>Avatars Preview</title>
        <style>
            html {
                background-color: #1E221F;
            }
            svg {
                height: 50px;
                width: 50px;
                margin: 10px;
            }
        </style>
    </head>
    <body>
"""
    html_end = "</body></html>"

    f.write(html_start)

    for x in range(10):
        seed = random.randint(1337, 1000000)
        character = await avatar.test_generate_character(seed=seed).invoke()
        recovered_svg = felt_array_to_ascii(character.result.tokenURI)
        svg = recovered_svg.replace('\\"','\"')
        f.write(svg)

    f.write(html_end)
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