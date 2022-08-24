import logging
import pytest

from starkware.starknet.testing.starknet import Starknet

from utils.signers import ControllerStarkSigner, StarkSigner, P256Signer
from utils.deployment import deploy
from utils.profiling import gas_report

LOGGER = logging.getLogger(__name__)

stark_signer = StarkSigner(123456789987654321)
webauthn_signer = P256Signer()

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

    return account, account_class, plugin, plugin_class


@pytest.mark.asyncio
async def test_add_device_key(account_factory):
    account, _, _, _ = account_factory

    controller_signer = ControllerStarkSigner(420)
    bad_controller_signer = ControllerStarkSigner(69)

    await webauthn_signer.send_transactions(account, [(account.contract_address, 'add_device_key', [controller_signer.public_key])])
    assert (await webauthn_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [controller_signer.public_key])])).result[0] == 1
    try:
        tx = await bad_controller_signer.send_transactions(account, [(account.contract_address, 'remove_device_key', [controller_signer.public_key])])
        raise Exception("should have been reverted. invalid public key")
    except:
        pass

    await controller_signer.send_transactions(account, [(account.contract_address, 'remove_device_key', [controller_signer.public_key])])


@pytest.mark.asyncio
async def test_add_remove_device_key(account_factory):
    account, _, _, _ = account_factory

    tx = await stark_signer.send_transactions(account, [(account.contract_address, 'add_device_key', [69])])
    assert (await stark_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [69])])).result[0] == 1

    tx = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_device_key', [69])])
    assert (await stark_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [69])])).result[0] == 0

    try:
        tx = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_device_key', [1])])
        raise Exception("should have been reverted. invalid public key")
    except:
        pass
