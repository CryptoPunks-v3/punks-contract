import { ethers } from 'hardhat'
import yaml from 'js-yaml'
import fs from 'fs'
import path from 'path'

let doc;
try {
    doc = yaml.load(fs.readFileSync(path.join(__dirname, './probability.yaml'), 'utf-8'))
} catch(error) {
    console.log(error)
}

async function main() {
    const NSeeder = await ethers.getContractFactory("NSeeder")
    const nSeeder = await NSeeder.deploy()
    await nSeeder.deployed()

    const typeProbabilities =
        doc.types
            .map(type => doc.probabilities[type].probability)
            .map(value => Math.floor(value * 1000))
    console.log(typeProbabilities)
    const typeResponse = await (await nSeeder.setTypeProbability(typeProbabilities)).wait()

    for(let [i, type] of doc.types.entries()) {
        const skinProbabilities = 
            doc.probabilities[type].skin
                .map(value => Math.floor(value * 1000))
        const skinResponse = await (await nSeeder.setSkinProbability(i, skinProbabilities)).wait()
    }

    const accProbabilities = 
        doc.accessories
            .map(value => Math.floor(value * 1000))
    const accResponse = await (await nSeeder.setTypeProbability(typeProbabilities)).wait()
}
main().catch((error) => {
    console.log(error);
    process.exitCode = 1;
})