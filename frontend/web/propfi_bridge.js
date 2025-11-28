// PropFi Bridge - JavaScript Interop for Cardano
// Handles wallet connection, transaction building (Lucid), and Blockfrost interaction.

const BLOCKFROST_PROJECT_ID = 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe';
const BLOCKFROST_BASE_URL = 'https://cardano-preprod.blockfrost.io/api/v0';

const CONTRACT_CONFIG = {
  network: 'preprod',
  fractionalizeScriptHash: '4e03e3aacbb838b267ee6dcccdaffebff835a3a8cf51d9870e5a6b2e',
  cip68MintingPolicyId: '7af62086280f10305eec66f17afff08526513d5b41549cb63bd1e4ca',
  marketplaceScriptHash: 'a763ffb61095577404d7594b17475e8db0d3b3a2595fa82e93642225',
};

const CIP68_REFERENCE_LABEL = 100;
const CIP68_USER_TOKEN_LABEL = 222;

window.PropFiBridge = {
  lucid: null,
  walletApi: null,
  selectedWallet: null,  // Track user's selected wallet
  connectedWallet: null, // Track which wallet the API is for
  config: CONTRACT_CONFIG,

  initLucid: async function () {
    if (this.lucid) return this.lucid;
    if (!window.Lucid) {
      console.log('Waiting for Lucid to load...');
      await new Promise(r => setTimeout(r, 1000));
      if (!window.Lucid) throw new Error('Lucid not loaded');
    }
    const Lucid = window.Lucid;
    const Blockfrost = window.Blockfrost;

    if (!Blockfrost) throw new Error('Blockfrost not loaded');

    try {
      this.lucid = await Lucid.new(
        new Blockfrost(BLOCKFROST_BASE_URL, BLOCKFROST_PROJECT_ID),
        'Preprod'
      );
      console.log('Lucid initialized');
      return this.lucid;
    } catch (e) {
      console.error('Lucid init failed:', e);
      throw e;
    }
  },

  getAvailableWallets: function () {
    if (!window.cardano) return [];
    return Object.keys(window.cardano).filter(key => window.cardano[key].enable);
  },

  // Set the user's selected wallet - always clears any cached state
  setSelectedWallet: function (walletId) {
    console.log('Setting selected wallet to:', walletId);
    // Always clear cache
    this.walletApi = null;
    this.connectedWallet = null;
    this.selectedWallet = walletId;
  },

  // Disconnect and clear all wallet state
  disconnectWallet: function () {
    console.log('Disconnecting wallet, clearing all state');
    this.walletApi = null;
    this.connectedWallet = null;
    this.selectedWallet = null;
  },

  // Get the currently connected wallet name
  getConnectedWalletName: function () {
    return this.connectedWallet || this.selectedWallet || null;
  },

  getWalletApi: async function () {
    const wallets = this.getAvailableWallets();
    if (wallets.length === 0) throw new Error('No wallets found');

    // Determine which wallet to use
    let walletName = this.selectedWallet;
    if (!walletName || !wallets.includes(walletName)) {
      walletName = wallets[0];
      console.log('No selected wallet, using first available:', walletName);
    }

    // Always get fresh wallet API - NO CACHING
    console.log('Connecting to wallet:', walletName);

    try {
      // Always request fresh connection
      this.walletApi = await window.cardano[walletName].enable();
      this.connectedWallet = walletName;
      
      console.log('Successfully connected to wallet:', walletName);
      return this.walletApi;
    } catch (e) {
      console.error('Wallet connection failed:', e);
      this.walletApi = null;
      this.connectedWallet = null;
      throw e;
    }
  },

  blockfrostGet: async function (endpoint) {
    try {
      const response = await fetch(`${BLOCKFROST_BASE_URL}${endpoint}`, {
        headers: { 'project_id': BLOCKFROST_PROJECT_ID }
      });
      if (!response.ok) throw new Error(`Blockfrost API error: ${response.statusText}`);
      return await response.json();
    } catch (e) {
      console.error('Blockfrost request failed:', e);
      return null;
    }
  },

  getScriptAddress: async function (scriptHash) {
    const lucid = await this.initLucid();
    return lucid.utils.credentialToAddress({ type: 'Script', hash: scriptHash });
  },

  /**
   * Generate a unique property ID from timestamp
   */
  generatePropertyId: function () {
    const timestamp = Date.now().toString(16);
    const random = Math.random().toString(16).slice(2, 10);
    return (timestamp + random).slice(0, 16).padStart(16, '0');
  },

  /**
   * Create on-chain property metadata (CIP-68 format)
   * Truncates strings to fit Cardano metadata limits (max 64 bytes per string)
   */
  createPropertyMetadata: function (property) {
    const truncate = (str, maxLen = 64) => {
      if (!str) return '';
      return str.length > maxLen ? str.slice(0, maxLen - 3) + '...' : str;
    };

    return {
      name: truncate(property.name, 64),
      description: truncate(property.description, 64),
      location: truncate(property.location, 64),
      image: truncate(property.imageUrl, 64),
      totalValue: property.totalValue.toString().slice(0, 20),
      totalFractions: property.totalFractions.toString().slice(0, 10),
      pricePerFraction: property.pricePerFraction.toString().slice(0, 20),
      ownerWallet: truncate(property.ownerWalletAddress, 64),
      legalDocCID: truncate(property.legalDocumentCID || '', 64),
      createdAt: new Date().toISOString().slice(0, 24),
    };
  },

  /**
   * List a property on-chain with CIP-68 metadata
   * This creates a UTxO at the marketplace script address with inline datum
   */
  listPropertyOnChain: async function (property) {
    console.log('=== listPropertyOnChain START ===');
    console.log('Property to list:', property);

    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const walletAddress = await lucid.wallet.address();
      console.log('Wallet address:', walletAddress);

      // Get payment credential (public key hash) from wallet address
      const walletDetails = lucid.utils.getAddressDetails(walletAddress);
      const sellerPkh = walletDetails.paymentCredential?.hash;
      if (!sellerPkh) {
        throw new Error('Could not extract payment credential from wallet');
      }
      console.log('Seller PKH:', sellerPkh);

      // Generate unique property ID
      const propertyId = this.generatePropertyId();
      console.log('Property ID:', propertyId);

      // CIP-68 token names
      const referenceTokenName = '000643b0' + propertyId; // Reference token (100)
      const userTokenName = '000de140' + propertyId; // User/fraction tokens (222)

      // Create metadata for the property
      const metadata = this.createPropertyMetadata(property);
      console.log('Metadata:', metadata);

      // Price in lovelace (1 ADA = 1,000,000 lovelace)
      const priceInLovelace = BigInt(Math.floor(property.pricePerFraction * 1000000));
      const totalFractions = BigInt(property.totalFractions);

      // Get marketplace script address using Lucid (same method as fetch)
      const marketplaceAddress = lucid.utils.credentialToAddress({
        type: 'Script',
        hash: CONTRACT_CONFIG.marketplaceScriptHash,
      });
      console.log('Marketplace address:', marketplaceAddress);

      // Create inline datum for marketplace listing
      // Format: MarketplaceDatum { seller, price, stablecoin_asset, fraction_asset, fraction_amount }
      const marketplaceDatum = {
        seller: sellerPkh,
        price: priceInLovelace,
        stablecoinAsset: {
          policyId: '', // Empty = ADA
          assetName: '',
        },
        fractionAsset: {
          policyId: CONTRACT_CONFIG.cip68MintingPolicyId,
          assetName: userTokenName,
        },
        fractionAmount: totalFractions,
        // Extended metadata for display
        propertyMetadata: metadata,
      };

      console.log('Marketplace datum:', marketplaceDatum);

      // Build the transaction:
      // 1. Create UTxO at marketplace address with inline datum
      // 2. Include property metadata in transaction metadata (CIP-25 style)

      // Minimum ADA for UTxO (2 ADA should be enough for datum)
      const minUtxoAda = 2000000n;

      // Transaction metadata (CIP-25 style for discoverability)
      // All strings must be <= 64 bytes for Cardano metadata
      const txMetadata = {
        // Label 721 is CIP-25 NFT metadata
        721: {
          [CONTRACT_CONFIG.cip68MintingPolicyId]: {
            [propertyId]: {
              name: metadata.name,
              desc: metadata.description,
              loc: metadata.location,
              img: metadata.image,
              val: metadata.totalValue,
              frac: metadata.totalFractions,
              price: metadata.pricePerFraction,
              owner: metadata.ownerWallet,
              propId: propertyId,
            }
          }
        },
        // PropFi custom label for easy querying
        1337: {
          act: 'list',
          pid: propertyId,
          sell: sellerPkh,
          pri: priceInLovelace.toString().slice(0, 20),
          frac: totalFractions.toString().slice(0, 10),
        }
      };

      console.log('Building transaction...');
      console.log('TX Metadata:', txMetadata);

      // For property listings, we use transaction metadata to store property info
      // This is simpler than using inline datums and works well with Blockfrost queries
      // The UTxO at marketplace address serves as a "registration" of the listing

      const tx = await lucid.newTx()
        .payToAddress(marketplaceAddress, { lovelace: minUtxoAda })
        .attachMetadata(721, txMetadata[721])
        .attachMetadata(1337, txMetadata[1337])
        .complete();

      console.log('Transaction built, signing...');

      const signedTx = await tx.sign().complete();
      console.log('Transaction signed, submitting...');

      const txHash = await signedTx.submit();
      console.log('Transaction submitted:', txHash);

      // Wait for transaction to appear on Blockfrost (with timeout)
      console.log('Waiting for transaction confirmation...');
      const confirmed = await this.waitForTxConfirmation(txHash, 120000); // 2 min timeout

      if (!confirmed) {
        console.warn('Transaction submitted but not yet confirmed. It may take a few minutes.');
      } else {
        console.log('Transaction confirmed on-chain!');
      }

      console.log('=== listPropertyOnChain SUCCESS ===');
      console.log('Transaction hash:', txHash);

      // Return listing details
      return {
        txHash: txHash,
        propertyId: propertyId,
        marketplaceAddress: marketplaceAddress,
        datum: marketplaceDatum,
        metadata: metadata,
        confirmed: confirmed,
      };

    } catch (error) {
      console.error('=== listPropertyOnChain ERROR ===', error);
      throw error;
    }
  },

  /**
   * Wait for a transaction to be confirmed on-chain
   */
  waitForTxConfirmation: async function (txHash, timeoutMs = 120000) {
    const startTime = Date.now();
    const pollInterval = 5000; // Check every 5 seconds

    console.log(`Polling for tx confirmation: ${txHash}`);

    while (Date.now() - startTime < timeoutMs) {
      try {
        const txInfo = await this.blockfrostGet(`/txs/${txHash}`);
        if (txInfo && txInfo.hash) {
          console.log('Transaction confirmed:', txInfo);
          return true;
        }
      } catch (e) {
        // 404 means not yet confirmed, keep waiting
        console.log(`TX not yet confirmed, waiting... (${Math.round((Date.now() - startTime) / 1000)}s)`);
      }

      await new Promise(resolve => setTimeout(resolve, pollInterval));
    }

    console.warn('Transaction confirmation timeout');
    return false;
  },

  /**
   * Fetch on-chain properties from marketplace using transaction metadata
   * This queries Blockfrost for transactions with PropFi metadata
   */
  fetchOnChainProperties: async function () {
    console.log('=== fetchOnChainProperties START ===');

    try {
      // Use Lucid to generate address (same as listPropertyOnChain uses)
      const lucid = await this.initLucid();
      const marketplaceAddress = lucid.utils.credentialToAddress({
        type: 'Script',
        hash: CONTRACT_CONFIG.marketplaceScriptHash,
      });
      console.log('Marketplace address (Lucid):', marketplaceAddress);

      // Also log our manual address for comparison
      const manualAddress = await this.getScriptAddress(CONTRACT_CONFIG.marketplaceScriptHash);
      console.log('Marketplace address (manual):', manualAddress);

      // Get all UTxOs at marketplace address (returns null if no UTxOs)
      const utxos = await this.blockfrostGet(`/addresses/${marketplaceAddress}/utxos`);

      if (!utxos || utxos.length === 0) {
        console.log('No UTxOs at marketplace address (no on-chain listings yet)');
        return [];
      }

      console.log('Found UTxOs:', utxos.length);

      const properties = [];

      for (const utxo of utxos) {
        try {
          // Get transaction details for metadata
          const txDetails = await this.blockfrostGet(`/txs/${utxo.tx_hash}/metadata`);
          console.log('TX metadata for', utxo.tx_hash, ':', txDetails);

          // Look for PropFi metadata (label 1337) AND CIP-25 (label 721)
          let propFiData = null;
          let cip25Data = null;

          if (txDetails && Array.isArray(txDetails)) {
            for (const meta of txDetails) {
              if (meta.label === '1337') {
                // PropFi custom metadata
                propFiData = meta.json_metadata;
              } else if (meta.label === '721') {
                // CIP-25 NFT metadata
                const nftMeta = meta.json_metadata;
                if (nftMeta && nftMeta[CONTRACT_CONFIG.cip68MintingPolicyId]) {
                  const policyMeta = nftMeta[CONTRACT_CONFIG.cip68MintingPolicyId];
                  const propId = Object.keys(policyMeta)[0];
                  if (propId) {
                    cip25Data = {
                      ...policyMeta[propId],
                      propertyId: propId,
                    };
                  }
                }
              }
            }
          }

          // Merge data, prioritizing CIP-25 for display info and PropFi for logic
          const propertyData = { ...propFiData, ...cip25Data };

          if (propertyData && (propFiData || cip25Data)) {
            // Create a clean object for Dart interop (avoid spread operator issues)
            const cleanProperty = {
              txHash: utxo.tx_hash,
              outputIndex: utxo.tx_index || utxo.output_index || 0,
              lovelace: utxo.amount?.find(a => a.unit === 'lovelace')?.quantity || '0',
              propertyId: propertyData.pid || propertyData.propId || propertyData.propertyId || '',
              name: propertyData.name || '',
              description: propertyData.desc || propertyData.description || '',
              location: propertyData.loc || propertyData.location || '',
              image: propertyData.img || propertyData.image || '',
              totalValue: propertyData.val || propertyData.totalValue || '0',
              totalFractions: propertyData.frac || propertyData.totalFractions || '0',
              pricePerFraction: propertyData.price || propertyData.pricePerFraction || '0',
              seller: propertyData.sell || propertyData.seller || propertyData.owner || '',
            };
            properties.push(cleanProperty);
          }
        } catch (err) {
          console.warn('Error fetching metadata for tx:', utxo.tx_hash, err);
        }
      }

      console.log('=== fetchOnChainProperties END ===');
      console.log('Found properties:', properties.length);
      console.log('Properties data:', JSON.stringify(properties));

      return properties;
    } catch (error) {
      console.error('Error fetching on-chain properties:', error);
      return [];
    }
  },

  /**
   * Fetch on-chain properties as JSON string (for easier Dart interop)
   */
  fetchOnChainPropertiesJson: async function () {
    const properties = await this.fetchOnChainProperties();
    return JSON.stringify(properties);
  },

  /**
   * Cancel/Delist a property from marketplace
   * Spends the UTxO back to the owner
   */
  cancelPropertyListing: async function (txHash, outputIndex) {
    console.log('=== cancelPropertyListing START ===');
    console.log('UTxO:', txHash, '#', outputIndex);

    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const walletAddress = await lucid.wallet.address();
      const marketplaceAddress = await this.getScriptAddress(CONTRACT_CONFIG.marketplaceScriptHash);

      // Get the UTxO to spend
      const utxos = await lucid.utxosAt(marketplaceAddress);
      const targetUtxo = utxos.find(u => u.txHash === txHash && u.outputIndex === outputIndex);

      if (!targetUtxo) {
        throw new Error('UTxO not found at marketplace address');
      }

      console.log('Found UTxO to cancel:', targetUtxo);

      // Build cancel transaction
      // For now, just return the ADA to the owner
      const tx = await lucid.newTx()
        .collectFrom([targetUtxo])
        .addSigner(walletAddress)
        .complete();

      const signedTx = await tx.sign().complete();
      const resultTxHash = await signedTx.submit();

      console.log('=== cancelPropertyListing SUCCESS ===');
      console.log('Cancel transaction hash:', resultTxHash);

      return resultTxHash;
    } catch (error) {
      console.error('=== cancelPropertyListing ERROR ===', error);
      throw error;
    }
  },

  /**
   * Build a simple payment transaction (for buying fractions with direct ADA payment)
   * @param {string} fromAddress - Sender's address (bech32 or hex)
   * @param {string} toAddress - Recipient's address (bech32) or payment key hash (hex)
   * @param {string} lovelaceAmount - Amount in lovelace (as string)
   * @returns {Promise<{txHash: string}>} - Transaction hash after signing and submitting
   */
  buildPaymentTransaction: async function(fromAddress, toAddress, lovelaceAmount) {
    console.log('=== buildPaymentTransaction START ===');
    console.log('From:', fromAddress);
    console.log('To (raw):', toAddress);
    console.log('Amount (lovelace):', lovelaceAmount);

    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      // Convert lovelace string to BigInt
      const amount = BigInt(lovelaceAmount);

      // Determine if toAddress is a bech32 address or a payment key hash
      let recipientAddress = toAddress;
      
      // If it's a hex payment key hash (56 or 64 chars), convert to address
      if (toAddress && !toAddress.startsWith('addr') && /^[0-9a-fA-F]+$/.test(toAddress)) {
        console.log('Converting payment key hash to address...');
        
        // Get network ID (0 = testnet, 1 = mainnet)
        const networkId = lucid.network === 'Mainnet' ? 1 : 0;
        
        // For preprod/preview, we need to construct a base address
        // Payment key hash is 28 bytes (56 hex chars)
        // We'll create an enterprise address (no staking part) for simplicity
        const paymentKeyHash = toAddress.length === 56 ? toAddress : toAddress.slice(0, 56);
        
        // Enterprise address prefix: 0x60 for testnet, 0x61 for mainnet (type 6)
        const prefix = networkId === 0 ? '60' : '61';
        const addressHex = prefix + paymentKeyHash;
        
        // Convert hex to bech32 using Lucid's utility
        const { C } = await import('https://unpkg.com/lucid-cardano@0.9.5/web/mod.js');
        const addressBytes = new Uint8Array(addressHex.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
        const address = C.Address.from_bytes(addressBytes);
        recipientAddress = address.to_bech32(networkId === 0 ? 'addr_test' : 'addr');
        
        console.log('Converted to address:', recipientAddress);
      }

      console.log('Building payment transaction to:', recipientAddress);

      // Build the transaction
      const tx = await lucid.newTx()
        .payToAddress(recipientAddress, { lovelace: amount })
        .complete();

      console.log('Transaction built, signing...');

      // Sign the transaction
      const signedTx = await tx.sign().complete();

      console.log('Transaction signed, submitting...');

      // Submit the transaction
      const txHash = await signedTx.submit();

      console.log('=== buildPaymentTransaction SUCCESS ===');
      console.log('Transaction hash:', txHash);

      return { txHash: txHash };
    } catch (error) {
      console.error('=== buildPaymentTransaction ERROR ===', error);
      throw error;
    }
  },

  /**
   * Get wallet balance in ADA
   */
  getBalance: async function () {
    try {
      console.log('getBalance: Starting...');
      
      const lucid = await this.initLucid();
      console.log('getBalance: Lucid initialized');
      
      const walletApi = await this.getWalletApi();
      console.log('getBalance: Got wallet API');
      
      lucid.selectWallet(walletApi);
      console.log('getBalance: Wallet selected in Lucid');

      const utxos = await lucid.wallet.getUtxos();
      console.log('getBalance: Got UTXOs:', utxos.length);
      
      let totalLovelace = 0n;
      for (const utxo of utxos) {
        if (utxo.assets && utxo.assets.lovelace) {
          totalLovelace += BigInt(utxo.assets.lovelace);
        }
      }
      
      const balanceAda = Number(totalLovelace) / 1000000;
      console.log('getBalance: Total balance:', balanceAda, 'ADA');
      
      return balanceAda;
    } catch (e) {
      console.error('Error fetching balance:', e);
      return 0;
    }
  },

  /**
   * Get all wallet assets (ADA + native tokens)
   */
  getWalletAssets: async function () {
    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const utxos = await lucid.wallet.getUtxos();
      
      let lovelace = 0n;
      const tokens = {};
      
      for (const utxo of utxos) {
        if (utxo.assets) {
          for (const [asset, amount] of Object.entries(utxo.assets)) {
            if (asset === 'lovelace') {
              lovelace += BigInt(amount);
            } else {
              if (!tokens[asset]) tokens[asset] = 0n;
              tokens[asset] += BigInt(amount);
            }
          }
        }
      }
      
      return {
        ada: Number(lovelace) / 1000000,
        lovelace: lovelace.toString(),
        tokens: Object.fromEntries(
          Object.entries(tokens).map(([k, v]) => [k, v.toString()])
        ),
        utxoCount: utxos.length,
      };
    } catch (e) {
      console.error('Error fetching wallet assets:', e);
      return { ada: 0, lovelace: '0', tokens: {}, utxoCount: 0 };
    }
  },

  // Crestadel metadata label for purchases (unique identifier)
  PURCHASE_METADATA_LABEL: 8888,

  /**
   * Build payment transaction WITH purchase metadata (decentralized storage)
   */
  buildPaymentWithMetadata: async function(toAddress, lovelaceAmount, purchaseData) {
    console.log('=== buildPaymentWithMetadata START ===');
    console.log('To:', toAddress);
    console.log('Amount:', lovelaceAmount);
    console.log('Purchase data:', purchaseData);

    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const amount = BigInt(lovelaceAmount);

      // Convert payment key hash to address if needed
      let recipientAddress = toAddress;
      if (toAddress && !toAddress.startsWith('addr') && /^[0-9a-fA-F]+$/.test(toAddress)) {
        const networkId = lucid.network === 'Mainnet' ? 1 : 0;
        const paymentKeyHash = toAddress.length === 56 ? toAddress : toAddress.slice(0, 56);
        const prefix = networkId === 0 ? '60' : '61';
        const addressHex = prefix + paymentKeyHash;
        const { C } = await import('https://unpkg.com/lucid-cardano@0.9.5/web/mod.js');
        const addressBytes = new Uint8Array(addressHex.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
        const address = C.Address.from_bytes(addressBytes);
        recipientAddress = address.to_bech32(networkId === 0 ? 'addr_test' : 'addr');
      }

      // Build purchase metadata with buyer details for certificate
      const metadata = {
        [this.PURCHASE_METADATA_LABEL]: {
          app: "crestadel",
          type: "purchase",
          propertyId: purchaseData.propertyId,
          propertyName: (purchaseData.propertyName || '').substring(0, 64), // Limit length
          fractions: purchaseData.fractions,
          priceAda: purchaseData.priceAda,
          buyer: {
            name: (purchaseData.buyerName || 'Anonymous').substring(0, 64),
            email: (purchaseData.buyerEmail || '').substring(0, 64),
            phone: (purchaseData.buyerPhone || '').substring(0, 20),
            wallet: (purchaseData.buyerWallet || '').substring(0, 120)
          },
          timestamp: Date.now(),
          version: 2
        }
      };

      console.log('Attaching metadata:', metadata);

      // Build the transaction with metadata
      const tx = await lucid.newTx()
        .payToAddress(recipientAddress, { lovelace: amount })
        .attachMetadata(this.PURCHASE_METADATA_LABEL, metadata[this.PURCHASE_METADATA_LABEL])
        .complete();

      const signedTx = await tx.sign().complete();
      const txHash = await signedTx.submit();

      console.log('=== buildPaymentWithMetadata SUCCESS ===');
      console.log('Transaction hash:', txHash);

      return { txHash: txHash };
    } catch (error) {
      console.error('=== buildPaymentWithMetadata ERROR ===', error);
      throw error;
    }
  },

  /**
   * Fetch user's purchase history from on-chain metadata (decentralized)
   */
  fetchUserPurchases: async function() {
    console.log('=== fetchUserPurchases START ===');
    
    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      // Get wallet address
      const address = await lucid.wallet.address();
      console.log('Fetching purchases for address:', address);

      // Query Blockfrost for transactions from this address
      const txsResponse = await fetch(
        `${BLOCKFROST_BASE_URL}/addresses/${address}/transactions?order=desc`,
        { headers: { 'project_id': BLOCKFROST_PROJECT_ID } }
      );
      
      if (!txsResponse.ok) {
        console.log('No transactions found or API error');
        return [];
      }

      const transactions = await txsResponse.json();
      console.log('Found transactions:', transactions.length);

      const purchases = [];

      // Check each transaction for Crestadel purchase metadata
      for (const tx of transactions.slice(0, 50)) { // Limit to last 50 txs
        try {
          const metadataResponse = await fetch(
            `${BLOCKFROST_BASE_URL}/txs/${tx.tx_hash}/metadata`,
            { headers: { 'project_id': BLOCKFROST_PROJECT_ID } }
          );

          if (metadataResponse.ok) {
            const metadata = await metadataResponse.json();
            
            // Look for our purchase label
            const purchaseData = metadata.find(m => m.label === this.PURCHASE_METADATA_LABEL.toString());
            
            if (purchaseData && purchaseData.json_metadata?.app === 'crestadel') {
              console.log('Found purchase in tx:', tx.tx_hash);
              purchases.push({
                txHash: tx.tx_hash,
                ...purchaseData.json_metadata
              });
            }
          }
        } catch (e) {
          // Skip transactions without metadata
        }
      }

      console.log('=== fetchUserPurchases END ===');
      console.log('Total purchases found:', purchases.length);
      
      return purchases;
    } catch (error) {
      console.error('Error fetching user purchases:', error);
      return [];
    }
  },

  /**
   * Get user purchases as JSON string (for Flutter interop)
   */
  fetchUserPurchasesJson: async function() {
    const purchases = await this.fetchUserPurchases();
    return JSON.stringify(purchases);
  },
};

// Log initialization
console.log('PropFi Bridge initialized with Blockfrost API', window.PropFiBridge.config);

// Check for wallets after a short delay (they inject after page load)
setTimeout(() => {
  const wallets = window.PropFiBridge.getAvailableWallets();
  console.log('PropFi Bridge: Detected wallets after delay:', wallets);
}, 1000);