// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // keep track who fund
    mapping(address => uint256) public whoSent;
    address[] public funders;
    using SafeMathChainlink for uint256;

    // define who is the owner
    address public owner;
    AggregatorV3Interface public priceFeed;

    // The _priceFeed is passed by brownie using the deploy method
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; // sender is who deploy the smart contract
    }

    // accept payments
    function fund() public payable {
        // payable keyword (ETH). Each function is associated with a value
        //map that associate to each address that call fund, with the value sent

        // convert min value to wei
        uint256 minUSD = 0.5 * 10**18;
        // like an assert. If the rquest is nos satisfied, it do an automatic revert
        require(
            getConvertionRate(msg.value) >= minUSD,
            "Coglione ma che non hai soldi!?"
        );

        whoSent[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // if the contract is found
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000); // we converted the price in wei
    }

    function getConvertionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        //We retireve the contract located at that address thata have the functions defined in the interface above.
        uint256 ethPriceWei = getPrice();
        uint256 ethPriceUSD = (ethPriceWei * ethAmount) / 1000000000000000000;
        return ethPriceUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimun USD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    //Modifier used to change the behaviour of a function in a declarative way
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (uint256 fIndex = 0; fIndex < funders.length; fIndex++) {
            address funder = funders[fIndex];
            whoSent[funder] = 0;
        }

        //retest also the array of funders
        funders = new address[](0);
    }
}
