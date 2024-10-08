// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IAuctionHouse} from "./IAuctionHouse.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract PodAuctionHouse is
    IAuctionHouse,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    IAuctionHouse.Auction public auction;

    uint256 public minimumRaise;

    /**
     * @notice Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() external override whenPaused nonReentrant {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a Pod Auction, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256, address)
        external
        payable
        override
        nonReentrant
    {
        IAuctionHouse.Auction memory _auction = auction;

        require(block.timestamp < _auction.endTime, "Auction expired");
        require(msg.value >= reservePrice, "Must send at least reservePrice");
        require(
            msg.value >=
                _auction.amount +
                    ((_auction.amount * minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
        require(
            msg.value >= _auction.amount + minimumRaise,
            "must send more than last bid by minimumRaise"
        );

        address payable lastBidder = _auction.bidder;
        uint256 cashback = _auction.earnAmount;
        uint256 lastAmount = _auction.amount;

        // Refund the last bidder, if applicable, plus 5%
        if (lastBidder != address(0)) {
            _safeTransferETH(lastBidder, _auction.amount.add(cashback));
        }

        uint256 earn = msg.value.sub(_auction.amount).mul(5).div(100);

        auction.earnAmount = earn;
        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(
            _auction.tokenId,
            msg.sender,
            msg.value,
            extended,
            earn
        );

        if (extended) {
            emit AuctionExtended(_auction.tokenId, _auction.endTime);
        }
    }

    /**
     * @notice Pause the Pod auction house.
     * @dev This function can only be called by the owner when the
     * contract is unpaused. While no new auctions can be started when paused,
     * anyone can settle an ongoing auction.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Pod auction house.
     * @dev This function can only be called by the owner when the
     * contract is paused.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) external override onlyOwner {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the auction time duration.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) external override onlyOwner {
        duration = _duration;

        emit AuctionTimeDurationUpdated(duration);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice)
        external
        override
        onlyOwner
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    function extendAuction(uint256 _extraTime) external onlyOwner {
        IAuctionHouse.Auction memory _auction = auction;

        _auction.endTime = _auction.endTime + _extraTime;
        auction = _auction;
        emit AuctionExtend(_extraTime);
    }

    function setMinimumRaise(uint256 _minimum) external onlyOwner {
        minimumRaise = _minimum;
    }

    function cancelLastAuction() external onlyOwner {
        IAuctionHouse.Auction memory _auction = auction;

        IERC721(_auction.contractAddress).transferFrom(
            address(this),
            owner(),
            _auction.tokenId
        );

        if (_auction.amount > 0) {
            address payable lastBidder = _auction.bidder;
            _safeTransferETH(lastBidder, _auction.amount);
        }

        auction.settled = true;
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage)
        external
        override
        onlyOwner
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(
            _minBidIncrementPercentage
        );
    }

    /**
     * @notice Create an auction.
     * @dev Store the auction details in the `auction` state variable and emit an AuctionCreated event.
     * fow the first version, only Pod team can create an auction
     */
    function createAuction(
        uint256 _tokenId,
        address _contractAddress,
        uint256 startingPrice
    ) external onlyOwner {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        IERC721(_contractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        auction = Auction({
            tokenId: _tokenId,
            contractAddress: _contractAddress,
            amount: startingPrice,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(msg.sender),
            settled: false,
            earnAmount: 0
        });

        emit AuctionCreated(_tokenId, startTime, endTime);
    }

    /**
     * @notice Settle an auction, finalizing the bid and paying out to the owner.
     */
    function _settleAuction() internal {
        IAuctionHouse.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Auction hasn't begun");
        require(!_auction.settled, "Auction has already been settled");
        require(
            block.timestamp >= _auction.endTime,
            "Auction hasn't completed"
        );

        auction.settled = true;

        IERC721(_auction.contractAddress).transferFrom(
            address(this),
            _auction.bidder,
            _auction.tokenId
        );

        if (_auction.amount > 0) {
            _safeTransferETH(owner(), _auction.amount);
        }

        emit AuctionSettled(
            _auction.tokenId,
            _auction.contractAddress,
            _auction.bidder,
            _auction.amount
        );
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdraw(uint256 amount) external {
        require(payable(msg.sender).send(amount));
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }
}
