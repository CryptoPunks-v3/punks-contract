import { ethers } from 'hardhat'
import yaml from 'js-yaml'
import fs from 'fs'
import path from 'path'

let probDoc;
try {
    probDoc = yaml.load(fs.readFileSync(path.join(__dirname, '../config/probability.yaml'), 'utf-8'))
} catch(error) {
    console.log(error)
}

async function deploy() {
    const PunksDescriptor = await ethers.getContractFactory("PunksDescriptor")
    const punksDescriptor = await PunksDescriptor.deploy()
    await punksDescriptor.deployed()
    
    const NSeeder = await ethers.getContractFactory("NSeeder")
    const nSeeder = await NSeeder.deploy(punksDescriptor.address)
    await nSeeder.deployed()

    const NToken = await ethers.getContractFactory("NToken")
    const nToken = await NToken.deploy(nSeeder.address)
    await nToken.deployed()
    return { punksDescriptor, nSeeder, nToken }
}
async function setProbabilities(nSeeder) {
    const typeProbabilities =
        Object.values(probDoc.probabilities)
            .map((probObj: { probability: number }) => Math.floor(probObj.probability * 1000))
    const typeResponse = await (await nSeeder.setTypeProbability(typeProbabilities)).wait()
    console.log("setTypeProbability", typeProbabilities)

    for(let [i, type] of Object.keys(probDoc.probabilities).entries()) {
        const skinProbabilities = 
            probDoc.probabilities[type].skin
                .map(value => Math.floor(value * 1000))
        const skinResponse = await (await nSeeder.setSkinProbability(i, skinProbabilities)).wait()
    }
    console.log("setSkinProbability")

    const accCountProbabilities = 
        probDoc.accessory_count_probabbilities
            .map(value => Math.floor(value * 1000))
    const accResponse = await (await nSeeder.setAccCountProbability(accCountProbabilities)).wait()
    console.log("setAccCountProbability", accCountProbabilities)
}

async function setAccSetting(nSeeder) {
    const accTypeCount = Object.keys(probDoc.acc_types).length
    const accTypeAvailabilities =
        Object.values(probDoc.probabilities)
            .map((probObj: { accessories: [] }) => {
                const binaryArray = probObj.accessories.reduce((prev, acc) => {
                    const typeIndex = Object.keys(probDoc.acc_types).indexOf(acc)
                    if(typeIndex < 0) throw new Error(`Unknown type found in type availability - ${acc}`)
                    prev[typeIndex] = 1
                    return prev
                }, Array(accTypeCount).fill(0))
                return parseInt(binaryArray.join(""), 2)
            })
    const typeAvailabilityResponse = await (await nSeeder.setAccAvailability(accTypeCount, accTypeAvailabilities)).wait()
    console.log("setAccAvailability", accTypeCount, accTypeAvailabilities)

    const accCountPerType = Object.keys(probDoc.acc_types).map(type => Object.values(probDoc.accessory_types).filter(item => item == type).length)
    console.log(accCountPerType)
    const accCountSetResponse = await (await nSeeder.setAccCountPerType(accCountPerType)).wait()

    const exclusives = probDoc.exclusive_groups.reduce((prev, group, groupIndex) => {
        group.forEach(item => {
            const typeIndex = Object.keys(probDoc.acc_types).indexOf(item)
            if(typeIndex < 0) throw new Error(`Unknown type found in exclusive groups - ${item}`)
            prev[typeIndex] = groupIndex
        })
        return prev
    }, Array(accTypeCount).fill(-1))
    let curExclusive = probDoc.exclusive_groups.length;
    for(let i in exclusives)
        if(exclusives[i] < 0)
            exclusives[i] = curExclusive ++
    const exclusiveResponse = await (await nSeeder.setExclusiveAcc(curExclusive, exclusives)).wait()
    console.log("setExclusiveAcc", curExclusive, exclusives)

    const seed = await nSeeder.generateSeed(0)
    console.log(seed)
}

async function minToken(nToken) {
    const [ deployer ] = await ethers.getSigners()
    const res = await (await nToken.mint(deployer.address, 1)).wait()
}

async function main() {
    const contracts = await deploy()
    await setProbabilities(contracts.nSeeder);
    await setAccSetting(contracts.nSeeder);
    await minToken(contracts.nToken);
}
main().catch((error) => {
    console.log(error);
    process.exitCode = 1;
})