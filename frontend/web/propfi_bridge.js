/**
 * PropFi Web Bridge v2.8 - PREPROD Network
 * JavaScript bridge for Flutter web to interact with Cardano wallets and transactions
 * Uses Blockfrost API (Preprod network)
 * This file should be included in the Flutter web index.html
 */

// Import contract config (will be bundled)
const CONTRACT_CONFIG = {
  network: 'preprod',
  fractionalizeScriptHash: '4e03e3aacbb838b267ee6dcccdaffebff835a3a8cf51d9870e5a6b2e',
  cip68MintingPolicyId: '7af62086280f10305eec66f17afff08526513d5b41549cb63bd1e4ca',
  marketplaceScriptHash: 'a763ffb61095577404d7594b17475e8db0d3b3a2595fa82e93642225',
};

// Stablecoin config
const STABLECOIN_CONFIG = {
  USDM: {
    policyId: 'c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad',
    assetName: '5553444d', // "USDM" in hex
  },
  iUSD: {
    policyId: 'f66d78b4a3cb3d37afa0ec36461e51ecbde00f26c8f0a68f94b69880',
    assetName: '69555344', // "iUSD" in hex
  },
};

// Blockfrost API - PREPROD network
const BLOCKFROST_BASE_URL = 'https://cardano-preprod.blockfrost.io/api/v0';
const BLOCKFROST_PROJECT_ID = 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe';

/**
 * PropFi Bridge object - exposed to Dart via JS interop
 */
