import 'package:flutter/material.dart';
import 'package:rc_ui/rc_ui.dart';

import '../../../core/app_constants.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: '帮助中心',
      onBack: () => Navigator.of(context).pop(),
      body: ListView.separated(
        itemCount: helpDocuments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final document = helpDocuments[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HelpDocumentPage(document: document),
                ),
              );
            },
            child: Panel(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: AppFonts.s16,
                            fontWeight: AppFonts.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          document.summary,
                          style: const TextStyle(
                            color: AppColors.textDim,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryBright,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class HelpDocumentPage extends StatelessWidget {
  const HelpDocumentPage({super.key, required this.document});

  final HelpDocument document;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: document.title,
      onBack: () => Navigator.of(context).pop(),
      body: Panel(
        child: SingleChildScrollView(
          child: Text(
            document.body,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}
