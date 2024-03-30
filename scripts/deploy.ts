import { ProductTransaction } from "./../typechain-types/contracts/ProductTransaction";
import { ethers, hardhatArguments } from "hardhat";
import * as Config from "./config";

async function main() {
  await Config.initConfig();
  const network = hardhatArguments.network ? hardhatArguments.network : "dev";
  const [deployer] = await ethers.getSigners();
  console.log("deploy from address: ", deployer.address);

  // const MarketCoins = await ethers.getContractFactory("MarketCoins");
  // const marketcoins = await MarketCoins.deploy();
  // console.log("MarketCoins address: ", marketcoins.target);
  // Config.setConfig(network + ".MarketCoins", marketcoins.target as string);

  // const SupplyChain = await ethers.getContractFactory("SupplyChain");
  // const supplyChain = await SupplyChain.deploy();
  // console.log("SupplyChain address: ", supplyChain.target);
  // Config.setConfig(network + ".SupplyChain", supplyChain.target as string);

  // const CrowdSale = await ethers.getContractFactory("CrowdSale");
  // const crowdSale = await CrowdSale.deploy(
  //   10000,
  //   "0x08f5A003EE2AA1d060B969583F4e819650c06482",
  //   "0xf707EA5293ECD90Fc5507fE1106602D51b4EAE97"
  // );
  // console.log("CrowdSale address: ", crowdSale.target);
  // Config.setConfig(network + ".CrowdSale", crowdSale.target as string);

  // const MKP = await ethers.getContractFactory("MarketPlace");
  // const marketplace = await MKP.deploy(
  //   "0xf707EA5293ECD90Fc5507fE1106602D51b4EAE97",
  //   "0x75e446a568f08549509F93701Aa84Dd5047EE6C5"
  // );
  // console.log("MarketPlace address: ", marketplace.target);
  // Config.setConfig(network + ".MarketPlace", marketplace.target as string);

  const ExchangeProduct = await ethers.getContractFactory("ExchangeProduct");
  const exchangeProduct = await ExchangeProduct.deploy(
    "0x75e446a568f08549509F93701Aa84Dd5047EE6C5"
  );
  console.log("ExchangeProduct address: ", exchangeProduct.target);
  Config.setConfig(
    network + ".ExchangeProduct",
    exchangeProduct.target as string
  );

  await Config.updateConfig();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