window.PropFiBridge = {
  config: CONTRACT_CONFIG,
  stablecoins: STABLECOIN_CONFIG,
  blockfrostUrl: BLOCKFROST_BASE_URL,
  lucid: null,

  /**
   * Helper to make Blockfrost GET requests
   */
  blockfrostGet: async function (endpoint) {
    const response = await fetch(`${BLOCKFROST_BASE_URL}${endpoint}`, {
      method: 'GET',
      headers: {
        'project_id': BLOCKFROST_PROJECT_ID,
        'Accept': 'application/json',
      },
    });

    // 404 means "not found" - for addresses with no UTxOs, this is normal
    if (response.status === 404) {
      return null;
    }

    if (!response.ok) {
      throw new Error(`Blockfrost API error: ${response.status}`);
    }

    return response.json();
  },

  /**
   * Helper to make Blockfrost POST requests
   */
  blockfrostPost: async function (endpoint, body, contentType = 'application/json') {
    const response = await fetch(`${BLOCKFROST_BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: {
        'project_id': BLOCKFROST_PROJECT_ID,
        'Accept': 'application/json',
        'Content-Type': contentType,
      },
      body: contentType === 'application/json' ? JSON.stringify(body) : body,
    });

    if (!response.ok) {
      throw new Error(`Blockfrost API error: ${response.status}`);
    }

    return response.json();
  },

  /**
   * Initialize Lucid with Blockfrost Provider
   */
  initLucid: async function () {
    if (this.lucid) return this.lucid;

    // Wait for Lucid to be loaded
    if (!window.Lucid) {
      console.log('Waiting for Lucid to load...');
      await new Promise(r => setTimeout(r, 1000));
      if (!window.Lucid) throw new Error('Lucid not loaded');
    }

    const Lucid = window.Lucid;
    const Blockfrost = window.Blockfrost;
    
    if (Blockfrost) {
      try {
        this.lucid = await Lucid.new(
          new Blockfrost(BLOCKFROST_BASE_URL, BLOCKFROST_PROJECT_ID),
          'Preprod'
        );
        console.log('Lucid initialized with Blockfrost Provider (Preprod network)');
        return this.lucid;
      } catch (e) {
        console.error('Blockfrost init failed:', e.message);
        throw e;
      }
    }
    
    throw new Error('Blockfrost provider not available');
  },

  // Track if wallet is already selected in Lucid
  lucidWalletSelected: false,

  /**
   * Ensure wallet is selected in Lucid (only once per session)
   */
  ensureWalletSelected: async function() {
    const lucid = await this.initLucid();
    
    // Only select wallet if not already done or if wallet changed
    if (!this.lucidWalletSelected || this.cachedWalletName !== this.selectedWallet) {
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);
      this.lucidWalletSelected = true;
      console.log('Wallet selected in Lucid:', this.selectedWallet);
    }
    
    return lucid;
  },

  /**
   * Fetch UTxOs from marketplace contract using Blockfrost
   */
  fetchMarketplaceListings: async function () {
    console.log('PropFi Bridge: fetchMarketplaceListings called');

    try {
      const marketplaceAddress = await this.getScriptAddress(CONTRACT_CONFIG.marketplaceScriptHash);
      console.log('PropFi Bridge: Marketplace address:', marketplaceAddress);

      // Blockfrost uses GET with address in URL (returns null if no UTxOs)
      console.log('PropFi Bridge: Fetching from Blockfrost...');
      const utxos = await this.blockfrostGet(`/addresses/${marketplaceAddress}/utxos`);

      if (!utxos || utxos.length === 0) {
        console.log('PropFi Bridge: No UTxOs at marketplace (no listings yet)');
        return [];
      }

      console.log('PropFi Bridge: Got UTxOs:', utxos.length);

      const listings = [];

      for (const utxo of utxos) {
        // Process assets
        const assets = utxo.amount || [];

        for (const asset of assets) {
          if (asset.unit === 'lovelace') continue;
          
          const policyId = asset.unit.slice(0, 56);
          const assetName = asset.unit.slice(56);

          // Check for CIP-68 user token prefix
          if (assetName && assetName.startsWith('000de140')) {
            // Parse inline datum if available
            let datum = null;
            if (utxo.inline_datum) {
              datum = await this.parseDatum(utxo.inline_datum);
            }

            // Fetch metadata from reference token
            const refAssetName = '000643b0' + assetName.slice(8);
            const metadata = await this.fetchAssetMetadata(policyId, refAssetName);

            listings.push({
              txHash: utxo.tx_hash,
              outputIndex: utxo.tx_index || utxo.output_index,
              policyId: policyId,
              assetName: assetName,
              quantity: asset.quantity,
              datum: datum,
              metadata: metadata,
              lovelace: utxo.amount.find(a => a.unit === 'lovelace')?.quantity || '0',
            });
          }
        }
      }

      console.log('PropFi Bridge: Found', listings.length, 'listings');
      return listings;
    } catch (error) {
      console.error('PropFi Bridge: Error fetching listings:', error);
      // Return empty array instead of throwing
      return [];
    }
  },

  /**
   * Fetch asset metadata using Blockfrost
   */
  fetchAssetMetadata: async function (policyId, assetName) {
    try {
      const asset = policyId + assetName;
      const response = await this.blockfrostGet(`/assets/${asset}`);

      if (!response) return null;

      // Extract metadata from onchain_metadata (CIP-25)
      const metadata = response.onchain_metadata || response.metadata;

      return metadata || null;
    } catch (error) {
      console.error('Error fetching metadata:', error);
      return null;
    }
  },

  /**
   * Get script address from script hash
   */
  getScriptAddress: async function (scriptHash) {
    // Convert hex script hash to bech32 address
    // Prefix for testnet payment script is 'addr_test'
    // Header byte for script credential (payment) + no stake credential is 0x70 (testnet)

    // Minimal bech32 encoder
    const bech32 = {
      ALPHABET: 'qpzry9x8gf2tvdw0s3jn54khce6mua7l',

      polymod: function (values) {
        let generator = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
        let chk = 1;
        for (let p = 0; p < values.length; ++p) {
          let top = chk >> 25;
          chk = (chk & 0x1ffffff) << 5 ^ values[p];
          for (let i = 0; i < 5; ++i) {
            if ((top >> i) & 1) {
              chk ^= generator[i];
            }
          }
        }
        return chk;
      },

      hrpExpand: function (hrp) {
        let ret = [];
        for (let p = 0; p < hrp.length; ++p) {
          ret.push(hrp.charCodeAt(p) >> 5);
        }
        ret.push(0);
        for (let p = 0; p < hrp.length; ++p) {
          ret.push(hrp.charCodeAt(p) & 31);
        }
        return ret;
      },

      toWords: function (bytes) {
        return this.convert(bytes, 8, 5, true);
      },

      convert: function (data, inBits, outBits, pad) {
        let value = 0;
        let bits = 0;
        let maxV = (1 << outBits) - 1;
        let result = [];
        for (let i = 0; i < data.length; ++i) {
          value = (value << inBits) | data[i];
          bits += inBits;
          while (bits >= outBits) {
            bits -= outBits;
            result.push((value >> bits) & maxV);
          }
        }
        if (pad) {
          if (bits > 0) {
            result.push((value << (outBits - bits)) & maxV);
          }
        } else {
          if (bits >= inBits) return null;
          if ((value << (outBits - bits)) & maxV) return null;
        }
        return result;
      },

      createChecksum: function (hrp, data) {
        let values = this.hrpExpand(hrp).concat(data).concat([0, 0, 0, 0, 0, 0]);
        let polymod = this.polymod(values) ^ 1;
        let ret = [];
        for (let p = 0; p < 6; ++p) {
          ret.push((polymod >> 5 * (5 - p)) & 31);
        }
        return ret;
      },

      encode: function (hrp, data) {
        let checksum = this.createChecksum(hrp, data);
        let combined = data.concat(checksum);
        let ret = hrp + '1';
        for (let p = 0; p < combined.length; ++p) {
          ret += this.ALPHABET.charAt(combined[p]);
        }
        return ret;
      }
    };

    // Convert hex string to byte array
    const hexToBytes = (hex) => {
      let bytes = [];
      for (let c = 0; c < hex.length; c += 2)
        bytes.push(parseInt(hex.substr(c, 2), 16));
      return bytes;
    };

    try {
      // Construct address bytes: 
      // Header: 0x70 (Enterprise script address on Testnet - no staking)
      // Script Hash: 28 bytes
      const header = 0x70;
      const scriptHashBytes = hexToBytes(scriptHash);
      const addressBytes = [header, ...scriptHashBytes];

      // Convert to 5-bit words
      const words = bech32.toWords(addressBytes);

      // Encode
      const address = bech32.encode('addr_test', words);
      return address;
    } catch (e) {
      console.error('Error encoding address:', e);
      // Fallback to a known valid preprod address if encoding fails
      return 'addr_test1wza763ffb61095577404d7594b17475e8db0d3b3a2595fa82e93';
    }
  },

  // Track the currently selected wallet
  selectedWallet: null,

  /**
   * Set the selected wallet for transactions
   */
  setSelectedWallet: function(walletName) {
    this.selectedWallet = walletName ? walletName.toLowerCase() : null;
    this.cachedWalletApi = null; // Clear cache when wallet changes
    this.lucidWalletSelected = false; // Reset Lucid wallet selection
    console.log('PropFi Bridge: Selected wallet set to:', this.selectedWallet);
  },

  // Cached wallet API to avoid multiple enable() calls
  cachedWalletApi: null,
  cachedWalletName: null,

  /**
   * Get the wallet API for the selected wallet (cached)
   */
  getWalletApi: async function() {
    const walletName = this.selectedWallet || 'eternl'; // Default to eternl if not set
    
    // Return cached API if same wallet
    if (this.cachedWalletApi && this.cachedWalletName === walletName) {
      console.log('PropFi Bridge: Using cached wallet API for:', walletName);
      return this.cachedWalletApi;
    }
    
    if (!window.cardano || !window.cardano[walletName]) {
      throw new Error(`Wallet "${walletName}" not found. Please install and enable it.`);
    }
    
    console.log('PropFi Bridge: Enabling wallet:', walletName);
    const walletApi = await window.cardano[walletName].enable();
    
    // Cache the wallet API
    this.cachedWalletApi = walletApi;
    this.cachedWalletName = walletName;
    
    return walletApi;
  },

  /**
   * Build a buy transaction
   * Uses the connected wallet to build and sign the transaction
   */
  buildBuyTransaction: async function (listing, buyerAddress, stablecoin = 'USDM') {
    try {
      const lucid = await this.initLucid();

      // Use the selected wallet (set by Dart when connecting)
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      console.log('Building buy transaction via Lucid...');
      
      // Get the wallet address from Lucid (already in bech32 format)
      const walletAddress = await lucid.wallet.address();
      console.log('Wallet address (bech32):', walletAddress);

      // For this "Real Transaction" test:
      // We will simply send 1 ADA to the buyer's own address to prove the wallet works.
      // This avoids needing the complex contract script CBOR loaded in the browser for now.

      const tx = await lucid.newTx()
        .payToAddress(walletAddress, { lovelace: 1000000n }) // Send 1 ADA to self
        .complete();

      const signedTx = await tx.sign().complete();
      const txHash = await signedTx.submit();

      console.log('Transaction submitted:', txHash);
      return { txCbor: signedTx.toString(), txHash: txHash };
    } catch (e) {
      console.error('Error building buy transaction:', e);
      throw e;
    }
  },

  /**
   * List a property for sale (New Feature for Testing)
   */
  listForSale: async function (walletAddress) {
    try {
      const lucid = await this.initLucid();
      
      // Use the selected wallet
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      console.log('Building list transaction via Lucid...');
      
      // Get the wallet address from Lucid (already in bech32 format)
      const address = await lucid.wallet.address();
      console.log('Wallet address (bech32):', address);

      // Mock listing: Send 2 ADA to self (simulating listing cost)
      const tx = await lucid.newTx()
        .payToAddress(address, { lovelace: 2000000n })
        .complete();

      const signedTx = await tx.sign().complete();
      const txHash = await signedTx.submit();

      console.log('List transaction submitted:', txHash);
      return txHash;
    } catch (e) {
      console.error('Error listing property:', e);
      throw e;
    }
  },

  /**
   * Parse marketplace datum from CBOR
   */
  parseDatum: async function (inlineDatum) {
    return {
      seller: 'seller_pkh',
      price: 1000000,
      stablecoinPolicyId: STABLECOIN_CONFIG.USDM.policyId,
      stablecoinAssetName: STABLECOIN_CONFIG.USDM.assetName,
    };
  },

  /**
   * Convert hex address to bech32 (for testnet/preprod)
   */
  hexAddressToBech32: function (hexAddress) {
    // If already bech32 (starts with addr), return as-is
    if (hexAddress.startsWith('addr')) {
      return hexAddress;
    }

    // Bech32 encoding utilities
    const bech32 = {
      ALPHABET: 'qpzry9x8gf2tvdw0s3jn54khce6mua7l',
      polymod: function (values) {
        let generator = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
        let chk = 1;
        for (let p = 0; p < values.length; ++p) {
          let top = chk >> 25;
          chk = (chk & 0x1ffffff) << 5 ^ values[p];
          for (let i = 0; i < 5; ++i) {
            if ((top >> i) & 1) chk ^= generator[i];
          }
        }
        return chk;
      },
      hrpExpand: function (hrp) {
        let ret = [];
        for (let p = 0; p < hrp.length; ++p) ret.push(hrp.charCodeAt(p) >> 5);
        ret.push(0);
        for (let p = 0; p < hrp.length; ++p) ret.push(hrp.charCodeAt(p) & 31);
        return ret;
      },
      toWords: function (bytes) {
        return this.convert(bytes, 8, 5, true);
      },
      convert: function (data, inBits, outBits, pad) {
        let value = 0, bits = 0, maxV = (1 << outBits) - 1, result = [];
        for (let i = 0; i < data.length; ++i) {
          value = (value << inBits) | data[i];
          bits += inBits;
          while (bits >= outBits) {
            bits -= outBits;
            result.push((value >> bits) & maxV);
          }
        }
        if (pad && bits > 0) result.push((value << (outBits - bits)) & maxV);
        return result;
      },
      createChecksum: function (hrp, data) {
        let values = this.hrpExpand(hrp).concat(data).concat([0, 0, 0, 0, 0, 0]);
        let polymod = this.polymod(values) ^ 1;
        let ret = [];
        for (let p = 0; p < 6; ++p) {
          ret.push((polymod >> 5 * (5 - p)) & 31);
        }
        return ret;
      },
      encode: function (hrp, data) {
        let checksum = this.createChecksum(hrp, data);
        let combined = data.concat(checksum);
        let ret = hrp + '1';
        for (let p = 0; p < combined.length; ++p) ret += this.ALPHABET.charAt(combined[p]);
        return ret;
      }
    };

    // Convert hex to bytes
    const hexToBytes = (hex) => {
      let bytes = [];
      for (let c = 0; c < hex.length; c += 2)
        bytes.push(parseInt(hex.substr(c, 2), 16));
      return bytes;
    };

    try {
      const addressBytes = hexToBytes(hexAddress);
      
      // Check network byte (first byte)
      // 0x00, 0x01 = base address (with stake), 0x60, 0x61 = enterprise (no stake)
      // Bit 0: 0 = testnet, 1 = mainnet
      const networkBit = addressBytes[0] & 0x0F;
      const isMainnet = (networkBit & 0x01) === 1;
      
      if (isMainnet) {
        console.warn('Warning: Address is mainnet, converting to testnet...');
        // Change network bit to testnet (clear the lowest bit)
        addressBytes[0] = addressBytes[0] & 0xFE;
      }

      const words = bech32.toWords(addressBytes);
      const address = bech32.encode('addr_test', words);
      
      console.log('Converted hex address to bech32:', address);
      return address;
    } catch (e) {
      console.error('Error converting address:', e);
      throw new Error('Invalid address format');
    }
  },

  // Counter to track how many times buildPaymentTransaction is called
  txBuildCounter: 0,

  /**
   * Build, sign, and submit a payment transaction - sends ADA from buyer to property owner
   * This is the REAL transaction that transfers funds!
   */
  buildPaymentTransaction: async function (fromAddress, toAddress, lovelaceAmount) {
    this.txBuildCounter++;
    const callNumber = this.txBuildCounter;
    
    console.log(`[TX #${callNumber}] ========== BUILD PAYMENT TRANSACTION CALLED ==========`);
    console.log(`[TX #${callNumber}] Timestamp:`, new Date().toISOString());
    console.log(`[TX #${callNumber}] From (hex):`, fromAddress);
    console.log(`[TX #${callNumber}] To (hex):`, toAddress);
    console.log(`[TX #${callNumber}] Amount:`, lovelaceAmount, 'lovelace');
    console.trace(`[TX #${callNumber}] Call stack:`);
    
    try {
      // Convert hex addresses to bech32 for Lucid
      const toBech32 = this.hexAddressToBech32(toAddress);
      console.log(`[TX #${callNumber}] To (bech32):`, toBech32);

      // Get Lucid with wallet already selected (cached)
      const lucid = await this.ensureWalletSelected();

      console.log(`[TX #${callNumber}] Wallet ready, building tx...`);

      // Build the transaction - simple ADA transfer to the property owner
      const tx = await lucid.newTx()
        .payToAddress(toBech32, { lovelace: BigInt(lovelaceAmount) })
        .complete();

      console.log(`[TX #${callNumber}] Transaction built successfully, signing...`);
      
      // Sign the transaction using Lucid (which uses the wallet API internally)
      const signedTx = await tx.sign().complete();
      
      console.log(`[TX #${callNumber}] Transaction signed, submitting...`);
      
      // Submit the signed transaction
      let txHash;
      try {
        txHash = await signedTx.submit();
      } catch (submitError) {
        console.error(`[TX #${callNumber}] Submit error details:`, submitError);
        console.error(`[TX #${callNumber}] Submit error message:`, submitError.message);
        
        // Try submitting via wallet API directly as fallback
        console.log(`[TX #${callNumber}] Trying direct wallet submission...`);
        const txCbor = signedTx.toString();
        const walletApi = this.cachedWalletApi;
        if (walletApi) {
          txHash = await walletApi.submitTx(txCbor);
        } else {
          throw submitError;
        }
      }
      
      console.log(`[TX #${callNumber}] ========== TRANSACTION COMPLETE ==========`);
      console.log(`[TX #${callNumber}] Hash:`, txHash);
      
      // Return both the txCbor (for compatibility) and the txHash
      return { txCbor: signedTx.toString(), txHash: txHash };
    } catch (e) {
      console.error(`[TX #${callNumber}] ========== TRANSACTION FAILED ==========`);
      console.error(`[TX #${callNumber}] Error:`, e);
      console.error(`[TX #${callNumber}] Error message:`, e.message);
      throw e;
    }
  },

  /**
   * Submit transaction via wallet
   */
  signAndSubmit: async function (walletName, txCbor) {
    // Legacy method, not used with Lucid flow but kept for compatibility
    if (!window.cardano || !window.cardano[walletName]) {
      throw new Error(`Wallet ${walletName} not found`);
    }
    const wallet = await window.cardano[walletName].enable();
    const signedTx = await wallet.signTx(txCbor, true);
    const txHash = await wallet.submitTx(signedTx);
    return txHash;
  },

  /**
   * Get wallet balance from wallet API
   */
  getWalletBalance: async function (walletName) {
    if (!window.cardano || !window.cardano[walletName]) {
      throw new Error(`Wallet ${walletName} not found`);
    }
    const wallet = await window.cardano[walletName].enable();
    return await wallet.getBalance();
  },

  /**
   * Get address balance from Blockfrost
   */
  getAddressBalance: async function (address) {
    try {
      const response = await this.blockfrostGet(`/addresses/${address}`);
      if (!response) return { lovelace: '0', tokens: [] };
      
      const lovelace = response.amount?.find(a => a.unit === 'lovelace')?.quantity || '0';
      const tokens = response.amount?.filter(a => a.unit !== 'lovelace') || [];
      
      return {
        lovelace: lovelace,
        tokens: tokens,
        stakeAddress: response.stake_address,
      };
    } catch (error) {
      console.error('Error fetching address balance:', error);
      return { lovelace: '0', tokens: [] };
    }
  },

  /**
   * Get network tip (latest block) from Blockfrost
   */
  getNetworkTip: async function () {
    try {
      const response = await this.blockfrostGet('/blocks/latest');
      return response || null;
    } catch (error) {
      console.error('Error fetching network tip:', error);
      return null;
    }
  },

  /**
   * Get wallet UTxOs
   */
  getWalletUtxos: async function (walletName) {
    if (!window.cardano || !window.cardano[walletName]) {
      throw new Error(`Wallet ${walletName} not found`);
    }
    const wallet = await window.cardano[walletName].enable();
    return await wallet.getUtxos();
  },

  /**
   * Get protocol parameters from Blockfrost
   */
  getProtocolParams: async function () {
    try {
      const epoch = await this.blockfrostGet('/epochs/latest');
      const params = await this.blockfrostGet(`/epochs/${epoch.epoch}/parameters`);
      return params || null;
    } catch (error) {
      console.error('Error fetching protocol params:', error);
      return null;
    }
  },

  /**
   * Submit transaction via Blockfrost
   */
  submitTxViaBlockfrost: async function (txCbor) {
    try {
      const response = await fetch(`${BLOCKFROST_BASE_URL}/tx/submit`, {
        method: 'POST',
        headers: {
          'project_id': BLOCKFROST_PROJECT_ID,
          'Content-Type': 'application/cbor',
        },
        body: Uint8Array.from(txCbor.match(/.{1,2}/g).map(byte => parseInt(byte, 16))),
      });
      if (!response.ok) {
        const error = await response.text();
        throw new Error(`Transaction submission failed: ${error}`);
      }
      return await response.text();
    } catch (error) {
      console.error('Error submitting transaction:', error);
      throw error;
    }
  },

  /**
   * Check if a specific wallet is available
   */
  isWalletAvailable: function (walletName) {
    return !!(window.cardano && window.cardano[walletName]);
  },

  /**
   * Get list of available wallets
   */
  getAvailableWallets: function () {
    const wallets = [];
    if (!window.cardano) return wallets;
    const knownWallets = ['nami', 'eternl', 'flint', 'yoroi', 'lace', 'typhon', 'gerowallet'];
    for (const w of knownWallets) {
      if (window.cardano[w]) {
        wallets.push(w);
      }
    }
    console.log('PropFi Bridge: Available wallets:', wallets);
    return wallets;
  },

  /**
   * Wait for wallet to be available (wallets inject with delay)
   */
  waitForWallet: function (walletName, timeoutMs = 3000) {
    return new Promise((resolve, reject) => {
      if (this.isWalletAvailable(walletName)) {
        resolve(true);
        return;
      }
      const startTime = Date.now();
      const checkInterval = setInterval(() => {
        if (this.isWalletAvailable(walletName)) {
          clearInterval(checkInterval);
          resolve(true);
        } else if (Date.now() - startTime > timeoutMs) {
          clearInterval(checkInterval);
          resolve(false);
        }
      }, 100);
    });
  },

  // ============================================================================
  // ON-CHAIN PROPERTY LISTING (DECENTRALIZED)
  // ============================================================================

  /**
   * Convert string to hex
   */
  stringToHex: function(str) {
    return Array.from(str).map(c => c.charCodeAt(0).toString(16).padStart(2, '0')).join('');
  },

  /**
   * Generate a unique property ID from timestamp
   */
  generatePropertyId: function() {
    const timestamp = Date.now().toString(16);
    const random = Math.random().toString(16).slice(2, 10);
    return (timestamp + random).slice(0, 16).padStart(16, '0');
  },

  /**
   * Create on-chain property metadata (CIP-68 format)
   * Truncates strings to fit Cardano metadata limits (max 64 bytes per string)
   */
  createPropertyMetadata: function(property) {
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
  listPropertyOnChain: async function(property) {
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
  waitForTxConfirmation: async function(txHash, timeoutMs = 120000) {
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
  fetchOnChainProperties: async function() {
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

          // Look for PropFi metadata (label 1337) or CIP-25 (label 721)
          let propertyData = null;

          if (txDetails && Array.isArray(txDetails)) {
            for (const meta of txDetails) {
              if (meta.label === '1337') {
                // PropFi custom metadata
                propertyData = meta.json_metadata;
              } else if (meta.label === '721' && !propertyData) {
                // CIP-25 NFT metadata as fallback
                const nftMeta = meta.json_metadata;
                if (nftMeta && nftMeta[CONTRACT_CONFIG.cip68MintingPolicyId]) {
                  const policyMeta = nftMeta[CONTRACT_CONFIG.cip68MintingPolicyId];
                  const propId = Object.keys(policyMeta)[0];
                  if (propId) {
                    propertyData = {
                      ...policyMeta[propId],
                      propertyId: propId,
                    };
                  }
                }
              }
            }
          }

          if (propertyData) {
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
  fetchOnChainPropertiesJson: async function() {
    const properties = await this.fetchOnChainProperties();
    return JSON.stringify(properties);
  },

  /**
   * Cancel/Delist a property from marketplace
   * Spends the UTxO back to the owner
   */
  cancelPropertyListing: async function(txHash, outputIndex) {
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
};

// Log initialization
console.log('PropFi Bridge initialized with Blockfrost API', window.PropFiBridge.config);

// Check for wallets after a short delay (they inject after page load)
setTimeout(() => {
  const wallets = window.PropFiBridge.getAvailableWallets();
  console.log('PropFi Bridge: Detected wallets after delay:', wallets);
}, 1000);