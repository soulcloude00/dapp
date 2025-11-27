/**
 * PropFi Contract Deployment Script
 * Deploys validators to Cardano Preprod testnet
 */

import * as fs from 'fs';
import * as path from 'path';

// Contract configuration
export interface ContractConfig {
  fractionalizeScriptHash: string;
  fractionalizeScriptAddress: string;
  cip68MintingPolicyId: string;
  marketplaceScriptHash: string;
  marketplaceScriptAddress: string;
}

// Network configuration
const NETWORK = 'preprod';
const NETWORK_ID = 0; // 0 for testnet, 1 for mainnet

// Address prefix for testnet
const SCRIPT_ADDRESS_PREFIX = 'addr_test1'; // Preprod/Preview

/**
 * Load compiled contracts from plutus.json
 */
export function loadCompiledContracts(): any {
  const plutusJsonPath = path.join(__dirname, '../../contracts/plutus.json');
  
  if (!fs.existsSync(plutusJsonPath)) {
    throw new Error('plutus.json not found. Run `aiken build` first.');
  }

  const plutusJson = JSON.parse(fs.readFileSync(plutusJsonPath, 'utf-8'));
  return plutusJson;
}

/**
 * Extract validator info from plutus.json
 */
export function getValidatorInfo(plutusJson: any, validatorTitle: string): { hash: string; compiledCode: string } | null {
  const validator = plutusJson.validators.find((v: any) => v.title === validatorTitle);
  
  if (!validator) {
    console.error(`Validator "${validatorTitle}" not found in plutus.json`);
    return null;
  }

  return {
    hash: validator.hash,
    compiledCode: validator.compiledCode,
  };
}

/**
 * Convert script hash to bech32 address
 * Note: This is a simplified version - in production use a proper library
 */
export function scriptHashToAddress(scriptHash: string, networkId: number = 0): string {
  // For proper address encoding, use @meshsdk/core or cardano-serialization-lib
  // This is a placeholder that shows the format
  
  // Script addresses have payment credential type 0x71 (script hash, no staking)
  // For testnet: addr_test1 prefix
  // For mainnet: addr1 prefix
  
  console.log(`Script Hash: ${scriptHash}`);
  console.log(`Note: Use MeshJS or cardano-serialization-lib to generate proper bech32 address`);
  
  return `addr_test1_script_${scriptHash.slice(0, 20)}...`;
}

/**
 * Generate contract configuration for the app
 */
export function generateContractConfig(): ContractConfig {
  const plutusJson = loadCompiledContracts();
  
  // Get validator hashes
  const fractionalize = getValidatorInfo(plutusJson, 'fractionalize.fractionalize.spend');
  const cip68Minting = getValidatorInfo(plutusJson, 'fractionalize.cip68_minting.mint');
  const marketplace = getValidatorInfo(plutusJson, 'fractionalize.marketplace.spend');

  if (!fractionalize || !cip68Minting || !marketplace) {
    throw new Error('Could not find all required validators in plutus.json');
  }

  const config: ContractConfig = {
    fractionalizeScriptHash: fractionalize.hash,
    fractionalizeScriptAddress: scriptHashToAddress(fractionalize.hash, NETWORK_ID),
    cip68MintingPolicyId: cip68Minting.hash,
    marketplaceScriptHash: marketplace.hash,
    marketplaceScriptAddress: scriptHashToAddress(marketplace.hash, NETWORK_ID),
  };

  return config;
}

/**
 * Export contract config to JSON file for frontend/offchain use
 */
export function exportContractConfig(outputPath: string): void {
  const config = generateContractConfig();
  
  const output = {
    network: NETWORK,
    networkId: NETWORK_ID,
    contracts: config,
    generatedAt: new Date().toISOString(),
    note: 'Script addresses need to be generated using MeshJS. Use the script hashes with resolveScriptAddress().',
  };

  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));
  console.log(`Contract config exported to: ${outputPath}`);
}

/**
 * Display contract information
 */
export function displayContractInfo(): void {
  console.log('\n=== PropFi Contract Information ===\n');
  
  const plutusJson = loadCompiledContracts();
  
  console.log(`Plutus Version: ${plutusJson.preamble.plutusVersion}`);
  console.log(`Compiler: ${plutusJson.preamble.compiler.name} ${plutusJson.preamble.compiler.version}`);
  console.log(`Network: ${NETWORK}\n`);

  console.log('Validators:');
  console.log('-'.repeat(60));
  
  for (const validator of plutusJson.validators) {
    console.log(`\nTitle: ${validator.title}`);
    console.log(`Hash:  ${validator.hash}`);
    console.log(`Size:  ${validator.compiledCode.length / 2} bytes`);
  }

  console.log('\n' + '-'.repeat(60));
  
  const config = generateContractConfig();
  console.log('\nContract Hashes for Integration:');
  console.log(`  Fractionalize Script Hash: ${config.fractionalizeScriptHash}`);
  console.log(`  CIP-68 Minting Policy ID:  ${config.cip68MintingPolicyId}`);
  console.log(`  Marketplace Script Hash:   ${config.marketplaceScriptHash}`);
  
  console.log('\n=== End Contract Information ===\n');
}

// Run if executed directly
if (require.main === module) {
  displayContractInfo();
  
  // Export config
  const configPath = path.join(__dirname, '../contract-config.json');
  exportContractConfig(configPath);
}
