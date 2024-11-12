module KGen::PoG_Consensus {

    use std::vector;
    use std::signer;
    use std::ed25519;

    // use KGen::oracle_management;

    const ECALLER_NOT_ADMIN: u64 = 1;
    const ECALLER_NOT_LEADER: u64 = 2;
    const EPLAYER_VECTOR_EMPTY: u64 = 3;
    const EPLAYER_ID_NOT_VALID: u64 = 4;
    const EINVALID_SIGNATURES: u64 = 5;
    const EINVALID_VECTOR_LENGTH: u64 = 6;
    const ETHRESHOLD_NOT_MET: u64 = 7;
    const EINVALID_SIGNATURE: u64 = 1001;
    const EPUB_KEY_NOT_PRESENT: u64 = 8;
    const EPUB_KEY_NOT_REMOVED: u64 = 9;
    const EINVALID_PLAYER_SCORE: u64 = 10;
    const EPUBLIC_KEY_ALREADY_ADDED: u64 = 11;
    const EPUB_KEY_VECTOR_NOT_PRESENT: u64 = 12;

    struct PublicKeyVector has key {
        oracle_public_keys: vector<vector<u8>>
    }

    struct PlayerScore has store, copy, drop {
        player_id: u64,
        rank: u64,
        score: u64
    }

    struct PlayerArray has key, drop {
        players_array: vector<PlayerScore>
    }

    fun init_module(owner: &signer) {
        test1(owner);
        test2(owner);
    }

    fun test1(owner: &signer) {
        let oracle_keys = vector::empty<vector<u8>>();
        move_to(owner, PublicKeyVector { oracle_public_keys: oracle_keys });
    }

    fun test2(owner: &signer) {
        let players_array = vector::empty<PlayerScore>();
        move_to(owner, PlayerArray { players_array: players_array });

    }

    public fun test_init_module(owner: &signer) {
        let players_array = vector::empty<PlayerScore>();
        move_to(owner, PlayerArray { players_array: players_array });
    }

    #[view]
    public fun public_key_index(): u64 acquires PublicKeyVector {
        let players_vector = borrow_global_mut<PublicKeyVector>(@KGen);

        vector::length(&players_vector.oracle_public_keys)
    }

    #[view]
    public fun view_player_index(player_id: u64): u64 acquires PlayerArray {

        let players_array = borrow_global<PlayerArray>(@KGen).players_array;
        // if ( vector::length(&players_array) == 0 ) {
        //     return false
        // };
        let vector_length = vector::length(&players_array);

        let i = 0;

        while (i <= vector_length) {
            let player_score = vector::borrow(&players_array, i);
            if (player_score.player_id == player_id) {
                return i
            };

            i = i + 1;
        };

        assert!(1 == 0, EPLAYER_ID_NOT_VALID);
        0

    }

    #[view]
    public fun fetch_player_score(index: u64): u64 acquires PlayerArray {
        let players_array = borrow_global<PlayerArray>(@KGen).players_array;
        let player_score = vector::borrow(&players_array, index);
        player_score.score
    }

    #[view]
    public fun fetch_player_rank(index: u64): u64 acquires PlayerArray {
        let players_array = borrow_global<PlayerArray>(@KGen).players_array;
        let player_score = vector::borrow(&players_array, index);
        player_score.rank

    }

    #[view]
    public fun is_player_exists(player_id: u64): bool acquires PlayerArray {
        let players_array = borrow_global<PlayerArray>(@KGen).players_array;

        // assert!(vector::length(&players_array) >=1, EPLAYER_VECTOR_EMPTY);
        if (vector::length(&players_array) == 0) {
            return false
        };

        let vector_length = vector::length(&players_array);

        let i = 0;

        while (i < vector_length) {
            let player_score = vector::borrow(&players_array, i);
            if (player_score.player_id == player_id) {
                return true
            };

            i = i + 1;
        };

        false
    }

    #[view]
    public fun is_pub_key_present(input_pub_key: vector<u8>): bool acquires PublicKeyVector {
        assert!(exists<PublicKeyVector>(@KGen), EPUB_KEY_VECTOR_NOT_PRESENT);
        let pub_key_vector = borrow_global<PublicKeyVector>(@KGen).oracle_public_keys;
        let vector_length = vector::length(&pub_key_vector);

        let i = 0;

        while (i < vector_length) {
            let pub_key = vector::borrow(&pub_key_vector, i);
            if (*pub_key == input_pub_key) {
                return true
            };

            i = i + 1;
        };

        false
    }

    #[view]
    public fun check_threshold(signatures: vector<vector<u8>>): bool acquires PublicKeyVector {
        let pub_key_vector = borrow_global<PublicKeyVector>(@KGen);
        let pub_key_length = vector::length(&pub_key_vector.oracle_public_keys);

        let sign_vector_length = vector::length(&signatures);

        pub_key_length * 67 <= sign_vector_length * 100
    }

    #[view]
    public fun pub_vectro_size(): u64 acquires PublicKeyVector {
        let pub_key_vector = borrow_global<PublicKeyVector>(@KGen).oracle_public_keys;
        vector::length(&pub_key_vector)
    }

    #[view]
    public fun verify_signature(
        message_hash: vector<u8>, signature: vector<u8>, pub_key: vector<u8>
    ): bool {

        // Convert signature bytes to Ed25519 signature
        let signature_ed = ed25519::new_signature_from_bytes(signature);

        // Convert public key bytes to Ed25519 public key
        let public_key_ed = ed25519::new_unvalidated_public_key_from_bytes(pub_key);

        // Verify the signature using the message hash
        let is_valid =
            ed25519::signature_verify_strict(&signature_ed, &public_key_ed, message_hash);

        is_valid
    }

    fun update_and_store_scores(
        player_id: u64, player_rank: u64, player_score: u64
    ) acquires PlayerArray {
        if (is_player_exists(player_id)) {
            let player_index = view_player_index(player_id);
            let players_vector = borrow_global_mut<PlayerArray>(@KGen);
            let player = vector::borrow_mut<PlayerScore>(
                &mut players_vector.players_array, player_index
            );
            player.rank = player_rank;
            player.score = player_score;
        } else {
            let player_score_obj = PlayerScore {
                player_id: player_id,
                rank: player_rank,
                score: player_score
            };
            let players_vector = borrow_global_mut<PlayerArray>(@KGen);
            vector::push_back<PlayerScore>(
                &mut players_vector.players_array, player_score_obj
            );
        };
    }

    public entry fun submit_score(
        _caller: &signer,
        message_hash: vector<u8>,
        signature_vector: vector<vector<u8>>,
        pub_key_vector: vector<vector<u8>>,
        player_id: vector<u64>,
        ranks: vector<u64>,
        scores: vector<u64>
    ) acquires PublicKeyVector, PlayerArray {

        assert!(signer::address_of(_caller) == KGen::oracle_management::get_leader_address(), ECALLER_NOT_LEADER);
        assert!(
            vector::length(&player_id) == vector::length(&ranks),
            EINVALID_VECTOR_LENGTH
        );
        assert!(
            vector::length(&player_id) == vector::length(&scores),
            EINVALID_VECTOR_LENGTH
        );
        assert!(
            vector::length(&signature_vector) == vector::length(&pub_key_vector),
            EINVALID_VECTOR_LENGTH
        );
        assert!(check_threshold(signature_vector), ETHRESHOLD_NOT_MET);

        let x = 0;

        while (x < vector::length(&signature_vector)) {
            let pub_key = vector::borrow(&pub_key_vector, x);
            let signature = vector::borrow(&signature_vector, x);

            assert!(is_pub_key_present(*pub_key), EPUB_KEY_NOT_PRESENT);
            assert!(
                verify_signature(message_hash, *signature, *pub_key),
                EINVALID_SIGNATURES
            );

            x = x + 1;
        };

        let i = 0;

        while (i < vector::length(&player_id)) {
            let player_id = vector::borrow(&player_id, i);
            let player_rank = vector::borrow(&ranks, i);
            let player_score = vector::borrow(&scores, i);
            update_and_store_scores(*player_id, *player_rank, *player_score);

            i = i + 1;
        };
    }

    public entry fun test_submit_score(
        _caller: &signer,
        player_id: vector<u64>,
        ranks: vector<u64>,
        scores: vector<u64>
    ) acquires PlayerArray {
        let i = 0;
        while (i < vector::length(&player_id)) {
            let player_id = vector::borrow(&player_id, i);
            let player_rank = vector::borrow(&ranks, i);
            let player_score = vector::borrow(&scores, i);
            update_and_store_scores(*player_id, *player_rank, *player_score);

            i = i + 1;
        };
    }

    public entry fun add_oracle_public_key(
        owner: &signer, public_key: vector<u8>
    ) acquires PublicKeyVector {
        assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);
        assert!(!is_pub_key_present(public_key), EPUBLIC_KEY_ALREADY_ADDED);

        if (!exists<PublicKeyVector>(@KGen)) {
            let oracle_keys = vector::empty<vector<u8>>();
            move_to(owner, PublicKeyVector { oracle_public_keys: oracle_keys });
        };

        let players_vector =
            borrow_global_mut<PublicKeyVector>(signer::address_of(owner));

        vector::push_back<vector<u8>>(
            &mut players_vector.oracle_public_keys, public_key
        );
    }

    public entry fun remove_oracle_public_key(
        owner: &signer, public_key: vector<u8>
    ) acquires PublicKeyVector {
        assert!(signer::address_of(owner) == @KGen, ECALLER_NOT_ADMIN);
        assert!(is_pub_key_present(public_key), EPUB_KEY_NOT_PRESENT);

        let i = 0;
        let pub_key_vector = borrow_global<PublicKeyVector>(@KGen).oracle_public_keys;
        let vector_length = vector::length(&pub_key_vector);

        while (i <= vector_length) {
            let pub_key = vector::borrow(&pub_key_vector, i);
            if (*pub_key == public_key) {
                {
                    let pub_key = borrow_global_mut<PublicKeyVector>(@KGen);
                    vector::swap_remove<vector<u8>>(&mut pub_key.oracle_public_keys, i);
                };
                break
            };
            i = i + 1;
        };

        assert!(!is_pub_key_present(public_key), EPUB_KEY_NOT_REMOVED);
    }

    #[test(owner = @KGen)]
    public fun test_test_submit_score(owner: &signer) acquires PlayerArray {
        init_module(owner);

        let player_id: vector<u64> = vector<u64>[1, 2, 3];
        let ranks: vector<u64> = vector<u64>[23, 45, 55];
        let scores: vector<u64> = vector<u64>[100, 23, 355];
        test_submit_score(owner, player_id, ranks, scores);

        assert!(fetch_player_score(0) == 100, EINVALID_PLAYER_SCORE);
        assert!(fetch_player_score(1) == 23, EINVALID_PLAYER_SCORE);
        assert!(fetch_player_score(2) == 355, EINVALID_PLAYER_SCORE);

        let player_id2: vector<u64> = vector<u64>[1, 2, 3];
        let ranks2: vector<u64> = vector<u64>[23, 45, 55];
        let scores2: vector<u64> = vector<u64>[300, 200, 100];
        test_submit_score(owner, player_id2, ranks2, scores2);

        let players_array = borrow_global<PlayerArray>(@KGen).players_array;
        let vector_length = vector::length(&players_array);

        assert!(vector_length == 3, EINVALID_VECTOR_LENGTH);

        std::debug::print(&std::string::utf8(b"Player score after updation:"));
        std::debug::print(&fetch_player_score(0));
        std::debug::print(&fetch_player_score(1));
        std::debug::print(&fetch_player_score(2));

        // assert!(fetch_player_score(2) == 100, EINVALID_PLAYER_SCORE);

    }
}

