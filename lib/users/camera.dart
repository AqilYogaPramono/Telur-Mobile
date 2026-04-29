import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:telur_mobile/users/detail-anlysis.dart';
import 'package:telur_mobile/users/history.dart';
import 'package:telur_mobile/users/home.dart';
import 'package:telur_mobile/users/profile.dart';
import 'package:telur_mobile/widgets/navbutton.dart';
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

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static int idEggDetections = 1;
  static CameraResultData? _cachedData;
  static Future<CameraResultData>? _ongoingAnalysis;
  static String? _cachedErrorMessage;

  bool _isLoading = false;
  String? _errorMessage = _cachedErrorMessage;
  CameraResultData? _data = _cachedData;

  @override
  void initState() {
    super.initState();
    if (_ongoingAnalysis != null) {
      _isLoading = true;
      _attachToOngoingAnalysis();
    }
  }

  Future<int> _waitForBackendAnalyzeResultId({
    required String apiValue,
    required int jobId,
  }) async {
    final normalized =
        apiValue.endsWith('/') ? apiValue.substring(0, apiValue.length - 1) : apiValue;
    final base = normalized
        .replaceFirst(RegExp(r'/egg-analysis-news$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'/egg-analysis$', caseSensitive: false), '');

    final uri = Uri.parse('$base/analyze-egg/jobs/$jobId');
    final deadline = DateTime.now().add(const Duration(minutes: 5));

    while (DateTime.now().isBefore(deadline)) {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Gagal cek status analisis: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (json['status'] as String?)?.toLowerCase();
      final resultId = (json['result_id'] as num?)?.toInt();
      final error = json['error']?.toString();

      if (status == 'succeeded' && resultId != null && resultId > 0) {
        return resultId;
      }
      if (status == 'failed') {
        throw Exception('Analisis gagal: ${error ?? response.body}');
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    throw Exception('Timeout menunggu hasil analisis.');
  }

  Future<int> _triggerEsp32ManualAnalyze(String esp32Url) async {
    final normalized = esp32Url.endsWith('/') ? esp32Url.substring(0, esp32Url.length - 1) : esp32Url;
    final uri = Uri.parse('$normalized/manual-analyze');
    final response = await http.post(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('ESP32 manual-analyze gagal: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final ok = json['ok'] == true;
    final jobId = ((json['job_id'] as num?) ?? (json['id'] as num?))?.toInt();
    if (!ok || jobId == null || jobId <= 0) {
      throw Exception('Response ESP32 tidak valid: ${response.body}');
    }
    return jobId;
  }

  Future<CameraResultData> _runAnalysisFlow() async {
    await dotenv.load(fileName: '.env');
    final apiValue = (dotenv.env['API'] ?? '').trim();
    if (apiValue.isEmpty) {
      throw Exception('API pada .env belum diisi');
    }

    final esp32Value = (dotenv.env['ESP32_URL'] ?? '').trim();
    if (esp32Value.isEmpty) {
      throw Exception('ESP32_URL pada .env belum diisi');
    }

    final jobId = await _triggerEsp32ManualAnalyze(esp32Value);
    final resultId = await _waitForBackendAnalyzeResultId(apiValue: apiValue, jobId: jobId);
    idEggDetections = resultId;

    final normalized = apiValue.endsWith('/')
        ? apiValue.substring(0, apiValue.length - 1)
        : apiValue;
    final base = normalized
        .replaceFirst(RegExp(r'/egg-analysis-news$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'/egg-analysis$', caseSensitive: false), '');
    final detailUri = Uri.parse('$base/egg-analysis/$idEggDetections');

    final response = await http.get(detailUri);
    if (response.statusCode != 200) {
      throw Exception('Gagal ambil data analisis: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CameraResultData.fromJson(json);
  }

  void _attachToOngoingAnalysis() {
    final future = _ongoingAnalysis;
    if (future == null) return;

    future.then((parsed) {
      _cachedData = parsed;
      _cachedErrorMessage = null;
      if (!mounted) return;
      setState(() {
        _data = parsed;
        _errorMessage = null;
      });
    }).catchError((error) {
      _cachedErrorMessage = error.toString();
      if (!mounted) return;
      setState(() {
        _errorMessage = _cachedErrorMessage;
      });
    }).whenComplete(() {
      if (identical(_ongoingAnalysis, future)) {
        _ongoingAnalysis = null;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _ambilFoto() async {
    if (_ongoingAnalysis != null) {
      if (mounted && !_isLoading) {
        setState(() {
          _isLoading = true;
        });
      }
      _attachToOngoingAnalysis();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _cachedErrorMessage = null;

    _ongoingAnalysis = _runAnalysisFlow();
    _attachToOngoingAnalysis();
  }

  void _ambilFotoLainnya() {
    setState(() {
      _data = null;
      _errorMessage = null;
    });
    _cachedData = null;
    _cachedErrorMessage = null;
  }

  void _onTabChanged(AppTab tab) {
    if (tab == AppTab.camera) return;
    final page = switch (tab) {
      AppTab.home => const HomePage(),
      AppTab.history => const HistoryPage(),
      _ => const CameraPage(),
    };
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: TopBar(
        title: 'Kamera',
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CameraResultCard(
                data: data,
                isLoading: _isLoading,
                onPrimaryAction: () {
                  if (data == null) {
                    _ambilFoto();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailAnalysisPage(analysisId: data.id),
                    ),
                  );
                },
                onTapImage: data == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _ImagePreviewPage(imageUrl: data.imageUrl),
                          ),
                        );
                      },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (data != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 190,
                  child: OutlinedButton(
                    onPressed: _ambilFotoLainnya,
                    child: const Text('Ambil Foto Lainnya'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavButton(
        activeTab: AppTab.camera,
        onChanged: _onTabChanged,
      ),
    );
  }
}

class _CameraResultCard extends StatelessWidget {
  const _CameraResultCard({
    required this.data,
    required this.isLoading,
    required this.onPrimaryAction,
    required this.onTapImage,
  });

  final CameraResultData? data;
  final bool isLoading;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onTapImage;

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
                  child: ColoredBox(
                    color: Colors.black,
                    child: _buildImageContent(),
                  ),
                ),
              ),
            ),
            if (data != null) ...[
              const SizedBox(height: 12),
              _StatChipsRow(data: data!),
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
                    _formatDateTimeId(data!.detectedAt),
                    style: const TextStyle(
                      color: Color(0xFF2F4A2B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPrimaryAction,
                child: Text(data == null ? 'Ambil Foto' : 'Lihat Detail'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.6,
        ),
      );
    }

    if (data == null) {
      return const Center(
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 54,
        ),
      );
    }

    return Image.network(
      data!.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Text(
          'Gambar tidak tersedia',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _StatChipsRow extends StatelessWidget {
  const _StatChipsRow({required this.data});

  final CameraResultData data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatChip(
          label: 'Total',
          value: data.eggCount,
          bgColor: const Color(0xFFE9F1E3),
          fgColor: const Color(0xFF3F6B2A),
        ),
        _StatChip(
          label: 'Fertil',
          value: data.fertileCount,
          bgColor: const Color(0xFFE8F5E9),
          fgColor: const Color(0xFF2E7D32),
        ),
        _StatChip(
          label: 'Infertil',
          value: data.infertileCount,
          bgColor: const Color(0xFFFFF3E0),
          fgColor: const Color(0xFFEF6C00),
        ),
        _StatChip(
          label: 'Mati',
          value: data.deadCount,
          bgColor: const Color(0xFFFFEBEE),
          fgColor: const Color(0xFFC62828),
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
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
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

class CameraResultData {
  const CameraResultData({
    required this.id,
    required this.imageDriveId,
    required this.eggCount,
    required this.fertileCount,
    required this.infertileCount,
    required this.deadCount,
    required this.detectedAt,
  });

  factory CameraResultData.fromJson(Map<String, dynamic> json) {
    return CameraResultData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageDriveId: json['images_detection']?.toString() ?? '',
      eggCount: (json['egg_count'] as num?)?.toInt() ?? 0,
      fertileCount: (json['fertile_count'] as num?)?.toInt() ?? 0,
      infertileCount: (json['infertile_count'] as num?)?.toInt() ?? 0,
      deadCount: (json['dead_count'] as num?)?.toInt() ?? 0,
      detectedAt:
          DateTime.tryParse(json['detected_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final int id;
  final String imageDriveId;
  final int eggCount;
  final int fertileCount;
  final int infertileCount;
  final int deadCount;
  final DateTime detectedAt;

  String get imageUrl =>
      'https://drive.usercontent.google.com/download?id=$imageDriveId&export=view&authuser=0';
}
