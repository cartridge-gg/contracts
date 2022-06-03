import pytest
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.core.os.contract_address.contract_address import calculate_contract_address, calculate_contract_address_from_hash
from utils import TestSigner, assert_revert, cached_contract, get_contract_def, TRUE

signer = TestSigner(123456789987654321)
other = TestSigner(987654321123456789)

IACCOUNT_ID = 0xf10dbd44

@pytest.fixture(scope='module')
async def contract_defs():
    account_def = await get_contract_def('account/Account.cairo')
    signer_def = await get_contract_def('account/plugins/signer/Signer.cairo')
    init_def = await get_contract_def("tests/mocks/Initializable.cairo")
    attacker_def = await get_contract_def("tests/mocks/account_reentrancy.cairo")

    return account_def, signer_def, init_def, attacker_def


@pytest.fixture(scope='module')
async def account_init(contract_defs):
    account_def, signer_def, init_def, attacker_def = contract_defs
    starknet = await Starknet.empty()

    signer_class = await starknet.declare(contract_class=signer_def)

    signer1 = signer_class.class_hash

    account1 = await starknet.deploy(
        contract_class=account_def,
        constructor_calldata=[
            signer1, 1, signer.public_key],
        contract_address_salt=420
    )

    account2 = await starknet.deploy(
        contract_class=account_def,
        constructor_calldata=[
            signer1, 1, signer.public_key]
    )
    initializable1 = await starknet.deploy(
        contract_class=init_def,
        constructor_calldata=[],
    )
    initializable2 = await starknet.deploy(
        contract_class=init_def,
        constructor_calldata=[],
    )
    attacker = await starknet.deploy(
        contract_class=attacker_def,
        constructor_calldata=[],
    )

    return starknet.state, signer1, account1, account2, initializable1, initializable2, attacker


@pytest.fixture
def account_factory(contract_defs, account_init):
    account_def, signer_def, init_def, attacker_def = contract_defs
    state, signer1, account1, account2, initializable1, initializable2, attacker = account_init
    _state = state.copy()
    # signer_plugin = cached_contract(_state, signer_def, signer_plugin)
    account1 = cached_contract(_state, account_def, account1)
    account2 = cached_contract(_state, account_def, account2)
    initializable1 = cached_contract(_state, init_def, initializable1)
    initializable2 = cached_contract(_state, init_def, initializable2)
    attacker = cached_contract(_state, attacker_def, attacker)

    return signer1, account1, account2, initializable1, initializable2, attacker


# @pytest.mark.asyncio
# async def test_constructor(account_factory):
#     signer1, account, *_ = account_factory

#     execution_info = await account.get_plugin(signer1).call()
#     assert execution_info.result == (1,)

#     execution_info = await signer.send_transactions(
#         account, [
#             (account.contract_address, 'use_plugin', [signer1]),
#             (account.contract_address, 'get_plugin', [signer1]),
#             # (account.contract_address, 'get_public_key', [])
#         ]
#     )

#     assert execution_info.result[0][0] == 1

#     execution_info = await account.supportsInterface(IACCOUNT_ID).call()
#     assert execution_info.result == (TRUE,)


# @pytest.mark.asyncio
# async def test_execute(account_factory):
#     signer1, account, _, initializable_1, initializable_2, *_ = account_factory

#     execution_info = await initializable_1.initialized().call()
#     assert execution_info.result == (0,)

#     await signer.send_transactions(account, [
#         (initializable_1.contract_address, 'initialize', [])
#     ])

#     execution_info = await initializable_1.initialized().call()
#     assert execution_info.result == (1,)

#     execution_info = await initializable_2.initialized().call()
#     assert execution_info.result == (0,)

#     await signer.send_transactions(account, [
#         (account.contract_address, 'use_plugin', [signer1]),
#         (initializable_2.contract_address, 'initialize', [])
#     ])

#     execution_info = await initializable_2.initialized().call()
#     assert execution_info.result == (1,)


