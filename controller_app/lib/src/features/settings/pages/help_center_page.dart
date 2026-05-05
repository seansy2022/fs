import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rc_ui/rc_ui.dart';

import '../widgets/settings_workspace.dart';

/// Base URL for help center documents.
/// Returns a JSON array of [HelpDocument].
const _helpDocumentListUrl = 'https://example.com/api/help/documents';

class HelpCenterContent extends ConsumerStatefulWidget {
  const HelpCenterContent({super.key});

  @override
  ConsumerState<HelpCenterContent> createState() =>
      _HelpCenterContentState();
}

class HelpDocument {
  const HelpDocument({
    required this.title,
    required this.contentUrl,
  });

  factory HelpDocument.fromJson(Map<String, Object?> json) {
    return HelpDocument(
      title: json['title']! as String,
      contentUrl: json['contentUrl']! as String,
    );
  }

  final String title;
  final String contentUrl;
}

class _HelpCenterContentState extends ConsumerState<HelpCenterContent> {
  List<HelpDocument>? _documents;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchDocuments());
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_helpDocumentListUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = '服务器返回错误：${response.statusCode}';
        });
        return;
      }
      final list = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _documents = list
            .whereType<Map<String, dynamic>>()
            .map(HelpDocument.fromJson)
            .toList(growable: false);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBright),
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: AppColors.textDim, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '重试',
            width: 120,
            onTap: _fetchDocuments,
          ),
        ],
      );
    }

    if (_documents == null || _documents!.isEmpty) {
      return const Center(
        child: Text(
          '暂无帮助文档',
          style: TextStyle(color: AppColors.textDim, fontSize: 14),
        ),
      );
    }

    return ListView(
      children: [
        ..._documents!.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ArrowItem(
                label: doc.title,
                onTap: () => _onDocumentTap(doc),
              ),
            )),
      ],
    );
  }

  Future<void> _onDocumentTap(HelpDocument doc) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DocumentLoadingDialog(document: doc),
    );
  }
}

class _ArrowItem extends StatelessWidget {
  const _ArrowItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsStrip(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: AppFonts.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDim,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentLoadingDialog extends StatefulWidget {
  const _DocumentLoadingDialog({required this.document});

  final HelpDocument document;

  @override
  State<_DocumentLoadingDialog> createState() =>
      _DocumentLoadingDialogState();
}

class _DocumentLoadingDialogState extends State<_DocumentLoadingDialog> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadContent());
  }

  Future<void> _loadContent() async {
    try {
      final response = await http
          .get(Uri.parse(widget.document.contentUrl))
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = '加载失败：${response.statusCode}';
        });
        return;
      }
      setState(() {
        _content = utf8.decode(response.bodyBytes);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1B2A),
      insetPadding: const EdgeInsets.all(0),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: TechShell(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.document.title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: AppFonts.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: AppColors.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0, 0.3334, 0.5092, 0.678, 1],
                        colors: [
                          Color.fromRGBO(126, 162, 207, 1),
                          Color.fromRGBO(0, 198, 255, 1),
                          Color.fromRGBO(146, 254, 157, 1),
                          Color.fromRGBO(0, 200, 255, 1),
                          Color.fromRGBO(125, 162, 206, 1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBright),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.textDim, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: SelectableText(
        _content ?? '',
        style: const TextStyle(
          color: AppColors.textDim,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}
