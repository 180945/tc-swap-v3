#!/bin/bash

# Deploy bridge contract
PRIVATE_KEY=$1 UPGRADE_WALLET=$2 WTC=$3 forge script script/DeploySwapV3.s.sol:TCScript --rpc-url $4 --broadcast -vvv