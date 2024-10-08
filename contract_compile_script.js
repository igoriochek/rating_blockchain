const fs = require("fs").promises;
const solc = require("solc");

async function main(fileName) {
    const sourceCode = await fs.readFile(`contracts/${fileName}.sol`, "utf-8");
    const contractNames = ["ReviewsContract", "ReviewContainer", "ItemContainer", "DomainContainer", "UserContainer"];

    for (const contract of contractNames) {
        let compInfo = compile(sourceCode, fileName, contract);
        let artifact = JSON.stringify(compInfo, null, 2);
        await fs.writeFile(`contracts/${contract}.json`, artifact);
        console.log(`ABI and Bytecode saved to contracts/${contract}.json`);
    }
}

function compile(sourceCode, fileName, contractName) {
    const input = {
        language: "Solidity",
        sources: { [fileName]: { content: sourceCode } },
        settings: { outputSelection: { "*": { "*": ["abi", "evm.bytecode"] } } },
    };

    const output = solc.compile(JSON.stringify(input));

    const parsedOutput = JSON.parse(output);
    if (parsedOutput.errors) {
        console.error("Failed to compile the contract:", parsedOutput.errors);
        process.exit(1);
    }

    const artifact = parsedOutput.contracts[fileName][contractName];
    return {
        abi: artifact.abi,
        bytecode: artifact.evm.bytecode.object,
    };
}

main("ReviewsContract").then(() => console.log("Contract compiled successfully!"));
