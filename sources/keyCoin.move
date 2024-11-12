module KGen::key_coin {
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::primary_fungible_store;
    use std::error;
    use std::signer;
    use std::string::{utf8};
    use std::option;

    // use KGen::oracle_management;

    /// Only fungible asset metadata owner can make changes.
    const ENOT_OWNER: u64 = 1;
    const ENOT_PAUSED: u64 = 2;
    const EKEY_LIMIT_EXCEEDED: u64 = 3;
    const ASSET_SYMBOL: vector<u8> = b"KEY";
    const EINVALID_AMOUNT: u64 = 2; // Invalid token amount
    const EINSUFFICIENT_BALANCE: u64 = 3; // Insufficient balance
    const EPAUSED: u64 = 2;
    const EINVALID_ARGUMENTS: u64 = 12;

    // Constants for your contract
    const KEY_PRICE_IN_APT: u64 = 1000000; // Set the price of 1 KEY in APT (example: 1 APT = 1,000,000 micro APT)

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef
    }

    struct A has key {
        amount: u64
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// Global state to pause the KGen.
    struct State has key {
        paused: bool,
        key_limit: u64
    }

    #[event]
    /// Emitted when bucket rewards are transfered between a stores.
    struct KeyMint has drop, store {
        sender: address,
        receiver: address,
        amount: u64
    }

    /// Initialize the module and metadata object and store the refs.
    entry fun init_module(admin: &signer) {
        assert!(signer::address_of(admin) == @KGen, error::invalid_argument(ENOT_OWNER));
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(b"Key Coin"), /* name */
            utf8(ASSET_SYMBOL), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com") /* project */
        );

        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);

        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );

        move_to(
            &metadata_object_signer,
            State { paused: false, key_limit: 0 }
        );
    }

    #[view]
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@KGen, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }

    #[view]
    public fun key_count(owner: address): u64 {
        let asset = get_metadata();
        primary_fungible_store::balance(owner, asset)
    }

    public entry fun mint_keys(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let managed_fungible_asset = authorized_borrow_refs(admin, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(
            &managed_fungible_asset.transfer_ref, to_wallet, fa
        );
    }

    public entry fun transfer(
        admin: &signer, from: address, to: address, amount: u64
    ) acquires ManagedFungibleAsset {
        // validate_not_paused();
        let asset = get_metadata();
        let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let balance = fungible_asset::balance(from_wallet);
        assert!((balance >= amount), error::permission_denied(EINSUFFICIENT_BALANCE));
        fungible_asset::transfer_with_ref(transfer_ref, from_wallet, to_wallet, amount);
    }

    public entry fun burn(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let burn_ref = &authorized_borrow_refs(admin, asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    // public fun get_staked_keys(oracle_address: address): u64 {
    //     KGen::oracle_management::staked_key_amount(oracle_address)
    // }

    public entry fun purchase_keys_apt(
        admin: &signer, buyer: &signer, amount: u64
    ) acquires ManagedFungibleAsset {
        let buyer_address = signer::address_of(buyer);
        let total_value_of_key = amount * KEY_PRICE_IN_APT;
        mint_keys(admin, buyer_address, total_value_of_key);
    }

    public entry fun set_pause(admin: &signer, pause: bool) acquires State {
        let asset = get_metadata();
        let state = authorized_borrow_state(admin, asset);
        state.paused = pause;
    }

    public entry fun set_key_limit(admin: &signer, new_limit: u64) acquires State {
        let asset = get_metadata();
        let state = authorized_borrow_state(admin, asset);
        state.key_limit = new_limit;
    }

    public fun deploy_module(admin: &signer, initial_key_limit: u64) acquires State {
        assert!(signer::address_of(admin) == @KGen, error::invalid_argument(ENOT_OWNER));
        let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            utf8(b"Key Coin"), /* name */
            utf8(ASSET_SYMBOL), /* symbol */
            8, /* decimals */
            utf8(b"http://example.com/favicon.ico"), /* icon */
            utf8(b"http://example.com") /* project */
        );

        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);

        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        );

        move_to(
            &metadata_object_signer,
            State { paused: false, key_limit: 0 }
        );
        set_key_limit(admin, initial_key_limit);
    }

    inline fun authorized_borrow_refs(
        owner: &signer, asset: Object<Metadata>
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ENOT_OWNER)
        );
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    inline fun authorized_borrow_state(
        owner: &signer, asset: Object<Metadata>
    ): &mut State acquires State {
        assert!(
            object::is_owner(asset, signer::address_of(owner)),
            error::permission_denied(ENOT_OWNER)
        );
        borrow_global_mut<State>(object::object_address(&asset))
    }

    public fun get_key_limit(): u64 acquires State {
        let asset = get_metadata();
        let state = borrow_global<State>(object::object_address(&asset));
        state.key_limit
    }

    public fun is_paused(): bool acquires State {
        let asset = get_metadata();
        let state = borrow_global<State>(object::object_address(&asset));
        state.paused
    }

    inline fun validate_not_paused() acquires State {
        let state = borrow_global<State>(@KGen);
        assert!(!state.paused, error::permission_denied(EPAUSED));
    }

    inline fun is_owner(owner: address): bool {
        owner == @KGen
    }

    #[test(admin = @KGen)]
    fun test_basic_flow(admin: &signer) acquires ManagedFungibleAsset {
        init_module(admin);
        let admin_address = signer::address_of(admin);
        mint_keys(admin, admin_address, 100);
        let asset = get_metadata();
        assert!(primary_fungible_store::balance(admin_address, asset) == 100, 4);
    }

    #[test(admin = @KGen, buyer = @0xface)]
    fun test_purchase_keys_apt(admin: &signer, buyer: &signer) acquires ManagedFungibleAsset {
        init_module(admin);
        let amount_to_purchase = 10;
        purchase_keys_apt(admin, buyer, amount_to_purchase);
        let asset = get_metadata();
        let
        balance = primary_fungible_store::balance(signer::address_of(buyer), asset);
        assert!(
            balance == (KEY_PRICE_IN_APT * amount_to_purchase),
            EINVALID_AMOUNT
        );
    }

    #[test(admin = @KGen)]
    fun test_pause(admin: &signer) acquires State {
        init_module(admin);
        set_pause(admin, true);
        assert!(is_paused(), ENOT_PAUSED);
    }

    #[test(admin = @KGen)]
    fun test_key_limit(admin: &signer) acquires State {
        init_module(admin);
        set_key_limit(admin, 100);
        assert!(get_key_limit() == 100, EKEY_LIMIT_EXCEEDED);
    }
}

