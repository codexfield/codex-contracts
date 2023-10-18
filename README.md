
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
forge script ./script/1-deploy.s.sol --rpc-url ${RPC_TESTNET} --legacy --broadcast --via-ir --private-key ${OWNER_PRIVATE_KEY}
```

## Upgrade

### Upgrade Account Manager