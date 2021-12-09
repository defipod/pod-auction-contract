require("dotenv").config();

const networks = {
  coverage: {
    url: "http://127.0.0.1:8555",
    blockGasLimit: 200000000,
    allowUnlimitedContractSize: true,
  },
  localhost: {
    chainId: 1,
    url: "http://127.0.0.1:8545",
    allowUnlimitedContractSize: true,
    timeout: 1000 * 60,
  },
  hardhat: {
    allowUnlimitedContractSize: true,
    chainId: 1337,
  },
};

if (process.env.TESTNET_MNEMONIC) {
  networks.ftmtestnet = {
    accounts: {
      mnemonic: process.env.TESTNET_MNEMONIC,
    },
    chainId: 4002,
    url: "https://xapi.testnet.fantom.network/lachesis",
  };
}

if (process.env.DEPLOYER_MAINNET_MNEMONIC) {
  networks.ftm = {
    accounts: {
      mnemonic: process.env.DEPLOYER_MAINNET_MNEMONIC,
    },
    chainId: 250,
    url: "https://rpc.ftm.tools/",
  };
}

module.exports = networks;
