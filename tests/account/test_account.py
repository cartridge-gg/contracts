import logging
import pytest

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import get_selector_from_name

from utils.signers import StarkSigner
from utils.deployment import deploy

LOGGER = logging.getLogger(__name__)

stark_signer = StarkSigner(123456789987654321)

@pytest.fixture(scope='module')
async def get_starknet():
    starknet = await Starknet.empty()
    return starknet

@pytest.fixture
async def account_factory(get_starknet):
    starknet = get_starknet
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

@pytest.mark.asyncio
async def test_default_plugin(account_factory):
    account, _, signer_plugin, signer_plugin_class, _ = account_factory

    assert (await account.is_plugin(signer_plugin_class.class_hash).call()).result.success == (1)

    print((await signer_plugin.get_public_key().call()).result)
    assert (await signer_plugin.get_public_key().call()).result.res == stark_signer.public_key

@pytest.mark.asyncio
async def test_add_plugin(account_factory):
    account, _, _, signer_plugin_class, mock_plugin_class = account_factory

    assert (await account.is_plugin(signer_plugin_class.class_hash).call()).result.success == (1)

    # we shouldnt be able to readd an existing plugin
    try:
        await stark_signer.send_transactions(account, [(account.contract_address, 'add_plugin', [signer_plugin_class.class_hash, 1, stark_signer.public_key])])
        raise Exception("should have been reverted. should not be able to add plugin that already exists")
    except:
        pass

    await stark_signer.send_transactions(account, [(account.contract_address, 'add_plugin', [mock_plugin_class.class_hash, 0])])
    assert (await account.is_plugin(mock_plugin_class.class_hash).call()).result.success == (1)

@pytest.mark.asyncio
async def test_remove_plugin(account_factory):
    account, _, _, signer_plugin_class, mock_plugin_class = account_factory

    # we shouldnt be able to remove base plugin
    try:
        await stark_signer.send_transactions(account, [(account.contract_address, 'remove_plugin', [signer_plugin_class.class_hash, 0])])
        raise Exception("should have been reverted. should not be able to remove default plugin")
    except:
        pass
    assert (await account.is_plugin(signer_plugin_class.class_hash).call()).result.success == (1)

    # try to add and remove plugin
    await stark_signer.send_transactions(account, [(account.contract_address, 'add_plugin', [mock_plugin_class.class_hash, 0])])
    assert (await account.is_plugin(mock_plugin_class.class_hash).call()).result.success == (1)

    await stark_signer.send_transactions(account, [(account.contract_address, 'remove_plugin', [mock_plugin_class.class_hash])])
    assert (await account.is_plugin(mock_plugin_class.class_hash).call()).result.success == (0)

@pytest.mark.asyncio
async def test_deploy_contract(account_factory):
    account, _, _, _, mock_plugin_class = account_factory

    await stark_signer.send_transactions(account, [(account.contract_address, 'deploy_contract', [mock_plugin_class.class_hash, 0, 0])])

@pytest.mark.asyncio
async def test_deploy_with_proxy(get_starknet, account_factory):
    starknet = get_starknet
    _, account_class, _, signer_plugin_class, _ = account_factory

    proxy, proxy_class = await deploy(starknet, "src/Proxy.cairo", [account_class.class_hash, get_selector_from_name('initialize'), 3, signer_plugin_class.class_hash, 1, stark_signer.public_key])
