const { Web3 } = require("web3");

const fs = require("fs");

async function main(fileName) {
    const { abi, bytecode } = JSON.parse(fs.readFileSync(`contracts/${fileName}.json`, 'utf-8'));

    if (!process.env.ETHEREUM_NETWORK) {
        throw new Error('ETHEREUM_NETWORK environment variable not set.');
    }

    const network = process.env.ETHEREUM_NETWORK.toLowerCase();
    const web3 = new Web3(
        new Web3.providers.HttpProvider(
            `https://${network}.infura.io/v3/${process.env.INFURA_API_KEY}`,
        ),
    );

    const signer = web3.eth.accounts.privateKeyToAccount(
        '0x' + process.env.CONTRACT_OWNER_PRIVATE_KEY,
    );
    web3.eth.accounts.wallet.add(signer);

    const contract = new web3.eth.Contract(abi);
    contract.options.data = bytecode;
    const deployTx = contract.deploy();
    const gasEstimate = await deployTx.estimateGas();
    const gasAsString = BigInt(gasEstimate * BigInt(2)).toString();
    const deployedContract = await deployTx
        .send({
            from: signer.address,
            gas: gasAsString,
        })
        .once("transactionHash", (txhash) => {
            console.log(`Mining deployment transaction ...`);
            console.log(`https://${network}.etherscan.io/tx/${txhash}`);
        })
        .catch((err) => {
            console.error("Failed to deploy:", err, "\nExiting...");
            process.exit(1);
        });

    console.log(`Contract deployed at ${deployedContract.options.address}`);
}

require("dotenv").config();
main("ReviewsContract").then(() => console.log("Contract deployed successfully!"));