module KGen::oracle_management {

    use std::vector;
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Metadata};

    // use KGen::reward_contract;
    use KGen::rkGen_token;
    use KGen::poa_nft;

    // KEY COIN SYMBOL
    const ASSET_SYMBOL: vector<u8> = b"KEY";

    const ENO_ADDRESS_STORED: u64 = 0;
    const ERESOURCE_ALREADY_EXISTS: u64 = 1;
    const ERESOURCE_NOT_EXISTS: u64 = 2;
    const EINVALID_ORACLE_COUNT: u64 = 3;
    const EINVALID_STAKED_KEY_COUNT: u64 = 4;
    const EINVALID_REWARD_BALANCE: u64 = 5;
    const EORACLE_ALREADY_ADDED: u64 = 6;
    const EORACLE_NOT_REGISTERED: u64 = 7;
    const EMISMATCH_KEYS_AND_SIGNATURES: u64 = 9;
    const ESIGNATURE_VARIFICATION_FAILED: u64 = 10;
    const EORACLE_ALREADY_VERIFIED: u64 = 11;
    const ECALLER_NOT_ADMIN: u64 = 12;
    const EORACLE_NOT_VERIFIED: u64 = 13;
    const EORACLE_NOT_REMOVED: u64 = 14;
    const ELEADER_NODE_NOT_EXISTS: u64 = 15;
    const EREGISTER_ORACLE_NOT_EXISTS: u64 = 16;
    const ELEADER_ADDR_INCORRECT: u64 = 17;
    const EINCORRECT_VECTOR_LENGTH: u64 = 18;
    const EINSUFFICIENT_KEY_BALANCE: u64 = 19;
    const EKEY_DID_NOT_GET_TRANSFERRED: u64 = 20;
    const ENFT_NOT_EXISTS: u64 = 21;
    const EPLAYER_ID_NOT_VALID: u64 = 22;

    struct RegisteredOracles has key {
        oracle_addresses: vector<address>
    }

    struct PerformanceMetrics has store, copy {
        oracle_uptime: u64,
        pog_accuracy: u64
    }

    struct RewardResource has key {
        oracle_addr: address,
        staked_key: u64,
        performance_metrics: PerformanceMetrics,
        reward_balance: u64,
        oracle: Oracle
    }

    struct Oracle has store {
        verified: bool,
        has_poa_nft: bool
    }

    struct LeaderNode has key {
        leader_address: address
    }

    struct PublicKeyVector has key {
        oracle_public_keys: vector<vector<u8>>
    }

    fun init_module(owner: &signer) {
        let leader_node = LeaderNode { leader_address: @0x0 };
        move_to(owner, leader_node);

        let oracle_vector = vector::empty<address>();
        move_to(owner, RegisteredOracles { oracle_addresses: oracle_vector });

        // let public_key_vector: vector<vector<u8>> = vector::empty<vector<u8>>();
        // move_to(owner, AdminSigner { signer_keys: public_key_vector});
    }

    #[view]
    public fun get_oracle_reward_balance(oracle_addr: address): u64 acquires RewardResource {
        let oracle_reward_resource =
            borrow_global<RewardResource>(oracle_addr).reward_balance;
        oracle_reward_resource
    }

    #[view]
    public fun registered_oracle_count(): u64 acquires RegisteredOracles {
        let registered_oracles_vector: vector<address> =
            borrow_global<RegisteredOracles>(@KGen).oracle_addresses;
        let vector_length = vector::length(&registered_oracles_vector);
        vector_length
    }

    #[view]
    public fun is_oracle_already_added(oracle_node: address): bool acquires RegisteredOracles {
        let i = 0;

        let oracle_addresses_vector =
            borrow_global<RegisteredOracles>(@KGen).oracle_addresses;
        let addr_vector_length = vector::length(&oracle_addresses_vector);

        while (i < addr_vector_length) {

            let oracle_address = vector::borrow(&oracle_addresses_vector, i);

            if (*oracle_address == oracle_node) {
                return true
            };

            i = i + 1;
        };

        false
    }

    #[view]
    public fun is_reward_associated(oracle: address): bool {
        if (exists<RewardResource>(oracle)) {
            return true
        } else {
            return false
        }
    }

    #[view]
    public fun is_oracle_verified(oracle_addr: address): bool acquires RewardResource {
        assert!(exists<RewardResource>(oracle_addr), ERESOURCE_NOT_EXISTS);

        let oracle_resource = borrow_global<RewardResource>(oracle_addr);
        oracle_resource.oracle.verified
    }

    #[view]
    public fun list_registered_oracle(): vector<address> acquires RegisteredOracles {
        let oracle_addresses_vector =
            borrow_global<RegisteredOracles>(@KGen).oracle_addresses;
        oracle_addresses_vector
    }

    #[view]
    public fun get_leader_address(): address acquires LeaderNode {
        let leader_address = borrow_global<LeaderNode>(@KGen).leader_address;
        leader_address
    }

    #[view]
    public fun staked_key_amount(oracle_address: address): u64 acquires RewardResource {
        borrow_global<RewardResource>(oracle_address).staked_key
    }

    #[view]
    public fun get_metadata(): Object<Metadata> {
        let asset_address = object::create_object_address(&@KGen, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }

    public entry fun set_oracle_status(
        owner: &signer, oracle_addr: address, status: bool
    ) acquires RewardResource {
        assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);
        assert!(exists<RewardResource>(oracle_addr), ERESOURCE_NOT_EXISTS);

        let oracle_resource = borrow_global_mut<RewardResource>(oracle_addr);
        oracle_resource.oracle.verified = status;
    }

    public entry fun distribute_rewards(
        owner: &signer, base_reward: u64
    ) acquires RegisteredOracles, RewardResource {
        assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);

        let owner_address = signer::address_of(owner);

        let oracle_addresses_vector =
            borrow_global<RegisteredOracles>(owner_address).oracle_addresses;

        let addr_vector_length = vector::length(&oracle_addresses_vector);

        assert!(addr_vector_length > 0, ENO_ADDRESS_STORED);
        let i = 0;

        while (i < addr_vector_length) {

            let oracle_address = vector::borrow(&oracle_addresses_vector, i);
            assert!(exists<RewardResource>(*oracle_address), ERESOURCE_NOT_EXISTS);

            if (is_oracle_verified(*oracle_address)) {
                let reward_resource = borrow_global_mut<RewardResource>(*oracle_address);

                let performance_factor =
                    reward_resource.performance_metrics.oracle_uptime
                        * reward_resource.performance_metrics.pog_accuracy;

                let _reward_points =
                    base_reward * reward_resource.staked_key * performance_factor;

                rkGen_token::mint_rkGen_token(owner, *oracle_address, 100);
                reward_resource.reward_balance = reward_resource.reward_balance + 100;
            };

            i = i + 1;
        }
    }

    public entry fun associate_reward_resource(oracle_node: &signer) {
        assert!(
            !exists<RewardResource>(signer::address_of(oracle_node)),
            ERESOURCE_ALREADY_EXISTS
        );

        let reward_resource = RewardResource {
            oracle_addr: signer::address_of(oracle_node),
            staked_key: 0,
            performance_metrics: PerformanceMetrics { oracle_uptime: 0, pog_accuracy: 0 },
            reward_balance: 0,
            oracle: Oracle { verified: false, has_poa_nft: false }
        };

        move_to(oracle_node, reward_resource);
    }

    public entry fun update_performance_metrics(
        _owner: &signer,
        oracle_address: address,
        uptime: u64,
        accuracy: u64
    ) acquires RewardResource {
        assert!(signer::address_of(_owner) == @KGen, ECALLER_NOT_ADMIN);
        let reward_resource = borrow_global_mut<RewardResource>(oracle_address);

        reward_resource.performance_metrics.oracle_uptime = uptime;
        reward_resource.performance_metrics.pog_accuracy = accuracy;
    }

    public entry fun add_oracle_address(
        owner: &signer, oracle_addr: address, token_name: String
    ) acquires RegisteredOracles, RewardResource {
        assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);

        assert!(
            (exists<RewardResource>(oracle_addr)),
            ERESOURCE_NOT_EXISTS
        );
        assert!(!is_oracle_already_added(oracle_addr), EORACLE_ALREADY_ADDED);

        let oracle_resource = borrow_global_mut<RewardResource>(oracle_addr);
        assert!(!oracle_resource.oracle.verified, EORACLE_ALREADY_VERIFIED);

        let token_name = token_name;
        let token_description = string::utf8(b"KGen Token #1 Description");
        let token_uri = string::utf8(b"KGen Token #1 URI/");

        poa_nft::mint_poa_nft(
            owner,
            token_description,
            token_name,
            token_uri,
            oracle_addr
        );
        KGen::key_coin::mint_keys(owner, oracle_addr, 100);

        oracle_resource.oracle.has_poa_nft = true;
        oracle_resource.oracle.verified = true;

        let module_owner_addr = signer::address_of(owner);
        let oracle_vector = borrow_global_mut<RegisteredOracles>(module_owner_addr);
        vector::push_back<address>(&mut oracle_vector.oracle_addresses, oracle_addr);

    }

    public entry fun mint_nft(
        _owner: &signer, oracle_addrs: address, token_name: String
    ) acquires RewardResource {
        assert!(signer::address_of(_owner) == @KGen, ECALLER_NOT_ADMIN);

        assert!(exists<RewardResource>(oracle_addrs), ERESOURCE_NOT_EXISTS);

        let oracle_resource = borrow_global_mut<RewardResource>(oracle_addrs);

        // let token_name = string::utf8(b"KGen Token #1");
        let token_description = string::utf8(b"KGen Token #1 Description");
        let token_uri = string::utf8(b"KGen Token #1 URI/");

        poa_nft::mint_poa_nft(
            _owner,
            token_description,
            token_name,
            token_uri,
            oracle_addrs
        );

        oracle_resource.oracle.has_poa_nft = true;
        oracle_resource.oracle.verified = true;
    }

    public entry fun set_leader_node(
        owner: &signer, oracle_addrs: address
    ) acquires LeaderNode, RewardResource {
        assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);
        assert!(is_oracle_verified(oracle_addrs), EORACLE_NOT_VERIFIED);

        let _leader_node_addrs =
            borrow_global_mut<LeaderNode>(signer::address_of(owner)).leader_address;

        _leader_node_addrs = oracle_addrs;
    }

    public entry fun remove_oracle_address(
        owner: &signer, oracle_addrs: address
    ) acquires RegisteredOracles {
        assert!(is_oracle_already_added(oracle_addrs), EORACLE_NOT_REGISTERED);
        assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);

        // let oracle_resource = borrow_global_mut<RewardResource>(oracle_addrs);
        // assert!(!oracle_resource.oracle.verified, EORACLE_ALREADY_VERIFIED );

        let i = 0;
        let oracle_index = 0;

        let oracle_addresses_vector =
            borrow_global<RegisteredOracles>(signer::address_of(owner));
        let addr_vector_length = vector::length(&oracle_addresses_vector.oracle_addresses);

        while (i < addr_vector_length) {

            let oracle_address = vector::borrow(
                &oracle_addresses_vector.oracle_addresses, i
            );

            if (*oracle_address == oracle_addrs) {
                oracle_index = i;
                break
            };
            i = i + 1;
        };

        {
            let reg_oracle_vector =
                borrow_global_mut<RegisteredOracles>(signer::address_of(owner));
            vector::swap_remove<address>(
                &mut reg_oracle_vector.oracle_addresses, oracle_index
            );
        };

        assert!(!is_oracle_already_added(oracle_addrs), EORACLE_NOT_REMOVED);
    }

    public entry fun revoke_poa_nft(
        _owner: &signer, oracle_addrs: address, token_name: String
    ) acquires RewardResource {
        assert!(signer::address_of(_owner) == @KGen, ECALLER_NOT_ADMIN);
        assert!(exists<RewardResource>(oracle_addrs), ERESOURCE_NOT_EXISTS);
        // assert!( poa_nft::has_nft(oracle_addrs, token_name), ENFT_NOT_EXISTS);

        let oracle_resource = borrow_global_mut<RewardResource>(oracle_addrs);
        assert!(oracle_resource.oracle.verified, EORACLE_NOT_VERIFIED);

        // POANFT::revoke_nft(owner, oracle_addrs);
        poa_nft::burn(_owner, token_name);

        oracle_resource.oracle.has_poa_nft = false;
        oracle_resource.oracle.verified = false;
    }

    // test for the init module
    #[test(owner = @KGen, oralce1 = @0x1)]
    public fun test_init_module(owner: &signer) acquires LeaderNode, RegisteredOracles {
        init_module(owner);

        assert!(
            exists<LeaderNode>(signer::address_of(owner)),
            ELEADER_NODE_NOT_EXISTS
        );
        assert!(
            exists<RegisteredOracles>(signer::address_of(owner)),
            EREGISTER_ORACLE_NOT_EXISTS
        );
        // assert!(exists<oracle_management_contract::oracle_management::AdminSigner>(signer::address_of(owner)));

        let leader_node_addr =
            borrow_global<LeaderNode>(signer::address_of(owner)).leader_address;

        let oracle_vector =
            borrow_global<RegisteredOracles>(signer::address_of(owner)).oracle_addresses;

        assert!(leader_node_addr == @0x0, ELEADER_ADDR_INCORRECT);

        assert!(vector::length(&oracle_vector) == 0, EINCORRECT_VECTOR_LENGTH);
    }

    // test for add_oracle_address()
    #[test(owner = @KGen, oracle1 = @0x1)]
    // #[expected_failure(abort_code=ERESOURCE_NOT_Ekey_ownerXISTS)]
    #[expected_failure(abort_code = EORACLE_ALREADY_ADDED)]
    public fun test_add_oracle_address(
        owner: &signer, oracle1: &signer
    ) acquires RegisteredOracles, RewardResource {
        init_module(owner);
        KGen::key_coin::deploy_module(owner, 100);

        associate_reward_resource(oracle1);
        poa_nft::create_collection(owner);
        add_oracle_address(owner, signer::address_of(oracle1), string::utf8(b"oracle1"));
        add_oracle_address(owner, signer::address_of(oracle1), string::utf8(b"oracle2"));
    }

    //  test for remove_oracle_address()
    #[test(owner = @KGen, oracle1 = @0x1)]
    public fun test_remove_oracle_address(
        owner: &signer, oracle1: &signer
    ) acquires RegisteredOracles, RewardResource {
        init_module(owner);
        poa_nft::create_collection(owner);
        KGen::key_coin::deploy_module(owner, 100);

        associate_reward_resource(oracle1);
        add_oracle_address(owner, signer::address_of(oracle1), string::utf8(b"oracle1"));

        // associate_reward_resource(oracle2, 10);
        // add_oracle_address(owner, signer::address_of(oracle2));

        // associate_reward_resource(oracle3, 10);
        // add_oracle_address(owner, signer::address_of(oracle3));

        // associate_reward_resource(oracle4, 10);
        // add_oracle_address(owner, signer::address_of(oracle4));

        // associate_reward_resource(oracle5, 10);
        // add_oracle_address(owner, signer::address_of(oracle5));

        let registered_oracles_vector: vector<address> =
            borrow_global<RegisteredOracles>(signer::address_of(owner)).oracle_addresses;
        let vector_length = vector::length(&registered_oracles_vector);

        assert!((vector_length == 1), 0);

        remove_oracle_address(owner, signer::address_of(oracle1));

        registered_oracles_vector = borrow_global<RegisteredOracles>(
            signer::address_of(owner)
        ).oracle_addresses;
        vector_length = vector::length(&registered_oracles_vector);

        assert!((vector_length == 0), 0);
    }

    // test is_oracle_verified()
    #[test(owner = @KGen, oracle1 = @0x1)]
    // #[expected_failure(abort_code=EORACLE_ALREADY_VERIFIED)]
    public fun test_is_oracle_verified(owner: &signer, oracle1: &signer) acquires RewardResource {
        init_module(owner);
        poa_nft::create_collection(owner);
        associate_reward_resource(oracle1);

        assert!(
            !is_oracle_verified(signer::address_of(oracle1)),
            EORACLE_ALREADY_VERIFIED
        );
        mint_nft(owner, signer::address_of(oracle1), string::utf8(b"oracle1"));
        assert!(is_oracle_verified(signer::address_of(oracle1)), EORACLE_NOT_VERIFIED);
        // mint_nft(owner, signer::address_of(oracle1));

    }

    // test for revoke_poa_nft()
    #[test(owner = @KGen, oracle1 = @0x1)]
    // #[expected_failure(abort_code=)]
    public fun test_revoke_poa_nft(owner: &signer, oracle1: &signer) acquires RewardResource {
        init_module(owner);
        poa_nft::create_collection(owner);
        associate_reward_resource(oracle1);

        assert!(
            !is_oracle_verified(signer::address_of(oracle1)),
            EORACLE_ALREADY_VERIFIED
        );
        mint_nft(owner, signer::address_of(oracle1), string::utf8(b"oracle1"));
        assert!(is_oracle_verified(signer::address_of(oracle1)), EORACLE_NOT_VERIFIED);

        // assert!(poa_nft::has_nft(signer::address_of(oracle1), string::utf8(b"oracle1")), ENFT_NOT_EXISTS);

        revoke_poa_nft(owner, signer::address_of(oracle1), string::utf8(b"oracle1"));
        assert!(
            !is_oracle_verified(signer::address_of(oracle1)),
            EORACLE_ALREADY_VERIFIED
        );
    }

    // test list_registered_oracle(owner)
    #[test(owner = @KGen, oracle1 = @0x1)]
    public fun test_list_registered_oracle(
        owner: &signer, oracle1: &signer
    ) acquires RegisteredOracles, RewardResource {
        init_module(owner);
        poa_nft::create_collection(owner);
        KGen::key_coin::deploy_module(owner, 100);

        associate_reward_resource(oracle1);
        add_oracle_address(owner, signer::address_of(oracle1), string::utf8(b"oracle1"));

        // associate_reward_resource(oracle2, 10);
        // add_oracle_address(owner, signer::address_of(oracle2));

        std::debug::print(&list_registered_oracle());
    }

    // test is_reward_associated(oracle_addr)
    #[test(oracle = @0x1)]
    public fun test_is_reward_associated(oracle: address) {
        std::debug::print(&is_reward_associated(oracle));
    }

    #[test(owner = @KGen, oracle1 = @0x1)]
    public fun test_get_leader_address(owner: &signer) acquires LeaderNode {
        init_module(owner);
        std::debug::print(&get_leader_address());
    }

    #[test(owner = @KGen, oracle1 = @0x1)]
    public fun test_get_oracle_reward_balance(
        owner: &signer, oracle1: &signer
    ) acquires RewardResource {
        init_module(owner);

        associate_reward_resource(oracle1);

        std::debug::print(&get_oracle_reward_balance(signer::address_of(oracle1)));
    }

    #[test(
        owner = @KGen, oracle1 = @0x1, oracle2 = @0x2, oracle3 = @0x3, leader_node = @0x111
    )]
    public fun test_end_to_end(
        owner: &signer,
        oracle1: &signer,
        leader_node: &signer,
        oracle3: &signer,
        oracle2: &signer
    ) acquires RegisteredOracles, RewardResource, LeaderNode {
        init_module(owner);
        poa_nft::create_collection(owner);
        KGen::key_coin::deploy_module(owner, 100);
        KGen::PoG_Consensus::test_init_module(owner);
        KGen::rkGen_token::pseudo_init(owner);

        std::debug::print(&exists<PublicKeyVector>(@KGen));
        // std::debug::print(&PoG_Consensus_01::public_key_index());

        assert!(registered_oracle_count() == 0, 1001);

        associate_reward_resource(oracle1);
        add_oracle_address(owner, signer::address_of(oracle1), string::utf8(b"oracle1"));
        assert!(
            KGen::key_coin::key_count(signer::address_of(oracle1)) == 100,
            EINVALID_STAKED_KEY_COUNT
        );
        std::debug::print(&string::utf8(b"Token:"));
        std::debug::print(&poa_nft::view_token(string::utf8(b"oracle1")));

        associate_reward_resource(oracle2);
        add_oracle_address(owner, signer::address_of(oracle2), string::utf8(b"oracle2"));
        assert!(
            KGen::key_coin::key_count(signer::address_of(oracle2)) == 100,
            EINVALID_STAKED_KEY_COUNT
        );

        associate_reward_resource(oracle3);
        add_oracle_address(owner, signer::address_of(oracle3), string::utf8(b"oracle3"));
        assert!(
            KGen::key_coin::key_count(signer::address_of(oracle3)) == 100,
            EINVALID_STAKED_KEY_COUNT
        );

        assert!(registered_oracle_count() == 3, 1001);

        associate_reward_resource(leader_node);
        mint_nft(owner, signer::address_of(leader_node), string::utf8(b"leader node"));
        set_leader_node(owner, signer::address_of(leader_node));

        let player_id: vector<u64> = vector<u64>[1, 2, 3];
        let ranks: vector<u64> = vector<u64>[23, 45, 55];
        let scores: vector<u64> = vector<u64>[100, 23, 355];
        KGen::PoG_Consensus::test_submit_score(owner, player_id, ranks, scores);

        // std::debug::print(&string::utf8(b"indx"));
        // std::debug::print(&PoG_Consensus_01::view_player_index(1));

        assert!(KGen::PoG_Consensus::view_player_index(1) == 0, EPLAYER_ID_NOT_VALID);
        assert!(KGen::PoG_Consensus::view_player_index(2) == 1, EPLAYER_ID_NOT_VALID);
        assert!(KGen::PoG_Consensus::fetch_player_score(0) == 100, EPLAYER_ID_NOT_VALID);

        // remove_oracle_address(owner, signer::address_of(oracle2));

        std::debug::print(&list_registered_oracle());
        std::debug::print(&get_oracle_reward_balance(@0x1));
        std::debug::print(&get_oracle_reward_balance(@0x2));
        std::debug::print(&get_oracle_reward_balance(@0x3));

        distribute_rewards(owner, 10);

        std::debug::print(&get_oracle_reward_balance(@0x1));
        std::debug::print(&get_oracle_reward_balance(@0x2));
        std::debug::print(&get_oracle_reward_balance(@0x3));

        std::debug::print(&std::string::utf8(b"Oracle status:"));
        std::debug::print(&is_oracle_verified(@0x2));

        set_oracle_status(owner, @0x2, false);
        distribute_rewards(owner, 10);

        std::debug::print(&is_oracle_verified(@0x2));

        std::debug::print(&get_oracle_reward_balance(@0x1));
        std::debug::print(&get_oracle_reward_balance(@0x2));
        std::debug::print(&get_oracle_reward_balance(@0x3));

        set_oracle_status(owner, @0x2, true);
        distribute_rewards(owner, 10);

        std::debug::print(&get_oracle_reward_balance(@0x1));
        std::debug::print(&get_oracle_reward_balance(@0x2));
        std::debug::print(&get_oracle_reward_balance(@0x3));

    }
}

