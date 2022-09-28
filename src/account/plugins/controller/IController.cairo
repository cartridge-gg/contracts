// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_secp.ec import EcPoint

from openzeppelin.account.library import AccountCallArray

@contract_interface
namespace IController {
    func initialize(admin_key: EcPoint, device_key: felt) {
    }

    //
    // Getters
    //

    //
    // Setters
    //

    func add_device_key(new_device_key: felt) {
    }

    func remove_device_key(device_key: felt) {
    }

    //
    // Business logic
    //

    func is_valid_signature(hash: felt, signature_len: felt, signature: felt*) -> (is_valid: felt) {
    }

    func validate(
        plugin_data_len: felt,
        plugin_data: felt*,
        call_array_len: felt,
        call_array: AccountCallArray*,
        calldata_len: felt,
        calldata: felt*,
    ) {
    }
}
