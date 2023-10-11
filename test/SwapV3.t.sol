// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "../src/core/UniswapV3Factory.sol";
import "../src/periphery/NonfungibleTokenPositionDescriptor.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";
import "../src/periphery/lens/QuoterV2.sol";
import "../src/wtc/wtc.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract SwapV3Test is Test {
    address public constant ADMIN_ADDR = address(10);
    address public constant U_1 = address(11);
    address public constant U_2 = address(12);
    uint256 public constant DEFAULT_HOLDING_PERIOD = 100;
    address public constant upgradeAddress = address(123);
    address public wtc;
    address public nftPosition;
    address public nftPManager;
    address public swapRouter;
    address public quoteV2;
    UniswapV3Factory public uV3Factory;

    function setUp() public {
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
        // @Addresses deploy proxy
        uV3Factory = UniswapV3Factory(address(new TransparentUpgradeableProxy(
            address(uV3FactoryImp),
            upgradeAddress,
            abi.encodeWithSelector(UniswapV3Factory.initialize.selector)
        )));
        uV3Factory.setUniswapV3PoolImplementation(address(uV3PoolImp));

        // NonfungibleTokenPositionDescriptor
        nftPosition =  address(new TransparentUpgradeableProxy(
            address(nftPositionImp),
            upgradeAddress,
            abi.encodeWithSelector(
                NonfungibleTokenPositionDescriptor.initialize.selector,
                wtc,
                bytes32("TC")
            )
        ));

        nftPManager =  address(new TransparentUpgradeableProxy(
            address(nftPManagerImp),
            upgradeAddress,
            abi.encodeWithSelector(
                NonfungiblePositionManager.initialize.selector,
                address(uV3Factory),
                wtc,
                nftPosition
            )
        ));

        // router
        swapRouter =  address(new TransparentUpgradeableProxy(
            address(swapRouterImp),
            upgradeAddress,
            abi.encodeWithSelector(
                SwapRouter.initialize.selector,
                address(uV3Factory),
                wtc
            )
        ));

        // quoteV2
        quoteV2 =  address(new TransparentUpgradeableProxy(
            address(quoteV2Imp),
            upgradeAddress,
            abi.encodeWithSelector(
                QuoterV2.initialize.selector,
                address(uV3Factory),
                wtc
            )
        ));

        UniswapV3Factory(uV3Factory).enableFeeAmount(50000, 1000);
        UniswapV3Factory(uV3Factory).enableFeeAmount(100000, 2000);
    }

    function testAddLiquidity() public {
        ERC20PresetMinterPauser usdc = new ERC20PresetMinterPauser("USDC", "USDC");
        ERC20PresetMinterPauser usdt = new ERC20PresetMinterPauser("USDT", "USDT");

        usdc.mint(U_1, 1e30);
        usdt.mint(U_1, 1e30);
        uint24 fee = 3000;

        (address token0, address token1) = address(usdc) > address(usdt) ?
            (address(usdt), address(usdc)) :
            (address(usdc), address(usdt));

        vm.startPrank(U_1);

        usdc.approve(nftPManager, 1e30);
        usdt.approve(nftPManager, 1e30);

        console.logBytes32(keccak256(abi.encodePacked(type(UniswapV3PoolProxy).creationCode)));

        NonfungiblePositionManager(payable(nftPManager)).createAndInitializePoolIfNecessary(
            token0,
            token1,
            fee,
            13907420169552288117713198190076
        );

        uV3Factory.getPool(token0, token1, fee);

        INonfungiblePositionManager.MintParams memory test = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: 48840,
            tickUpper: 50820,
            amount0Desired: 56000000000000000000,
            amount1Desired: 7319209853762021079375,
            amount0Min: 0,
            amount1Min: 0,
            recipient: U_1,
            deadline: 1697028929
        });

        NonfungiblePositionManager(payable(nftPManager)).mint(test);

        vm.stopPrank();
    }
}
