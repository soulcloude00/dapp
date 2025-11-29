const BLOCKFROST_PROJECT_ID = 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe';
const BLOCKFROST_BASE_URL = 'https://cardano-preprod.blockfrost.io/api/v0';

const CONTRACT_CONFIG = {
  marketplaceScriptHash: '4e03e3aacbb838b267ee6dcccdaffebff835a3a8cf51d9870e5a6b2e',
  cip68MintingPolicyId: '7af62086280f10305eec66f17afff08526513d5b41549cb63bd1e4ca',
};

window.PropFiBridge = {
  // Configuration
  config: {
    blockfrostProjectId: BLOCKFROST_PROJECT_ID,
    network: 'Preprod',
    marketplaceScriptHash: CONTRACT_CONFIG.marketplaceScriptHash,
    cip68MintingPolicyId: CONTRACT_CONFIG.cip68MintingPolicyId,
  },

  initLucid: async function () {
    if (this._lucid) return this._lucid;
    const { Lucid, Blockfrost } = await import('https://unpkg.com/lucid-cardano@0.9.5/web/mod.js');
    this._lucid = await Lucid.new(
      new Blockfrost(BLOCKFROST_BASE_URL, BLOCKFROST_PROJECT_ID),
      this.config.network
    );
    return this._lucid;
  },

  // Selected wallet management
  _selectedWallet: null,

  setSelectedWallet: function (walletId) {
    console.log('PropFiBridge: Setting selected wallet to:', walletId);
    this._selectedWallet = walletId;
    this._walletApi = null; // Clear cached API to force reconnection
    localStorage.setItem('selectedWallet', walletId);
  },

  disconnectWallet: function () {
    console.log('PropFiBridge: Disconnecting wallet');
    this._selectedWallet = null;
    this._walletApi = null;
    this._lucid = null;
    localStorage.removeItem('selectedWallet');
  },

  getConnectedWalletName: function () {
    return this._selectedWallet || localStorage.getItem('selectedWallet') || null;
  },

  getWalletApi: async function () {
    const walletName = this._selectedWallet || localStorage.getItem('selectedWallet');
    if (!walletName) {
      throw new Error('No wallet selected');
    }
    if (this._walletApi) return this._walletApi;
    if (window.cardano && window.cardano[walletName]) {
      this._walletApi = await window.cardano[walletName].enable();
      return this._walletApi;
    }
    throw new Error('Wallet not found: ' + walletName);
  },

  /**
   * Get wallet balance in ADA
   */
  getBalance: async function () {
    console.log('PropFiBridge: Getting balance...');
    try {
      const assets = await this.getWalletAssets();
      console.log('PropFiBridge: Balance is', assets.ada, 'ADA');
      return assets.ada;
    } catch (e) {
      console.error('PropFiBridge: Error getting balance:', e);
      return 0;
    }
  },

  /**
   * Helper to call Blockfrost API
   * Returns null for 404 (address not found / no UTxOs) instead of throwing
   */
  blockfrostGet: async function (endpoint) {
    const response = await fetch(`${BLOCKFROST_BASE_URL}${endpoint}`, {
      headers: { 'project_id': BLOCKFROST_PROJECT_ID }
    });
    if (response.status === 404) {
      // 404 means address has no UTxOs or doesn't exist - this is valid, not an error
      console.log('Blockfrost: No data found for', endpoint);
      return null;
    }
    if (!response.ok) {
      throw new Error(`Blockfrost API error: ${response.status}`);
    }
    return response.json();
  },

  /**
   * Get script address from script hash
   */
  getScriptAddress: async function (scriptHash) {
    const lucid = await this.initLucid();
    return lucid.utils.credentialToAddress({
      type: 'Script',
      hash: scriptHash,
    });
  },

  getAvailableWallets: function () {
    const wallets = [];
    if (window.cardano) {
      for (const key in window.cardano) {
        if (window.cardano[key].enable && window.cardano[key].name) {
          wallets.push(key);
        }
      }
    }
    return wallets;
  },

  generatePropertyId: function () {
    return Array.from(crypto.getRandomValues(new Uint8Array(16)))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  },
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

      const walletDetails = lucid.utils.getAddressDetails(walletAddress);
      const sellerPkh = walletDetails.paymentCredential?.hash;
      if (!sellerPkh) throw new Error('Could not extract payment credential from wallet');

      const propertyId = this.generatePropertyId();
      const userTokenName = '000de140' + propertyId;
      const metadata = this.createPropertyMetadata(property);
      const priceInLovelace = BigInt(Math.floor(property.pricePerFraction * 1000000));
      const totalFractions = BigInt(property.totalFractions);

      const marketplaceAddress = lucid.utils.credentialToAddress({
        type: 'Script',
        hash: CONTRACT_CONFIG.marketplaceScriptHash,
      });

      const marketplaceDatum = {
        seller: sellerPkh,
        price: priceInLovelace,
        stablecoinAsset: { policyId: '', assetName: '' },
        fractionAsset: { policyId: CONTRACT_CONFIG.cip68MintingPolicyId, assetName: userTokenName },
        fractionAmount: totalFractions,
        propertyMetadata: metadata,
      };

      const minUtxoAda = 2000000n;
      const txMetadata = {
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
        1337: {
          act: 'list',
          pid: propertyId,
          sell: sellerPkh,
          pri: priceInLovelace.toString().slice(0, 20),
          frac: totalFractions.toString().slice(0, 10),
        }
      };

      const tx = await lucid.newTx()
        .payToAddress(marketplaceAddress, { lovelace: minUtxoAda })
        .attachMetadata(721, txMetadata[721])
        .attachMetadata(1337, txMetadata[1337])
        .complete();

      const signedTx = await tx.sign().complete();
      const txHash = await signedTx.submit();

      console.log('=== listPropertyOnChain SUCCESS ===');
      console.log('Transaction hash:', txHash);

      return {
        txHash: txHash,
        propertyId: propertyId,
        marketplaceAddress: marketplaceAddress,
        datum: marketplaceDatum,
        metadata: metadata,
        confirmed: false,
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
    const pollInterval = 5000;

    console.log(`Polling for tx confirmation: ${txHash}`);

    while (Date.now() - startTime < timeoutMs) {
      try {
        const txInfo = await this.blockfrostGet(`/txs/${txHash}`);
        if (txInfo && txInfo.hash) {
          console.log('Transaction confirmed:', txInfo);
          return true;
        }
      } catch (e) {
        console.log(`TX not yet confirmed, waiting...`);
      }
      await new Promise(resolve => setTimeout(resolve, pollInterval));
    }
    return false;
  },

  /**
   * Fetch on-chain properties from marketplace using transaction metadata
   */
  fetchOnChainProperties: async function () {
    console.log('=== fetchOnChainProperties START ===');
    try {
      const lucid = await this.initLucid();
      const marketplaceAddress = lucid.utils.credentialToAddress({
        type: 'Script',
        hash: CONTRACT_CONFIG.marketplaceScriptHash,
      });

      const utxos = await this.blockfrostGet(`/addresses/${marketplaceAddress}/utxos`);
      if (!utxos || utxos.length === 0) return [];

      const properties = [];
      for (const utxo of utxos) {
        try {
          const txDetails = await this.blockfrostGet(`/txs/${utxo.tx_hash}/metadata`);
          let propFiData = null;
          let cip25Data = null;

          if (txDetails && Array.isArray(txDetails)) {
            for (const meta of txDetails) {
              if (meta.label === '1337') propFiData = meta.json_metadata;
              else if (meta.label === '721') {
                const nftMeta = meta.json_metadata;
                if (nftMeta && nftMeta[CONTRACT_CONFIG.cip68MintingPolicyId]) {
                  const policyMeta = nftMeta[CONTRACT_CONFIG.cip68MintingPolicyId];
                  const propId = Object.keys(policyMeta)[0];
                  if (propId) cip25Data = { ...policyMeta[propId], propertyId: propId };
                }
              }
            }
          }

          const propertyData = { ...propFiData, ...cip25Data };
          if (propertyData && (propFiData || cip25Data)) {
            properties.push({
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
            });
          }
        } catch (err) {
          console.warn('Error fetching metadata for tx:', utxo.tx_hash, err);
        }
      }
      return properties;
    } catch (error) {
      // Don't log as error - this often means the script address has no UTxOs yet
      console.log('fetchOnChainProperties: No on-chain properties found or error:', error.message || error);
      return [];
    }
  },

  fetchOnChainPropertiesJson: async function () {
    const properties = await this.fetchOnChainProperties();
    return JSON.stringify(properties);
  },

  cancelPropertyListing: async function (txHash, outputIndex) {
    console.log('=== cancelPropertyListing START ===');
    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const walletAddress = await lucid.wallet.address();
      const marketplaceAddress = await this.getScriptAddress(CONTRACT_CONFIG.marketplaceScriptHash);

      const utxos = await lucid.utxosAt(marketplaceAddress);
      const targetUtxo = utxos.find(u => u.txHash === txHash && u.outputIndex === outputIndex);

      if (!targetUtxo) throw new Error('UTxO not found at marketplace address');

      const tx = await lucid.newTx()
        .collectFrom([targetUtxo])
        .addSigner(walletAddress)
        .complete();

      const signedTx = await tx.sign().complete();
      const resultTxHash = await signedTx.submit();

      console.log('=== cancelPropertyListing SUCCESS ===');
      return resultTxHash;
    } catch (error) {
      console.error('=== cancelPropertyListing ERROR ===', error);
      throw error;
    }
  },

  /**
   * Build a simple payment transaction (for buying fractions with direct ADA payment)
   */
  buildPaymentTransaction: async function (fromAddress, toAddress, lovelaceAmount) {
    console.log('=== buildPaymentTransaction START ===');
    console.log('From:', fromAddress);
    console.log('To (raw):', toAddress);
    console.log('Amount (lovelace):', lovelaceAmount);

    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const amount = BigInt(lovelaceAmount);
      let recipientAddress = toAddress;

      if (toAddress && !toAddress.startsWith('addr') && /^[0-9a-fA-F]+$/.test(toAddress)) {
        console.log('Converting payment key hash to address...');
        const networkId = lucid.network === 'Mainnet' ? 1 : 0;
        const paymentKeyHash = toAddress.length === 56 ? toAddress : toAddress.slice(0, 56);
        const prefix = networkId === 0 ? '60' : '61';
        const addressHex = prefix + paymentKeyHash;
        const { C } = await import('https://unpkg.com/lucid-cardano@0.9.5/web/mod.js');
        const addressBytes = new Uint8Array(addressHex.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
        const address = C.Address.from_bytes(addressBytes);
        recipientAddress = address.to_bech32(networkId === 0 ? 'addr_test' : 'addr');
      }

      console.log('Building payment transaction to:', recipientAddress);

      const tx = await lucid.newTx()
        .payToAddress(recipientAddress, { lovelace: amount })
        .complete();

      const signedTx = await tx.sign().complete();
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
   * Get wallet assets (ADA and native tokens)
   */
  getWalletAssets: async function () {
    console.log('=== getWalletAssets START ===');
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
            if (asset === 'lovelace') lovelace += BigInt(amount);
            else {
              if (!tokens[asset]) tokens[asset] = 0n;
              tokens[asset] += BigInt(amount);
            }
          }
        }
      }

      return {
        ada: Number(lovelace) / 1000000,
        lovelace: lovelace.toString(),
        tokens: Object.fromEntries(Object.entries(tokens).map(([k, v]) => [k, v.toString()])),
        utxoCount: utxos.length,
      };
    } catch (e) {
      console.error('Error fetching wallet assets:', e);
      return { ada: 0, lovelace: '0', tokens: {}, utxoCount: 0 };
    }
  },

  getWalletAssetsJson: async function () {
    const assets = await this.getWalletAssets();
    return JSON.stringify(assets);
  },

  PURCHASE_METADATA_LABEL: 8888,

  buildPaymentWithMetadata: async function (toAddress, lovelaceAmount, purchaseData) {
    console.log('=== buildPaymentWithMetadata START ===');
    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const amount = BigInt(lovelaceAmount);
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

      // Cardano metadata has a 64 byte limit per string
      // Wallet address can be derived from tx inputs, so we just store a hash/prefix
      const walletPrefix = (purchaseData.buyerWallet || '').substring(0, 40);
      
      const metadata = {
        [this.PURCHASE_METADATA_LABEL]: {
          app: "crestadel",
          type: "purchase",
          pid: (purchaseData.propertyId || '').substring(0, 32),
          pname: (purchaseData.propertyName || '').substring(0, 50),
          frac: purchaseData.fractions,
          ada: purchaseData.priceAda,
          buyer: {
            n: (purchaseData.buyerName || 'Anonymous').substring(0, 50),
            e: (purchaseData.buyerEmail || '').substring(0, 50),
            p: (purchaseData.buyerPhone || '').substring(0, 20),
            w: walletPrefix  // Just store prefix, full address in tx inputs
          },
          ts: Date.now(),
          v: 2
        }
      };

      const tx = await lucid.newTx()
        .payToAddress(recipientAddress, { lovelace: amount })
        .attachMetadata(this.PURCHASE_METADATA_LABEL, metadata[this.PURCHASE_METADATA_LABEL])
        .complete();

      const signedTx = await tx.sign().complete();
      const txHash = await signedTx.submit();

      console.log('=== buildPaymentWithMetadata SUCCESS ===');
      return { txHash: txHash };
    } catch (error) {
      console.error('=== buildPaymentWithMetadata ERROR ===', error);
      throw error;
    }
  },

  fetchUserPurchases: async function () {
    console.log('=== fetchUserPurchases START ===');
    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);

      const address = await lucid.wallet.address();
      const txsResponse = await fetch(
        `${BLOCKFROST_BASE_URL}/addresses/${address}/transactions?order=desc`,
        { headers: { 'project_id': BLOCKFROST_PROJECT_ID } }
      );

      if (!txsResponse.ok) return [];
      const transactions = await txsResponse.json();
      const purchases = [];

      for (const tx of transactions.slice(0, 50)) {
        try {
          const metadataResponse = await fetch(
            `${BLOCKFROST_BASE_URL}/txs/${tx.tx_hash}/metadata`,
            { headers: { 'project_id': BLOCKFROST_PROJECT_ID } }
          );

          if (metadataResponse.ok) {
            const metadata = await metadataResponse.json();
            console.log(`TX ${tx.tx_hash}: metadata labels =`, metadata.map(m => m.label));
            const purchaseMeta = metadata.find(m => m.label === this.PURCHASE_METADATA_LABEL.toString());
            if (purchaseMeta) {
              const data = purchaseMeta.json_metadata;
              console.log(`TX ${tx.tx_hash}: purchase metadata =`, JSON.stringify(data));
              // Handle both old (long names) and new (short names) format
              const purchase = {
                txHash: tx.tx_hash,
                timestamp: data.ts || data.timestamp,
                propertyId: data.pid || data.propertyId || '',
                propertyName: data.pname || data.propertyName || '',
                fractions: data.frac || data.fractions || 0,
                priceAda: data.ada || data.priceAda || 0,
                buyer: data.buyer ? {
                  name: data.buyer.n || data.buyer.name || 'Anonymous',
                  email: data.buyer.e || data.buyer.email || '',
                  phone: data.buyer.p || data.buyer.phone || '',
                  wallet: data.buyer.w || data.buyer.wallet || ''
                } : { name: 'Anonymous', email: '', phone: '', wallet: '' }
              };
              console.log(`Parsed purchase:`, purchase);
              purchases.push(purchase);
            }
          }
        } catch (e) { }
      }
      return purchases;
    } catch (error) {
      console.error('Error fetching user purchases:', error);
      return [];
    }
  },

  fetchUserPurchasesJson: async function () {
    const purchases = await this.fetchUserPurchases();
    return JSON.stringify(purchases);
  },

  _convertHydraUtxosToLucid: function (hydraUtxos) {
    let utxoList = Array.isArray(hydraUtxos) ? hydraUtxos : Object.entries(hydraUtxos).map(([key, value]) => {
      value.txIn = key;
      return value;
    });

    return utxoList.map(u => {
      let txHash, outputIndex;
      if (u.txIn) [txHash, outputIndex] = u.txIn.split('#');
      else { txHash = u.txHash; outputIndex = u.outputIndex; }

      const assets = {};
      if (u.value) {
        if (typeof u.value === 'number' || typeof u.value === 'string' || typeof u.value === 'bigint') {
          assets['lovelace'] = BigInt(u.value);
        } else {
          if (u.value.lovelace !== undefined) assets['lovelace'] = BigInt(u.value.lovelace);
          if (u.value.coin !== undefined) assets['lovelace'] = BigInt(u.value.coin);
          if (u.value.assets) {
            for (const [key, val] of Object.entries(u.value.assets)) assets[key] = BigInt(val);
          }
        }
      }

      return {
        txHash,
        outputIndex: parseInt(outputIndex),
        address: u.address,
        assets,
        datumHash: u.datumHash || null,
        datum: u.datum || u.inlineDatum || null,
      };
    });
  },

  buildHydraTx: async function (hydraUtxosJson, toAddress, lovelaceAmount, assetId, assetAmount) {
    console.log('=== buildHydraTx START ===');
    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);
      const myAddress = await lucid.wallet.address();

      const allUtxos = JSON.parse(hydraUtxosJson);
      const lucidUtxos = this._convertHydraUtxosToLucid(allUtxos);
      const myUtxos = lucidUtxos.filter(u => u.address === myAddress);

      if (myUtxos.length === 0) throw new Error("No UTxOs found in Hydra Head for this wallet");

      const amount = BigInt(lovelaceAmount);
      const assets = { lovelace: amount };
      if (assetId && assetAmount) assets[assetId] = BigInt(assetAmount);

      const tx = lucid.newTx().collectFrom(myUtxos).payToAddress(toAddress, assets);
      const completedTx = await tx.complete();
      const signedTx = await completedTx.sign().complete();
      return signedTx.toCBOR();
    } catch (error) {
      console.error('=== buildHydraTx ERROR ===', error);
      throw error;
    }
  },

  initPeerConnect: async function () {
    try {
      await new Promise(resolve => setTimeout(resolve, 500));
      return "web+cardano://connect?key=mock_p2p_key&name=PropFi";
    } catch (error) {
      console.error('Error initializing Peer Connect:', error);
      return null;
    }
  },

  waitForMobileConnection: async function () {
    try {
      await new Promise(resolve => setTimeout(resolve, 3000));
      return true;
    } catch (error) {
      console.error('Error waiting for mobile connection:', error);
      return false;
    }
  },

  getWalletUtxosForHydra: async function () {
    console.log('=== getWalletUtxosForHydra START ===');
    try {
      const lucid = await this.initLucid();
      const walletApi = await this.getWalletApi();
      lucid.selectWallet(walletApi);
      const utxos = await lucid.wallet.getUtxos();
      const hydraUtxos = {};

      for (const u of utxos) {
        const txIn = `${u.txHash}#${u.outputIndex}`;
        const value = { lovelace: Number(u.assets.lovelace) };
        const nativeAssets = {};
        let hasNative = false;
        for (const [key, val] of Object.entries(u.assets)) {
          if (key !== 'lovelace') {
            nativeAssets[key] = Number(val);
            hasNative = true;
          }
        }
        if (hasNative) value.assets = nativeAssets;

        hydraUtxos[txIn] = {
          address: u.address,
          value: value,
          datum: u.datum || null,
          datumHash: u.datumHash || null,
          inlineDatum: u.inlineDatum || null
        };
      }
      return JSON.stringify(hydraUtxos);
    } catch (error) {
      console.error('Error getting wallet UTxOs for Hydra:', error);
      return '{}';
    }
  }
};

console.log('PropFi Bridge initialized with Blockfrost API', window.PropFiBridge.config);

setTimeout(() => {
  const wallets = window.PropFiBridge.getAvailableWallets();
  console.log('PropFi Bridge: Detected wallets after delay:', wallets);
}, 1000);