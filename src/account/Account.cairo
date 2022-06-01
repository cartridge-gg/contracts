# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from openzeppelin.account.library import AccountCallArray
from src.account.library import Account
from src.account.plugins.signer.ISigner import ISigner

from openzeppelin.introspection.ERC165 import ERC165

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    plugin : felt, public_key : felt
):
    Account.initializer(plugin)
    ISigner.delegate_initialize(contract_address=plugin, public_key=public_key)
    return ()
end

#
# Getters
#

@view
func get_nonce{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res : felt):
    let (res) = Account.get_nonce()
    return (res=res)
end

@view
func supportsInterface{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    interfaceId : felt
) -> (success : felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

#
# Setters
#

@external
func set_plugin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(plugin : felt):
    Account.set_plugin(plugin, 1)
    return ()
end

#
# Business logic
#

@external
func __execute__{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, ecdsa_ptr : SignatureBuiltin*
}(
    call_array_len : felt,
    call_array : AccountCallArray*,
    calldata_len : felt,
    calldata : felt*,
    nonce : felt,
) -> (response_len : felt, response : felt*):
    let (response_len, response) = Account.execute(
        call_array_len, call_array, calldata_len, calldata, nonce
    )
    return (response_len=response_len, response=response)
end
