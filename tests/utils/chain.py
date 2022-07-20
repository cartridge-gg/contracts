from starkware.starknet.business_logic.state.state import BlockInfo

DEFAULT_TIMESTAMP = 1640991600

def update_starknet_block(starknet, block_number=1, block_timestamp=DEFAULT_TIMESTAMP):
    starknet.state.state.block_info = BlockInfo(
        block_number=block_number, block_timestamp=block_timestamp, gas_price=0)

def reset_starknet_block(starknet):
    update_starknet_block(starknet=starknet)
