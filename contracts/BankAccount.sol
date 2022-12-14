// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract BankAccount {
  address owner;

  bytes32[] public whitelistedSymbols;
  mapping(bytes32 => address) public whitelistedTokens;
  mapping(address => mapping(bytes32 => uint256)) public balances;

  event LogDeposit(address _address, uint256 _amount);
  event LogWithdrawal(address _address, uint256 _amount);

  modifier validAmount(uint256 _amount){
    require(_amount > 0, 'Amount is not valid');
    _;
    }

  constructor() {
    owner = msg.sender;
  }

  function whitelistToken(bytes32 _symbol, address _tokenAddress) external {
    require(msg.sender == owner, 'This function is not public!');

    whitelistedSymbols.push(_symbol);
    whitelistedTokens[_symbol] = _tokenAddress;
  }

  function getWhitelistedSymbols() external view returns(bytes32[] memory) {
    return whitelistedSymbols;
  }

  function getWhitelistedTokenAddress(bytes32 _symbol) external view returns(address) {
    return whitelistedTokens[_symbol];
  }

  receive() external payable {
    balances[msg.sender]['Eth'] += msg.value;
  }

  function withdrawEther(uint _withdrawAmount) external {
    require(balances[msg.sender]['Eth'] >= _withdrawAmount, 'Insufficient funds');

    balances[msg.sender]['Eth'] -= _withdrawAmount;
    (bool success, ) = payable(msg.sender).call{value: _withdrawAmount}("");
    require(success, 'Failed to send ETH');
    emit LogWithdrawal(msg.sender, _withdrawAmount);
  }

  function depositTokens(uint256 _amount, bytes32 _symbol) external {
    balances[msg.sender][_symbol] += _amount;
    IERC20(whitelistedTokens[_symbol]).transferFrom(msg.sender, address(this), _amount);
    emit LogDeposit(msg.sender, _amount);
  }

  function withdrawTokens(uint256 _withdrawAmount, bytes32 _symbol) external {
    require(balances[msg.sender][_symbol] >= _withdrawAmount, 'Insufficient funds');

    balances[msg.sender][_symbol] -= _withdrawAmount;
    IERC20(whitelistedTokens[_symbol]).transfer(msg.sender, _withdrawAmount);
    emit LogWithdrawal(msg.sender, _withdrawAmount);
  }

  function getTokenBalance(bytes32 _symbol) external view returns(uint256) {
    return balances[msg.sender][_symbol];
  }
}