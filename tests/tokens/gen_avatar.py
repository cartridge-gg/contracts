"""contract.cairo test file."""
import os
import pytest
from random import randint
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

    avatar, _ = await deploy(starknet, "src/fixtures/Avatar.cairo")
    body = ""

    num_avatars = 10             # number of avatars per dimension
    dimensions = [8, 10, 12]    # avatar dimensions

    for i in range(num_avatars):
        body += "<div>"
        seed = int.from_bytes(os.urandom(16), byteorder="big")
        for j in dimensions:
                character = await avatar.test_generate_svg(
                    seed=seed,
                    border=1,
                    dimension=j,
                    evolution=1).execute()
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
                    background-color: #1E221F;
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

