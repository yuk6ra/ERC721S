const { ethers } = require("hardhat");

describe("DeployTest", function() {

    it("OK", async function () {
        const contractFactory = await ethers.getContractFactory("ERC721S");

        const contract = await contractFactory.deploy("10", "1000000000000000000");

        await contract.deployed();
        await contract.mint(
          {
            value: hre.ethers.utils.parseEther("10"),
          }
        );

        console.log("Contract deployed to:", contract.address);

        

    })
})