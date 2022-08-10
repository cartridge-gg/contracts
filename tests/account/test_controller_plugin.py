import logging
import pytest

from starkware.starknet.testing.starknet import Starknet

from utils.signers import StarkSigner, P256Signer
from utils.deployment import deploy
from utils.profiling import gas_report

LOGGER = logging.getLogger(__name__)

stark_signer = StarkSigner(123456789987654321)
webauthn_signer = P256Signer()

# webauthn_signer.send_transactions("0x0", [("0xdead", 'add_public_key', [0])])


@pytest.fixture(scope='module')
async def get_starknet():
    starknet = await Starknet.empty()
    return starknet


@pytest.fixture
async def controller_plugin_factory(get_starknet):
    starknet = get_starknet
    plugin_signer, plugin_class = await deploy(starknet, "src/account/plugins/controller/Controller.cairo")
    return plugin_signer, plugin_class


@pytest.fixture
async def account_factory(controller_plugin_factory, get_starknet):
    starknet = get_starknet
    plugin, plugin_class = controller_plugin_factory

    account, account_class = await deploy(starknet, "src/account/PluginAccount.cairo")
    tx = await account.initialize(plugin_class.class_hash, [*webauthn_signer.public_key, stark_signer.public_key]).invoke()
    print(gas_report(tx))

    return account, account_class, plugin, plugin_class


@pytest.mark.asyncio
async def test_add_public_key(account_factory):
    account, _, _, _ = account_factory

    tx = await webauthn_signer.send_transactions(account, [(account.contract_address, 'add_public_key', [0])])
    print(gas_report(tx))
    assert (await webauthn_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [0])])).result[0] == 1


# @pytest.mark.asyncio
# async def test_add_remove_public_key(account_factory):
#     account, _, _, _ = account_factory

#     tx = await stark_signer.send_transactions(account, [(account.contract_address, 'add_public_key', [0])])
#     assert (await stark_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [0])])).result[0] == 1

#     tx = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_public_key', [0])])
#     assert (await stark_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [0])])).result[0] == 0

#     try:
#         tx = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_public_key', [1])])
#         raise Exception("should have been reverted. invalid public key")
#     except:
#         pass
