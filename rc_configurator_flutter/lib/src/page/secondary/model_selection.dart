import 'package:flutter/material.dart';

import 'package:rc_ui/rc_ui.dart';
import '../../types.dart';

class ModelSelection extends StatelessWidget {
  const ModelSelection({
    super.key,
    required this.models,
    required this.onSelectModel,
    required this.onRenameModel,
  });

  final List<Model> models;
  final ValueChanged<String> onSelectModel;
  final void Function(String id, String name) onRenameModel;
  static const _maxModelNameLength = 5;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimens.gapL),
      children: [
        ...models.asMap().entries.map((entry) {
          final model = entry.value;
          final displayName = model.name.isEmpty ? model.id : model.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.gapM),
            child: CellModeWidget(
              index: entry.key + 1,
              name: displayName,
              selected: model.active,
              onTap: () => onSelectModel(model.id),
              onEdit: () => _renameModel(context, model, entry.key + 1),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _renameModel(
    BuildContext context,
    Model model,
    int index,
  ) async {
    final nextName = await AlertInputWidget.show(
      context,
      title: '模型$index名称',
      hintText: '输入提示语',
      initialText: model.name.length > _maxModelNameLength
          ? model.name.substring(0, _maxModelNameLength)
          : model.name,
      maxLength: _maxModelNameLength,
    );
    if (nextName == null || nextName.isEmpty) return;
    final normalized = nextName.length > _maxModelNameLength
        ? nextName.substring(0, _maxModelNameLength)
        : nextName;
    onRenameModel(model.id, normalized);
  }
}
