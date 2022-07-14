# SPDX-License-Identifier: MIT

%lang starknet

from openzeppelin.account.library import AccountCallArray

@contract_interface
namespace IController:
    func initialize(public_key: felt):
    end

    #
    # Getters
    #

    #
    # Setters
    #

    func add_public_key(new_public_key: felt):
    end

    func remove_public_key(public_key: felt):
    end

    #
    # Business logic
    #

    func is_valid_signature(
            hash: felt,
            signature_len: felt,
            signature: felt*
        ) -> (is_valid: felt):
    end

    func validate(
        plugin_data_len: felt,
        plugin_data: felt*,
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*
        ):
    end
end
