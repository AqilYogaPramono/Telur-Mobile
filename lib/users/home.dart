import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:telur_mobile/widgets/navbutton.dart';
import 'package:telur_mobile/widgets/skeleton.dart';
import 'package:telur_mobile/widgets/topbar.dart';

String formatDateTimeId(DateTime value) {
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _errorMessage;
  AnalysisRecord? _latest;
  List<AnalysisRecord> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      final latestEndpoint = normalized.endsWith('/egg-analysis-news')
          ? normalized
          : '$normalized/egg-analysis-news';
      final latestUri = Uri.parse(latestEndpoint);
      final historyUri = Uri.parse('$latestEndpoint/history');
      final responses = await Future.wait([http.get(latestUri), http.get(historyUri)]);
      if (responses[0].statusCode != 200) {
        throw Exception('Gagal ambil data terbaru: ${responses[0].statusCode}');
      }
      if (responses[1].statusCode != 200) {
        throw Exception('Gagal ambil data riwayat: ${responses[1].statusCode}');
      }
      final latestJson = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final historyJson = jsonDecode(responses[1].body) as List<dynamic>;
      final latest = AnalysisRecord.fromJson(latestJson);
      final history = historyJson
          .map((e) => AnalysisRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      setState(() {
        _latest = latest;
        _history = history.take(3).toList();
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

  void _onTabChanged(AppTab tab) {
    if (tab == AppTab.home) return;
    final page = switch (tab) {
      AppTab.history => const _PlaceholderPage(title: 'Riwayat'),
      AppTab.camera => const _PlaceholderPage(title: 'Kamera'),
      _ => const HomePage(),
    };
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  void _toDetail(AnalysisRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DetailAnalysisPage(record: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latest;
    return Scaffold(
      appBar: TopBar(
        title: 'Home',
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _PlaceholderPage(title: 'Profil'),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader(
              title: 'Hasil Analisis Terbaru',
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const AnalysisCardSkeleton()
            else if (_errorMessage != null)
              _ErrorCard(message: _errorMessage!, onRetry: _loadData)
            else if (latest != null)
              _LatestCard(
                record: latest,
                onTapImage: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ImagePreviewPage(imageUrl: latest.imageUrl),
                    ),
                  );
                },
                onTapDetail: () => _toDetail(latest),
              )
            else
              const _EmptyCard(text: 'Belum ada data analisis terbaru'),
            const SizedBox(height: 18),
            const _SectionHeader(
              title: 'Riwayat 3 Hari Terakhir',
              subtitle: 'Hasil analisis terbaru',
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              ...List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: AnalysisCardSkeleton(),
                ),
              )
            else if (_errorMessage == null && _history.isEmpty)
              const _EmptyCard(text: 'Belum ada riwayat analisis')
            else
              ..._history.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnalysisCard(
                    record: record,
                    onTap: () => _toDetail(record),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavButton(
        activeTab: AppTab.home,
        onChanged: _onTabChanged,
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

class _LatestCard extends StatelessWidget {
  const _LatestCard({
    required this.record,
    required this.onTapImage,
    required this.onTapDetail,
  });

  final AnalysisRecord record;
  final VoidCallback onTapImage;
  final VoidCallback onTapDetail;

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
              onTap: onTapImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    record.imageUrl,
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
            _StatChipsRow(record: record),
            const SizedBox(height: 12),
            _MetaRow(
              label: 'Tanggal & Waktu',
              value: formatDateTimeId(record.detectedAt),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTapDetail,
                child: const Text('Lihat Detail'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({super.key, required this.record, this.onTap});

  final AnalysisRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    record.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(
                      color: Color(0xFFF2EFE3),
                      child: Center(child: Text('Gambar tidak tersedia')),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _StatChipsRow(record: record, compact: true),
              const SizedBox(height: 10),
              _MetaRow(
                label: 'Tanggal & Waktu',
                value: formatDateTimeId(record.detectedAt),
              ),
              Row(
                children: const [
                  Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF6B7565),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnalysisCardSkeleton extends StatelessWidget {
  const AnalysisCardSkeleton({super.key});

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
            SkeletonBox(height: 180, borderRadius: 12),
            SizedBox(height: 10),
            SkeletonBox(height: 14, width: 220),
            SizedBox(height: 8),
            SkeletonBox(height: 14, width: 160),
            SizedBox(height: 8),
            SkeletonBox(height: 14, width: 130),
            SizedBox(height: 8),
            SkeletonBox(height: 14, width: 130),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7565),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF2F4A2B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              'Gagal memuat data',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F4A2B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7565),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatChipsRow extends StatelessWidget {
  const _StatChipsRow({required this.record, this.compact = false});

  final AnalysisRecord record;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
          label: 'Total',
          value: record.eggCount,
          bgColor: const Color(0xFFE9F1E3),
          fgColor: const Color(0xFF3F6B2A),
          compact: compact,
        ),
        _StatChip(
          label: 'Fertil',
          value: record.fertileCount,
          bgColor: const Color(0xFFE8F5E9),
          fgColor: const Color(0xFF2E7D32),
          compact: compact,
        ),
        _StatChip(
          label: 'Infertil',
          value: record.infertileCount,
          bgColor: const Color(0xFFFFF3E0),
          fgColor: const Color(0xFFEF6C00),
          compact: compact,
        ),
        _StatChip(
          label: 'Mati',
          value: record.deadCount,
          bgColor: const Color(0xFFFFEBEE),
          fgColor: const Color(0xFFC62828),
          compact: compact,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.fgColor,
    required this.compact,
  });

  final String label;
  final int value;
  final Color bgColor;
  final Color fgColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: fgColor,
        ),
      ),
    );
  }
}

class _DetailAnalysisPage extends StatelessWidget {
  const _DetailAnalysisPage({required this.record});

  final AnalysisRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(title: 'Detail Analisis'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(record.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          _StatChipsRow(record: record),
          const SizedBox(height: 12),
          _MetaRow(
            label: 'Tanggal & Waktu',
            value: formatDateTimeId(record.detectedAt),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: title),
      body: Center(
        child: Text(
          '$title page belum dipindah',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2F4A2B),
          ),
        ),
      ),
      bottomNavigationBar: NavButton(
        activeTab: switch (title) {
          'Riwayat' => AppTab.history,
          'Kamera' => AppTab.camera,
          _ => AppTab.none,
        },
        onChanged: (tab) {
          if (tab == AppTab.home) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
            return;
          }
          if (tab == AppTab.camera) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const _PlaceholderPage(title: 'Kamera'),
              ),
            );
            return;
          }
          if (tab == AppTab.history) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const _PlaceholderPage(title: 'Riwayat'),
              ),
            );
          }
        },
      ),
    );
  }
}

class AnalysisRecord {
  const AnalysisRecord({
    required this.imageDriveId,
    required this.eggCount,
    required this.fertileCount,
    required this.infertileCount,
    required this.deadCount,
    required this.detectedAt,
  });

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    return AnalysisRecord(
      imageDriveId: json['images_detection']?.toString() ?? '',
      eggCount: (json['egg_count'] as num?)?.toInt() ?? 0,
      fertileCount: (json['fertile_count'] as num?)?.toInt() ?? 0,
      infertileCount: (json['infertile_count'] as num?)?.toInt() ?? 0,
      deadCount: (json['dead_count'] as num?)?.toInt() ?? 0,
      detectedAt:
          DateTime.tryParse(json['detected_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String imageDriveId;
  final int eggCount;
  final int fertileCount;
  final int infertileCount;
  final int deadCount;
  final DateTime detectedAt;

  String get imageUrl =>
      'https://drive.usercontent.google.com/download?id=$imageDriveId&export=view&authuser=0';
}
