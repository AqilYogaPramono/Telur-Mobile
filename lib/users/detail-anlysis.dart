import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:telur_mobile/widgets/topbar.dart';

String _formatDateTimeId(DateTime value) {
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  final day = days[value.weekday - 1];
  final month = months[value.month - 1];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day, ${value.day} $month ${value.year} $hour:$minute';
}

class DetailAnalysisPage extends StatefulWidget {
  const DetailAnalysisPage({super.key, required this.analysisId});

  final int analysisId;

  @override
  State<DetailAnalysisPage> createState() => _DetailAnalysisPageState();
}

class _DetailAnalysisPageState extends State<DetailAnalysisPage> {
  bool _isLoading = true;
  String? _errorMessage;
  DetailAnalysisData? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await dotenv.load(fileName: '.env');
      final apiValue = (dotenv.env['API'] ?? '').trim();
      if (apiValue.isEmpty) {
        throw Exception('API pada .env belum diisi');
      }
      final normalized = apiValue.endsWith('/')
          ? apiValue.substring(0, apiValue.length - 1)
          : apiValue;
      final base = normalized.endsWith('/egg-analysis-news')
          ? normalized.replaceFirst('/egg-analysis-news', '')
          : normalized;
      final detailUri = Uri.parse('$base/egg-analysis/${widget.analysisId}');
      final response = await http.get(detailUri);
      if (response.statusCode != 200) {
        throw Exception('Gagal ambil detail analisis: ${response.statusCode}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _detail = DetailAnalysisData.fromJson(json);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: const TopBar(title: 'Detail Analisis'),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const _DetailLoadingCard()
            else if (_errorMessage != null)
              _ErrorCard(message: _errorMessage!, onRetry: _loadDetail)
            else if (detail == null)
              const _EmptyCard(text: 'Data detail tidak ditemukan')
            else ...[
              _DetailHeaderCard(detail: detail),
              const SizedBox(height: 14),
              const Text(
                'Klasifikasi Per Telur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F4A2B),
                ),
              ),
              const SizedBox(height: 10),
              if (detail.classifications.isEmpty)
                const _EmptyCard(text: 'Belum ada data klasifikasi telur')
              else
                ...detail.classifications.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ClassificationCard(item: item),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailHeaderCard extends StatelessWidget {
  const _DetailHeaderCard({required this.detail});

  final DetailAnalysisData detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ImagePreviewPage(imageUrl: detail.imageUrl),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    detail.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(
                      color: Color(0xFFF2EFE3),
                      child: Center(child: Text('Gambar tidak tersedia')),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    label: 'Total',
                    value: detail.eggCount,
                    bgColor: const Color(0xFFE9F1E3),
                    fgColor: const Color(0xFF3F6B2A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Fertil',
                    value: detail.fertileCount,
                    bgColor: const Color(0xFFE8F5E9),
                    fgColor: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Infertil',
                    value: detail.infertileCount,
                    bgColor: const Color(0xFFFFF3E0),
                    fgColor: const Color(0xFFEF6C00),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    label: 'Mati',
                    value: detail.deadCount,
                    bgColor: const Color(0xFFFFEBEE),
                    fgColor: const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Tanggal & Waktu',
                  style: TextStyle(
                    color: Color(0xFF6B7565),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTimeId(detail.detectedAt),
                  style: const TextStyle(
                    color: Color(0xFF2F4A2B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassificationCard extends StatelessWidget {
  const _ClassificationCard({required this.item});

  final EggClassification item;

  bool get _isFertil => item.classificationLabel.toLowerCase().contains('fertil');
  String get _displayClassificationLabel {
    final label = item.classificationLabel;
    final normalized = label.replaceAll('_', ' ');
    if (RegExp(r'^infertil\s*hari\s*ke-', caseSensitive: false).hasMatch(normalized)) {
      return normalized.replaceFirst(
        RegExp(r'^infertil\s*hari\s*ke-', caseSensitive: false),
        'Infertil Hari Ke-',
      );
    }
    if (RegExp(r'^fertil\s*hari\s*ke-', caseSensitive: false).hasMatch(normalized)) {
      return normalized.replaceFirst(
        RegExp(r'^fertil\s*hari\s*ke-', caseSensitive: false),
        'Fertil Hari Ke-',
      );
    }
    if (RegExp(r'^mati\s*hari\s*ke-', caseSensitive: false).hasMatch(normalized)) {
      return normalized.replaceFirst(
        RegExp(r'^mati\s*hari\s*ke-', caseSensitive: false),
        'Mati Hari Ke-',
      );
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final tagBg = _isFertil ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final tagFg = _isFertil ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00);
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Telur ${item.eggIndex}',
                  style: const TextStyle(
                    color: Color(0xFF2F4A2B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _displayClassificationLabel,
                    style: TextStyle(
                      color: tagFg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Tingkat Keyakinan',
                  style: TextStyle(
                    color: Color(0xFF6B7565),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(item.confidenceScore * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: Color(0xFF2F4A2B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  const _ImagePreviewPage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Pratinjau Gambar'),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'Gagal memuat gambar',
                style: TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.fgColor,
  });

  final String label;
  final int value;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          color: fgColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE1A53B),
              size: 22,
            ),
            const SizedBox(height: 6),
            const Text(
              'Gagal memuat detail',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F4A2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Color(0xFF6B7565))),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF6B7565),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF6B7565),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLoadingCard extends StatelessWidget {
  const _DetailLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(
              height: 180,
              child: ColoredBox(color: Color(0xFFF2EFE3)),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 14,
              width: 180,
              child: ColoredBox(color: Color(0xFFF2EFE3)),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 14,
              width: 130,
              child: ColoredBox(color: Color(0xFFF2EFE3)),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailAnalysisData {
  const DetailAnalysisData({
    required this.id,
    required this.imageDriveId,
    required this.eggCount,
    required this.fertileCount,
    required this.infertileCount,
    required this.deadCount,
    required this.detectedAt,
    required this.classifications,
  });

  factory DetailAnalysisData.fromJson(Map<String, dynamic> json) {
    final list = json['egg_classifications'] as List<dynamic>? ?? [];
    return DetailAnalysisData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageDriveId: json['images_detection']?.toString() ?? '',
      eggCount: (json['egg_count'] as num?)?.toInt() ?? 0,
      fertileCount: (json['fertile_count'] as num?)?.toInt() ?? 0,
      infertileCount: (json['infertile_count'] as num?)?.toInt() ?? 0,
      deadCount: (json['dead_count'] as num?)?.toInt() ?? 0,
      detectedAt:
          DateTime.tryParse(json['detected_at']?.toString() ?? '') ?? DateTime.now(),
      classifications: list
          .map((e) => EggClassification.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String imageDriveId;
  final int eggCount;
  final int fertileCount;
  final int infertileCount;
  final int deadCount;
  final DateTime detectedAt;
  final List<EggClassification> classifications;

  String get imageUrl =>
      'https://drive.usercontent.google.com/download?id=$imageDriveId&export=view&authuser=0';
}

class EggClassification {
  const EggClassification({
    required this.eggIndex,
    required this.classificationLabel,
    required this.confidenceScore,
  });

  factory EggClassification.fromJson(Map<String, dynamic> json) {
    return EggClassification(
      eggIndex: (json['egg_index'] as num?)?.toInt() ?? 0,
      classificationLabel: json['classification_label']?.toString() ?? '-',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0,
    );
  }

  final int eggIndex;
  final String classificationLabel;
  final double confidenceScore;
}
