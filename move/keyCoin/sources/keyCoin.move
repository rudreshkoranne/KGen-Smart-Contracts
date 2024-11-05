
module KEYCoin::key_coin {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::string::utf8;
    use std::option;
  
    
    /// Only fungible asset metadata owner can make changes.
    const ENOT_OWNER: u64 = 1;
    const ENOT_PAUSED: u64 = 2;
    const EKEY_LIMIT_EXCEEDED: u64 = 3;
    const ASSET_SYMBOL: vector<u8> = b"KEY";
    const EINVALID_AMOUNT: u64 = 2; // Invalid token amount
    const EINSUFFICIENT_BALANCE: u64 = 3; // Insufficient balance
    const EPAUSED: u64 = 2;
    const EINVALID_ARGUMENTS: u64 = 12;

    const BUYR_SIGNER_KEY: vector<u8> = x"c3c8b4fba6a38309517ff29151c7a25b6bdac57ba2827bb7f37071abcdc922ce";


 // Constants for your contract
    const KEY_PRICE_IN_APT: u64 = 1000000; // Set the price of 1 KEY in APT (example: 1 APT = 1,000,000 micro APT)
    
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    // Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }


    struct A has key { amount: u64 }
 

     #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
      /// Global state to pause the KEYcoin.
      struct State has key {
        paused: bool,
        key_limit: u64,
      }

      #[event]
    /// Emitted when bucket rewards are transfered between a stores.
    struct KeyMint has drop, store {
        sender: address,
        receiver: address,
        amount: u64,
    }

  
      

    /// Initialize  the module and metadata object and store the refs.
      entry fun init_module(admin: &signer) {
        // Check if the signer is valid
        // assert!(!(signer::address_of(admin) == @KEYCoin), error::invalid_argument(ENOT_OWNER));
        assert!(signer::address_of(admin) == @KEYCoin, error::invalid_argument(ENOT_OWNER));
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(b"Key Coin"), /* name */
            utf8(ASSET_SYMBOL), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com"), /* project */
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        //This ensures that only actions authorized by this signer can access these references and manage the token.
        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );
        // Create a global state to pause the KEYcoin and move to Metadata object.
        //This struct defines the global state of the token, specifically a paused field. 
        // This State struct defines global settings for the token:
        move_to(
            &metadata_object_signer,
            State { paused: false, key_limit:0 }
        );
    }




 #[view]
/// Return the address of the managed fungible asset that's created when this module is deployed.
 public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@KEYCoin, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }




