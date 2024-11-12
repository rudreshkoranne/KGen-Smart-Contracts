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
const POA_NFT_MODULE = "poa_nft";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

export async function view_token(tokenName: string) {
  const payload: InputViewFunctionData = {
    function: `${KGEN_WALLET_ADDRESS}::${POA_NFT_MODULE}::view_token`,
    functionArguments: [tokenName],
  };

  const result = await aptos.view({ payload });

  console.log("Token held by address: ", result[0]);
}
