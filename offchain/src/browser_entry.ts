import { PropFiTransactionBuilder } from './transaction_builder_web';

// Expose the builder to the browser window
(window as any).PropFiTransactionBuilder = PropFiTransactionBuilder;
console.log('PropFi Offchain SDK loaded');
