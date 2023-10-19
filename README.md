
## Install Dependencies

```shell
 forge install openzeppelin/openzeppelin-contracts@v4.9.3 --no-commit
 forge install openzeppelin/openzeppelin-contracts-upgradeable@v4.9.3 --no-commit
```

## Build

```shell
 forge build --via-ir
```

## Test

```shell
 forge test --via-ir
```

## Deploy

```shell
source .env
forge script ./script/1-deploy-account-manager.s.sol --rpc-url ${RPC_TESTNET} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY}
```

## Upgrade

```shell
source .env
forge script ./script/2-upgrade-account-manager.s.sol --rpc-url ${RPC_TESTNET} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY}
```