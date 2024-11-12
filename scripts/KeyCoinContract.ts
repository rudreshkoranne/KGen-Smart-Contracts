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
const KEY_COIN_MODULE = "key_coin";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

export async function key_coin_count(oracle: AccountAddress) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${KEY_COIN_MODULE}::key_count`,
    functionArguments: [oracle],
  };

  const data = await aptos.view({ payload });
  console.log("Key Coin held by wallet: ", data[0]);
}
