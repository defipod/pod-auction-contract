const hre = require("hardhat")

const { run, ethers } = hre;

async function main() {
  await run("compile")

  let auctionContract = "0xc7d41396b44d7eb650fb164dcf4bcd4d9ef93990"
  const factory = await ethers.getContractFactory("PodAuctionHouse")
  const auction = factory.attach(auctionContract)

  filter = auction.filters.AuctionBid()
  let nfts = [];
  let addresses = [];
  let amount = [];
  let ts = [];
  const txs = await auction.queryFilter(filter)
  for (const tx of txs) {
    if (tx.blockNumber < 25809105) {
      continue
    }
    let block = await tx.getBlock()
    nft = tx.args[0]
    address = tx.args[1]
    value = tx.args[2]
    ts.push(block.timestamp)
  }

  console.log(ts)
}

main();
