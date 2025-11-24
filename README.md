## Install Dependencies

```shell
 yarn install
```

## Build

```shell
 forge build --via-ir --use 0.8.20
```

## Test

```shell
 forge test --via-ir --use 0.8.20
 forge test --match-path test/CodexHub.t.sol --fork-url ${RPC_URL} -vvvvv  --via-ir --use 0.8.20
```

## Deploy

```shell
source .env
forge script ./script/1-deploy-account-manager.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use 0.8.20
forge script ./script/3-deploy-codex-hub.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use 0.8.20
```

## Upgrade

```shell
source .env
forge script ./script/2-upgrade-account-manager.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use 0.8.20
forge script ./script/4-upgrade-codex-hub.s.sol --rpc-url ${RPC_URL} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY} --use 0.8.20
```