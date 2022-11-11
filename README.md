# Cartridge Contracts

Cairo implementations of Cartridge onchain functionality.

## Setup

First, install nile + protostar.

Then install the package dependencies:
```sh
protostar install
```

## Build

```sh
protostar build
```

## Declare

```sh
protostar declare ./build/account.json --network=testnet
protostar declare ./build/account_proxy.json --network=testnet
protostar declare ./build/avatar.json --network=testnet
protostar declare ./build/controller.json --network=testnet
protostar declare ./build/experience.json --network=testnet
protostar declare ./build/proxy.json --network=testnet
```
