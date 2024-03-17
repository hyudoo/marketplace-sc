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

  // const CrowdSale = await ethers.getContractFactory("CrowdSale");
  // const crowdSale = await CrowdSale.deploy(
  //   10000,
  //   "0xF8245050365E42C6FEc0c24539BA4E45675D8FE0",
  //   "0xbff25E68cf50b8dDC6e56Ab36F0B66f6e4820a97"
  // );
  // console.log("CrowdSale address: ", crowdSale.target);
  // Config.setConfig(network + ".CrowdSale", crowdSale.target as string);

  const SupplyChain = await ethers.getContractFactory("SupplyChain");
  const supplyChain = await SupplyChain.deploy();
  console.log("SupplyChain address: ", supplyChain.target);
  Config.setConfig(network + ".SupplyChain", supplyChain.target as string);

  // const MKP = await ethers.getContractFactory("MarketPlace");
  // const marketplace = await MKP.deploy(
  //   "0xbff25E68cf50b8dDC6e56Ab36F0B66f6e4820a97",
  //   "0xE2b7Aae826b16Daf94F191a82698ac3874Fe3AC2"
  // );
  // console.log("MarketPlace address: ", marketplace.target);
  // Config.setConfig(network + ".MarketPlace", marketplace.target as string);

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
