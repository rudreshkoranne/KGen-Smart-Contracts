import {
  Account,
  AccountAddress,
  Ed25519Account,
  Aptos,
  AptosConfig,
  Network,
  InputViewFunctionData,
  U64,
} from "@aptos-labs/ts-sdk";

const KGEN_WALLET_ADDRESS = "0x123";
const REWARD_CONTRACT_MODULE = "reward_contract";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

export async function get_oracle_reward_balance(oracleAddr: AccountAddress) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${REWARD_CONTRACT_MODULE}::is_oracle_verified`,
    functionArguments: [oracleAddr],
  };

  const result = await aptos.view({ payload });

  console.log("Oracle reward balance", result[0]);
}

export async function distribute_rewards(
  owner: Ed25519Account,
  base_reward: number
) {
  const transaction = await aptos.transaction.build.simple({
    sender: owner.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${REWARD_CONTRACT_MODULE}::distribute_rewards`,
      functionArguments: [base_reward],
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

export async function update_performance_metrics(
  owner: Ed25519Account,
  oracle_address: AccountAddress,
  uptime: U64,
  accuracy: U64
) {
  const transaction = await aptos.transaction.build.simple({
    sender: owner.accountAddress,
    data: {
      function: `${KGEN_WALLET_ADDRESS}::${REWARD_CONTRACT_MODULE}::update_performance_metrics`,
      functionArguments: [oracle_address, uptime, accuracy],
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
