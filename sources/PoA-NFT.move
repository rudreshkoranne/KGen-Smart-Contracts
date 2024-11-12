module KGen::poa_nft {
    use std::error;
    use std::option;
    use std::string::{Self, String};
    use std::signer;

    use aptos_framework::object::{Self, Object};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_token_objects::property_map;

    const ETOKEN_DOES_NOT_EXIST: u64 = 1;
    const ENOT_CREATOR: u64 = 2;

    /// The ambassador token collection name
    const COLLECTION_NAME: vector<u8> = b"KGen NFT Collection";
    /// The ambassador token collection description
    const COLLECTION_DESCRIPTION: vector<u8> = b"KGen NFT Description";
    /// The ambassador token collection URI
    const COLLECTION_URI: vector<u8> = b"KGen Collection URI";

    // The KGen token used to mutate the token uri used to burn. used to mutate properties the base URI of the token
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct KGenToken has key {
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
        property_mutator_ref: property_map::MutatorRef,
        base_uri: String
    }

    #[view]
    public fun view_token(token_name: String): Object<KGenToken> {
        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address =
            token::create_token_address(&@KGen, &collection_name, &token_name);
        let token = object::address_to_object<KGenToken>(token_address);

        token
    }

    #[view]
    public fun view_token_owner_address(token_name: String): address {
        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address =
            token::create_token_address(&@KGen, &collection_name, &token_name);
        let token = object::address_to_object<KGenToken>(token_address);

        object::owner(token)
    }

    #[view]
    public fun has_nft(owner: address, token_name: String): bool {
        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address =
            token::create_token_address(&owner, &collection_name, &token_name);

        let token = object::address_to_object<KGenToken>(token_address);
        let token_addr = object::object_address(&token);
        exists<KGenToken>(token_addr)
    }

    fun init_module(sender: &signer) {
        create_collection(sender);
    }

    public fun create_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(COLLECTION_DESCRIPTION);
        let name = string::utf8(COLLECTION_NAME);
        let uri = string::utf8(COLLECTION_URI);

        // Creates the collection with unlimited supply and without establishing any royalty configuration.
        collection::create_unlimited_collection(
            creator,
            description,
            name,
            option::none(),
            uri
        );
    }

    public entry fun mint_poa_nft(
        creator: &signer,
        description: String,
        name: String,
        base_uri: String,
        soul_bound_to: address
    ) {
        mint_poa_nft_impl(
            creator,
            description,
            name,
            base_uri,
            soul_bound_to,
            false
        );
    }

    public entry fun mint_numbered_poa_nft(
        creator: &signer,
        description: String,
        name: String,
        base_uri: String,
        soul_bound_to: address
    ) {
        mint_poa_nft_impl(
            creator,
            description,
            name,
            base_uri,
            soul_bound_to,
            true
        );
    }

    fun mint_poa_nft_impl(
        creator: &signer,
        description: String,
        name: String,
        base_uri: String,
        soul_bound_to: address,
        numbered: bool
    ) {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(COLLECTION_NAME);
        // Creates the ambassador token, and get the constructor ref of the token. The constructor ref
        // is used to generate the refs of the token.
        let uri = base_uri;
        string::append(&mut uri, string::utf8(b"RANK_BRONZE"));
        let constructor_ref =
            if (numbered) {
                token::create_numbered_token(
                    creator,
                    collection,
                    description,
                    name,
                    string::utf8(b""),
                    option::none(),
                    uri
                )
            } else {
                token::create_named_token(
                    creator,
                    collection,
                    description,
                    name,
                    option::none(),
                    uri
                )
            };

        // Generates the object signer and the refs. The object signer is used to publish a resource
        // (e.g., AmbassadorLevel) under the token object address. The refs are used to manage the token.
        let object_signer = object::generate_signer(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Transfers the token to the `soul_bound_to` address
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, soul_bound_to);

        // Disables ungated transfer, thus making the token soulbound and non-transferable
        object::disable_ungated_transfer(&transfer_ref);

        // Initializes the ambassador level as 0

        // Initialize the property map and the ambassador rank as Bronze
        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"Rank"),
            string::utf8(b"RANK_BRONZE")
        );

        // Publishes the AmbassadorToken resource with the refs.
        let poa_nft_token = KGenToken {
            mutator_ref,
            burn_ref,
            property_mutator_ref,
            base_uri
        };
        move_to(&object_signer, poa_nft_token);
    }

    public entry fun burn(creator: &signer, token_name: String) acquires KGenToken {

        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address =
            token::create_token_address(&@KGen, &collection_name, &token_name);
        let token = object::address_to_object<KGenToken>(token_address);

        authorize_creator(creator, &token);
        let poa_nft_token = move_from<KGenToken>(object::object_address(&token));
        let KGenToken { mutator_ref: _, burn_ref, property_mutator_ref, base_uri: _ } =
            poa_nft_token;

        property_map::burn(property_mutator_ref);
        token::burn(burn_ref);
    }

    inline fun authorize_creator<T: key>(
        creator: &signer, token: &Object<T>
    ) {
        let token_address = object::object_address(token);
        assert!(
            exists<T>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST)
        );
        assert!(
            token::creator(*token) == signer::address_of(creator),
            error::permission_denied(ENOT_CREATOR)
        );
    }

    #[test(owner = @KGen, oracle1 = @0x1)]
    fun test_mint_burn_poa_nft(owner: &signer, oracle1: &signer) acquires KGenToken {
        create_collection(owner);

        let token_name = string::utf8(b"KGen Token #1");
        let token_description = string::utf8(b"KGen Token #1 Description");
        let token_uri = string::utf8(b"KGen Token #1 URI/");
        let user1_addr = signer::address_of(oracle1);
        // Creates the Ambassador token for User1.
        mint_poa_nft(
            owner,
            token_description,
            token_name,
            token_uri,
            user1_addr
        );
        let collection_name = string::utf8(COLLECTION_NAME);
        let token_address =
            token::create_token_address(
                &signer::address_of(owner),
                &collection_name,
                &token_name
            );
        let token = object::address_to_object<KGenToken>(token_address);
        // Asserts that the owner of the token is User1.
        assert!(object::owner(token) == user1_addr, 1);

        // Creator burns the token.
        let token_addr = object::object_address(&token);
        std::debug::print(&view_token(token_name));
        // Asserts that the token exists before burning.
        assert!(exists<KGenToken>(token_addr), 6);
        // Burns the token.
        burn(owner, token_name);
        // Asserts that the token does not exist after burning.
        assert!(!exists<KGenToken>(token_addr), 7);
    }
}
