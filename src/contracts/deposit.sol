// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

/// @title Sentible Pool Deposit Contract

abstract contract AaveDepositInterface {
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external payable virtual;
}

contract Deposit {
  address v2PoolAddress = 0xC6845a5C768BF8D7681249f8927877Efda425baf;
  AaveDepositInterface aaveDeposit = AaveDepositInterface(v2PoolAddress);

  function processDeposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
  ) public payable {
    aaveDeposit.deposit(asset, amount, onBehalfOf, 0);
  }
}
