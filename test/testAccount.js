const { expect } = require("chai");
const { ethers } = require("hardhat");
const entryABI = require("../static/entryABI.json");
const { SimpleAccountAPI } = require( "@account-abstraction/sdk")

const entryPointAddr = "0x602aB3881Ff3Fa8dA60a8F44Cf633e91bA1FdB69"
describe("AA", function () {
    it("should work (prays)", async function () {
        const [admin, forwarder] = await ethers.getSigners();
        const Account = await ethers.getContractFactory("Account");
        const account = await Account.deploy(admin.address, entryPointAddr);
        await account.deployed();
        console.log("Account deployed to:", account.address);
        await admin.sendTransaction({ value: ethers.utils.parseEther("1"), to: account.address });
        
        let walletAPI = new SimpleAccountAPI({
            provider: admin.provider,
            entryPointAddress: entryPointAddr,
            owner: admin,
            accountAddress: account.address,
        });

        const targetContractIface = new ethers.utils.Interface([
            "function balanceOf(address) external view returns (uint256)"]);
        let calldata = targetContractIface.encodeFunctionData("balanceOf", [admin.address]);
        
        let op = await walletAPI.createSignedUserOp({
            target: "0x3f152B63Ec5CA5831061B2DccFb29a874C317502", // random erc20
            data: calldata
            // recipient.interface.encodeFunctionData('balanceOf', [admin.address])
        })

        const entryPoint = new ethers.Contract(entryPointAddr, entryABI, admin);
      
        let op_modified = {
            sender: op.sender,
            nonce: op.nonce,
            initCode: op.initCode,
            callData: op.initCode,
            callGas: op.callGasLimit,
            verificationGas: op.verificationGasLimit,
            preVerificationGas: op.preVerificationGas,
            maxFeePerGas: op.maxFeePerGas,
            maxPriorityFeePerGas: op.maxPriorityFeePerGas,
            paymaster: ethers.constants.AddressZero,
            paymasterData: '0x',
            signature: op.signature,
        }
        const tx = await entryPoint.connect(forwarder).handleOps([op_modified], forwarder.address, {
            gasLimit: 1000000,
        })
        const receipt = await tx.wait();
    });
});