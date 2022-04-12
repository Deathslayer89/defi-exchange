//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract Exchange is ERC20 {
    address public cryptoDevTokenAddress;

    constructor(address _CryptoDevtoken) ERC20("CryptoDev LP Token", "CDLP") {
        require(_CryptoDevtoken != address(0), "TOken address is NULL");
        cryptoDevTokenAddress = _CryptoDevtoken;
    }

    function getReserve() public view returns (uint256) {
        return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 liquidity;
        uint256 ethbalance = address(this).balance;
        uint256 cryptoDevTokenReserve = getReserve();
        ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);

        if (cryptoDevTokenReserve == 0) {
            cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethbalance;
            _mint(msg.sender, liquidity);
        } else {
            uint256 ethReserve = ethbalance - msg.value;
            uint256 cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve) /
                ethReserve;
            require(
                _amount >= cryptoDevTokenAmount,
                "Amount is less than the amount of the token"
            );
            cryptoDevToken.transferFrom(
                msg.sender,
                address(this),
                cryptoDevTokenAmount
            );
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
    }

    function removeLiquidity(uint256 _amount)
        public
        returns (uint256, uint256)
    {
        require(_amount > 0, "_amount should be greater than zero");
        uint256 ethReserve = address(this).balance;
        uint256 _totalSupply = totalSupply();
        uint256 ethAmount = (ethReserve * _amount) / _totalSupply;
        uint256 cryptoDevTokenAmount = (getReserve() * _amount) / _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
        return (ethAmount, cryptoDevTokenAmount);
    }

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }
    function ethToCryptoDevTOken(uint _mintTokens)public payable{
        uint tokenReserve=getReserve();
        uint tokensBought=getAmountOfTokens(msg.value, address(this).balance-msg.value, tokenReserve);
        require(tokensBought>=_mintTokens, "Not enough tokens");
        ERC20(cryptoDevTokenAddress).transfer(msg.sender, tokensBought);
    }
    function cryptoDevTokenToEth(uint _tokensSold,uint _mintEth)public{
        uint tokenReserve=getReserve();
        uint ethBought=getAmountOfTokens(_tokensSold, tokenReserve, address(this).balance);
        require(ethBought>=_mintEth, "Not enough eth");
        ERC20(cryptoDevTokenAddress).transferFrom(msg.sender,address(this), _tokensSold);
        payable(msg.sender).transfer(ethBought);
    } 
}
