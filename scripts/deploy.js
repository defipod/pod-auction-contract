const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const PodAuctionHouse = await hre.ethers.getContractFactory(
    "PodAuctionHouse"
  );
  const auctionHouse = await upgrades.deployProxy(
    PodAuctionHouse,
    [0, 0, 0, 0]
  );
  await auctionHouse.deployed();

  console.log("auctionHouse deployed to:", auctionHouse.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
