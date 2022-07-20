# Build and test
build :; nile compile
test  :; pytest tests/account -s
