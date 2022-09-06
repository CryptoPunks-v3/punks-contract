import { task, types } from 'hardhat/config'

task("initialize", "Initialize deployed smart contracts")
    // .addOptionalParam('nToken', 'The NToken contract address')
    // .addOptionalParam('nSeeder', 'The NSeeder contract address')
    // .addOptionalParam('probDoc', 'The Probability config')
    .setAction(async({ nToken, nSeeder, probDoc }, { ethers, run, network }) => {

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

    })