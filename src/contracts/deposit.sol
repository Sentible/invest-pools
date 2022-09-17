// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 < 0.9.0;
pragma experimental ABIEncoderV2;
/// @title Sentible v1 Router Contract
/// @author SentibleLabs
/// @notice This contract is used to deposit and withdraw from the Sentible Pool
import "@aave/protocol-v2/contracts/interfaces/IAToken.sol";

interface AaveLendingPool {
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function getReserveData(address asset) external view returns (
    uint256 configuration,
    uint128 liquidityIndex,
    uint128 variableBorrowIndex,
    uint128 currentLiquidityRate,
    uint128 currentVariableBorrowRate,
    uint128 currentStableBorrowRate,
    uint40 lastUpdateTimestamp,
    address aTokenAddress,
    address stableDebtTokenAddress,
    address variableDebtTokenAddress,
    address interestRateStrategyAddress,
    uint8 id
  );

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;

  function paused() external view returns (bool);
}

contract SentibleRouterV1 {
  address public owner;
  address public lendingPoolAddress;
  bool public isPaused = false;
  AaveLendingPool aaveLendingPool;

  event Deposit(address owner, uint256 amount, address asset);
  event Withdraw(address owner, uint256 amount, address asset);

  modifier poolActive {
    require(!aaveLendingPool.paused(), "Aave contract is paused");
    require(!isPaused, "Sentible contract is paused");
    _;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  constructor() public {
    owner = msg.sender;
    lendingPoolAddress = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    aaveLendingPool = AaveLendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  }

  function approveSpender(address asset, uint256 amount, address spender) public onlyOwner {
    IERC20(asset).approve(spender, amount);
  }

  function approvePool(address asset, uint256 amount) public onlyOwner {
    IERC20(asset).approve(lendingPoolAddress, amount);
  }

  // Deposit to lending pool
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf
  ) public poolActive {
    require(IERC20(asset).allowance(msg.sender, address(this)) >= amount, "Allowance required");

    IERC20(asset).approve(lendingPoolAddress, amount);
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    aaveLendingPool.deposit(asset, amount, onBehalfOf, 0);
    emit Deposit(msg.sender, amount, asset);
  }

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) public poolActive {
    (, , , , , , , address aTokenAddress, , , , ) = aaveLendingPool.getReserveData(asset);
    address borrower = address(this);
    IAToken aToken = IAToken(aTokenAddress);

    aToken.transferFrom(msg.sender, borrower, amount);
    aaveLendingPool.withdraw(asset, amount, to);
    emit Withdraw(msg.sender, amount, asset);
  }

  function setPoolAddress(address _poolAddress) public onlyOwner {
    require(msg.sender == owner, "Only owner can set pool address");
    lendingPoolAddress = _poolAddress;
    aaveLendingPool = AaveLendingPool(_poolAddress);
  }

  function setPaused(bool _isPaused) public onlyOwner {
    require(msg.sender == owner, "Only owner can pause");
    isPaused = _isPaused;
  }
}