# @pytest.mark.asyncio
# async def test_multicall(account_factory):
#     signer1, account, _, initializable_1, initializable_2, _ = account_factory

#     execution_info = await initializable_1.initialized().call()
#     assert execution_info.result == (0,)
#     execution_info = await initializable_2.initialized().call()
#     assert execution_info.result == (0,)

#     await signer.send_transactions(
#         account,
#         [
#             (account.contract_address, 'use_plugin', [signer1]),
#             (initializable_1.contract_address, 'initialize', []),
#             (initializable_2.contract_address, 'initialize', [])
#         ]
#     )

#     execution_info = await initializable_1.initialized().call()
#     assert execution_info.result == (1,)
#     execution_info = await initializable_2.initialized().call()
#     assert execution_info.result == (1,)


# @pytest.mark.asyncio
# async def test_return_value(account_factory):
#     signer1, account, _, initializable, *_ = account_factory

#     # initialize, set `initialized = 1`
#     await signer.send_transactions(account, [(account.contract_address, 'use_plugin', [signer1]),
#                                              (initializable.contract_address, 'initialize', [])])

#     read_info = await signer.send_transactions(account, [(account.contract_address, 'use_plugin', [signer1]),
#                                                          (initializable.contract_address, 'initialized', [])])
#     call_info = await initializable.initialized().call()
#     (call_result, ) = call_info.result
#     assert read_info.result.response == [call_result]  # 1


# @pytest.mark.asyncio
# async def test_nonce(account_factory):
#     _, account, _, initializable, *_ = account_factory

#     execution_info = await account.get_nonce().call()
#     current_nonce = execution_info.result.res

#     # lower nonce
#     try:
#         await signer.send_transactions(account, [(initializable.contract_address, 'initialize', [])], current_nonce - 1)
#         assert False
#     except StarkException as err:
#         _, error = err.args
#         assert error['code'] == StarknetErrorCode.TRANSACTION_FAILED

#     # higher nonce
#     try:
#         await signer.send_transactions(account, [(initializable.contract_address, 'initialize', [])], current_nonce + 1)
#         assert False
#     except StarkException as err:
#         _, error = err.args
#         assert error['code'] == StarknetErrorCode.TRANSACTION_FAILED
#     # right nonce
#     await signer.send_transactions(account, [(initializable.contract_address, 'initialize', [])], current_nonce)

#     execution_info = await initializable.initialized().call()
#     assert execution_info.result == (1,)


@pytest.mark.asyncio
async def test_public_key_setter(account_factory):
    signer1, account, *_ = account_factory

    execution_info = await signer.send_transactions(account, [
        (account.contract_address, 'exec_plugin', [signer1]),
        (signer1, 'get_public_key', [])
    ])
    assert execution_info.result[0][0] == signer.public_key

    print(signer1, account.contract_address)

    # set new pubkey
    await signer.send_transactions(account, [
        (account.contract_address, 'exec_plugin', [signer1]),
        (signer1, 'set_public_key', [other.public_key])
    ])

    execution_info = await signer.send_transactions(account, [
        (account.contract_address, 'exec_plugin', [signer1]),
        (signer1, 'get_public_key', [])])
    assert execution_info.result == (other.public_key,)


# @pytest.mark.asyncio
# async def test_public_key_setter_different_account(account_factory):
#     _, account, bad_account, *_ = account_factory

#     # set new pubkey
#     await assert_revert(
#         signer.send_transactions(
#             bad_account,
#             [(account.contract_address, 'set_public_key', [other.public_key])]
#         ),
#         reverted_with="Account: caller is not this account"
#     )


# @pytest.mark.asyncio
# async def test_account_takeover_with_reentrant_call(account_factory):
#     _, account, _, _, _, attacker = account_factory

#     await assert_revert(
#         signer.send_transaction(
#             account, attacker.contract_address, 'account_takeover', []),
#         reverted_with="Account: no reentrant call"
#     )

    # execution_info = await account.get_public_key().call()
    # assert execution_info.result == (signer.public_key,)
