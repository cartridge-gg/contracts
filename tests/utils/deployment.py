
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import compile_starknet_files

CAIRO_PATH = [
    "lib",
    "lib/cairo_webauthn",
    "lib/cairo_webauthn/lib/cairo_base64",
    "lib/cairo_webauthn/lib/cairo_p256",
    "lib/cairo_contracts/src",
    "lib/argent_contracts_starknet"]

contract_classes = {}

async def deploy(starknet, path, params=None):
    params = params or []
    if path in contract_classes:
        contract_class, class_hash = contract_classes[path]
    else:
        contract_class = compile_starknet_files(
            [path], debug_info=True, cairo_path=CAIRO_PATH, disable_hint_validation=True)
        class_hash = await starknet.declare(contract_class=contract_class)
        contract_classes[path] = contract_class, class_hash
    deployed_contract = await starknet.deploy(contract_class=contract_class, constructor_calldata=params)
    return deployed_contract, class_hash


async def declare(starknet, path):
    contract_class = compile_starknet_files(
        [path], debug_info=True, cairo_path=CAIRO_PATH)
    declared_class = await starknet.declare(contract_class=contract_class)
    return declared_class


async def deploy_proxy(starknet, proxy_path, abi, params=None):
    params = params or []
    proxy_class = compile_starknet_files(
        [proxy_path], debug_info=True, cairo_path=CAIRO_PATH)
    declared_proxy = await starknet.declare(contract_class=proxy_class)
    deployed_proxy = await starknet.deploy(contract_class=proxy_class, constructor_calldata=params)
    wrapped_proxy = StarknetContract(
        state=starknet.state,
        abi=abi,
        contract_address=deployed_proxy.contract_address,
        deploy_execution_info=deployed_proxy.deploy_execution_info)
    return deployed_proxy, wrapped_proxy
