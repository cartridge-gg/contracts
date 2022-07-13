import logging
import pytest
import pytest_asyncio
import asyncio
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.cairo.common.hash_state import compute_hash_on_elements

from utils.Signer import Signer
from utils.utilities import deploy, assert_revert, str_to_felt, assert_event_emmited
from utils.TransactionSender import TransactionSender

LOGGER = logging.getLogger(__name__)

signer = Signer(123456789987654321)

session_key = Signer(666666666666666666)
wrong_session_key = Signer(6767676767)

DEFAULT_TIMESTAMP = 1640991600
ESCAPE_SECURITY_PERIOD = 24*7*60*60

VERSION = str_to_felt('0.2.2')

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
async def plugin_factory(get_starknet):
    starknet = get_starknet
    plugin_session, plugin_class = await deploy(starknet, "src/account/plugins/signer/WebAuthnSigner.cairo")
    return plugin_session, plugin_class

@pytest_asyncio.fixture
async def account_factory(plugin_factory, get_starknet):
    starknet = get_starknet
    plugin, plugin_class = plugin_factory

    account, account_class = await deploy(starknet, "src/account/PluginAccount.cairo", [plugin_class.class_hash, 7, 0, 0, 0, 0, 0, 0, signer.public_key])
    return account, account_class, plugin, plugin_class

# sig: 304502205ee29a838807a20b214fe64269e3fd3d0b4e36c92b4d708308bbdf312fd28b5c022100962a0eff275f733d626540a1200c8f7b2724bf39b2fdd20e865da3711ef3fdc6
# x: "mD9+rmM6b2YHnxAGQLNUoKq3JOCz5ocqhONLLbMgfg8="
# y: "lqYQ6vTKMOU3oovdN5r0dosIRWRdC8ocns8U9yeBYn0="


@pytest.mark.asyncio
async def test_add_plugin(account_factory, plugin_factory):
    account, account_class, base_plugin, base_plugin_class = account_factory
    sender = TransactionSender(account)

    assert (await account.is_plugin(base_plugin_class.class_hash).call()).result.success == (1)
    
    plugin, plugin_class = plugin_factory
    tx_exec_info = await sender.send_transaction([(account.contract_address, 'add_plugin', [plugin_class.class_hash, 7, 0, 0, 0, 0, 0, 0, signer.public_key])], [signer])
    assert (await account.is_plugin(plugin_class.class_hash).call()).result.success == (1)

# @pytest.mark.asyncio
# async def test_call_dapp_with_session_key(account_factory, plugin_factory, dapp_factory, get_starknet):
#     account = account_factory
#     plugin = plugin_factory
#     dapp = dapp_factory
#     starknet = get_starknet
#     sender = TransactionSender(account)

#     tx_exec_info = await sender.send_transaction([(account.contract_address, 'add_plugin', [plugin.contract_address])], [signer])

#     session_token = get_session_token(session_key.public_key, DEFAULT_TIMESTAMP + 10)
#     assert (await dapp.get_number(account.contract_address).call()).result.number == 0
#     update_starknet_block(starknet=starknet, block_timestamp=(DEFAULT_TIMESTAMP))
#     tx_exec_info = await sender.send_transaction(
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


def get_session_token(key, expires):
    session = [
        key,
        expires
    ]
    hash = compute_hash_on_elements(session)
    return signer.sign(hash)
