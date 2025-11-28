import 'package:flutter/material.dart';
import '../../../services/certificate_service.dart';

/// Dialog shown after successful purchase with certificate download option
class CertificateSuccessDialog extends StatelessWidget {
  final ContractCertificate certificate;
  final CertificateService certificateService;
  final String txHash;

  const CertificateSuccessDialog({
    super.key,
    required this.certificate,
    required this.certificateService,
    required this.txHash,
  });

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFD4AF37);
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: goldColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon Animation
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    goldColor.withValues(alpha: 0.3),
                    goldColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: goldColor, width: 3),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 50,
                color: goldColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              '🎉 Purchase Successful!',
              style: TextStyle(
                color: goldColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Your ownership has been recorded on the Cardano blockchain',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Certificate Preview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    goldColor.withValues(alpha: 0.1),
                    goldColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: goldColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.article_outlined, color: goldColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ownership Certificate',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              certificate.certificateId,
                              style: TextStyle(
                                color: goldColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(color: goldColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  
                  // Certificate Details
                  _buildDetailRow('Property', certificate.propertyName),
                  const SizedBox(height: 8),
                  _buildDetailRow('Fractions', '${certificate.fractionsPurchased}'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Ownership', '${certificate.ownershipPercentage.toStringAsFixed(4)}%'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Amount Paid', '${certificate.totalAmountAda.toStringAsFixed(2)} ADA'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Buyer', certificate.buyerName),
                  
                  const SizedBox(height: 16),
                  
                  // Transaction Hash
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tag, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TX: ${_shortenHash(txHash)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, size: 16, color: Colors.grey[500]),
                          onPressed: () {
                            // Copy to clipboard would go here
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Download Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await certificateService.downloadPdf(certificate);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Certificate downloaded successfully!'),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error downloading: $e'),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download Certificate (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // View on Explorer Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Open CardanoScan in new tab
                  // Would use url_launcher here
                },
                icon: Icon(Icons.open_in_new, color: goldColor),
                label: Text(
                  'View on CardanoScan',
                  style: TextStyle(color: goldColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: goldColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Close Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _shortenHash(String hash) {
    if (hash.length <= 20) return hash;
    return '${hash.substring(0, 10)}...${hash.substring(hash.length - 8)}';
  }
}
