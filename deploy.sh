#!/bin/bash
cd "$(dirname "$(realpath -- "$0")")";
# Deploy bridge contract
PRIVATE_KEY=$1 UPGRADE_WALLET=$2 forge script script/DeploySwapV3.s.sol:TCScript --rpc-url $3 --broadcast -vvv