// public fun verify_signatures(message_hash: vector<u8>, signatures: vector<vector<u8>>, ): bool acquires PublicKeyVector {

//     // Get the stored oracle's public keys
//     let pub_key_vector = borrow_global<PublicKeyVector>(@KGen);
//     let oracle_public_keys = pub_key_vector.oracle_public_keys;

//     // Check if the number of public keys matches the number of signatures
//     let num_keys = vector::length(&oracle_public_keys);
//     let num_signatures = vector::length(&signatures);

//     if (num_keys != num_signatures) {
//         return false // Mismatch between number of keys and signatures
//     };

//     // Loop through all signatures and public keys to verify each one
//     let x = 0;
//     while (x < num_keys) {
//         let signature = vector::borrow(&signatures, x);
//         let public_key = vector::borrow(&oracle_public_keys, x);

//         // Convert signature bytes to Ed25519 signature
//         let signature_ed = ed25519::new_signature_from_bytes(*signature);

//         // Convert public key bytes to Ed25519 public key
//         let public_key_ed = ed25519::new_unvalidated_public_key_from_bytes(*public_key);

//         // Verify the signature using the message hash
//         let is_valid = ed25519::signature_verify_strict(&signature_ed, &public_key_ed, message_hash);

//         // If any signature is invalid, return false
//         if (!is_valid) {
//             return false
//         };

//         x = x + 1;
//     };

//     // If all signatures are valid, return true
//     return true
// }
