
## Install Dependencies

```shell
 forge install openzeppelin/openzeppelin-contracts@v4.9.3 --no-commit
 forge install openzeppelin/openzeppelin-contracts-upgradeable@v4.9.3 --no-commit
```

## Build

```shell
 forge build --via-ir --use 0.8.20
```

## Test

```shell
 forge test --via-ir --use 0.8.20
```

## Deploy

```shell
source .env
forge script ./script/1-deploy-account-manager.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use 0.8.20
```

## Upgrade

```shell
source .env
forge script ./script/2-upgrade-account-manager.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use 0.8.20
```