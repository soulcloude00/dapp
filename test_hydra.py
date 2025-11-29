#!/usr/bin/env python3
"""Quick Hydra connection test"""
import asyncio
import json

try:
    import websockets
except ImportError:
    print("Installing websockets...")
    import subprocess
    subprocess.run(["pip3", "install", "websockets", "-q"])
    import websockets

async def test_hydra():
    url = "ws://127.0.0.1:4001"
    print(f"🔌 Connecting to {url}...")
    
    try:
        async with websockets.connect(url) as ws:
            print("✅ Connected to Hydra!")
            
            # Wait for Greetings message
            msg = await asyncio.wait_for(ws.recv(), timeout=5)
            data = json.loads(msg)
            
            print(f"\n📨 Received: {data.get('tag', 'unknown')}")
            
            if data.get('tag') == 'Greetings':
                status = data.get('headStatus', {})
                if isinstance(status, dict):
                    status = status.get('tag', 'unknown')
                print(f"   Head Status: {status}")
                print(f"   Snapshot #: {data.get('snapshotNumber', 0)}")
                
                utxos = data.get('utxo', {})
                print(f"   UTxOs in Head: {len(utxos)}")
                
                if utxos:
                    print("\n   UTxO Summary:")
                    for txin, output in list(utxos.items())[:3]:
                        addr = output.get('address', 'unknown')[:30]
                        value = output.get('value', {})
                        lovelace = value.get('lovelace', value) if isinstance(value, dict) else value
                        print(f"     - {txin[:20]}... → {lovelace} lovelace")
            
            print("\n✅ Hydra node is working correctly!")
            
    except asyncio.TimeoutError:
        print("❌ Timeout waiting for response")
    except ConnectionRefusedError:
        print("❌ Connection refused - is Hydra running?")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_hydra())
