const {ethers, run} = require("hardhat");
const entryPointAddr = "0x602aB3881Ff3Fa8dA60a8F44Cf633e91bA1FdB69"
async function main() {
  const [deployer] = await ethers.getSigners()

  const Account = await ethers.getContractFactory("Account");
  const account = await Account.deploy(deployer.address, entryPointAddr);
  await account.deployed();


  console.log("Account deployed to:", account.address);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
