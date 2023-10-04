// SPDX-License-Identifier: UNLICENSED
pragma abicoder v2;
pragma solidity >=0.6.0 <0.8.0;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/core/UniswapV3PoolProxy.sol";
import "../src/core/UniswapV3Factory.sol";
import "../src/periphery/libraries/NFTDescriptor.sol";
import "../src/periphery/NonfungibleTokenPositionDescriptor.sol";
import "../src/periphery/lens/QuoterV2.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";
import "../src/wtc/wtc.sol";

contract TCScript is Script {
    address upgradeAddress;
    address wtc;

    function setUp() public {
        upgradeAddress = vm.envAddress("UPGRADE_WALLET");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy wtc
        wtc = address(new WETH9());

        // deploy v3 pool factory
        UniswapV3Factory uV3FactoryImp = new UniswapV3Factory();

        // deploy v3 pool
        UniswapV3Pool uV3PoolImp = new UniswapV3Pool();

        // @todo: deploy lib once nftDescriptor: ContractData
        // NFTDescriptor nftDescriptorLib = new NFTDescriptor();

        // nonfungibleTokenPositionDescriptor: ContractData
        NonfungibleTokenPositionDescriptor nftPositionImp = new NonfungibleTokenPositionDescriptor();

        // @todo: deploy lib once
        // UniswapV3Broker

        // uniswapV3Broker: ContractData
        NonfungiblePositionManager nftPManagerImp = new NonfungiblePositionManager();

        // swap router
        SwapRouter swapRouterImp = new SwapRouter();

        // quote v2
        QuoterV2 quoteV2Imp = new QuoterV2();

        bytes memory result = bytes('{');

        result = abi.encodePacked(result, jsonFormat(bytes('"WTC"'), bytes(vm.toString(address(wtc))), false));

        // @Addresses deploy proxy
        UniswapV3Factory uV3Factory = UniswapV3Factory(address(new TransparentUpgradeableProxy(
            address(uV3FactoryImp),
            upgradeAddress,
            abi.encodeWithSelector(UniswapV3Factory.initialize.selector)
        )));
        uV3Factory.setUniswapV3PoolImplementation(address(uV3PoolImp));

        result = abi.encodePacked(result, jsonFormat(bytes('"UniswapV3Factory"'), bytes(vm.toString(address(uV3Factory))), false));

        // NonfungibleTokenPositionDescriptor
        address nftPosition =  address(new TransparentUpgradeableProxy(
            address(nftPositionImp),
            upgradeAddress,
            abi.encodeWithSelector(
                NonfungibleTokenPositionDescriptor.initialize.selector,
                wtc,
                bytes32("TC")
            )
        ));

        result = abi.encodePacked(result, jsonFormat(bytes('"NonfungibleTokenPositionDescriptor"'), bytes(vm.toString(address(nftPosition))), false));

        address nftPManager =  address(new TransparentUpgradeableProxy(
            address(nftPManagerImp),
            upgradeAddress,
            abi.encodeWithSelector(
                NonfungiblePositionManager.initialize.selector,
                address(uV3Factory),
                wtc,
                nftPosition
            )
        ));

        result = abi.encodePacked(result, jsonFormat(bytes('"NonfungiblePositionManager"'), bytes(vm.toString(address(nftPManager))), false));

        // router
        address swapRouter =  address(new TransparentUpgradeableProxy(
            address(swapRouterImp),
            upgradeAddress,
            abi.encodeWithSelector(
                SwapRouter.initialize.selector,
                address(uV3Factory),
                wtc
            )
        ));

        result = abi.encodePacked(result, jsonFormat(bytes('"SwapRouter"'), bytes(vm.toString(address(swapRouter))), false));

        // quoteV2
        address quoteV2 =  address(new TransparentUpgradeableProxy(
            address(quoteV2Imp),
            upgradeAddress,
            abi.encodeWithSelector(
                QuoterV2.initialize.selector,
                address(uV3Factory),
                wtc
            )
        ));

        result = abi.encodePacked(result, jsonFormat(bytes('"QuoterV2"'), bytes(vm.toString(address(quoteV2))), true));

        vm.stopBroadcast();

        vm.writeFile("deploy.json", string(result));
    }

    function jsonFormat(bytes memory key, bytes memory value, bool isLastItem) pure internal returns(bytes memory temp) {
        temp = abi.encodePacked(temp, key);
        temp = abi.encodePacked(temp, bytes(':'));
        temp = abi.encodePacked(temp, bytes('"'));
        temp = abi.encodePacked(temp, value);
        temp = abi.encodePacked(temp, bytes('"'));

        if (!isLastItem) {
            temp = abi.encodePacked(temp, bytes(','));
        } else {
            temp = abi.encodePacked(temp, bytes('}'));
        }
    }
}