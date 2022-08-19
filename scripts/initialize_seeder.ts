import { ethers } from 'hardhat'
import yaml from 'js-yaml'
import fs from 'fs'

try {
    const doc = yaml.load(fs.readFileSync('./probability.yaml', 'utf-8'))
    console.log(doc)
} catch(error) {
    console.log(error)
}

async function main() {
    const NSeeder = await ethers.getContractFactory("NSeeder")
    const nSeeder = await NSeeder.deploy()
    await nSeeder.deployed()

    // await nSeeder.setTypeProbability()
}
main().catch((error) => {
    console.log(error);
    process.exitCode = 1;
})