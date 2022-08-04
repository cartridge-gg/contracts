"""Points.cairo test file"""
import pytest

from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

from utils.deployment import deploy
from utils.utilities import str_to_felt, uint


@pytest.mark.asyncio
async def test_nontransferrable():
    """Test transfer methods while paused."""
    controller = int("0x36e8d758b358c59f48b0686a66ab05b582d18f37fafb4bc2dd56a7e079097a6", 16)
    alice = int("0x111111111111111111111111111111111111111111111111111111111111111", 16)
    bob = int("0x222222222222222222222222222222222222222222222222222222222222222", 16)

    starknet = await Starknet.empty()

    points, _ = await deploy(
      starknet,
      "src/tokens/Points/Points.cairo",
      params=[
        str_to_felt("Cartridge Points"),
        str_to_felt("PNTS"),
        0,
        *uint(0),
        controller,
        controller,
      ]
    )
    await points.pause().invoke(caller_address=controller)

    await points.mint(alice, uint(10)).invoke(caller_address=controller)
    alice_balance = await points.balanceOf(alice).call()
    bob_balance = await points.balanceOf(bob).call()
    assert alice_balance.result.balance == uint(10)
    assert bob_balance.result.balance == uint(0)

    # Assert that transfer is not possible
    with pytest.raises(StarkException, match="Pausable: paused"):
        await points.transfer(bob, uint(10)).invoke(caller_address=alice)
        await points.transferFrom(alice, bob, uint(10)).invoke(caller_address=controller)

    # Sanity check that token amounts are unchanged
    alice_balance = await points.balanceOf(alice).call()
    bob_balance = await points.balanceOf(bob).call()
    assert alice_balance.result.balance == uint(10)
    assert bob_balance.result.balance == uint(0)

    await points.unpause().invoke(caller_address=controller)

    await points.transfer(bob, uint(10)).invoke(caller_address=alice)

    # Assert tokens were sent to bob
    alice_balance = await points.balanceOf(alice).call()
    bob_balance = await points.balanceOf(bob).call()
    assert alice_balance.result.balance == uint(0)
    assert bob_balance.result.balance == uint(10)
