import 'package:flutter/material.dart';

/// Compact heading row for sections that may expose one secondary action.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
    super.key,
  }) : assert(
         trailing == null || actionLabel == null,
         'Use either trailing or actionLabel, not both.',
       ),
       assert(
         actionLabel == null || onAction != null,
         'onAction is required when actionLabel is provided.',
       );

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action =
        trailing ??
        (actionLabel == null
            ? null
            : TextButton(onPressed: onAction, child: Text(actionLabel!)));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}
