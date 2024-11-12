import {
  Account,
  AccountAddress,
  Ed25519Account,
  Aptos,
  AptosConfig,
  Network,
  InputViewFunctionData,
} from "@aptos-labs/ts-sdk";

const KGEN_WALLET_ADDRESS = "0x123";
const POG_MODULE = "PoG_Consensus";

// Initialize Aptos config and instance
const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

export async function is_pub_key_present(pubKey: Uint8Array) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::is_pub_key_present`,
    functionArguments: [pubKey],
  };

  const result = await aptos.view({ payload });

  if (result[0]) {
    console.log("The Public Key is Present!!!");
  } else {
    console.log("The Public Key is Not Present!!!");
  }
}

export async function check_threshold(pub_key_vector: Uint8Array[]) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::check_threshold`,
    functionArguments: [pub_key_vector],
  };

  const result = await aptos.view({ payload });

  if (result[0]) {
    console.log("Threshold Met");
  } else {
    console.log("Thereshold is not met!!!");
  }
}

export async function pub_vectro_size() {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::pub_vectro_size`,
    functionArguments: [],
  };

  const result = await aptos.view({ payload });

  console.log("Public Key Vector Size: ", result[0]);
}

export async function verify_signature(
  owner: Ed25519Account,
  message_hash: Uint8Array,
  signature: Uint8Array,
  pub_key: Uint8Array
) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::verify_signature`,
    functionArguments: [message_hash, signature, pub_key],
  };

  const result = await aptos.view({ payload });

  if (result[0]) {
    console.log("Signature Verified!!!");
  } else {
    console.log("Signature is Not Verified!!!");
  }
}

export async function fetch_player_score(index: number) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::fetch_player_score`,
    functionArguments: [index],
  };

  const result = await aptos.view({ payload });

  console.log("Score for the Player: ", result[0]);
}

export async function fetch_player_rank(index: number) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::fetch_player_rank`,
    functionArguments: [index],
  };

  const result = await aptos.view({ payload });

  console.log("Rank of the Player: ", result[0]);
}

export async function submit_score(
  owner: Ed25519Account,
  message_hash: Uint8Array,
  signature_vector: Uint8Array[],
  pub_key_vector: Uint8Array[],
  player_id: bigint[],
  ranks: bigint[],
  scores: bigint[]
) {
  const transaction = await aptos.transaction.build.simple({
    sender: owner.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::submit_score`,
      functionArguments: [
        message_hash,
        signature_vector,
        pub_key_vector,
        player_id,
        ranks,
        scores,
      ],
    },
  });

  const committedTxn = await aptos.signAndSubmitTransaction({
    transaction,
    signer: owner,
  });

  const executedTxn = await aptos.waitForTransaction({
    transactionHash: committedTxn.hash,
  });

  console.log("Transaction hash: ", executedTxn.hash);
}

export async function add_oracle_public_key(
  owner: Ed25519Account,
  pubKey: Uint8Array
) {
  const transaction = await aptos.transaction.build.simple({
    sender: owner.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::add_oracle_public_key`,
      functionArguments: [pubKey],
    },
  });

  const committedTxn = await aptos.signAndSubmitTransaction({
    transaction,
    signer: owner,
  });

  const executedTxn = await aptos.waitForTransaction({
    transactionHash: committedTxn.hash,
  });

  console.log("Transaction hash: ", executedTxn.hash);
}

export async function remove_oracle_public_key(
  owner: Ed25519Account,
  pubKey: Uint8Array
) {
  const transaction = await aptos.transaction.build.simple({
    sender: owner.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::remove_oracle_public_key`,
      functionArguments: [pubKey],
    },
  });

  const committedTxn = await aptos.signAndSubmitTransaction({
    transaction,
    signer: owner,
  });

  const executedTxn = await aptos.waitForTransaction({
    transactionHash: committedTxn.hash,
  });

  console.log("Transaction hash: ", executedTxn.hash);
}

// import {
// Account,
// AccountAddress,
// Ed25519Account,
// Aptos,
// AptosConfig,
// Network,
// InputViewFunctionData
// } from "@aptos-labs/ts-sdk";

// const KGEN_WALLET_ADDRESS = "0xe2973b0f17f4813b3b36ffb24283251b7dff2fade4832e1b457b48f646dc58e7";
// const POG_MODULE = "PoG_Consensus_01";

// const config = new AptosConfig({ network: Network.DEVNET });
// const aptos = new Aptos(config);

// export async function is_pub_key_present(pubKey: Uint8Array) {
//     const payload: InputViewFunctionData = {
//         function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::is_pub_key_present`,
//         functionArguments: [pubKey],
//     }

//     const result = await aptos.view({payload});

//     if(result[0]) {
//         console.log("The Public Key is Not Present!!!");
//     } else {
//         console.log("The Public Key is Present!!!");
//     }
// }

// export async function submit_score(
// owner: Ed25519Account,
// message_hash: vector<u8>,
// signature_vector: vector<vector<u8>>,
// pub_key_vector: vector<vector<u8>>,
// player_id: vector<u64>,
// ranks: vector<u64>,
// scores: vector<u64>
// ) {

//     const transaction = await aptos.transaction.build.simple({
//     sender: owner.accountAddress,
//     data: {
//         function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::submit_score`,
//         functionArguments: [message_hash, signature_vector, pub_key_vector, player_id, ranks, scores ],
//     }
//     });

//     const committedTxn = await aptos.signAndSubmitTransaction({
//     transaction,
//     signer: owner,
//     });

//     const executedTxn = await aptos.waitForTransaction({
//     transactionHash: committedTxn.hash
//     });

//     console.log("Transaction hash: ", executedTxn.hash);

// }

// export async function add_oracle_public_key(owner: Ed25519Account, pubKey: Uint8Array) {
//     const transaction = await aptos.transaction.build.simple({
//         sender: owner.accountAddress,
//         data: {
//             function: `${KGEN_WALLET_ADDRESS}::${POG_MODULE}::add_oracle_public_key`,
//             functionArguments: [pubKey],
//         }
//         });

//         const committedTxn = await aptos.signAndSubmitTransaction({
//         transaction,
//         signer: owner,
//         });

//         const executedTxn = await aptos.waitForTransaction({
//         transactionHash: committedTxn.hash
//         });

//         console.log("Transaction hash: ", executedTxn.hash);
// }
