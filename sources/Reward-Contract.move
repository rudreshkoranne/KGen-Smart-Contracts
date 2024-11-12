module KGen::reward_contract {

    use KGen::oracle_management;
    // Address Vector has no Address

    const ENO_ADDRESS_STORED: u64 = 0;
    const ERESOURCE_ALREADY_EXISTS: u64 = 1;

    const ERESOURCE_NOT_EXISTS: u64 = 2;
    const EINVALID_ORACLE_COUNT: u64 = 3;
    const EINVALID_STAKED_KEY_COUNT: u64 = 4;
    const EINVALID_REWARD_BALANCE: u64 = 5;
    const EORACLE_ALREADY_ADDED: u64 = 6;
    const EORACLE_NOT_REGISTERED: u64 = 7;
    const ECALLER_NOT_ADMIN: u64 = 8;

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

    #[view]
    public fun get_oracle_reward_balance(oracle_addr: address): u64 {
        oracle_management::get_oracle_reward_balance(oracle_addr)
    }

    public entry fun distribute_rewards(owner: &signer, base_reward: u64) {
        oracle_management::distribute_rewards(owner, base_reward);
    }

    public entry fun update_performance_metrics(
        _owner: &signer,
        oracle_address: address,
        uptime: u64,
        accuracy: u64
    ) {
        oracle_management::update_performance_metrics(
            _owner, oracle_address, uptime, accuracy
        );
    }
}

// public entry fun distribute_rewards(owner: &signer, base_reward: u64) acquires RegisteredOracles, RewardResource {

//     assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);

//     let owner_address = signer::address_of(owner);

//     let oracle_addresses_vector = borrow_global<RegisteredOracles>(owner_address).oracle_addresses;

//     let addr_vector_length = vector::length(&oracle_addresses_vector);

//     assert!(addr_vector_length > 0, ENO_ADDRESS_STORED);
//     let i = 0;

//     while ( i < addr_vector_length ) {

//     let oracle_address = vector::borrow(&oracle_addresses_vector, i);
//     assert!(exists<RewardResource>(*oracle_address), ERESOURCE_NOT_EXISTS);

//     let reward_resource = borrow_global_mut<RewardResource>(*oracle_address);

//     let performance_factor = reward_resource.performance_metrics.oracle_uptime * reward_resource.performance_metrics.pog_accuracy;

//     let reward_points = base_reward * reward_resource.staked_key * performance_factor;

//     // @KGen::rKGeN_Token_Contract::mint_to(owner, oracle_address, reward_points);
//     reward_resource.reward_balance = reward_resource.reward_balance + reward_points;

//     i = i + 1;
//     }
// }

// // Test fn(x) fot update_performance_metrics()
// #[test(owner=@KGen, oracle1=@0x1, oracle2=@0x2)]
// #[expected_failure]
// public fun test_update_performance_metrics(owner: &signer, oracle1: &signer, oracle2: &signer) acquires RewardResource, RegisteredOracles {
//     init_module(owner);

//     associate_reward_resource(oracle1, 100);
//     add_oracle_address(owner, @0x1);

//     update_performance_metrics(owner, signer::address_of(oracle1), 50, 90);

//     let reward_resource = borrow_global<RewardResource>(signer::address_of(oracle1));
//     assert!(reward_resource.performance_metrics.oracle_uptime == 50, 1);
//     assert!(reward_resource.performance_metrics.pog_accuracy == 90, 2);

//     update_performance_metrics(owner, signer::address_of(oracle1), 70, 30);

//     reward_resource = borrow_global<RewardResource>(signer::address_of(oracle1));
//     assert!(reward_resource.performance_metrics.oracle_uptime == 70, 1);
//     assert!(reward_resource.performance_metrics.pog_accuracy == 30, 2);

//     update_performance_metrics(owner, signer::address_of(oracle2), 60, 85);
// }

// // Test for the distribute_rewards() fn(x)
// #[test(owner=@KGen, oracle1=@0x1, oracle2=@0x2)]
// public fun test_distribute_rewards(owner: &signer, oracle1: &signer, oracle2: &signer) acquires RegisteredOracles, RewardResource {

//     init_module(owner);

//     associate_reward_resource(oracle1, 100);
//     add_oracle_address(owner, @0x1);

//     associate_reward_resource(oracle2, 100);
//     add_oracle_address(owner, @0x2);

//     let oracle_count = registered_oracle_count(signer::address_of(owner));
//     assert!(oracle_count == 2, EINVALID_ORACLE_COUNT);

//     update_performance_metrics(owner, signer::address_of(oracle1), 50, 90);
//     update_performance_metrics(owner, signer::address_of(oracle2), 50, 90);

//     distribute_rewards(owner, 1000);

//     let reward_resource1 = borrow_global<RewardResource>(signer::address_of(oracle1));
//     let reward_resource2 = borrow_global<RewardResource>(signer::address_of(oracle2));

//     // std::debug::print(&reward_resource1.reward_balance);
//     // std::debug::print(&reward_resource2.reward_balance);

//     assert!(reward_resource1.reward_balance > 0, 8);
// assert!(reward_resource2.reward_balance > 0, 8);
// }
 