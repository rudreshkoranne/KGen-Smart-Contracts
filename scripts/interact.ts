import {
  Account,
  AccountAddress,
  AnyNumber,
  Aptos,
  AptosConfig,
  Ed25519PrivateKey,
  Ed25519Signature,
  InputViewFunctionData,
  Network,
  Serializable,
  Serializer,
} from "@aptos-labs/ts-sdk";
import sha256 from "fast-sha256";
import {
  listRegisteredOracles,
  registered_oracle_count,
  get_oracle_reward_balance,
  associate_reward_resource,
  isRewardAssociated,
  add_oracle_address,
  is_oracle_verified,
  set_oracle_status,
} from "./OracleManagementContract";
import { view_token } from "./POANFTContract";
import { reward_token_count } from "./RKGenContract";
import { key_coin_count } from "./KeyCoinContract";
import {
  submit_score,
  is_pub_key_present,
  add_oracle_public_key,
  remove_oracle_public_key,
  verify_signature,
  fetch_player_score,
  pub_vectro_size,
  check_threshold,
  fetch_player_rank,
} from "./PoGContract";
import { distribute_rewards } from "./RewardContract";

const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

function hexToUint8Array(hex: string): Uint8Array {
  if (hex.startsWith("0x")) {
    hex = hex.slice(2);
  }
  const length = hex.length / 2;
  const array = new Uint8Array(length);
  for (let i = 0; i < length; i++) {
    array[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return array;
}

export class Uint64 extends Serializable {
  constructor(public value: bigint) {
    super();
  }

  serialize(serializer: Serializer): void {
    serializer.serializeU64(this.value);
  }
}

export class MessageMoveStruct extends Serializable {
  constructor(public name: string, public age: Uint64, public gender: string) {
    super();
  }

  serialize(serializer: Serializer): void {
    serializer.serializeStr(this.name);
    serializer.serialize(this.age);
    serializer.serializeStr(this.gender);
  }
}

export async function signMessage(
  privateKey: Ed25519PrivateKey,
  messageHash: Uint8Array
): Promise<Ed25519Signature> {
  const signature = await privateKey.sign(messageHash);
  return signature;
}

async function main() {
  console.log("This program helps us interact with the KGen-Contracts.");

  let ownerPrivateKey = new Ed25519PrivateKey(
    "0xa5ba1014dbfc5eee63aae053a753e300feb443006c626a0322e340abcf1c0835"
  );
  let ownerAcc = Account.fromPrivateKey({ privateKey: ownerPrivateKey });

  let Oracle1PrivateKey = new Ed25519PrivateKey(
    "0x32a2a0ae8d7df55d8a989db2fc47d161f16c0e477edf7af9eac62c54fe27ff0e"
  );
  let oracle1Acc = Account.fromPrivateKey({ privateKey: Oracle1PrivateKey });

  let Oracle2PrivateKey = new Ed25519PrivateKey(
    "0x76aa7fb032e3e03717673d5da8002f9f2faaa658d7bba8297827af74df27420c"
  );
  let oracle2Acc = Account.fromPrivateKey({ privateKey: Oracle2PrivateKey });

  let Oracle3PrivateKey = new Ed25519PrivateKey(
    "0x700550b3a9cf7100bb6e53d5473d54a3564fde071df9030e0b33afb658655076"
  );
  let oracle3Acc = Account.fromPrivateKey({ privateKey: Oracle3PrivateKey });

  console.log("Owner Account Address: ", ownerAcc.accountAddress.toString());
  console.log(
    "Oracle1 Account Address: ",
    oracle1Acc.accountAddress.toString()
  );
  console.log(
    "Oracle2 Account Address: ",
    oracle2Acc.accountAddress.toString()
  );
  console.log(
    "Oracle3 Account Address: ",
    oracle3Acc.accountAddress.toString()
  );

  let player_id = [BigInt(1), BigInt(2), BigInt(3)];
  let player_rank = [BigInt(53), BigInt(100), BigInt(45)];
  let player_scores = [BigInt(300), BigInt(200), BigInt(100)];

  let message = new MessageMoveStruct(
    "Rudresh Koranne",
    new Uint64(BigInt(21)),
    "iMentus"
  );

  let msg_bytes = message.bcsToBytes();
  let msg_hash = sha256(msg_bytes);

  let oracle1Signature = await signMessage(oracle1Acc.privateKey, msg_hash);
  let oracle2Signature = await signMessage(oracle2Acc.privateKey, msg_hash);
  let oracle3Signature = await signMessage(oracle3Acc.privateKey, msg_hash);

  // await associate_reward_resource(oracle1Acc)
  // await associate_reward_resource(oracle2Acc)
  // await associate_reward_resource(oracle3Acc)

  // await add_oracle_address(ownerAcc, oracle1Acc.accountAddress, "Tokon01")
  // await add_oracle_address(ownerAcc, oracle2Acc.accountAddress, "Tokon02")
  // await add_oracle_address(ownerAcc, oracle3Acc.accountAddress, "Tokon03")

  // await add_oracle_public_key(ownerAcc, oracle1Acc.publicKey.toUint8Array());
  // await add_oracle_public_key(ownerAcc, oracle2Acc.publicKey.toUint8Array());
  // await add_oracle_public_key(ownerAcc, oracle3Acc.publicKey.toUint8Array());
  // await is_pub_key_present(oracle1Acc.publicKey.toUint8Array());
  // await is_pub_key_present(oracle2Acc.publicKey.toUint8Array());
  // await is_pub_key_present(oracle3Acc.publicKey.toUint8Array());

  // await pub_vectro_size();
  // await check_threshold(
  //   [
  //     oracle1Acc.publicKey.toUint8Array(),
  //     oracle2Acc.publicKey.toUint8Array(),
  //     oracle3Acc.publicKey.toUint8Array(),
  //   ]
  // )

  // await submit_score(
  //   ownerAcc,
  //   msg_hash,
  //   [
  //     oracle1Signature.toUint8Array(),
  //     oracle2Signature.toUint8Array(),
  //     oracle3Signature.toUint8Array()
  //   ],
  //   [
  //     oracle1Acc.publicKey.toUint8Array(),
  //     oracle2Acc.publicKey.toUint8Array(),
  //     oracle3Acc.publicKey.toUint8Array(),
  //   ],
  //   player_id,
  //   player_rank,
  //   player_scores,
  // )

  // await fetch_player_rank(0);
  // await fetch_player_rank(1);
  // await fetch_player_rank(2);

  // player_rank = [BigInt(100), BigInt(200), BigInt(300)];

  // await submit_score(
  //   ownerAcc,
  //   msg_hash,
  //   [
  //     oracle1Signature.toUint8Array(),
  //     oracle2Signature.toUint8Array(),
  //     oracle3Signature.toUint8Array()
  //   ],
  //   [
  //     oracle1Acc.publicKey.toUint8Array(),
  //     oracle2Acc.publicKey.toUint8Array(),
  //     oracle3Acc.publicKey.toUint8Array(),
  //   ],
  //   player_id,
  //   player_rank,
  //   player_scores,
  // )

  // await fetch_player_rank(0);
  // await fetch_player_rank(1);
  // await fetch_player_rank(2);

  await get_oracle_reward_balance(oracle1Acc.accountAddress);
  await get_oracle_reward_balance(oracle2Acc.accountAddress);
  await get_oracle_reward_balance(oracle3Acc.accountAddress);

  await reward_token_count(oracle1Acc.accountAddress);
  await reward_token_count(oracle2Acc.accountAddress);
  await reward_token_count(oracle3Acc.accountAddress);

  await is_oracle_verified(oracle1Acc.accountAddress);
  await is_oracle_verified(oracle2Acc.accountAddress);
  await is_oracle_verified(oracle3Acc.accountAddress);

  await distribute_rewards(ownerAcc, 20);

  await get_oracle_reward_balance(oracle1Acc.accountAddress);
  await get_oracle_reward_balance(oracle2Acc.accountAddress);
  await get_oracle_reward_balance(oracle3Acc.accountAddress);

  await reward_token_count(oracle1Acc.accountAddress);
  await reward_token_count(oracle2Acc.accountAddress);
  await reward_token_count(oracle3Acc.accountAddress);

  // await set_oracle_status(ownerAcc, oracle1Acc.accountAddress, true);
}

main()
  .then(() => console.log("Main executed successfully."))
  .catch((err) => console.log("Error while executing main: ", err));