public entry fun mint_keys(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let managed_fungible_asset = authorized_borrow_refs(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
    }

    
    
      /// Transfer as the owner of metadata object ignoring field.
public entry fun transfer(admin: &signer, from: address, to: address, amount: u64) acquires ManagedFungibleAsset,State {
         validate_not_paused();
        //   assert!(amount > 0, error::invalid_argument(EINVALID_AMOUNT));
        //   assert!(from != to, error::invalid_argument(EINVALID_AMOUNT)); // Prevent self-transfer
          let asset = get_metadata();
          let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
          let from_wallet = primary_fungible_store::primary_store(from, asset);
          let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
          let balance = fungible_asset::balance(from_wallet);
           assert!(!(balance >= amount), error::permission_denied(EINSUFFICIENT_BALANCE));
          fungible_asset::transfer_with_ref(transfer_ref, from_wallet, to_wallet, amount);
    }
      
  
     /// Burn fungible assets as the owner of metadata object.
    public entry fun burn(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let burn_ref = &authorized_borrow_refs(admin, asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }


    /// Fetch staked keys for a particular address (this needs to be implemented with staking logic)
    public fun get_staked_keys(_owner: address): u64 {
         // Placeholder logic to be implemented based on staking mechanism
        0
    }


       // Function to purchase keys using APT
    public entry fun purchase_keys_apt( admin: &signer, buyer: &signer, amount: u64) acquires ManagedFungibleAsset {
        
        // Get the buyer's address
        let buyer_address = signer::address_of(buyer);

        // Calculate the total APT cost (amount of keys * price per key)
        let total_value_of_key = amount * KEY_PRICE_IN_APT;

        // // Check if the buyer has enough APT
        // let buyer_balance = fungible_asset::balance(buyer_address);
        // assert!(buyer_balance >= total_cost_in_apt, error::permission_denied(EINSUFFICIENT_BALANCE));

        // // Transfer the APT from the buyer to the contract (you might want to specify the contract's address here)
        // fungible_asset::transfer(buyer, @KEYCoin, total_cost_in_apt);
        // let from_wallet = primary_fungible_store::primary_store(from, asset);
        // let balance = fungible_asset::balance(from_wallet);

        // Mint the specified amount of keys
        mint_keys(admin ,buyer_address, total_value_of_key);
}



    /// Pause or unpause the coin's activity.
public entry fun set_pause(admin: &signer, pause: bool) acquires State {
        let asset = get_metadata();
        let state = authorized_borrow_state(admin, asset);
        state.paused = pause;
    }

 public entry fun set_key_limit(admin: &signer, new_limit: u64) acquires State {
        // assert!(signer::address_of(admin) != @KEYCoin, error::invalid_argument(ENOT_OWNER));
         let asset = get_metadata();
        let state = authorized_borrow_state(admin, asset);
         state.key_limit = new_limit;
       }



         /// Deploy function to initialize the module and set key limit
    public fun deploy_module(admin: &signer, initial_key_limit: u64) acquires State {
        init_module(admin);
        set_key_limit(admin,initial_key_limit );
        
       } 


    /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
inline fun authorized_borrow_refs(
          owner: &signer,
          asset: Object<Metadata>,
       ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
           assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
           borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
          }

   /// Helper function to borrow the state of the coin securely.
   inline fun authorized_borrow_state(
        owner: &signer,
        asset: Object<Metadata>,
    ): &mut State acquires State {
        assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
        borrow_global_mut<State>(object::object_address(&asset))
    }


// View function to get the current key mint limit.
    public fun get_key_limit(): u64 acquires State {
        let asset = get_metadata();
        let state = borrow_global<State>(object::object_address(&asset));
        state.key_limit
    }

/// View function to check if the asset is paused.
    public fun is_paused(): bool acquires State {
        let asset = get_metadata();
        let state = borrow_global<State>(object::object_address(&asset));
        state.paused
    }


    /// Helper function: validate if the contract is not paused
inline fun validate_not_paused() acquires State {
        let state = borrow_global<State>(@KEYCoin);
        assert!(!state.paused, error::permission_denied(EPAUSED));
    }

    // to check if the address is of admin
inline fun is_owner(owner: address) : bool{
        owner == @KEYCoin
  }

#[test(admin = @KEYCoin)]
fun test_basic_flow(
        admin: &signer,
    ) acquires ManagedFungibleAsset{
        init_module(admin);
        let admin_address = signer::address_of(admin);
        mint_keys(admin, admin_address, 100);
        let asset = get_metadata();
        assert!(primary_fungible_store::balance(admin_address, asset) == 100, 4);
       
    }
 
  #[test( admin = @KEYCoin, buyer = @0xface)]
    fun test_purchase_keys_apt(
        admin: &signer,
        buyer: &signer
    ) acquires ManagedFungibleAsset {
        init_module(admin);
       // Define the amount of keys to purchase
       let amount_to_purchase = 10;
        purchase_keys_apt(admin, buyer, amount_to_purchase);
        // Get the asset metadata
        let asset = get_metadata();
      // Check the balance of the buyer
        let buyer_address = signer::address_of(buyer);
        let expected_balance = amount_to_purchase * KEY_PRICE_IN_APT;
        assert!(primary_fungible_store::balance(buyer_address, asset) == expected_balance, 4);
    }


 #[test(admin = @KEYCoin)]
fun test_set_key_limit(
    admin: &signer
) acquires State {
    // Initialize the module
    init_module(admin);

    // Set an initial key limit
    let initial_key_limit = 500;
    set_key_limit(admin, initial_key_limit);

    // Verify that the key limit is set correctly
    let current_key_limit = get_key_limit();
    assert!(current_key_limit == initial_key_limit, error::permission_denied(EKEY_LIMIT_EXCEEDED));

    // Update the key limit to a new value
    let new_key_limit = 1000;
    set_key_limit(admin, new_key_limit);

    // Verify the key limit has been updated
    let updated_key_limit = get_key_limit();
    assert!(updated_key_limit == new_key_limit, error::permission_denied(EKEY_LIMIT_EXCEEDED));
}


}
