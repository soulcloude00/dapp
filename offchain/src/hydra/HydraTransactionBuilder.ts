/**
 * Transaction Builder for Hydra L2 Property Trading
 * Builds Cardano transactions for property fraction trades within Hydra
 */

import {
  MeshTxBuilder,
  MeshWallet,
  Asset,
  UTxO,
  serializePlutusScript,
  resolveScriptHash,
} from '@meshsdk/core';
import { HydraClient, HydraUTxO } from './HydraClient';

// ============================================================================
// Types
// ============================================================================

export interface TradeParams {
  seller: string;
  buyer: string;
  policyId: string;
  assetName: string;
  quantity: number;
  priceLovelace: bigint;
  sellerUtxo: HydraUTxO;
  buyerUtxo: HydraUTxO;
}

export interface TransferParams {
  from: string;
  to: string;
  policyId: string;
  assetName: string;
  quantity: number;
  sourceUtxo: HydraUTxO;
}

export interface CommitParams {
  address: string;
  utxos: UTxO[];
}

// ============================================================================
// Transaction Builder
// ============================================================================

export class HydraTransactionBuilder {
  private hydra: HydraClient;
  private wallet: MeshWallet;

  constructor(hydra: HydraClient, wallet: MeshWallet) {
    this.hydra = hydra;
    this.wallet = wallet;
  }

  /**
   * Build a property fraction trade transaction
   * Seller sends fraction tokens, buyer sends ADA
   */
  async buildTradeTx(params: TradeParams): Promise<string> {
    const {
      seller,
      buyer,
      policyId,
      assetName,
      quantity,
      priceLovelace,
      sellerUtxo,
      buyerUtxo,
    } = params;

    const assetUnit = `${policyId}${assetName}`;
    const asset: Asset = {
      unit: assetUnit,
      quantity: quantity.toString(),
    };

    const txBuilder = new MeshTxBuilder();

    // Input: Seller's UTxO with the fraction tokens
    txBuilder.txIn(
      this.parseUtxoTxHash(sellerUtxo.txIn),
      this.parseUtxoTxIndex(sellerUtxo.txIn)
    );

    // Input: Buyer's UTxO with ADA
    txBuilder.txIn(
      this.parseUtxoTxHash(buyerUtxo.txIn),
      this.parseUtxoTxIndex(buyerUtxo.txIn)
    );

    // Output: Buyer receives fraction tokens with min ADA
    txBuilder.txOut(buyer, [
      { unit: 'lovelace', quantity: '2000000' },
      asset,
    ]);

    // Output: Seller receives ADA payment
    txBuilder.txOut(seller, [
      { unit: 'lovelace', quantity: priceLovelace.toString() },
    ]);

    // Change goes back to buyer (remaining ADA after payment)
    txBuilder.changeAddress(buyer);

    // Build the transaction
    const unsignedTx = await txBuilder.complete();
    
    return unsignedTx;
  }

  /**
   * Build a simple token transfer transaction (within Hydra)
   */
  async buildTransferTx(params: TransferParams): Promise<string> {
    const { from, to, policyId, assetName, quantity, sourceUtxo } = params;

    const assetUnit = `${policyId}${assetName}`;
    const asset: Asset = {
      unit: assetUnit,
      quantity: quantity.toString(),
    };

    const txBuilder = new MeshTxBuilder();

    // Input: Source UTxO
    txBuilder.txIn(
      this.parseUtxoTxHash(sourceUtxo.txIn),
      this.parseUtxoTxIndex(sourceUtxo.txIn)
    );

    // Output: Recipient receives tokens with min ADA
    txBuilder.txOut(to, [
      { unit: 'lovelace', quantity: '2000000' },
      asset,
    ]);

    // Change back to sender
    txBuilder.changeAddress(from);

    const unsignedTx = await txBuilder.complete();
    
    return unsignedTx;
  }

  /**
   * Build ADA transfer transaction (within Hydra)
   */
  async buildAdaTransferTx(
    from: string,
    to: string,
    amountLovelace: bigint,
    sourceUtxo: HydraUTxO
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder();

    txBuilder.txIn(
      this.parseUtxoTxHash(sourceUtxo.txIn),
      this.parseUtxoTxIndex(sourceUtxo.txIn)
    );

    // Output: Recipient receives ADA
    txBuilder.txOut(to, [
      { unit: 'lovelace', quantity: amountLovelace.toString() },
    ]);

    txBuilder.changeAddress(from);

    const unsignedTx = await txBuilder.complete();
    
    return unsignedTx;
  }

  /**
   * Build commit transaction for initial UTxO commitment to Head
   */
  buildCommitUtxoMap(utxos: UTxO[]): Record<string, any> {
    const commitMap: Record<string, any> = {};

    for (const utxo of utxos) {
      const txIn = `${utxo.input.txHash}#${utxo.input.outputIndex}`;
      
      const value: any = {
        lovelace: utxo.output.amount.find((a) => a.unit === 'lovelace')?.quantity || '0',
      };

      // Add assets
      const assets = utxo.output.amount.filter((a) => a.unit !== 'lovelace');
      if (assets.length > 0) {
        value.assets = {};
        for (const asset of assets) {
          value.assets[asset.unit] = asset.quantity;
        }
      }

      commitMap[txIn] = {
        address: utxo.output.address,
        value,
        datum: utxo.output.plutusData,
        datumHash: utxo.output.dataHash,
      };
    }

    return commitMap;
  }

  /**
   * Sign a transaction with the wallet
   */
  async signTx(unsignedTx: string): Promise<string> {
    return await this.wallet.signTx(unsignedTx);
  }

  /**
   * Build and submit a trade in one call
   */
  async executeTradeInHydra(params: TradeParams): Promise<string> {
    // Build the transaction
    const unsignedTx = await this.buildTradeTx(params);

    // Sign it
    const signedTx = await this.signTx(unsignedTx);

    // Submit to Hydra
    const result = await this.hydra.submitTx(signedTx);

    return result.txId;
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  private parseUtxoTxHash(txIn: string): string {
    return txIn.split('#')[0];
  }

  private parseUtxoTxIndex(txIn: string): number {
    return parseInt(txIn.split('#')[1], 10);
  }

  /**
   * Find suitable UTxO for a trade (has enough ADA)
   */
  findPaymentUtxo(address: string, requiredLovelace: bigint): HydraUTxO | undefined {
    const utxos = this.hydra.getUtxosAtAddress(address);
    return utxos.find((utxo) => utxo.value.lovelace >= requiredLovelace);
  }

  /**
   * Find UTxO containing specific tokens
   */
  findTokenUtxo(
    address: string,
    policyId: string,
    assetName: string,
    requiredQuantity: bigint
  ): HydraUTxO | undefined {
    const utxos = this.hydra.getUtxosAtAddress(address);
    const assetId = `${policyId}${assetName}`;

    return utxos.find((utxo) => {
      const assets = utxo.value.assets;
      if (!assets) return false;
      const quantity = assets[assetId];
      return quantity !== undefined && quantity >= requiredQuantity;
    });
  }
}
