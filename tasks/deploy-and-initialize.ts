import { task, types } from 'hardhat/config'

task("deploy-and-initialize", "Deploy and initialize smart contracts")
    .addOptionalParam('noundersdao', 'The nounders DAO contract address')
    .setAction(async ({}, { ethers, run, network }) => {

        const contracts = await run("deploy")

        const probDoc = await run("get-prob-doc")
        
        await run("initialize", { ...contracts, probDoc })

        await run("mint", contracts)
    })