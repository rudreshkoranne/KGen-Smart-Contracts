    
module rkGen_add::rkGen_token {
    
    
    use aptos_framework::fungible_asset::{Self,MintRef, TransferRef, BurnRef, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::string::utf8;
    use std::option;
  

    //  Error Codes
    const E_NOT_OWNER: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;
    const ENOT_OWNER: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 3; // Insufficient balance

    const ASSET_SYMBOL: vector<u8> = b"rkGEN";

 #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    // Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }


/// Initialize  the module and metadata object and store the refs.
entry fun init_module(admin: &signer) {
        // Check if the signer is valid
        // assert!(!(signer::address_of(admin) == @rkGen_add), error::invalid_argument(ENOT_OWNER));
        assert!(signer::address_of(admin) == @rkGen_add, error::invalid_argument(ENOT_OWNER));
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(b"rkGen"), /* name */
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
       
    }


 #[view]
  /// Return the address of the managed fungible asset that's created when this module is deployed.
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@rkGen_add, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }



  public entry fun mint_rkGen_token(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let managed_fungible_asset = authorized_borrow_refs(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
    }


   /// Transfer as the owner of metadata object ignoring field.
      public entry fun transfer(admin: &signer, from: address, to: address, amount: u64) acquires ManagedFungibleAsset {
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


  /// Borrow the immutable reference of the refs of `metadata`.
    /// This validates that the signer is the metadata object's owner.
    inline fun authorized_borrow_refs(
          owner: &signer,
          asset: Object<Metadata>,
       ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
           assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
           borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
          }


 // to check if the address is of admin
  inline fun is_owner(owner: address) : bool{
        owner == @rkGen_add
  }

#[test(admin = @rkGen_add)]
fun test_basic_flow(
        admin: &signer,
    ) acquires ManagedFungibleAsset{
        init_module(admin);
        let admin_address = signer::address_of(admin);
        // mint_keys(admin, admin_address, 100);
        mint_rkGen_token(admin,admin_address,100);
        let asset = get_metadata();
        assert!(primary_fungible_store::balance(admin_address, asset) == 100, 4);
       
    }

}
