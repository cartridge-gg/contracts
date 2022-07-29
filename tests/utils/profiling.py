def gas_report(tx):
    resource = tx.call_info.execution_resources
    builtins = resource.builtin_instance_counter
    gas = resource.n_steps * 0.05 \
        + builtins['pedersen_builtin'] * 0.4 \
        + builtins['range_check_builtin'] * 0.4 \
        + builtins['bitwise_builtin'] * 12.8
    return "\n gas: {:10.0f}\n".format(gas) 