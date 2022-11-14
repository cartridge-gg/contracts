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

#### Existing declarations

Account: `0x058551c375e5cbf4458c4875d9a9c0d0fe6c91740ea3e2e4db3a6923761c457c`
Account Proxy: `0x04be79b3904b4e2775fd706fa037610b41d8f8708ce298aac3a470badf68176d`
Avatar: `0x0750bdf3e4f49e3395b0864cfd8a3b11677f5683ea30925f644235dfba5a5304`
Controller: `0x0286a2ea79ee08506efcbc330efd2ae34e2f22b79ecd2fb9b86ce26d6a1dbece`
Experience: `0x024687922f74953d73475008a5285c5f2a57efe751a6b060dc14f1e73cf375cf`
Proxy: `0x01067c8f4aa8f7d6380cc1b633551e2a516d69ad3de08af1b3d82e111b4feda4`
