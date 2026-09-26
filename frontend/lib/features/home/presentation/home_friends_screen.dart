import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../users/data/user_identity_adapters.dart';
import '../../users/data/user_search_api_client.dart';
import '../../users/data/user_session.dart';
import '../../users/data/users_repository.dart';
import '../../users/domain/user_relationship.dart';
import '../../users/presentation/user_card.dart';
import '../../users/presentation/user_relationships_controller.dart';

final _searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final searchResultsProvider = FutureProvider.autoDispose<List<UserSummary>>((
  ref,
) {
  final account = ref.watch(activeAccountIdProvider);
  ref.watch(identityRevisionProvider);
  final query = ref.watch(_searchQueryProvider).trim();
  if (account == null || query.isEmpty) return [];
  return ref.watch(usersRepositoryProvider).searchUsers(query);
});

class HomeFriendsScreen extends ConsumerWidget {
  const HomeFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_searchQueryProvider);
    final search = ref.watch(searchResultsProvider);
    final relationships = ref.watch(userRelationshipsProvider);
    final controller = ref.read(userRelationshipsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Find friends')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(searchResultsProvider);
          await controller.refresh();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              decoration: const InputDecoration(
                hintText: "Type a friend's username",
                prefixIcon: Icon(Icons.search),
              ),
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (value) =>
                  ref.read(_searchQueryProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            if (relationships.loading) const LinearProgressIndicator(),
            if (relationships.error != null) ...[
              Text(relationships.error!),
              TextButton(
                onPressed: relationships.loading ? null : controller.refresh,
                child: const Text('Retry'),
              ),
            ],
            if (query.trim().isNotEmpty)
              search.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Column(
                  children: [
                    const Text('Could not search users.'),
                    TextButton(
                      onPressed: () => ref.invalidate(searchResultsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: (users) => users.isEmpty
                    ? const Text('No users found for this username.')
                    : Column(
                        children: [
                          for (final user in users)
                            UserCard(
                              key: ValueKey('search-${user.id}'),
                              user: user.identity,
                            ),
                        ],
                      ),
              ),
            for (final section in [
              (RelationshipKind.incoming, 'Incoming requests'),
              (RelationshipKind.outgoing, 'Outgoing requests'),
              (RelationshipKind.friend, 'Friends'),
            ])
              if (relationships.usersOfKind(section.$1).isNotEmpty ||
                  (section.$1 == RelationshipKind.friend &&
                      relationships.loaded)) ...[
                const SizedBox(height: 20),
                Text(
                  section.$2,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (section.$1 == RelationshipKind.friend &&
                    relationships.usersOfKind(section.$1).isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('No friends yet.'),
                  ),
                for (final user in relationships.usersOfKind(section.$1))
                  UserCard(
                    key: ValueKey('${section.$1.name}-${user.id}'),
                    user: user,
                  ),
              ],
          ],
        ),
      ),
    );
  }
}
