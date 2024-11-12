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
const RKGEN_MODULE = "rkGen_token";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

export async function reward_token_count(oracleAddr: AccountAddress) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${RKGEN_MODULE}::token_count`,
    functionArguments: [oracleAddr],
  };

  const result = await aptos.view({ payload });
  console.log("rKGen Token held by Address: ", result[0]);
}
