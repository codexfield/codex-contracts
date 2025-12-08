## Install Dependencies

```shell
forge install bnb-chain/greenfield-contracts@v1.2.2 --no-commit
forge install OpenZeppelin/openzeppelin-contracts@v4.9.3 --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v4.9.3 --no-commit
```

## Build

```shell
 forge build --via-ir --use ${COMPILER_VERSION}
```

## Test

```shell
 forge test --fork-url ${RPC_URL} --via-ir --use ${COMPILER_VERSION}
```

## Deploy

```shell
source .env
forge script ./script/1-deploy-account-manager.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use ${COMPILER_VERSION}  --verify --etherscan-api-key ${BSC_API_KEY}
```

## Upgrade

```shell
source .env
forge script ./script/2-upgrade-account-manager.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use ${COMPILER_VERSION}  --verify --etherscan-api-key ${BSC_API_KEY}
```

## Migrate

```shell
source .env
forge script ./script/3-migrate-account-manager.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use ${COMPILER_VERSION}
```