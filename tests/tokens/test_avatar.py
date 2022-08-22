"""contract.cairo test file."""
import os
import pytest
from tinyhtml import html, raw, h

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash

from utils.deployment import deploy

DIMENSIONS = [5, 6, 7, 8, 9, 10, 11]
ITERATIONS = 10

@pytest.mark.asyncio
async def test_generate_avatars():
    """Test generate_character method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    avatar, avatar_class = await deploy(starknet, "src/fixtures/Avatar.cairo")

    body = ""

    for i in DIMENSIONS:
        body += html_h2(i)
        for j in range(ITERATIONS):
            seed = int.from_bytes(os.urandom(16), byteorder="big")
            character = await avatar.test_generate_character(seed=seed, dimension=i).invoke()
            recovered_svg = felt_array_to_ascii(character.result.tokenURI)
            body += recovered_svg.replace('\\"','\"')


    file = open("avatars_preview.html", "w")
    file.write(html_doc(raw(body)))
    file.close()


def felt_array_to_ascii(felt_array):
    ret = ""
    for felt in felt_array:
        ret += felt_to_ascii(felt)
    return ret

def felt_to_ascii(felt):
    bytes_object = bytes.fromhex(hex(felt)[2:])
    ascii_string = bytes_object.decode("ASCII")
    return ascii_string

def html_h2(dim):
    return f"<h2>{dim}x{dim}</h2>"

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

