import { PropFiTransactionBuilder } from './transaction_builder_web';
import { HydraManager, hydraManager } from './hydra_manager';

// Expose the builder and Hydra manager to the browser window
(window as any).PropFiTransactionBuilder = PropFiTransactionBuilder;
(window as any).HydraManager = HydraManager;
(window as any).hydraManager = hydraManager;
console.log('PropFi Offchain SDK loaded with Hydra support');
