# Build and test
build :; nile compile
test  :; pytest tests/account/test_Account.py -s
