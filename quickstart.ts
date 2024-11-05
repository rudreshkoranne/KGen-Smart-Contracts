/* eslint-disable no-console */
/* eslint-disable max-len */

function hexToUint8Array(hex: string): Uint8Array {
  if (hex.startsWith('0x')) {
      hex = hex.slice(2);
  }
  const length = hex.length / 2;
  const array = new Uint8Array(length);
  for (let i = 0; i < length; i++) {
      array[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return array;
}

import {
    Account,
    AccountAddress,
    AnyNumber,
    Aptos,
    AptosConfig,
    InputViewFunctionData,
    Network,
    NetworkToNetworkName,
    Ed25519PrivateKey,
    Ed25519PublicKey,
    Ed25519Account
  } from "@aptos-labs/ts-sdk";
  import { compilePackage, getPackageBytesToPublish } from "./utils";
  
  // Set up the client
  // const APTOS_NETWORK: Network = NetworkToNetworkName[process.env.APTOS_NETWORK ?? Network.DEVNET];
  const config = new AptosConfig({ network: Network.DEVNET });
  const aptos = new Aptos(config);
  
  
  const CONTRACT_ADDRESS =
    "0xb1a89139c3b9f0ddd99f947df773b73c508d44c6ea487ccd742906623825cd6b";
  
  
  
  
  /** Admin forcefully transfers the newly created coin to the specified receiver address */
  async function transferCoin(
    admin: Account,
    fromAddress: AccountAddress,
    toAddress: AccountAddress,
    amount: AnyNumber,
  ): Promise<string> {
    const transaction = await aptos.transaction.build.simple({
      sender: admin.accountAddress,
      data: {
        function: `${admin.accountAddress}::key_coin::transfer`,
        functionArguments: [fromAddress, toAddress, amount],
      },
    });
  
    const senderAuthenticator = aptos.transaction.sign({ signer: admin, transaction });
    console.log("senderAuthenticator",senderAuthenticator);
    
    const pendingTxn = await aptos.transaction.submit.simple({ transaction, senderAuthenticator });
    console.log("pendingTxn",pendingTxn);
    return pendingTxn.hash;
  }
  
  
  
  /** Admin mint the newly created coin to the specified receiver address */
  async function mintCoin(admin: Account, receiver: Account, amount: AnyNumber): Promise<string> {
    const transaction = await aptos.transaction.build.simple({
      sender: admin.accountAddress,
      data: {
        function: `${admin.accountAddress}::key_coin::mint_keys`,
        functionArguments: [receiver.accountAddress, amount],
      },
    });
  
    const senderAuthenticator = aptos.transaction.sign({ signer: admin, transaction });
    const pendingTxn = await aptos.transaction.submit.simple({ transaction, senderAuthenticator });
  
    return pendingTxn.hash;
  }
  
  
  // /** Admin mint the newly created coin to the specified receiver address */
  // async function purchesKey(admin: Account, buyer: Account, amount: AnyNumber): Promise<string> {
  //   const transaction = await aptos.transaction.build.simple({
  //     sender: admin.accountAddress,
  //     data: {
  //       function: `${admin.accountAddress}::key_contarct::purchase_keys_apt`,
  //       functionArguments: [buyer.accountAddress, amount],
  //     },
  //   });
  
  //   console.log("transaction",transaction);
    
  
  //   const senderAuthenticator = aptos.transaction.sign({ signer: admin, transaction });
  //   console.log("senderAuthenticator",senderAuthenticator);
    
  //   const pendingTxn = await aptos.transaction.submit.simple({ transaction, senderAuthenticator });
  //   console.log("pendingTxn",pendingTxn);
    
  //   return pendingTxn.hash;
  
  // }
  
  
  
  
  /** Admin mint the newly created coin to the specified receiver address */
  async function purchesKey(admin: Ed25519Account, buyer: Ed25519Account, amount: number): Promise<string>  {

    try {

        // console.log("admin: Account, buyer: Account, amount: AnyNumber");
        console.log("ADMIN: ", admin);
      const transaction = await aptos.transaction.build.multiAgent({
        sender: admin.accountAddress,
        secondarySignerAddresses: [buyer.accountAddress],
        data: {
          function: `${admin.accountAddress}::key_coin::purchase_keys_apt`,
          // function: "ccb1939533c02b8b608f84c3d11a22ccb107b3693deda95abdbd3d014a5218ff::key_coin::purchase_keys_apt",
          functionArguments: [amount],
        },
      });
      // console.log("Admin account address: ", admin.accountAddress.toString());
      console.log("transaction",transaction);  
      const senderAuthenticator = aptos.transaction.sign({ signer: admin, transaction });
      console.log("senderAuthenticator",senderAuthenticator);
    
      const senderAuthenticator2 = aptos.transaction.sign({ signer: buyer, transaction });
      console.log("senderAuthenticator",senderAuthenticator2);
      
      const pendingTxn = await aptos.transaction.submit.multiAgent({ 
        transaction, 
        senderAuthenticator:senderAuthenticator,
        additionalSignersAuthenticators:[senderAuthenticator2] 
      });
      console.log("pendingTxn",pendingTxn);
      
        return pendingTxn.hash;
        
    } catch (error) {
         console.log("error in catch",error);
         return "";
    }
    
  }
  
  
  /** Return the address of the managed fungible asset that's created when this module is deployed */
  async function getMetadata(admin: Account): Promise<string> {
    const payload: InputViewFunctionData = {
      function: `${admin.accountAddress}::key_coin::get_metadata`,
      functionArguments: [],
    };
    const res = (await aptos.view<[{ inner: string }]>({ payload }))[0];
    return res.inner;
  }
  
  
  const getFaBalance = async (owner: Account, assetType: string): Promise<number> => {
    const data = await aptos.getCurrentFungibleAssetBalances({
      options: {
        where: {
          owner_address: { _eq: owner.accountAddress.toStringLong() },
          asset_type: { _eq: assetType },
        },
      },
    });
  
    return data[0]?.amount ?? 0;
  };
  
  
  /** Admin burns the newly created coin from the specified receiver address */
  async function burnCoin(admin: Account, fromAddress: AccountAddress, amount: AnyNumber): Promise<string> {
    const transaction = await aptos.transaction.build.simple({
      sender: admin.accountAddress,
      data: {
        function: `${admin.accountAddress}::key_coin::burn`,
        functionArguments: [fromAddress, amount],
      },
    });
  
    const senderAuthenticator = aptos.transaction.sign({ signer: admin, transaction });
    const pendingTxn = await aptos.transaction.submit.simple({ transaction, senderAuthenticator });
  
    return pendingTxn.hash;
  }
  
  
  
  
  async function setKeyLimit(admin: Account, amount: number): Promise<string> {
    const transaction = await aptos.transaction.build.simple({
      sender: admin.accountAddress,
      data: {
        function: `${admin.accountAddress}::key_coin::set_key_limit`,
        functionArguments: [amount],
      },
    });
   console.log("transaction",transaction);
    const senderAuthenticator = aptos.transaction.sign({ signer: admin, transaction });
    console.log("senderAuthenticator",senderAuthenticator);
    const pendingTxn = await aptos.transaction.submit.simple({ transaction, senderAuthenticator });
    console.log("pendingTxn",pendingTxn);
    return pendingTxn.hash;
  
  }
  
  async function main() {
    const alice = Account.generate();
    const bob = Account.generate();
    const charlie = Account.generate();
   
  
    // const privateKeyOwner = new Ed25519PrivateKey("0xa281811d53d538f9077d5700fff380844651530d5ea66edcf448a4da9950baae");
    const privateKeyOwner = new Ed25519PrivateKey(hexToUint8Array("0xa281811d53d538f9077d5700fff380844651530d5ea66edcf448a4da9950baae"))
    const owner = Account.fromPrivateKey({ privateKey: privateKeyOwner });

    const privateKeyBuyer = new Ed25519PrivateKey(hexToUint8Array("0xb370074e787738402bf086b98ab1bdde2a4d060a5c976188f32d56907cdd745f"))
    const buyer = Account.fromPrivateKey({ privateKey: privateKeyBuyer });

    const privateKeyRecever = new Ed25519PrivateKey(hexToUint8Array("0x054458f06cd52d62010c56eefb228f39d275fd7cda3023f4e59f26a5c529b920"))
    const receiver = Account.fromPrivateKey({ privateKey: privateKeyRecever });


  
    console.log("owner",owner);
    
    console.log("\n=== Addresses ===");
    console.log(`Alice: ${alice.accountAddress.toString()}`);
    console.log(`Bob: ${bob.accountAddress.toString()}`);
    console.log(`Charlie: ${charlie.accountAddress.toString()}`);
    console.log(`owner: ${owner.accountAddress.toString()}`);
  
  
    //   const balance=await aptos.fundAccount({ accountAddress: owner.accountAddress, amount: 100000000 });
    //   console.log("balance",balance);
      
    // await aptos.fundAccount({
    //   accountAddress: bob.accountAddress,
    //   amount: 100_000_000,
    // });
  
    // console.log("\n=== Compiling FACoin package locally ===");
    // compilePackage("move/keyCoin", "move/keyCoin/keyCoin.json", [{ name: "KEYCoin", address: alice.accountAddress }]);
  
    // const { metadataBytes, byteCode } = getPackageBytesToPublish("move/keyCoin/keyCoin.json");
  
    // console.log("\n===Publishing FACoin package===");
    // const transaction = await aptos.publishPackageTransaction({
    //   account: alice.accountAddress,
    //   metadataBytes,
    //   moduleBytecode: byteCode,
    // });
    // const response = await aptos.signAndSubmitTransaction({
    //   signer: alice,
    //   transaction,
    // });
    // console.log(`Transaction hash: ${response.hash}`);
    
    // console.log("response",response);
  
  
    // const tst= await aptos.waitForTransaction({
    //   transactionHash: response.hash,
    // });
  
  
  
    // const metadataAddress = await getMetadata(owner);
    // console.log(getMetadata(owner));
    
    // console.log("metadata address:", metadataAddress);
    // console.log("All the balances in this example refer to balance in primary fungible stores of each account.");
    // console.log(`Owner's initial balance: ${await getFaBalance(owner, metadataAddress)}.`);
    // console.log(`Bob's initial FACoin balance: ${await getFaBalance(bob, metadataAddress)}.`);
  
  
    // console.log("owner mints Charlie 100 coins.");
    // const mintCoinTransactionHash = await mintCoin(owner, bob, 100);
    // console.log("mintCoinTransactionHash",mintCoinTransactionHash);
  
    // await aptos.waitForTransaction({ transactionHash: mintCoinTransactionHash });
    // console.log(
    //   `bobs's updated FACoin primary fungible store balance: ${await getFaBalance(bob, metadataAddress)}.`,
    // );
  
    // console.log("owner burns 50 coins from Bob.");
    // const burnCoinTransactionHash = await burnCoin(owner, bob.accountAddress, 50);
    // console.log("burnCoinTransactionHash",burnCoinTransactionHash);
    // await aptos.waitForTransaction({ transactionHash: burnCoinTransactionHash });
  
    // console.log(`Bob's updated FACoin balance: ${await getFaBalance(bob, metadataAddress)}.`);
  
  
  
    const transferCoinTransactionHash = await transferCoin(owner, buyer.accountAddress, receiver.accountAddress, 100);
    console.log("transferCoinTransactionHash",transferCoinTransactionHash);
    
      // await aptos.waitForTransaction({ transactionHash: transferCoinTransactionHash });
    // console.log("transferhash",transferhash.hash);
    
    // // console.log(`Bob's updated FACoin balance: ${await getFaBalance(bob, metadataAddress)}.`);
  
    const setKeyLimitHash = await setKeyLimit(owner, 10000);
    console.log("setKeyLimitHash,",setKeyLimitHash);
  
    const hash= await aptos.waitForTransaction({ transactionHash: setKeyLimitHash });
    console.log("sussfully transation done",hash.hash);
    
  

    console.log("owner mints Charlie 100 coins.");
    const purchesKey1 = await purchesKey(owner, buyer, 10);
    console.log("purchesKey",purchesKey1);


    // const transaction = await aptos.transaction.build.multiAgent({
    //   sender: owner.accountAddress,
    //   secondarySignerAddresses: [buyer.accountAddress],
    //   data: {
    //     // function: `${admin.accountAddress.toString()}::key_coin::purchase_keys_apt`,
    //     function: "ccb1939533c02b8b608f84c3d11a22ccb107b3693deda95abdbd3d014a5218ff::key_coin::purchase_keys_apt",
    //     functionArguments: [100],
    //   },
    // });

    // // console.log("Admin account address: ", admin.accountAddress.toString());
    
  
    // console.log("transaction",transaction);  
    // const senderAuthenticator = aptos.transaction.sign({ signer: owner, transaction });
    // console.log("senderAuthenticator",senderAuthenticator);
  
    // const senderAuthenticator2 = aptos.transaction.sign({ signer: buyer, transaction });
    // console.log("senderAuthenticator",senderAuthenticator2);
    
    // const pendingTxn = await aptos.transaction.submit.multiAgent({ 
    //   transaction, 
    //   senderAuthenticator:senderAuthenticator,
    //   additionalSignersAuthenticators:[senderAuthenticator2] 
    // });
    // console.log("pendingTxn",pendingTxn);
    
    //   // return pendingTxn.hash;
  
    // const hash=await aptos.waitForTransaction({ transactionHash: pendingTxn.hash });
  
    // console.log("hash",hash.hash);
    
  }
  
  main();
  