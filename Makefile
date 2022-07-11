# Build and test
build :; nile compile
test  :; pytest tests/account/test_plugin_signer.py -s
