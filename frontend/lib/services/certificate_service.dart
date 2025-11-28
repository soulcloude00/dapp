import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Conditional imports for web download
import 'js_stub.dart' if (dart.library.html) 'js_web.dart' as js;

/// Contract certificate data model
class ContractCertificate {
  final String certificateId;
  final String txHash;
  final DateTime transactionDate;
  
  // Property Details
  final String propertyId;
  final String propertyName;
  final String propertyLocation;
  final String propertyDescription;
  final String propertyImageUrl;
  final double propertyTotalValue;
  final int totalFractions;
  
  // Owner Details
  final String ownerName;
  final String ownerWalletAddress;
  final String? ownerEmail;
  final String? ownerPhone;
  
  // Buyer Details
  final String buyerName;
  final String buyerWalletAddress;
  final String? buyerEmail;
  final String? buyerPhone;
  
  // Transaction Details
  final int fractionsPurchased;
  final double pricePerFraction;
  final double totalAmountAda;
  final double ownershipPercentage;
  
  ContractCertificate({
    required this.certificateId,
    required this.txHash,
    required this.transactionDate,
    required this.propertyId,
    required this.propertyName,
    required this.propertyLocation,
    required this.propertyDescription,
    required this.propertyImageUrl,
    required this.propertyTotalValue,
    required this.totalFractions,
    required this.ownerName,
    required this.ownerWalletAddress,
    this.ownerEmail,
    this.ownerPhone,
    required this.buyerName,
    required this.buyerWalletAddress,
    this.buyerEmail,
    this.buyerPhone,
    required this.fractionsPurchased,
    required this.pricePerFraction,
    required this.totalAmountAda,
    required this.ownershipPercentage,
  });
  
  Map<String, dynamic> toJson() => {
    'certificateId': certificateId,
    'txHash': txHash,
    'transactionDate': transactionDate.toIso8601String(),
    'propertyId': propertyId,
    'propertyName': propertyName,
    'propertyLocation': propertyLocation,
    'propertyDescription': propertyDescription,
    'propertyImageUrl': propertyImageUrl,
    'propertyTotalValue': propertyTotalValue,
    'totalFractions': totalFractions,
    'ownerName': ownerName,
    'ownerWalletAddress': ownerWalletAddress,
    'ownerEmail': ownerEmail,
    'ownerPhone': ownerPhone,
    'buyerName': buyerName,
    'buyerWalletAddress': buyerWalletAddress,
    'buyerEmail': buyerEmail,
    'buyerPhone': buyerPhone,
    'fractionsPurchased': fractionsPurchased,
    'pricePerFraction': pricePerFraction,
    'totalAmountAda': totalAmountAda,
    'ownershipPercentage': ownershipPercentage,
  };
  
  factory ContractCertificate.fromJson(Map<String, dynamic> json) => ContractCertificate(
    certificateId: json['certificateId'] ?? '',
    txHash: json['txHash'] ?? '',
    transactionDate: DateTime.tryParse(json['transactionDate'] ?? '') ?? DateTime.now(),
    propertyId: json['propertyId'] ?? '',
    propertyName: json['propertyName'] ?? '',
    propertyLocation: json['propertyLocation'] ?? '',
    propertyDescription: json['propertyDescription'] ?? '',
    propertyImageUrl: json['propertyImageUrl'] ?? '',
    propertyTotalValue: _parseDouble(json['propertyTotalValue']),
    totalFractions: _parseInt(json['totalFractions']),
    ownerName: json['ownerName'] ?? '',
    ownerWalletAddress: json['ownerWalletAddress'] ?? '',
    ownerEmail: json['ownerEmail'],
    ownerPhone: json['ownerPhone'],
    buyerName: json['buyerName'] ?? '',
    buyerWalletAddress: json['buyerWalletAddress'] ?? '',
    buyerEmail: json['buyerEmail'],
    buyerPhone: json['buyerPhone'],
    fractionsPurchased: _parseInt(json['fractionsPurchased']),
    pricePerFraction: _parseDouble(json['pricePerFraction']),
    totalAmountAda: _parseDouble(json['totalAmountAda']),
    ownershipPercentage: _parseDouble(json['ownershipPercentage']),
  );
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  
  /// Generate metadata for on-chain storage
  Map<String, dynamic> toOnChainMetadata() => {
    'app': 'crestadel',
    'type': 'contract',
    'version': '1.0',
    'certId': certificateId,
    'property': {
      'id': propertyId,
      'name': propertyName,
      'location': propertyLocation,
      'totalValue': propertyTotalValue,
      'totalFractions': totalFractions,
    },
    'owner': {
      'name': ownerName,
      'wallet': ownerWalletAddress,
      'email': ownerEmail ?? '',
      'phone': ownerPhone ?? '',
    },
    'buyer': {
      'name': buyerName,
      'wallet': buyerWalletAddress,
      'email': buyerEmail ?? '',
      'phone': buyerPhone ?? '',
    },
    'transaction': {
      'fractions': fractionsPurchased,
      'pricePerFraction': pricePerFraction,
      'totalAda': totalAmountAda,
      'ownershipPct': ownershipPercentage,
      'timestamp': transactionDate.toIso8601String(),
    },
  };
}

/// Service for generating contract certificates
class CertificateService extends ChangeNotifier {
  static const int CONTRACT_METADATA_LABEL = 8889; // Different from purchase label
  
  List<ContractCertificate> _certificates = [];
  List<ContractCertificate> get certificates => _certificates;
  
