// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract FlashLoan is FlashLoanSimpleReceiverBase {
    address payable owner;

    constructor(address _addressProvider) 
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) 
    {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the Owner can call this");
        _;   
    }

    function arbitrage(address _tokenAddress, uint256 _amount) private returns (bool) {
        uint256 arbitrageAmount = (_amount/10);
        IERC20 token = IERC20(_tokenAddress);
        return token.transfer(owner, arbitrageAmount);
    }

        //Requests flash from the POOL of AAVE
    function requestFlashLoan(address _token, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    // This function is called after your contract has received the flash loaned amount
    function executeOperation (
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {

        // Calls Arbitrage function
        bool status = arbitrage(asset, amount);



        //Approve the Pool Contract allowance to 'PULL' the amount owed 
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return status;
    }

    function getBalance(address _tokenAddress) external view returns(uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);

        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    receive() external payable {}
}