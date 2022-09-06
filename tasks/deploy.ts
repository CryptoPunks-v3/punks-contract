import { task, types } from 'hardhat/config'

task("deploy", "Deploy NToken, NSeeder and ...")
    .setAction(async ({}, { ethers }) => {
        // const PunksDescriptor = await ethers.getContractFactory("PunksDescriptor")
        // const punksDescriptor = await PunksDescriptor.deploy()
        // await punksDescriptor.deployed()
        
        const NSeeder = await ethers.getContractFactory("NSeeder")
        const nSeeder = await NSeeder.deploy()
        await nSeeder.deployed()

        const NToken = await ethers.getContractFactory("NToken")
        const nToken = await NToken.deploy(nSeeder.address)
        await nToken.deployed()
        return { nSeeder, nToken }
    })