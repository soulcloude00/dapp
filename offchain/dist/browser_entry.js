"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const transaction_builder_web_1 = require("./transaction_builder_web");
const hydra_manager_1 = require("./hydra_manager");
// Expose the builder and Hydra manager to the browser window
window.PropFiTransactionBuilder = transaction_builder_web_1.PropFiTransactionBuilder;
window.HydraManager = hydra_manager_1.HydraManager;
window.hydraManager = hydra_manager_1.hydraManager;
console.log('PropFi Offchain SDK loaded with Hydra support');
