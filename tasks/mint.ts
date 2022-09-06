import { task, types } from 'hardhat/config'

task("mint", "Mint Punk2 token")
    .setAction(async({ nSeeder, nToken }, { ethers }) => {
        const [ deployer ] = await ethers.getSigners()
        const res = await (await nToken.mint(deployer.address, 1)).wait()
    })