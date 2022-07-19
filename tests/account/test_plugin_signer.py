import logging
import pytest
import pytest_asyncio
import asyncio
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.cairo.common.hash_state import compute_hash_on_elements

from utils.Signer import MockSigner
from utils.P256Signer import MockP256Signer
from utils.utilities import deploy

LOGGER = logging.getLogger(__name__)

stark_signer = MockSigner(123456789987654321)
webauthn_signer = MockP256Signer(123)

DEFAULT_TIMESTAMP = 1640991600

IACCOUNT_ID = 0xf10dbd44


@pytest_asyncio.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


@pytest_asyncio.fixture(scope='module')
async def get_starknet():
    starknet = await Starknet.empty()
    return starknet


def update_starknet_block(starknet, block_number=1, block_timestamp=DEFAULT_TIMESTAMP):
    starknet.state.state.block_info = BlockInfo(
        block_number=block_number, block_timestamp=block_timestamp, gas_price=0)


def reset_starknet_block(starknet):
    update_starknet_block(starknet=starknet)

@pytest_asyncio.fixture
async def dapp_factory(get_starknet):
    starknet = get_starknet

    dapp = await deploy(starknet, "lib/argent_contracts_starknet/contracts/test/TestDapp.cairo")
    return dapp


@pytest_asyncio.fixture
async def controller_plugin_factory(get_starknet):
    starknet = get_starknet
    plugin_session, plugin_class = await deploy(starknet, "src/account/plugins/controller/Controller.cairo")
    return plugin_session, plugin_class

@pytest_asyncio.fixture
async def signer_plugin_factory(get_starknet):
    starknet = get_starknet
    plugin_session, plugin_class = await deploy(starknet, "src/account/plugins/signer/Signer.cairo")
    return plugin_session, plugin_class


@pytest_asyncio.fixture
async def account_factory(controller_plugin_factory, get_starknet):
    starknet = get_starknet
    plugin, plugin_class = controller_plugin_factory

    account, account_class = await deploy(starknet, "src/account/PluginAccount.cairo", [plugin_class.class_hash, 7, *webauthn_signer.public_key, stark_signer.public_key])
    return account, account_class, plugin, plugin_class


@pytest.mark.asyncio
async def test_add_public_key(account_factory):
    account, account_class, base_plugin, base_plugin_class = account_factory
    
    tx = await webauthn_signer.send_transactions(account, [(account.contract_address, 'add_public_key', [0])])
    assert (await webauthn_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [0])])).result[0] == 1

# @pytest.mark.asyncio
# async def test_add_plugin(account_factory, signer_plugin_factory):
#     account, account_class, base_plugin, base_plugin_class = account_factory
#     sender = TransactionSender(account)

#     assert (await account.is_plugin(base_plugin_class.class_hash).call()).result.success == (1)
    
#     plugin, plugin_class = signer_plugin_factory
#     tx_exec_info = await stark_signer.send_transactions(account, [(account.contract_address, 'add_plugin', [plugin_class.class_hash, 1, signer.public_key])])
#     assert (await account.is_plugin(plugin_class.class_hash).call()).result.success == (1)

# @pytest.mark.asyncio
# async def test_remove_plugin(account_factory, signer_plugin_factory):
#     account, account_class, base_plugin, base_plugin_class = account_factory
#     sender = TransactionSender(account)

#     # we shouldnt be able to remove base plugin
#     try:
#         tx_exec_info = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_plugin', [base_plugin_class.class_hash])])
#         raise Exception("should have been reverted. should not be able to remove default plugin")
#     except:
#         pass
#     assert (await account.is_plugin(base_plugin_class.class_hash).call()).result.success == (1)

#     # try to add and remove plugin
#     plugin, plugin_class = signer_plugin_factory
#     tx_exec_info = await stark_signer.send_transactions(account, [(account.contract_address, 'add_plugin', [plugin_class.class_hash, 1, signer.public_key])])
#     assert (await account.is_plugin(plugin_class.class_hash).call()).result.success == (1)

#     tx_exec_info = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_plugin', [plugin_class.class_hash])])
#     assert (await account.is_plugin(plugin_class.class_hash).call()).result.success == (0)

# @pytest.mark.asyncio
# async def test_add_remove_public_key(account_factory):
#     account, account_class, base_plugin, base_plugin_class = account_factory
    
#     tx = await stark_signer.send_transactions(account, [(account.contract_address, 'add_public_key', [0])])
#     assert (await stark_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [0])])).result[0] == 1

#     tx = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_public_key', [0])])
#     assert (await stark_signer.send_transactions(account, [(account.contract_address, 'is_public_key', [0])])).result[0] == 0

#     try:
#         tx = await stark_signer.send_transactions(account, [(account.contract_address, 'remove_public_key', [1])])
#         raise Exception("should have been reverted. invalid public key")
#     except:
#         pass

# @pytest.mark.asyncio
# async def test_p256_verify(account_factory, get_starknet):
#     starknet = get_starknet
#     account, account_class, base_plugin, base_plugin_class = account_factory
#     sender = TransactionSender(account)

    
#     p256, p256_class = await deploy(starknet, "src/fixtures/p-256.cairo")
#     tx = await stark_signer.send_transactions(account, [(p256.contract_address, 'test_p256_verify_tx_hash', [])], [signer])


# @pytest.mark.asyncio
# async def test_call_dapp_with_session_key(account_factory, plugin_factory, dapp_factory, get_starknet):
#     account = account_factory
#     plugin = plugin_factory
#     dapp = dapp_factory
#     starknet = get_starknet
#     sender = TransactionSender(account)

#     tx_exec_info = await stark_signer.send_transactions(account, [(account.contract_address, 'add_plugin', [plugin.contract_address])], [signer])

#     session_token = get_session_token(session_key.public_key, DEFAULT_TIMESTAMP + 10)
#     assert (await dapp.get_number(account.contract_address).call()).result.number == 0
#     update_starknet_block(starknet=starknet, block_timestamp=(DEFAULT_TIMESTAMP))
#     tx_exec_info = await stark_signer.send_transactions(account, 
#         [
#             (account.contract_address, 'use_plugin', [plugin.contract_address, session_key.public_key, DEFAULT_TIMESTAMP + 10, session_token[0], session_token[1]]),
#             (dapp.contract_address, 'set_number', [47])
#         ],
#         [session_key])

#     assert_event_emmited(
#         tx_exec_info,
#         from_address=account.contract_address,
#         name='transaction_executed'
#     )

#     assert (await dapp.get_number(account.contract_address).call()).result.number == 47
