// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
/// @title Sentible Pool Router Contract
/// @author Sentible
/// @notice This contract is used to deposit and withdraw from the Sentible Pool
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface AaveDepositInterface {
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function paused() external view returns (bool);
}

contract Deposit is Ownable {
  address v2PoolAddress = 0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210;
  bool public isPaused = false;
  AaveDepositInterface aaveDeposit = AaveDepositInterface(v2PoolAddress);

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf
  ) public payable {
    uint allowedValue = IERC20(asset).allowance(address(this), msg.sender);
    uint v2AllowedValue = IERC20(asset).allowance(v2PoolAddress, address(this));
    require(allowedValue <=amount, "Allowance required");
    require(!aaveDeposit.paused(), "Aave contract is paused");
    require(!isPaused, "Deposit contract is paused");

    IERC20(asset).transferFrom(msg.sender, address(this), amount);

    if (v2AllowedValue < amount) {
      IERC20(asset).approve(v2PoolAddress, amount);
    }

    aaveDeposit.deposit(asset, amount, onBehalfOf, 0);
  }

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) public {
    require(!aaveDeposit.paused(), "Aave contract is paused");
    require(!isPaused, "Deposit contract is paused");
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    IERC20(asset).approve(v2PoolAddress, amount);
    aaveDeposit.withdraw(asset, amount, to);
  }

  function setPoolAddress(address _poolAddress) public onlyOwner {
    v2PoolAddress = _poolAddress;
  }

  function setPaused(bool _isPaused) public onlyOwner {
    isPaused = _isPaused;
  }
}
