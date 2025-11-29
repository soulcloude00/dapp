"use strict";
/**
 * PropFi Contract Deployment Script
 * Deploys validators to Cardano Preprod testnet
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadCompiledContracts = loadCompiledContracts;
exports.getValidatorInfo = getValidatorInfo;
exports.scriptHashToAddress = scriptHashToAddress;
exports.generateContractConfig = generateContractConfig;
exports.exportContractConfig = exportContractConfig;
exports.displayContractInfo = displayContractInfo;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
// Network configuration
const NETWORK = 'preprod';
const NETWORK_ID = 0; // 0 for testnet, 1 for mainnet
// Address prefix for testnet
const SCRIPT_ADDRESS_PREFIX = 'addr_test1'; // Preprod/Preview
/**
 * Load compiled contracts from plutus.json
 */
function loadCompiledContracts() {
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
function getValidatorInfo(plutusJson, validatorTitle) {
    const validator = plutusJson.validators.find((v) => v.title === validatorTitle);
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
function scriptHashToAddress(scriptHash, networkId = 0) {
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
function generateContractConfig() {
    const plutusJson = loadCompiledContracts();
    // Get validator hashes
    const fractionalize = getValidatorInfo(plutusJson, 'fractionalize.fractionalize.spend');
    const cip68Minting = getValidatorInfo(plutusJson, 'fractionalize.cip68_minting.mint');
    const marketplace = getValidatorInfo(plutusJson, 'fractionalize.marketplace.spend');
    if (!fractionalize || !cip68Minting || !marketplace) {
        throw new Error('Could not find all required validators in plutus.json');
    }
    const config = {
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
function exportContractConfig(outputPath) {
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
function displayContractInfo() {
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