  /// Generate a unique certificate ID
  String generateCertificateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    return 'CREST-${timestamp.toString().substring(5)}-$random';
  }
  
  /// Create a contract certificate
  ContractCertificate createCertificate({
    required String txHash,
    required String propertyId,
    required String propertyName,
    required String propertyLocation,
    required String propertyDescription,
    required String propertyImageUrl,
    required double propertyTotalValue,
    required int totalFractions,
    required String ownerName,
    required String ownerWalletAddress,
    String? ownerEmail,
    String? ownerPhone,
    required String buyerName,
    required String buyerWalletAddress,
    String? buyerEmail,
    String? buyerPhone,
    required int fractionsPurchased,
    required double pricePerFraction,
  }) {
    final certificate = ContractCertificate(
      certificateId: generateCertificateId(),
      txHash: txHash,
      transactionDate: DateTime.now(),
      propertyId: propertyId,
      propertyName: propertyName,
      propertyLocation: propertyLocation,
      propertyDescription: propertyDescription,
      propertyImageUrl: propertyImageUrl,
      propertyTotalValue: propertyTotalValue,
      totalFractions: totalFractions,
      ownerName: ownerName,
      ownerWalletAddress: ownerWalletAddress,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
      buyerName: buyerName,
      buyerWalletAddress: buyerWalletAddress,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
      fractionsPurchased: fractionsPurchased,
      pricePerFraction: pricePerFraction,
      totalAmountAda: fractionsPurchased * pricePerFraction,
      ownershipPercentage: (fractionsPurchased / totalFractions) * 100,
    );
    
    _certificates.add(certificate);
    notifyListeners();
    
    return certificate;
  }
  
  /// Generate PDF certificate
  Future<Uint8List> generatePdfCertificate(ContractCertificate cert) async {
    final pdf = pw.Document();
    
    // Crestadel Royal Gold color
    final goldColor = PdfColor.fromHex('#D4AF37');
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: goldColor, width: 3),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header with Logo
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: goldColor, width: 2)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '🏰 CRESTADEL',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'PROPERTY OWNERSHIP CERTIFICATE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Blockchain Verified • Cardano Network',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Certificate ID and Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Certificate ID:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(cert.certificateId, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Issue Date:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.Text(
                          '${cert.transactionDate.day}/${cert.transactionDate.month}/${cert.transactionDate.year}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 25),
                
                // This Certifies Section
                pw.Text(
                  'THIS CERTIFIES THAT',
                  style: pw.TextStyle(fontSize: 12, letterSpacing: 1.5),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF8E7'),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    cert.buyerName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Wallet: ${_shortenAddress(cert.buyerWalletAddress)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                
                pw.SizedBox(height: 20),
                
                // Ownership Statement
                pw.Text(
                  'is the registered owner of',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: goldColor),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${cert.fractionsPurchased} FRACTIONS',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                      pw.Text(
                        '(${cert.ownershipPercentage.toStringAsFixed(4)}% Ownership)',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                pw.Text('of the property known as', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 10),
                
                // Property Details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F5F5'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cert.propertyName,
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('📍 ${cert.propertyLocation}', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Value', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                              pw.Text('\$${cert.propertyTotalValue.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Total Fractions', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                              pw.Text('${cert.totalFractions}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Property ID', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                              pw.Text(cert.propertyId.length > 15 ? '${cert.propertyId.substring(0, 15)}...' : cert.propertyId, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Transaction Details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TRANSACTION DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem('Price per Fraction', '${cert.pricePerFraction} ADA'),
                          _buildDetailItem('Total Paid', '${cert.totalAmountAda} ADA'),
                          _buildDetailItem('Transaction Hash', _shortenAddress(cert.txHash)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                // Seller Info
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F0F0F0'),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('PROPERTY OWNER', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 3),
                            pw.Text(cert.ownerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text(_shortenAddress(cert.ownerWalletAddress), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#FFF8E7'),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('FRACTION OWNER', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 3),
                            pw.Text(cert.buyerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text(_shortenAddress(cert.buyerWalletAddress), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                pw.Spacer(),
                
                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: goldColor)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'This certificate is cryptographically secured on the Cardano blockchain.',
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Verify at: cardanoscan.io/transaction/${cert.txHash}',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.blue),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '© ${DateTime.now().year} Crestadel - Decentralized Real Estate Investment Platform',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  static pw.Widget _buildDetailItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
  
  static String _shortenAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }
  
  /// Download PDF in browser
  Future<void> downloadPdf(ContractCertificate cert) async {
    try {
      final pdfBytes = await generatePdfCertificate(cert);
      
      if (kIsWeb) {
        // Web download using JS
        final base64Data = base64Encode(pdfBytes);
        final fileName = 'Crestadel_Certificate_${cert.certificateId}.pdf';
        
        // Use the global window object to create download
        final window = js.webWindow;
        if (window != null) {
          // Create a Blob and download link via JS eval
          final script = '''
            (function() {
              var byteCharacters = atob('$base64Data');
              var byteNumbers = new Array(byteCharacters.length);
              for (var i = 0; i < byteCharacters.length; i++) {
                byteNumbers[i] = byteCharacters.charCodeAt(i);
              }
              var byteArray = new Uint8Array(byteNumbers);
              var blob = new Blob([byteArray], {type: 'application/pdf'});
              var url = URL.createObjectURL(blob);
              var a = document.createElement('a');
              a.href = url;
              a.download = '$fileName';
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              URL.revokeObjectURL(url);
              return true;
            })()
          ''';
          js.context['eval'].apply([script]);
          debugPrint('PDF download initiated: ${cert.certificateId}');
        }
      } else {
        debugPrint('PDF download only available on web platform');
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      rethrow;
    }
  }
}
