"""Points.cairo test file"""
import pytest

from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starkware_utils.error_handling import StarkException

from utils.signers import StarkSigner
from utils.deployment import deploy
from utils.utilities import str_to_felt, uint

@pytest.mark.asyncio
async def test_nontransferrable():
    """Test transfer methods while paused."""

    starknet = await Starknet.empty()

    deployer = int("0x07d7bbf672edd77578b8864c3e2900ac9194698220adb1b1ecdc45f9222ca291", 16)
    alice_signer = StarkSigner(123456789987654321)
    bob_signer = StarkSigner(987654321987654321)
    (alice_account, _, _, _, _) = await deploy_account(starknet, alice_signer)
    (bob_account, _, _, _, _) = await deploy_account(starknet, bob_signer)
    alice = alice_account.contract_address
    bob = bob_account.contract_address
    achievement_id = uint(1)

    points, _ = await deploy(
      starknet,
      "src/tokens/Achievements/Achievements.cairo",
      params=[
        str_to_felt("{foo: \"bar\"}"),
        deployer,
      ]
    )
    await points.pause().invoke(caller_address=deployer)

    await points.mint(
      to=alice,
      id=achievement_id,
      amount=uint(10),
      data=[0],
    ).invoke(caller_address=deployer)
    alice_balance = await points.balanceOf(alice, achievement_id).call()
    bob_balance = await points.balanceOf(bob, achievement_id).call()
    assert alice_balance.result.balance == uint(10)
    assert bob_balance.result.balance == uint(0)

    # Assert that transfer is not possible
    with pytest.raises(StarkException, match="Pausable: paused"):
        await points.safeTransferFrom(
          from_=bob,
          to=alice,
          id=achievement_id,
          amount=uint(10),
          data=[0],
        ).invoke(caller_address=alice)
        await points.safeBatchTransferFrom(
          from_=alice,
          to=bob,
          ids=[achievement_id],
          amounts=[uint(10)],
          data=[0],
        ).invoke(caller_address=deployer)

    # Sanity check that token amounts are unchanged
    alice_balance = await points.balanceOf(alice, achievement_id).call()
    bob_balance = await points.balanceOf(bob, achievement_id).call()
    assert alice_balance.result.balance == uint(10)
    assert bob_balance.result.balance == uint(0)

    await points.unpause().invoke(caller_address=deployer)

    await points.safeTransferFrom(
      from_=alice,
      to=bob,
      id=achievement_id,
      amount=uint(10),
      data=[0],
    ).invoke(caller_address=alice)

    # Assert tokens were sent to bob
    alice_balance = await points.balanceOf(alice, achievement_id).call()
    bob_balance = await points.balanceOf(bob, achievement_id).call()
    assert alice_balance.result.balance == uint(0)
    assert bob_balance.result.balance == uint(10)

async def deploy_account(starknet, stark_signer):
    signer, signer_plugin_class = await deploy(starknet, "src/account/plugins/signer/Signer.cairo")
    _, mock_plugin_class = await deploy(starknet, "tests/mocks/plugin.cairo")
    account, account_class = await deploy(starknet, "src/account/PluginAccount.cairo")
    await account.initialize(signer_plugin_class.class_hash, [stark_signer.public_key]).invoke()

    signer_plugin = StarknetContract(
        state=starknet.state,
        abi=signer.abi,
        contract_address=account.contract_address,
        deploy_execution_info=signer.deploy_execution_info)

    return account, account_class, signer_plugin, signer_plugin_class, mock_plugin_class
