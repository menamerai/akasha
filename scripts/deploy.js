const hre = require("hardhat");

async function main() {

  const aka = await hre.ethers.deployContract("Akasha", []);

  await aka.waitForDeployment();
  console.log("Launched the Akasha.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