// module KGen::key_coin {
//     use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
//     use aptos_framework::object::{Self, Object};
//     use aptos_framework::primary_fungible_store;
//     use std::error;
//     use std::signer;
//     use std::string::utf8;
//     use std::option;

//     // use KGen::oracle_management;

//     /// Only fungible asset metadata owner can make changes.
//     const ENOT_OWNER: u64 = 1;
//     const ENOT_PAUSED: u64 = 2;
//     const EKEY_LIMIT_EXCEEDED: u64 = 3;
//     const ASSET_SYMBOL: vector<u8> = b"KEY";
//     const EINVALID_AMOUNT: u64 = 2; // Invalid token amount
//     const EINSUFFICIENT_BALANCE: u64 = 3; // Insufficient balance
//     const EPAUSED: u64 = 2;
//     const EINVALID_ARGUMENTS: u64 = 12;

//     // Constants for your contract
//     const KEY_PRICE_IN_APT: u64 = 1000000; // Set the price of 1 KEY in APT (example: 1 APT = 1,000,000 micro APT)

//     #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
//     struct ManagedFungibleAsset has key {
//         mint_ref: MintRef,
//         transfer_ref: TransferRef,
//         burn_ref: BurnRef,
//     }

//     struct A has key { amount: u64 }

//     #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
//     /// Global state to pause the KGen.
//     struct State has key {
//         paused: bool,
//         key_limit: u64,
//     }

//     #[event]
//     /// Emitted when bucket rewards are transfered between a stores.
//     struct KeyMint has drop, store {
//         sender: address,
//         receiver: address,
//         amount: u64,
//     }

//     /// Initialize the module and metadata object and store the refs.
//     entry fun init_module(admin: &signer) {
//         assert!(signer::address_of(admin) == @KGen, error::invalid_argument(ENOT_OWNER));
//         let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
//         primary_fungible_store::create_primary_store_enabled_fungible_asset(
//             constructor_ref,
//             option::none(),
//             utf8(b"Key Coin"), /* name */
//             utf8(ASSET_SYMBOL), /* symbol */
//             8, /* decimals */
//             utf8(b"http://example.com/favicon.ico"), /* icon */
//             utf8(b"http://example.com"), /* project */
//         );

//         let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
//         let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
//         let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
//         let metadata_object_signer = object::generate_signer(constructor_ref);

//         move_to(
//             &metadata_object_signer,
//             ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
//         );

//         move_to(
//             &metadata_object_signer,
//             State { paused: false, key_limit: 0 }
//         );
//     }

//     #[view]
//     public fun get_metadata(): Object<Metadata> {
//         let asset_address = object::create_object_address(&@KGen, ASSET_SYMBOL);
//         object::address_to_object<Metadata>(asset_address)
//     }

//     public entry fun mint_keys(admin: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
//         let asset = get_metadata();
//         let managed_fungible_asset = authorized_borrow_refs(admin, asset);
//         let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
//         let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
//         fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
//     }

//     public entry fun transfer(admin: &signer, from: address, to: address, amount: u64) acquires ManagedFungibleAsset, State {
//         validate_not_paused();
//         let asset = get_metadata();
//         let transfer_ref = &authorized_borrow_refs(admin, asset).transfer_ref;
//         let from_wallet = primary_fungible_store::primary_store(from, asset);
//         let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
//         let balance = fungible_asset::balance(from_wallet);
//         assert!(!(balance >= amount), error::permission_denied(EINSUFFICIENT_BALANCE));
//         fungible_asset::transfer_with_ref(transfer_ref, from_wallet, to_wallet, amount);
//     }

