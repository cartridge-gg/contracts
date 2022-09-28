// SPDX-License-Identifier: MIT

%lang starknet

from openzeppelin.account.library import AccountCallArray

@contract_interface
namespace IPlugin {
    // Method to call during validation
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
