pragma solidity ^0.8.4;

interface IAuctionHouse {
    struct Auction {
        // ID for the NFT (ERC721 token ID)
        uint256 tokenId;
        // Address for the NFT contract
        address contractAddress;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
        // amount of earn
        uint256 earnAmount;
    }

    event AuctionCreated(
        uint256 indexed nftId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed nftId,
        address sender,
        uint256 value,
        bool extended,
        uint256 earn
    );

    event AuctionExtended(uint256 indexed nftId, uint256 endTime);

    event AuctionSettled(
        uint256 indexed nftId,
        address indexed contractAddress,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionTimeDurationUpdated(uint256 duration);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    event AuctionExtend(uint256 extraTime);

    function settleAuction() external;

    function createBid(uint256 tokenId, address contractAddress)
        external
        payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setDuration(uint256 _duration) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage)
        external;
}
