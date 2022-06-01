%lang starknet

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.memcpy import memcpy
from starkware.starknet.common.syscalls import call_contract, get_caller_address, get_tx_info

from openzeppelin.introspection.ERC165 import ERC165

from openzeppelin.utils.constants import IACCOUNT_ID

from src.account.IPlugin import IPlugin
from openzeppelin.account.library import Call, AccountCallArray

const USE_PLUGIN_SELECTOR = 1121675007639292412441492001821602921366030142137563176027248191276862353634

#
# Storage
#

@storage_var
func Account_current_nonce() -> (res: felt):
end

@storage_var
func Account_default_plugin() -> (res: felt):
end

@storage_var
func Account_plugins(plugin: felt) -> (res: felt):
end

@storage_var
func Account_plugin_storage(plugin: felt, key: felt) -> (res: felt):
end

namespace Account:

    #
    # Initializer
    #

    func initializer{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(plugin: felt):
        Account_plugins.write(plugin, 1)
        Account_default_plugin.write(plugin)
        ERC165.register_interface(IACCOUNT_ID)
        return()
    end

    #
    # Guards
    #

    func assert_only_self{syscall_ptr : felt*}():
        let (self) = get_contract_address()
        let (caller) = get_caller_address()
        with_attr error_message("Account: caller is not this account"):
            assert self = caller
        end
        return ()
    end

    #
    # Getters
    #

    func get_nonce{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (res: felt):
        let (res) = Account_current_nonce.read()
        return (res=res)
    end

    func get_plugin{
            syscall_ptr: felt*, 
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (plugin: felt) -> (success: felt):
        let (res) = Account_plugins.read(plugin)
        return (success=res)
    end

    func get_plugin_storage{
            syscall_ptr : felt*,
            range_check_ptr,
            pedersen_ptr : HashBuiltin*
        } (
            plugin: felt,
            key: felt
        ) -> (value : felt):
        let (value) = Account_plugin_storage.read(plugin, key)
        return (value=value)
    end

    #
    # Setters
    #

    func set_plugin{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        } (
            plugin: felt,
            value: felt
        ):
        # only called via execute
        assert_only_self()

        # change signer
        with_attr error_message("plugin cannot be null"):
            assert_not_zero(plugin)
        end
        Account_plugins.write(plugin, value)
        return()
    end

    func set_plugin_storage{
            syscall_ptr : felt*,
            range_check_ptr,
            pedersen_ptr : HashBuiltin*
        } (
            plugin: felt,
            key: felt,
            value: felt
        ):
        Account_plugin_storage.write(plugin, key, value)
        return()
    end

    #
    # Business logic
    #

    func is_valid{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            ecdsa_ptr: SignatureBuiltin*,
            range_check_ptr
        } (
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*
        ):
        alloc_locals

        let plugin = calldata[call_array[0].data_offset]
        let (is_plugin) = Account_plugins.read(plugin)
        assert_not_zero(is_plugin)

        IPlugin.delegate_validate(
            contract_address=plugin,
            plugin_data_len=call_array[0].data_len - 1,
            plugin_data=calldata + call_array[0].data_offset + 1,
            call_array_len=call_array_len - 1,
            call_array=call_array + AccountCallArray.SIZE,
            calldata_len=calldata_len - call_array[0].data_len,
            calldata=calldata + call_array[0].data_offset + call_array[0].data_len)
        return()
    end

    func execute{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*
        }(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
        alloc_locals

        let (caller) = get_caller_address()
        with_attr error_message("Account: no reentrant call"):
            assert caller = 0
        end

        let (__fp__, _) = get_fp_and_pc()
        let (tx_info) = get_tx_info()
        let (_current_nonce) = Account_current_nonce.read()

        # validate nonce
        assert _current_nonce = nonce
        # bump nonce
        Account_current_nonce.write(_current_nonce + 1)

        # TMP: Convert `AccountCallArray` to 'Call'.
        let (calls : Call*) = alloc()
        _from_call_array_to_call(call_array_len, call_array, calldata, calls)
        let calls_len = call_array_len

        # validate & execute calls
        let (response : felt*) = alloc()

        # validate with plugin
        is_valid(call_array_len, call_array, calldata_len, calldata)
        let (response_len) = _execute_list(calls_len - 1, calls + Call.SIZE, response)

        return (response_len=response_len, response=response)
    end

    func _execute_list{syscall_ptr: felt*}(
            calls_len: felt,
            calls: Call*,
            response: felt*
        ) -> (response_len: felt):
        alloc_locals

        # if no more calls
        if calls_len == 0:
           return (0)
        end

        # do the current call
        let this_call: Call = [calls]
        let res = call_contract(
            contract_address=this_call.to,
            function_selector=this_call.selector,
            calldata_size=this_call.calldata_len,
            calldata=this_call.calldata
        )
        # copy the result in response
        memcpy(response, res.retdata, res.retdata_size)
        # do the next calls recursively
        let (response_len) = _execute_list(calls_len - 1, calls + Call.SIZE, response + res.retdata_size)
        return (response_len + res.retdata_size)
    end

    func _from_call_array_to_call{syscall_ptr: felt*}(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata: felt*,
            calls: Call*
        ):
        # if no more calls
        if call_array_len == 0:
           return ()
        end

        # parse the current call
        assert [calls] = Call(
                to=[call_array].to,
                selector=[call_array].selector,
                calldata_len=[call_array].data_len,
                calldata=calldata + [call_array].data_offset
            )
        # parse the remaining calls recursively
        _from_call_array_to_call(call_array_len - 1, call_array + AccountCallArray.SIZE, calldata, calls + Call.SIZE)
        return ()
    end
end
