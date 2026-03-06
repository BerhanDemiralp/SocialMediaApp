import 'package:flutter/material.dart';

enum AsyncViewState { loading, error, empty, data }

class AsyncStateView extends StatelessWidget {
  final AsyncViewState state;
  final Widget Function(BuildContext context) builder;
  final String? errorMessage;
  final String? emptyMessage;
  final VoidCallback? onRetry;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.builder,
    this.errorMessage,
    this.emptyMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AsyncViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case AsyncViewState.error:
        return _ErrorView(
          message: errorMessage ?? 'Something went wrong',
          onRetry: onRetry,
        );
      case AsyncViewState.empty:
        return _EmptyView(message: emptyMessage ?? 'Nothing to see yet');
      case AsyncViewState.data:
        return builder(context);
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (onRetry != null)
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

