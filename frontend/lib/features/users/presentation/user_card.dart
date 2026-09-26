import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_notice.dart';
import '../domain/user_identity.dart';
import '../domain/user_relationship.dart';
import 'user_conversations.dart';
import 'user_identity_view.dart';
import 'user_relationships_controller.dart';

/// Screens supply an identity, never relationship flags or API callbacks.
class UserCard extends ConsumerWidget {
  const UserCard({super.key, required this.user});
  final UserIdentity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userRelationshipsProvider);
    final opening = ref.watch(
      userConversationCoordinatorProvider.select(
        (ids) => ids.contains(user.id),
      ),
    );
    final controller = ref.read(userRelationshipsProvider.notifier);
    final record = state.records[user.id];
    final kind = state.kindFor(user.id);
    final missingRequestId =
        (kind == RelationshipKind.incoming ||
            kind == RelationshipKind.outgoing) &&
        record?.requestId == null;
    final busy = state.busy.contains(user.id) || opening;
    void open() => ref
        .read(userConversationCoordinatorProvider.notifier)
        .open(context, user: user);
    return UserCardView(
      user: user,
      kind: kind,
      busy: busy,
      needsRetry: kind == RelationshipKind.unknown || missingRequestId,
      loading: state.loading,
      onRetry: controller.refresh,
      onMessage: open,
      onAction: (action) async {
        final result = await controller.perform(user, action);
        if (result != null && controller.isActive && context.mounted) {
          showAppNotice(context, result.message);
        }
      },
    );
  }
}

/// Shared policy and layout; no repository calls or navigation here.
class UserCardView extends StatelessWidget {
  const UserCardView({
    super.key,
    required this.user,
    required this.kind,
    required this.busy,
    required this.needsRetry,
    required this.loading,
    required this.onRetry,
    required this.onMessage,
    required this.onAction,
  });
  final UserIdentity user;
  final RelationshipKind kind;
  final bool busy;
  final bool needsRetry;
  final bool loading;
  final VoidCallback onRetry;
  final VoidCallback onMessage;
  final void Function(UserAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    final style = FilledButton.styleFrom(minimumSize: const Size(48, 48));
    Widget action(String label, UserAction action) => FilledButton(
      style: action == UserAction.accept
          ? FilledButton.styleFrom(
              minimumSize: const Size(48, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tapTargetSize: MaterialTapTargetSize.padded,
              visualDensity: VisualDensity.standard,
            )
          : style,
      onPressed: busy || needsRetry ? null : () => onAction(action),
      child: Text(label),
    );
    Widget cancel(String label, UserAction action) => IconButton(
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: busy || needsRetry ? null : () => onAction(action),
      icon: const Icon(Icons.close),
    );
    switch (kind) {
      case RelationshipKind.self:
        break;
      case RelationshipKind.none:
        actions.add(action('Add friend', UserAction.add));
      case RelationshipKind.outgoing:
        actions.add(cancel('Cancel request', UserAction.cancel));
      case RelationshipKind.incoming:
        actions.addAll([
          action('Accept', UserAction.accept),
          cancel('Decline request', UserAction.decline),
        ]);
      case RelationshipKind.friend:
        actions.add(
          PopupMenuButton<UserAction>(
            tooltip: 'Friend options',
            enabled: !busy,
            constraints: const BoxConstraints(minWidth: 180),
            icon: const Icon(Icons.more_horiz),
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: UserAction.remove,
                child: Text('Remove friend'),
              ),
            ],
          ),
        );
      case RelationshipKind.unknown:
        break;
    }
    if (needsRetry) {
      actions.add(
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: loading || busy ? null : onRetry,
          child: Text(loading ? 'Loading...' : 'Retry'),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: kind == RelationshipKind.friend && !busy ? onMessage : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final iconOnly =
                  !needsRetry &&
                  (kind == RelationshipKind.friend ||
                      kind == RelationshipKind.outgoing);
              final actionWidth = (constraints.maxWidth * .56).clamp(
                0.0,
                iconOnly ? (busy ? 72.0 : 48.0) : 240.0 * scale,
              );
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: UserIdentityView(
                        user: user,
                        isSelf: kind == RelationshipKind.self,
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: actionWidth,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...actions,
                            if (busy)
                              Semantics(
                                label: 'Working',
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
