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
const ORACLE_MANAGEMENT_MODULE = "oracle_management";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

// This is a view function to check if a reward is associated
export async function isRewardAssociated(oracle: AccountAddress) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::is_reward_associated`,
    functionArguments: [oracle],
  };

  const data = await aptos.view({ payload });
  if (data[0]) {
    console.log("Resource is associated successfully.");
  } else {
    console.log("Reward is not associated.");
  }
}

// This is a view function to list registered oracles
export async function listRegisteredOracles() {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::list_registered_oracle`,
    functionArguments: [],
  };

  const result = await aptos.view({ payload });
  console.log("Registered Oracles: ", result[0]);
}

// This is a view function to get the reward balance of an oracle
export async function get_oracle_reward_balance(oracleAddress: AccountAddress) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::get_oracle_reward_balance`,
    functionArguments: [oracleAddress],
  };

  const result = await aptos.view({ payload });
  console.log("Oracle Reward Balance: ", result[0]);
}

// This is a view function to get the count of registered oracles
export async function registered_oracle_count() {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::registered_oracle_count`,
    functionArguments: [],
  };

  const result = await aptos.view({ payload });
  console.log("Registered Oracles Count:", result[0]);
}

// This function associates a reward resource to an oracle
export async function associate_reward_resource(oracle: Ed25519Account) {
  const transaction = await aptos.transaction.build.simple({
    sender: oracle.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::associate_reward_resource`,
      functionArguments: [],
    },
  });

  const committedTxn = await aptos.signAndSubmitTransaction({
    transaction,
    signer: oracle,
  });

  const executedTxn = await aptos.waitForTransaction({
    transactionHash: committedTxn.hash,
  });

  console.log("Transaction hash: ", executedTxn.hash);
}

// This function adds an oracle address to the owner
export async function add_oracle_address(
  owner: Ed25519Account,
  oracleAddr: AccountAddress,
  tokenName: string
) {
  const transaction = await aptos.transaction.build.simple({
    sender: owner.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::add_oracle_address`,
      functionArguments: [oracleAddr, tokenName],
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

export async function is_oracle_verified(oracleAddress: AccountAddress) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::is_oracle_verified`,
    functionArguments: [oracleAddress],
  };

  const result = await aptos.view({ payload });

  if (result[0]) {
    console.log("Oracle is Verified!!!");
  } else {
    console.log("Oracle is Not Verified!!!");
  }
}

export async function set_oracle_status(
  owner: Ed25519Account,
  oracleAddr: AccountAddress,
  status: boolean
) {
  const transaction = await aptos.transaction.build.simple({
    sender: owner.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${ORACLE_MANAGEMENT_MODULE}::set_oracle_status`,
      functionArguments: [oracleAddr, status],
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

// export class OracleManagementContract {
//   private aptos: Aptos;
//   private oracleManagementAddress: string;
//   private oracleManagementModule: string;

//   constructor(aptos: Aptos) {
//     this.aptos = aptos;
//     this.oracleManagementAddress = ORACLE_MANAGEMENT_ADDRESS;
//     this.oracleManagementModule = ORACLE_MANAGEMENT_MODULE;
//   }

//

//   // Add more methods for other functions
// }

// // contracts/OracleManagementContract.ts
// import { Account, AccountAddress, Ed25519Account, Aptos, AptosConfig, InputViewFunctionData } from "@aptos-labs/ts-sdk";

// const ORACLE_MANAGEMENT_ADDRESS = "0xe2973b0f17f4813b3b36ffb24283251b7dff2fade4832e1b457b48f646dc58e7";
// const ORACLE_MANAGEMENT_MODULE = "oracle_management";

// export class OracleManagementContract {
//   private aptos: Aptos;
//   private oracleManagementAddress: string;
//   private oracleManagementModule: string;

//   constructor(aptos: Aptos) {
//     this.aptos = aptos;
//     this.oracleManagementAddress = ORACLE_MANAGEMENT_ADDRESS;
//     this.oracleManagementModule = ORACLE_MANAGEMENT_MODULE;
//   }

//   // This is a view function
//   public async isRewardAssociated(oracle: AccountAddress) {
//     // const payload: InputViewFunctionData = {
//     //   function: `${this.oracleManagementAddress}::${this.oracleManagementModule}::is_reward_associated`,
//     //   functionArguments: [oracle],
//     // };

//     // const result = await this.aptos.view<[{ inner: string }]>(payload);

//     const payload: InputViewFunctionData = {
//       function: `${this.oracleManagementAddress}::${this.oracleManagementModule}::is_reward_associated`,
//       functionArguments: [oracle],
//     }

//     const data = await this.aptos.view({ payload });
//     if (data[0]) {
//       console.log("Resource is associated successfully.");
//     } else {
//       console.log("Reward is not associated.");
//     }
//   }

//   // This is a view function
//   public async listRegisteredOracles() {
//     const payload: InputViewFunctionData = {
//       function: `${this.oracleManagementAddress}::${this.oracleManagementModule}::list_registered_oracle`,
//       functionArguments: [],
//     };

//     const result = await this.aptos.view({payload});
//     console.log("Registered Oracles: ", result[0]);
//   }

//   // This is a view function
//   public async get_oracle_reward_balance(oracleAddress: AccountAddress){
//     const payload: InputViewFunctionData = {
//       function: `${this.oracleManagementAddress}::${this.oracleManagementModule}::get_oracle_reward_balance`,
//       functionArguments: [oracleAddress],
//     };

//     const result = await this.aptos.view({payload});
//     console.log("Registered Oracles: ", result[0]);
//   }

//   // This is a view function
//   public async registered_oracle_count(){
//     const payload: InputViewFunctionData = {
//       function: `${this.oracleManagementAddress}::${this.oracleManagementModule}::registered_oracle_count`,
//       functionArguments: [],
//     };

//     const result = await this.aptos.view({payload});
//     console.log("Registered Oracles Count:", result[0]);
//   }

//   public async associate_reward_resource(oracle: Ed25519Account) {
//     const transaction = await this.aptos.transaction.build.simple({
//       sender: oracle.accountAddress,
//       data: {
//         function: `${this.oracleManagementAddress}::${this.oracleManagementModule}::associate_reward_resource`,
//         functionArguments: [],
//       }
//     })

//     const committedTxn = await this.aptos.signAndSubmitTransaction({
//       transaction,
//       signer: oracle,
//     })

//     const executedTxn = await this.aptos.waitForTransaction({
//       transactionHash: committedTxn.hash
//     });

//     console.log("Transaction hash: ", executedTxn.hash);
//   }

//   public async add_oracle_address(owner: Ed25519Account, oracleAddr: AccountAddress, tokenName: string) {
//     const transaction = await this.aptos.transaction.build.simple({
//       sender: owner.accountAddress,
//       data: {
//         function: `${this.oracleManagementAddress}::${this.oracleManagementModule}::add_oracle_address`,
//         functionArguments: [oracleAddr, tokenName],
//       }
//     })

//     const committedTxn = await this.aptos.signAndSubmitTransaction({
//       transaction,
//       signer: owner,
//     })

//     const executedTxn = await this.aptos.waitForTransaction({
//       transactionHash: committedTxn.hash
//     });

//     console.log("Transaction hash: ", executedTxn.hash);
//   }

//   // Add more methods for other functions
// }
