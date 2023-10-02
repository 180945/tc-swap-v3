// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import {AddressUpgradeable} from "@openzeppelin-upgradeable/utils/AddressUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "../base/BlockContext.sol";
import "./interfaces/IUniswapV3Factory.sol";

import "./UniswapV3PoolDeployer.sol";
import "./NoDelegateCall.sol";

import "./UniswapV3Pool.sol";

/// @title Canonical Uniswap V3 factory
/// @notice Deploys Uniswap V3 pools and manages _ownership and control over pool protocol fees
contract UniswapV3Factory is
    IUniswapV3Factory,
    BlockContext,
    OwnableUpgradeable,
    UniswapV3PoolDeployer,
    NoDelegateCall
{
    using AddressUpgradeable for address;
    //
    /// @inheritdoc IUniswapV3Factory
    address public override getUniswapV3PoolImplementation;
    /// @inheritdoc IUniswapV3Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc IUniswapV3Factory
    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getPool;
    /// @inheritdoc IUniswapV3Factory
    uint8 public override feeProtocol;
    /// @inheritdoc IUniswapV3Factory
    address public override feeTo;

    function initialize() external initializer {
        __Ownable_init();
        __NoDelegateCall_init();
        //
        feeAmountTickSpacing[100] = 1;
        emit FeeAmountEnabled(100, 1);
        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
        //
        setFeeToInternal(msg.sender);
        setFeeProtocolInternal(2, 2);
    }

    function setUniswapV3PoolImplementation(
        address uniswapV3PoolImplementationArg
    ) external onlyOwner {
        require(uniswapV3PoolImplementationArg.isContract(), "UF_INC");
        getUniswapV3PoolImplementation = uniswapV3PoolImplementationArg;
    }

    /// @inheritdoc IUniswapV3Factory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IUniswapV3Factory
    function enableFeeAmount(
        uint24 fee,
        int24 tickSpacing
    ) public override onlyOwner {
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }

    function setFeeProtocol(
        uint8 feeProtocol0,
        uint8 feeProtocol1
    ) external override onlyOwner {
        setFeeProtocolInternal(feeProtocol0, feeProtocol1);
    }

    function setFeeProtocolInternal(
        uint8 feeProtocol0,
        uint8 feeProtocol1
    ) internal {
        require(
            (feeProtocol0 == 0 || (feeProtocol0 >= 2 && feeProtocol0 <= 10)) &&
                (feeProtocol1 == 0 || (feeProtocol1 >= 2 && feeProtocol1 <= 10))
        );
        uint8 feeProtocolOld = feeProtocol;
        feeProtocol = feeProtocol0 + (feeProtocol1 << 4);
        emit SetFeeProtocol(
            feeProtocolOld % 16,
            feeProtocolOld >> 4,
            feeProtocol0,
            feeProtocol1
        );
    }

    function setFeeTo(address feeToArg) external override onlyOwner {
        setFeeToInternal(feeToArg);
    }

    function setFeeToInternal(address feeToArg) internal {
        require(feeToArg != address(0));
        feeTo = feeToArg;
        emit SetFeeTo(feeToArg, feeTo);
    }
}
