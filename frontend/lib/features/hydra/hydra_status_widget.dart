import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/hydra_service.dart';

/// Widget showing Hydra connection status and controls
class HydraStatusWidget extends StatefulWidget {
  final bool compact;
  
  const HydraStatusWidget({
    Key? key,
    this.compact = false,
  }) : super(key: key);

  @override
  State<HydraStatusWidget> createState() => _HydraStatusWidgetState();
}

class _HydraStatusWidgetState extends State<HydraStatusWidget> {
  final TextEditingController _urlController = TextEditingController(
    text: 'ws://localhost:4001',
  );

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Color _getStatusColor(HydraStatus status) {
    switch (status) {
      case HydraStatus.idle:
        return Colors.grey;
      case HydraStatus.initializing:
        return Colors.orange;
      case HydraStatus.open:
        return Colors.green;
      case HydraStatus.closed:
        return Colors.red;
      case HydraStatus.finalized:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(HydraStatus status) {
    switch (status) {
      case HydraStatus.idle:
        return 'Idle';
      case HydraStatus.initializing:
        return 'Initializing...';
      case HydraStatus.open:
        return 'Open (Active)';
      case HydraStatus.closed:
        return 'Closed';
      case HydraStatus.finalized:
        return 'Finalized';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(HydraStatus status) {
    switch (status) {
      case HydraStatus.idle:
        return Icons.power_settings_new;
      case HydraStatus.initializing:
        return Icons.hourglass_bottom;
      case HydraStatus.open:
        return Icons.check_circle;
      case HydraStatus.closed:
        return Icons.cancel;
      case HydraStatus.finalized:
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HydraService>(
      builder: (context, hydra, child) {
        if (widget.compact) {
          return _buildCompactView(context, hydra);
        }
        return _buildFullView(context, hydra);
      },
    );
  }

  Widget _buildCompactView(BuildContext context, HydraService hydra) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(hydra.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(hydra.status),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(hydra.status),
            size: 16,
            color: _getStatusColor(hydra.status),
          ),
          const SizedBox(width: 6),
          Text(
            'Hydra: ${_getStatusText(hydra.status)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(hydra.status),
            ),
          ),
          if (hydra.status == HydraStatus.open) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context, HydraService hydra) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Hydra Layer 2',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildCompactView(context, hydra),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Hydra enables instant, low-cost transactions by running a Layer 2 payment channel.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Connection controls
            if (!hydra.isConnected) ...[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Hydra Node WebSocket URL',
                  hintText: 'ws://localhost:4001',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await hydra.connect(_urlController.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connected to Hydra node'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connection failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.power),
                  label: const Text('Connect to Hydra'),
                ),
              ),
            ] else ...[
              // Connected - show controls
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hydra.status == HydraStatus.idle)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await hydra.initHead();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Initialize Head'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  if (hydra.status == HydraStatus.open)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await hydra.closeHead();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text('Close Head'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  if (hydra.status == HydraStatus.closed)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await hydra.fanout();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.account_tree),
                      label: const Text('Fanout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await hydra.disconnect();
                    },
                    icon: const Icon(Icons.power_off),
                    label: const Text('Disconnect'),
                  ),
                ],
              ),
              
              // Message history
              if (hydra.messageHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Message History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => hydra.clearHistory(),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: hydra.messageHistory.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final msg = hydra.messageHistory[
                        hydra.messageHistory.length - 1 - index
                      ];
                      final tag = msg['tag'] ?? 'Unknown';
                      final timestamp = msg['timestamp'];
                      final time = timestamp != null 
                        ? DateTime.fromMillisecondsSinceEpoch(timestamp as int)
                        : null;
                      
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getMessageIcon(tag),
                          size: 18,
                          color: _getMessageColor(tag),
                        ),
                        title: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: time != null
                          ? Text(
                              '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  IconData _getMessageIcon(String tag) {
    switch (tag) {
      case 'Greetings':
        return Icons.waving_hand;
      case 'HeadIsInitializing':
        return Icons.start;
      case 'HeadIsOpen':
        return Icons.check_circle;
      case 'HeadIsClosed':
        return Icons.close;
      case 'HeadIsFinalized':
        return Icons.done_all;
      case 'TxValid':
        return Icons.check;
      case 'TxInvalid':
        return Icons.error;
      case 'SnapshotConfirmed':
        return Icons.photo_camera;
      default:
        return Icons.message;
    }
  }

  Color _getMessageColor(String tag) {
    switch (tag) {
      case 'TxValid':
      case 'HeadIsOpen':
        return Colors.green;
      case 'TxInvalid':
      case 'HeadIsClosed':
        return Colors.red;
      case 'HeadIsInitializing':
        return Colors.orange;
      case 'HeadIsFinalized':
      case 'SnapshotConfirmed':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
