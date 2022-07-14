const { ethers } = require("hardhat")
const { expect, assert } = require("chai")
const { MerkleTree } = require("merkletreejs")
const keccak256 = require("keccak256")

describe("Mafia Contract Test", function () {
    let mafiaFactory, mafia, owner
    beforeEach(async function () {
        owner = (await ethers.getSigners())[0]
        mafiaFactory = await ethers.getContractFactory("Mafia")
        mafia = await mafiaFactory.deploy()
    })

    it("Should have owner", async function () {
        const mafiaOwner = await mafia.owner()
        assert.equals(mafiaOwner, owner)
    })

    it("Should reserve tokens", async function () {
        const id = (await mafia.currentTokenId()).toNumber()
        const reserved = (await mafia.reserved()).toNumber()
        assert.equal(id, reserved)
    })
})

// describe("MerkleProof Tests", function () {
//     let mafiaFactory, mafia
//     beforeEach(async function () {
//         mafiaFactory = await ethers.getContractFactory("Mafia")
//         mafia = await mafiaFactory.deploy()
//     })
// })

describe("Mafia Mint FREE", function () {
    let mafiaFactory, mafia
    beforeEach(async function () {
        mafiaFactory = await ethers.getContractFactory("Mafia")
        mafia = await mafiaFactory.deploy()
        await mafia.setStatus(2)
    })

    it("Has FREE status", async function () {
        const status = await mafia.status()
        assert.equal(status, 2)
    })

    it("Cannot mint 0 free", async function () {
        const proof = 0
        try {
            await mafia.mint(proof, 0)
        } catch (error) {
            console.log(error)
        }
        assert.fail("Expected error to be thrown")
    })

    // not wl, 0 free, cannot mint 0 paid
    // not wl, 0 free, can mint 1 paid
    // not wl, 0 free, can mint 2 paid
    // not wl, 0 free, cannot mint 3 paid

    // not wl, 1 free, cannot mint 0 paid
    // not wl, 1 free, can mint 1 paid
    // not wl, 1 free, can mint 2 paid
    // not wl, 1 free, cannot mint 3 paid
})

// describe("Mafia Mint With WL", function () {
//     let mafiaFactory, mafia
//     beforeEach(async function () {
//         mafiaFactory = await ethers.getContractFactory("Mafia")
//         mafia = await mafiaFactory.deploy()
//     })

//     // has wl, 0 free, cannot mint 0 paid
//     // has wl, 0 free, can mint 1 paid
//     // has wl, 0 free, can mint 2 paid
//     // has wl, 0 free, cannot mint 3 paid

//     // has wl, 1 free, cannot mint 0 paid
//     // has wl, 1 free, can mint 1 paid
//     // has wl, 1 free, can mint 2 paid
//     // has wl, 1 free, cannot mint 3 paid
// })
