/**
 * Quick Hydra Connection Test
 * Run with: npx ts-node test-hydra.ts
 */

const WebSocket = require('ws');

const HYDRA_URL = 'ws://127.0.0.1:4001';

console.log('🧪 Testing Hydra Connection...');
console.log(`   URL: ${HYDRA_URL}`);
console.log('');

const ws = new WebSocket(HYDRA_URL);

ws.on('open', () => {
  console.log('✅ Connected to Hydra node!');
});

ws.on('message', (data: Buffer) => {
  try {
    const message = JSON.parse(data.toString());
    console.log(`📨 Received: ${message.tag}`);
    
    if (message.tag === 'Greetings') {
      console.log('');
      console.log('🤝 Hydra Greetings:');
      console.log(`   Head Status: ${message.headStatus?.tag || message.headStatus || 'Unknown'}`);
      console.log(`   Snapshot #: ${message.snapshotNumber || 0}`);
      console.log(`   Head ID: ${message.headId || 'None'}`);
      console.log(`   UTxOs: ${Object.keys(message.utxo || {}).length}`);
      console.log('');
      
      // If head is idle, we can init
      if (message.headStatus?.tag === 'Idle' || message.headStatus === 'Idle') {
        console.log('💡 Head is idle. You can initialize with:');
        console.log('   ws.send(JSON.stringify({ tag: "Init" }))');
      }
      
      // Close after getting greeting
      setTimeout(() => {
        console.log('');
        console.log('✅ Test complete! Hydra node is working.');
        ws.close();
        process.exit(0);
      }, 1000);
    }
  } catch (e) {
    console.error('Failed to parse message:', e);
  }
});

ws.on('error', (error: Error) => {
  console.error('❌ Connection error:', error.message);
  process.exit(1);
});

ws.on('close', () => {
  console.log('Connection closed');
});

// Timeout after 10 seconds
setTimeout(() => {
  console.error('❌ Timeout - no response from Hydra node');
  process.exit(1);
}, 10000);
