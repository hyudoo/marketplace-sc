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
  //   "0xBBDA901BA3CF75d150f45C2bEDAdfd630Aca79eE",
  //   "0x647c94dc172411077d0e0c907315674dE3C44680"
  // );
  // console.log("CrowdSale address: ", crowdSale.target);
  // Config.setConfig(network + ".CrowdSale", crowdSale.target as string);

  // const MKP = await ethers.getContractFactory("MarketPlace");
  // const marketplace = await MKP.deploy(
  //   "0x647c94dc172411077d0e0c907315674dE3C44680",
  //   "0xafa048370623EFCb50c4F94Dc3e53BfbB1bcBCA2"
  // );
  // console.log("MarketPlace address: ", marketplace.target);
  // Config.setConfig(network + ".MarketPlace", marketplace.target as string);

  const ExchangeProduct = await ethers.getContractFactory("ExchangeProduct");
  const exchangeProduct = await ExchangeProduct.deploy(
    "0xafa048370623EFCb50c4F94Dc3e53BfbB1bcBCA2"
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
