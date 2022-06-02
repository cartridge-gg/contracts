# SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from openzeppelin.account.library import AccountCallArray
from src.account.library import Account
from src.account.plugins.signer.ISigner import ISigner
from starkware.starknet.common.syscalls import library_call

from openzeppelin.introspection.ERC165 import ERC165

#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    plugin_hash : felt, initializer_calldata_len : felt, initializer_calldata : felt*
):
    library_call(
        class_hash=plugin_hash,
        function_selector=215307247182100370520050591091822763712463273430149262739280891880522753123,
        calldata_size=initializer_calldata_len,
        calldata=initializer_calldata,
    )
    Account.initializer(plugin_hash)
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
func get_plugin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    plugin : felt
) -> (res : felt):
    let (res) = Account.get_plugin(plugin)
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
