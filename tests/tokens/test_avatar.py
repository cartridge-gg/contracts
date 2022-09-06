"""contract.cairo test file."""
import os
import pytest
from tinyhtml import html, raw, h

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash

from utils.deployment import deploy


@pytest.mark.asyncio
async def test_generate_avatars():
    """Test generate_character method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    avatar, avatar_class = await deploy(starknet, "src/fixtures/Avatar.cairo")
    body = ""

    dimensions = [8]        # avatar dimensions
    iterations = 5          # number of avatars per dimension
    color = "#FFF"          # color of the avatar
    bg_color = "#1E221F"     # background color of avatar
    bias = 3                # approx area filled: 2 ~ 50%, 3 ~ 33%, 4 ~ 25%...
    for i in dimensions:
        body += html_h2(i, color, bias)
        for j in range(iterations):
            seed = int.from_bytes(os.urandom(16), byteorder="big")
            character = await avatar.test_generate_character(seed=seed, 
                bias=bias, 
                dimension=i, 
                color=ascii_to_felt(color), 
                bg_color=ascii_to_felt(bg_color)).invoke()

            recovered_svg = felt_array_to_ascii(character.result.tokenURI)
            body += recovered_svg.replace('\\"','\"')

    file = open("avatars_preview.html", "w")
    file.write(html_doc(raw(body)))
    file.close()

def ascii_to_felt(ascii):
    return int(ascii.encode('utf-8').hex(), 16)

def felt_array_to_ascii(felt_array):
    ret = ""
    for felt in felt_array:
        ret += felt_to_ascii(felt)
    return ret

def felt_to_ascii(felt):
    bytes_object = bytes.fromhex(hex(felt)[2:])
    ascii_string = bytes_object.decode("ASCII")
    return ascii_string

def html_h2(dim, color, bias):
    return f"<h2>Dimensions: {dim}x{dim} - Color: {color} - Bias: {bias}</h2>"

def html_doc(body):
    return html(lang="en")(
        h("head")(
            h("title")("Avatars Preview"),
            h("style")("""
                html {
                    background-color: #0F1410;
                }
                svg {
                    margin: 25px;
                }
                h2 {
                    color: white;
                }
            """)
        ),
        h("body")(body)
    ).render()

