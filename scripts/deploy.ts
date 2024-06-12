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

  // const Product = await ethers.getContractFactory("Product");
  // const product = await Product.deploy();
  // console.log("Product address: ", product.target);
  // Config.setConfig(network + ".Product", product.target as string);

  // const CrowdSale = await ethers.getContractFactory("CrowdSale");
  // const crowdSale = await CrowdSale.deploy(
  //   10000,
  //   "0x5Bb82422bd946BfF2cDCc9783bf35A568613ac38",
  //   "0xaEa826728197bBC0AC64432d72C45B0bacf3A35f"
  // );
  // console.log("CrowdSale address: ", crowdSale.target);
  // Config.setConfig(network + ".CrowdSale", crowdSale.target as string);

  // const MKP = await ethers.getContractFactory("MarketPlace");
  // const marketplace = await MKP.deploy(
  //   "0xaEa826728197bBC0AC64432d72C45B0bacf3A35f",
  //   "0x459Bb3034Fcd4A68cFDA424a46F9a778f6C683dA"
  // );
  // console.log("MarketPlace address: ", marketplace.target);
  // Config.setConfig(network + ".MarketPlace", marketplace.target as string);

  // const ExchangeProduct = await ethers.getContractFactory("ExchangeProduct");
  // const exchangeProduct = await ExchangeProduct.deploy(
  //   "0x459Bb3034Fcd4A68cFDA424a46F9a778f6C683dA"
  // );
  // console.log("ExchangeProduct address: ", exchangeProduct.target);
  // Config.setConfig(
  //   network + ".ExchangeProduct",
  //   exchangeProduct.target as string
  // );

  const Auction = await ethers.getContractFactory("Auction");
  const auction = await Auction.deploy(
    "0xaEa826728197bBC0AC64432d72C45B0bacf3A35f",
    "0x459Bb3034Fcd4A68cFDA424a46F9a778f6C683dA"
  );
  console.log("Auction address: ", auction.target);
  Config.setConfig(network + ".Auction", auction.target as string);

  // const Profile = await ethers.getContractFactory("Profile");
  // const profile = await Profile.deploy();
  // console.log("Profile address: ", profile.target);
  // Config.setConfig(network + ".Profile", profile.target as string);

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
