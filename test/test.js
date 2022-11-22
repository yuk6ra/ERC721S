const { ethers } = require("hardhat");

describe("Deploy", function() {

    it("deploy", async function () {
        const contractFactory = await ethers.getContractFactory("ERC721S");

        const contract = await contractFactory.deploy();

        await contract.deployed();

        console.log("Contract deployed to:", contract.address);

        

    })
})