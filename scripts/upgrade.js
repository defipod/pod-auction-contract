const hre = require("hardhat");

async function main() {
  const contract = await hre.ethers.getContractFactory("PodAuctionHouse");
  const PodAuctionHouseAddress = "0xc7d41396b44D7Eb650fb164DCf4bCd4d9Ef93990";
  console.log("Upgrading PodAuctionHouse...");
  const PodAuctionHouse = await upgrades.upgradeProxy(
    PodAuctionHouseAddress,
    contract
  );
  await PodAuctionHouse.deployed();

  console.log("PodAuctionHouse upgrade");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
