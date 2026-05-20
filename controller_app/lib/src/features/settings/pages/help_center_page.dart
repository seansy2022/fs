import 'package:flutter/material.dart';
import 'package:internet_file/internet_file.dart';
import 'package:pdfx/pdfx.dart';
import 'package:rc_ui/rc_ui.dart';

class HelpCenterContent extends StatefulWidget {
  const HelpCenterContent({super.key});

  @override
  State<HelpCenterContent> createState() => _HelpCenterContentState();
}

class _HelpCenterContentState extends State<HelpCenterContent> {
  static const _manualUrl =
      'https://flyskydownload.flyskytech.com/s/pdf/shr_fzhngn8m';

  late final Future<PdfControllerPinch> _controllerFuture = _loadController();

  Future<PdfControllerPinch> _loadController() async {
    final bytes = await InternetFile.get(_manualUrl);
    final document = PdfDocument.openData(bytes);
    return PdfControllerPinch(document: document);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<PdfControllerPinch>(
        future: _controllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'PDF 打开失败，请检查网络或链接是否可用。',
                  style: TextStyle(color: AppColors.text, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return PdfViewPinch(
            controller: snapshot.data!,
            builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              pageLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'PDF 渲染失败：$error',
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
