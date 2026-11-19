import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/auth/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/waste_deposit.dart';
import '../../data/repositories/app_repository.dart';

class OfficerScreen extends StatefulWidget {
  const OfficerScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<OfficerScreen> createState() => _OfficerScreenState();
}

class _OfficerScreenState extends State<OfficerScreen> {
  static const _categories = [
    'Plastik',
    'Kertas',
    'Logam',
    'Organik',
    'E-Waste',
    'Kaca',
    'Lainnya',
  ];

  late final AppRepository _repository = widget.session.repository;
  final _manualCodeController = TextEditingController();
  final _materialController = TextEditingController(text: 'Botol Plastik');
  final _weightController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();

  var _showQueue = false;
  var _busy = false;
  String? _token;
  String? _memberCode;
  String _category = 'Plastik';
  late Future<List<Map<String, dynamic>>> _queueFuture;

  @override
  void initState() {
    super.initState();
    _queueFuture = _repository.getOfficerDeposits();
  }

  @override
  void dispose() {
    _manualCodeController.dispose();
    _materialController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy || _token != null || _memberCode != null) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      final uri = Uri.tryParse(raw);
      final token = uri?.queryParameters['token'] ?? raw;
      setState(() {
        _token = token;
        _category = 'Plastik';
        _materialController.text = 'Botol Plastik';
      });
      return;
    }
  }

  Future<void> _submitManualCode() async {
    final code = _manualCodeController.text.trim();
    if (code.isEmpty) {
      _message('Masukkan kode member terlebih dahulu.');
      return;
    }
    setState(() {
      _memberCode = code;
      _token = null;
    });
  }

  Future<void> _submitScan() async {
    final weight = double.tryParse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    if (weight == null || weight <= 0 || weight > 500) {
      _message('Berat harus lebih dari 0 dan maksimal 500 kg.');
      return;
    }
    if (_materialController.text.trim().length < 2) {
      _message('Nama material wajib diisi.');
      return;
    }

    setState(() => _busy = true);
    try {
      final response = await _repository.scanDeposit(
        token: _token,
        memberCode: _memberCode,
        items: [
          {
            'material': _materialController.text.trim(),
            'category': _category,
            'weightKg': weight,
          },
        ],
      );
      if (!mounted) return;
      final member = Map<String, dynamic>.from(response['member'] as Map);
      final points = (response['pointsEarned'] as num?)?.toInt() ?? 0;
      _clearScan();
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.forest),
          title: const Text('Setoran berhasil dicatat'),
          content: Text(
            '${member['name'] ?? 'Member'} mendapat $points poin.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearScan() {
    setState(() {
      _token = null;
      _memberCode = null;
      _manualCodeController.clear();
      _materialController.text = 'Botol Plastik';
      _weightController.text = '1.0';
      _notesController.clear();
      _category = 'Plastik';
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _completePickup(Map<String, dynamic> raw) async {
    final deposit = WasteDeposit.fromJson(raw);
    final materialController = TextEditingController(text: deposit.material);
    final weightController = TextEditingController(
      text: deposit.weightKg > 0 ? deposit.weightKg.toStringAsFixed(1) : '1.0',
    );
    var category = _categories.contains(deposit.category)
        ? deposit.category
        : 'Plastik';
    var busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timbang ${deposit.code}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    deposit.address ?? 'Alamat tidak tersedia',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: materialController,
                    decoration: const InputDecoration(
                      labelText: 'Nama material',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      for (final item in _categories)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (value) {
                      if (value != null) setSheetState(() => category = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Berat aktual',
                      suffixText: 'kg',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () async {
                              final weight = double.tryParse(
                                weightController.text.replaceAll(',', '.'),
                              );
                              if (weight == null || weight <= 0) {
                                _message('Masukkan berat aktual yang valid.');
                                return;
                              }
                              setSheetState(() => busy = true);
                              try {
                                await _repository.completeDeposit(
                                  id: raw['id'] as String,
                                  items: [
                                    {
                                      'material': materialController.text
                                          .trim(),
                                      'category': category,
                                      'weightKg': weight,
                                    },
                                  ],
                                );
                                if (!sheetContext.mounted || !mounted) return;
                                Navigator.pop(sheetContext);
                                setState(
                                  () => _queueFuture = _repository
                                      .getOfficerDeposits(),
                                );
                                _message('Penjemputan selesai ditimbang.');
                              } catch (error) {
                                if (!context.mounted) return;
                                setSheetState(() => busy = false);
                                _message(error.toString());
                              }
                            },
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Selesaikan setoran'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    materialController.dispose();
    weightController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.session.profile;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Panel Petugas'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () async {
              await widget.session.logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.mint,
                    child: Icon(Icons.badge_rounded, color: AppColors.forest),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? 'Petugas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Pindai QR atau proses penjemputan.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Scan QR')),
                  ButtonSegment(value: true, label: Text('Antrean jemput')),
                ],
                selected: {_showQueue},
                onSelectionChanged: (values) {
                  setState(() {
                    _showQueue = values.first;
                    if (_showQueue) {
                      _queueFuture = _repository.getOfficerDeposits();
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _showQueue ? _buildQueue() : _buildScanner()),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_token == null && _memberCode == null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 270,
                child: MobileScanner(
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => Container(
                    color: AppColors.forestDark,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Kamera tidak dapat dibuka. Gunakan kode member secara manual.\n${error.errorCode.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _manualCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Kode member',
                hintText: 'TT-2024-00147',
                suffixIcon: IconButton(
                  tooltip: 'Gunakan kode',
                  onPressed: _submitManualCode,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              onSubmitted: (_) => _submitManualCode(),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.forest,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _memberCode == null
                          ? 'QR berhasil dipindai'
                          : 'Member $_memberCode',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: _clearScan,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _materialController,
              decoration: const InputDecoration(labelText: 'Nama material'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Berat aktual',
                suffixText: 'kg',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submitScan,
                icon: const Icon(Icons.check_rounded),
                label: Text(_busy ? 'Mencatat...' : 'Catat setoran'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQueue() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _queueFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(
                    () => _queueFuture = _repository.getOfficerDeposits(),
                  ),
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          ),
        );
      }

      final rows = snapshot.data ?? const <Map<String, dynamic>>[];
      final pickups = rows.where((row) => row['method'] == 'pickup').toList();
      if (pickups.isEmpty) {
        return const Center(child: Text('Tidak ada penjemputan di antrean.'));
      }

      return RefreshIndicator(
        onRefresh: () async {
          setState(() => _queueFuture = _repository.getOfficerDeposits());
          await _queueFuture;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: pickups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final row = pickups[index];
            final member = Map<String, dynamic>.from(row['member'] as Map);
            final deposit = WasteDeposit.fromJson(row);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deposit.material,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Chip(label: Text(deposit.status.name)),
                      ],
                    ),
                    Text('${member['name'] ?? 'Member'} · ${deposit.code}'),
                    const SizedBox(height: 4),
                    Text(
                      deposit.address ?? 'Alamat tidak tersedia',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (deposit.scheduledAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Jadwal: ${deposit.scheduledAt!.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _completePickup(row),
                        child: const Text('Timbang & selesaikan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
