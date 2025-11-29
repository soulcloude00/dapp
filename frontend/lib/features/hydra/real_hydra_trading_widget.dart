import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/hydra_trading_service.dart';

/// Real Hydra Trading Dashboard Widget
/// Connects to actual Hydra node for instant property trades
class RealHydraTradingWidget extends StatefulWidget {
  const RealHydraTradingWidget({super.key});

  @override
  State<RealHydraTradingWidget> createState() => _RealHydraTradingWidgetState();
}

class _RealHydraTradingWidgetState extends State<RealHydraTradingWidget> {
  final TextEditingController _urlController = TextEditingController(
    text: 'ws://localhost:4001',
  );
  bool _isConnecting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    // Use global provider
    return Consumer<HydraTradingService>(
      builder: (context, service, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(service),
              const Divider(height: 1),
              Expanded(
                child: service.isConnected
                    ? _buildTradingContent(service)
                    : _buildConnectionPanel(service),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(HydraTradingService service) {
    final state = service.state;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: state.isOpen
              ? [Colors.green.shade800, Colors.green.shade600]
              : state.isConnected
              ? [Colors.blue.shade800, Colors.blue.shade600]
              : [Colors.grey.shade800, Colors.grey.shade600],
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isOpen ? Icons.bolt : Icons.water_drop,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hydra L2 Trading',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  state.isOpen
                      ? 'Head Open • Instant Trades Enabled'
                      : state.isConnected
                      ? 'Connected • Status: ${state.status}'
                      : 'Disconnected',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildStatusBadge(state),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(HydraHeadState state) {
    Color color;
    String text;
    IconData icon;

    switch (state.status) {
      case 'Open':
        color = Colors.green;
        text = 'LIVE';
        icon = Icons.bolt;
        break;
      case 'Initializing':
        color = Colors.orange;
        text = 'INIT';
        icon = Icons.hourglass_top;
        break;
      case 'Closed':
        color = Colors.grey;
        text = 'CLOSED';
        icon = Icons.lock;
        break;
      default:
        color = state.isConnected ? Colors.blue : Colors.grey;
        text = state.isConnected ? 'IDLE' : 'OFFLINE';
        icon = state.isConnected ? Icons.check_circle : Icons.cloud_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel(HydraTradingService service) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 64,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Connect to Hydra Node',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your Hydra node WebSocket URL to enable instant trading',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Hydra Node URL',
              hintText: 'ws://localhost:4001',
              prefixIcon: const Icon(Icons.link),
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConnecting ? null : () => _connect(service),
              icon: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.power),
              label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingContent(HydraTradingService service) {
    return Column(
      children: [
        // Stats bar
        _buildStatsBar(service),
        const Divider(height: 1),
        // Main content
        Expanded(
          child: Row(
            children: [
              // Left: Head controls
              Expanded(flex: 1, child: _buildHeadControls(service)),
              const VerticalDivider(width: 1),
              // Right: Trading panel
              Expanded(flex: 2, child: _buildTradingPanel(service)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(HydraTradingService service) {
    final stats = service.state.stats;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Trades', stats.totalTrades.toString()),
          _buildStat('TPS', stats.currentTps.toStringAsFixed(1)),
          _buildStat('Peak TPS', stats.peakTps.toStringAsFixed(1)),
          _buildStat(
            'Avg Latency',
            '${stats.averageLatencyMs.toStringAsFixed(0)}ms',
          ),
          _buildStat('Snapshot', '#${service.state.snapshotNumber}'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildHeadControls(HydraTradingService service) {
    final state = service.state;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Head Controls', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // Head ID
          if (state.headId != null) ...[
            _buildInfoRow('Head ID', state.headId!.substring(0, 16) + '...'),
            const SizedBox(height: 8),
          ],

          _buildInfoRow('Status', state.status),
          _buildInfoRow('UTxOs', state.utxoCount.toString()),
          _buildInfoRow('Parties', state.parties.length.toString()),

          const Spacer(),

          if (state.status == 'Initializing') ...[
            ElevatedButton.icon(
              onPressed: () => _showCommitDialog(context, service),
              icon: const Icon(Icons.upload),
              label: const Text('Commit Funds'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => service.abort(),
              icon: const Icon(Icons.cancel),
              label: const Text('Abort'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ] else if (!state.isOpen) ...[
            ElevatedButton.icon(
              onPressed: () => service.initHead(),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Initialize Head'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => service.closeHead(),
              icon: const Icon(Icons.stop),
              label: const Text('Close Head'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => service.disconnect(),
            icon: const Icon(Icons.power_off),
            label: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTradingPanel(HydraTradingService service) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Fractions'),
              Tab(text: 'Recent Trades'),
              Tab(text: 'Messages'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFractionsTab(service),
                _buildTradesTab(service),
                _buildMessagesTab(service),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFractionsTab(HydraTradingService service) {
    final fractions = service.availableFractions;

    if (fractions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No property fractions in Head'),
            Text(
              'Commit UTxOs to start trading',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: fractions.length,
      itemBuilder: (context, index) {
        final fraction = fractions[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.home_work)),
            title: Text('Property ${fraction.propertyId.substring(0, 8)}...'),
            subtitle: Text(
              'Qty: ${fraction.quantity} • ${fraction.ownerAddress.substring(0, 20)}...',
            ),
            trailing: const Icon(Icons.swap_horiz),
            onTap: () => _showTradeDialog(service, fraction),
          ),
        );
      },
    );
  }

  Widget _buildTradesTab(HydraTradingService service) {
    final trades = service.recentTrades;

    if (trades.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No trades yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        final isConfirmed = trade.status == 'confirmed';

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isConfirmed ? Colors.green : Colors.orange,
              child: Icon(
                isConfirmed ? Icons.check : Icons.hourglass_top,
                color: Colors.white,
              ),
            ),
            title: Text(trade.orderId),
            subtitle: Text(
              '${trade.quantity} fractions @ ${trade.pricePerUnit} lovelace',
            ),
            trailing: Text(
              trade.status.toUpperCase(),
              style: TextStyle(
                color: isConfirmed ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab(HydraTradingService service) {
    final messages = service.messageHistory;

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[messages.length - 1 - index];
        final tag = msg['tag'] ?? 'Unknown';

        // Use localTimestamp (int) or fallback to parsing timestamp string
        String timeStr = '';
        try {
          final localTs = msg['localTimestamp'];
          if (localTs is int) {
            timeStr = DateTime.fromMillisecondsSinceEpoch(
              localTs,
            ).toString().substring(11, 19);
          } else {
            // Fallback: try to parse Hydra's ISO timestamp string
            final hydraTs = msg['timestamp'];
            if (hydraTs is String && hydraTs.isNotEmpty) {
              timeStr = DateTime.parse(
                hydraTs,
              ).toLocal().toString().substring(11, 19);
            }
          }
        } catch (_) {
          timeStr = '--:--:--';
        }

        return Card(
          child: ListTile(
            dense: true,
            leading: _getMessageIcon(tag),
            title: Text(tag),
            subtitle: Text(timeStr),
          ),
        );
      },
    );
  }

  Widget _getMessageIcon(String tag) {
    IconData icon;
    Color color;

    switch (tag) {
      case 'Greetings':
        icon = Icons.waving_hand;
        color = Colors.blue;
        break;
      case 'HeadIsOpen':
        icon = Icons.lock_open;
        color = Colors.green;
        break;
      case 'TxValid':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'TxInvalid':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'SnapshotConfirmed':
        icon = Icons.photo_camera;
        color = Colors.purple;
        break;
      default:
        icon = Icons.message;
        color = Colors.grey;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Future<void> _connect(HydraTradingService service) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      await service.connect(_urlController.text);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _showTradeDialog(
    HydraTradingService service,
    HydraFraction fraction,
  ) async {
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: '10');
    final recipientController = TextEditingController();
    bool isBuying = true;
    bool isBuilding = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Trade ${fraction.propertyId.substring(0, 8)}...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Buy'),
                      selected: isBuying,
                      onSelected: (v) => setState(() => isBuying = true),
                      selectedColor: Colors.green.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Sell'),
                      selected: !isBuying,
                      onSelected: (v) => setState(() => isBuying = false),
                      selectedColor: Colors.red.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (ADA)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              if (!isBuying) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Address',
                    border: OutlineInputBorder(),
                    hintText: 'addr_test...',
                  ),
                ),
              ],
              if (isBuilding) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                const Text(
                  'Building & Signing Transaction...',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isBuilding
                  ? null
                  : () async {
                      final qty = int.tryParse(quantityController.text);
                      final price = double.tryParse(priceController.text);

                      if (qty != null && price != null) {
                        setState(() => isBuilding = true);

                        try {
                          final toAddress = isBuying
                              ? fraction.ownerAddress
                              : recipientController.text;

                          if (toAddress.isEmpty) {
                            throw Exception('Recipient address required');
                          }

                          final cbor = await service.buildTradeTx(
                            toAddress: toAddress,
                            lovelaceAmount: isBuying
                                ? BigInt.from(price * 1000000)
                                : BigInt.from(2000000),
                            assetId: isBuying ? null : fraction.fractionId,
                            assetAmount: isBuying ? null : BigInt.from(qty),
                          );

                          await service.submitTrade(
                            propertyId: fraction.propertyId,
                            policyId: fraction.policyId,
                            assetName: fraction.assetName,
                            seller: isBuying ? fraction.ownerAddress : 'Me',
                            buyer: isBuying ? 'Me' : toAddress,
                            quantity: BigInt.from(qty),
                            pricePerUnit: BigInt.from(price * 1000000),
                            txCborHex: cbor,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trade submitted successfully!'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => isBuilding = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              child: const Text('Submit Trade'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCommitDialog(
    BuildContext context,
    HydraTradingService service,
  ) async {
    // Show loading while fetching UTxOs
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final utxos = await service.getWalletUtxos();

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Commit Funds to Hydra Head'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: utxos.isEmpty
                ? const Center(
                    child: Text('No UTxOs found in connected wallet.'),
                  )
                : ListView.builder(
                    itemCount: utxos.length,
                    itemBuilder: (context, index) {
                      final txIn = utxos.keys.elementAt(index);
                      final output = utxos[txIn];
                      final value = output['value'];
                      final lovelace = value is Map ? value['lovelace'] : value;
                      final assets = value is Map ? value['assets'] : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(txIn.substring(0, 20) + '...'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ADA: ${(lovelace ?? 0) / 1000000}'),
                              if (assets != null)
                                Text('Assets: ${(assets as Map).length}'),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              // Commit this single UTxO
                              // Hydra commit expects { "txIn": output } map
                              final commitMap = {txIn: output};
                              try {
                                await service.commitUtxo(commitMap);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Commit submitted!'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Commit'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching UTxOs: $e')));
      }
    }
  }
}