// public entry fun stak_key(owner: &signer, key_owner: &signer, oracle_address: address, amount: u64) acquires RewardResource {
//     let staked_key = borrow_global_mut<RewardResource>(oracle_address).staked_key;

//     let asset = get_metadata();
//     let initial_owner_key_balance = primary_fungible_store::balance(signer::address_of(key_owner), asset);
//     let oracle_key_balance = primary_fungible_store::balance(oracle_address, asset);

//     assert!(initial_owner_key_balance >= amount, EINSUFFICIENT_KEY_BALANCE);
//     KGen::key_coin::transfer(owner, signer::address_of(key_owner), oracle_address, amount);

//     assert!(primary_fungible_store::balance(signer::address_of(key_owner), asset) == initial_owner_key_balance - amount, EKEY_DID_NOT_GET_TRANSFERRED);
//     assert!(primary_fungible_store::balance(oracle_address, asset) == oracle_key_balance + amount, EKEY_DID_NOT_GET_TRANSFERRED);

//     staked_key = staked_key + amount;

//     // return staked_key
// }

// {
//     assert!(staked_key_amount(signer::address_of(oracle1)) == 0, 1002);
//     let asset = KGen::key_coin::get_metadata();
//     KGen::key_coin::purchase_keys_apt(owner, key_owner, 100);
//     std::debug::print(&string::utf8(b"Key Owner Amount: "));
//     std::debug::print(& aptos_framework::primary_fungible_store::balance(signer::address_of(key_owner), asset));
//     assert!(staked_key_amount(signer::address_of(oracle1)) == 0, EINVALID_STAKED_KEY_COUNT);
//     stak_key(owner, key_owner, signer::address_of(oracle1), 50);
//     assert!(staked_key_amount(signer::address_of(oracle1)) == 50, EINVALID_STAKED_KEY_COUNT);
//     assert!(primary_fungible_store::balance(signer::address_of(key_owner), asset) == 50, EKEY_DID_NOT_GET_TRANSFERRED);
//     assert!(primary_fungible_store::balance(signer::address_of(oracle1), asset) == 50, EKEY_DID_NOT_GET_TRANSFERRED);
// }