//     public entry fun burn(admin: &signer, from: address, amount: u64) acquires ManagedFungibleAsset {
//         let asset = get_metadata();
//         let burn_ref = &authorized_borrow_refs(admin, asset).burn_ref;
//         let from_wallet = primary_fungible_store::primary_store(from, asset);
//         fungible_asset::burn_from(burn_ref, from_wallet, amount);
//     }

//     // public fun get_staked_keys(oracle_address: address): u64 {
//     //     KGen::oracle_management::staked_key_amount(oracle_address)
//     // }

//     public entry fun purchase_keys_apt(admin: &signer, buyer: &signer, amount: u64) acquires ManagedFungibleAsset {
//         let buyer_address = signer::address_of(buyer);
//         let total_value_of_key = amount * KEY_PRICE_IN_APT;
//         mint_keys(admin, buyer_address, total_value_of_key);
//     }

//     public entry fun set_pause(admin: &signer, pause: bool) acquires State {
//         let asset = get_metadata();
//         let state = authorized_borrow_state(admin, asset);
//         state.paused = pause;
//     }

//     public entry fun set_key_limit(admin: &signer, new_limit: u64) acquires State {
//         let asset = get_metadata();
//         let state = authorized_borrow_state(admin, asset);
//         state.key_limit = new_limit;
//     }

//     public fun deploy_module(admin: &signer, initial_key_limit: u64) acquires State {
//         assert!(signer::address_of(admin) == @KGen, error::invalid_argument(ENOT_OWNER));
//         let constructor_ref = &object::create_named_object(admin, ASSET_SYMBOL);
//         primary_fungible_store::create_primary_store_enabled_fungible_asset(
//             constructor_ref,
//             option::none(),
//             utf8(b"Key Coin"), /* name */
//             utf8(ASSET_SYMBOL), /* symbol */
//             8, /* decimals */
//             utf8(b"http://example.com/favicon.ico"), /* icon */
//             utf8(b"http://example.com"), /* project */
//         );

//         let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
//         let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
//         let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
//         let metadata_object_signer = object::generate_signer(constructor_ref);

//         move_to(
//             &metadata_object_signer,
//             ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
//         );

//         move_to(
//             &metadata_object_signer,
//             State { paused: false, key_limit: 0 }
//         );
//         set_key_limit(admin, initial_key_limit);
//     }

//     inline fun authorized_borrow_refs(owner: &signer, asset: Object<Metadata>): &ManagedFungibleAsset acquires ManagedFungibleAsset {
//         assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
//         borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
//     }

//     inline fun authorized_borrow_state(owner: &signer, asset: Object<Metadata>): &mut State acquires State {
//         assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
//         borrow_global_mut<State>(object::object_address(&asset))
//     }

//     public fun get_key_limit(): u64 acquires State {
//         let asset = get_metadata();
//         let state = borrow_global<State>(object::object_address(&asset));
//         state.key_limit
//     }

//     public fun is_paused(): bool acquires State {
//         let asset = get_metadata();
//         let state = borrow_global<State>(object::object_address(&asset));
//         state.paused
//     }

//     inline fun validate_not_paused() acquires State {
//         let state = borrow_global<State>(@KGen);
//         assert!(!state.paused, error::permission_denied(EPAUSED));
//     }

//     inline fun is_owner(owner: address) : bool {
//         owner == @KGen
//     }

//     #[test(admin = @KGen)]
//     fun test_basic_flow(admin: &signer) acquires ManagedFungibleAsset {
//         init_module(admin);
//         let admin_address = signer::address_of(admin);
//         mint_keys(admin, admin_address, 100);
//         let asset = get_metadata();
//         assert!(primary_fungible_store::balance(admin_address, asset) == 100, 4);
//     }

//     #[test(admin = @KGen, buyer = @0xface)]
//     fun test_purchase_keys_apt(admin: &signer, buyer: &signer) acquires ManagedFungibleAsset {
//         init_module(admin);
//         let amount_to_purchase = 10;
//         purchase_keys_apt(admin, buyer, amount_to_purchase);
//         let asset = get_metadata();
//         let buyer_address = signer::address_of(buyer);
//         let expected_balance = amount_to_purchase * KEY_PRICE_IN_APT;
//         assert!(primary_fungible_store::balance(buyer_address, asset) == expected_balance, 4);
//     }

//     #[test(admin = @KGen)]
//     fun test_set_key_limit(admin: &signer) acquires State {
//         init_module(admin);
//         let initial_key_limit = 500;
//         set_key_limit(admin, initial_key_limit);
//         let current_key_limit = get_key_limit();
//         assert!(current_key_limit == initial_key_limit, error::permission_denied(EKEY_LIMIT_EXCEEDED));
//         let new_key_limit = 1000;
//         set_key_limit(admin, new_key_limit);
//         let updated_key_limit = get_key_limit();
//         assert!(updated_key_limit == new_key_limit, error::permission_denied(EKEY_LIMIT_EXCEEDED));
//     }
// }
