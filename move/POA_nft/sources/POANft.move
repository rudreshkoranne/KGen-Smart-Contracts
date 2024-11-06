module POANft_add::POANft{

   use std ::error;
   use std::option;
   use std::signer;
   use aptos_framework::object::{Self,Object};
   use std::string::{Self, String};
   use std::vector;
   use aptos_token::token;
   use aptos_token::token::TokenDataId;


   // This struct stores an POANFT collection's relevant information
    struct ModuleData has key {
        token_data_id: TokenDataId,
    }
   
    /// Action not authorized because the signer is not the admin of this module
    const ENOT_AUTHORIZED: u64 = 1;
    /// The provided signer is not the creator
    const ENOT_CREATOR: u64 = 2;
    /// Attempted to mutate an immutable field
    const EFIELD_NOT_MUTABLE: u64 = 3;
    /// Attempted to burn a non-burnable token
    const ETOKEN_NOT_BURNABLE: u64 = 4;
    /// Attempted to mutate a property map that is not mutable
    const EPROPERTIES_NOT_MUTABLE: u64 = 5;
    // The collection does not exist
    const ECOLLECTION_DOES_NOT_EXIST: u64 = 6;


     /// The ambassador token collection name
    const COLLECTION_NAME: vector<u8> = b"POANft Collection";
    /// The ambassador token collection description
    const COLLECTION_DESCRIPTION: vector<u8> = b"POANft Collection Description";
    /// The ambassador token collection URI
    const COLLECTION_URI: vector<u8> = b"POANft Collection URI";

    const TOKEN_URI: vector<u8> = b"POANft Token URI";

    const TOKEN_NAME: vector<u8> = b"POAToken";


 
  /// Initializes the module, creating the ambassador collection. The creator of the module is the creator of the
    /// ambassador collection. As this init function is called only once when the module is published, there will
    // /// be only one ambassador collection.
    // fun init_module(sender: &signer) {
    //     create_poanft_collection(sender);
    // }

    // fun create_poanft_collection(creator: &signer) {
    //     // Constructs the strings from the bytes.
    //     let description = string::utf8(COLLECTION_DESCRIPTION);
    //     let name = string::utf8(COLLECTION_NAME);
    //     let uri = string::utf8(COLLECTION_URI);

    //     // Creates the collection with unlimited supply and without establishing any royalty configuration.
    //     collection::create_unlimited_collection(
    //         creator,
    //         description,
    //         name,
    //         option::none(),
    //         uri,
    //     );
    // }



    /// `init_module` is automatically called when publishing the module.
    /// In this function, we create an example NFT collection and an example token.
    

    fun init_module(admin: &signer) {
        let collection_name = string::utf8(COLLECTION_NAME);
        let description = string::utf8(COLLECTION_DESCRIPTION);
        let collection_uri = string::utf8(COLLECTION_URI);
        let token_name = string::utf8(TOKEN_URI);
        let token_uri = string::utf8(TOKEN_NAME);
        // This means that the supply of the token will not be tracked.
        let maximum_supply = 0;
        // This variable sets if we want to allow mutation for collection description, uri, and maximum.
        // Here, we are setting all of them to false, which means that we don't allow mutations to any CollectionData fields.
        let mutate_setting = vector<bool>[ false, false, false ];

        // Create the nft collection.
        token::create_collection(admin, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // Create a token data id to specify the token to be minted.
        let token_data_id = token::create_tokendata(
            admin,
            collection_name,
            token_name,
            string::utf8(b""),
            0,
            token_uri,
            signer::address_of(admin),
            1,
            0,
            // This variable sets if we want to allow mutation for token maximum, uri, royalty, description, and properties.
            // Here we enable mutation for properties by setting the last boolean in the vector to true.
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            // We can use property maps to record attributes related to the token.
            // In this example, we are using it to record the receiver's address.
            // We will mutate this field to record the user's address
            // when a user successfully mints a token in the `mint_nft()` function.
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[ string::utf8(b"address") ],
        );

        // Store the token data id within the module, so we can refer to it later
        // when we're minting the NFT and updating its property version.
        move_to(admin, ModuleData {
            token_data_id,
        });
    }

    public entry fun mint_POANft(admin: &signer, receiver: &signer) acquires ModuleData {
        // Assert that the module owner signer is the owner of this module.
         assert!(signer::address_of(admin) == @POANft_add, error::permission_denied(ENOT_AUTHORIZED));
         // Mint token to the receiver.
         let module_data = borrow_global_mut<ModuleData>(@POANft_add);
         let token_id = token::mint_token(admin, module_data.token_data_id, 1);
         token::direct_transfer(admin, receiver, token_id, 1);
    }

}

