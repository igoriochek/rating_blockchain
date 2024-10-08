# WEB3 Decentralized Reviews

<font color="#A10B0B">MAKE SURE YOU HAVE A .ENV FILE IN ROOT DIRECTORY OF PROJECT</font>

## Dealing with contracts

<b>Environment Variables For Contract</b>
> <b>ETHEREUM_NETWORK</b> - name of network to deploy contract<br>
> <b>CONTRACT_OWNER_PRIVATE_KEY</b> - private key of contract owner<br>
> <b>INFURA_API_KEY</b> - Infura API key<br>

<b>"ReviewsContract" file name is already in script files.

<b>Compile</b>
> - <strong>Contract should be in /contracts</strong><br>
> - Run contract_compile_script<br>
>> node .\contract_compile_script.js<br>

<b>Deploy</b>
> - <strong>Compiled contract JSON should be in /contracts</strong><br>
> - Run contract_deployment_script<br>
>> node .\contract_deployment_script.js<br>