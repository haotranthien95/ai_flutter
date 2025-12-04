import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Provider for connectivity status
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.instance.onConnectivityChanged;
});

/// Offline banner widget that appears when network is unavailable
class OfflineBanner extends ConsumerWidget {
  /// Creates offline banner
  const OfflineBanner({
    required this.child,
    super.key,
  });

  /// Child widget to display below the banner
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return Column(
      children: [
        connectivity.when(
          data: (isConnected) {
            if (!isConnected) {
              return Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.errorContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Không có kết nối Internet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final isConnected = await ConnectivityService.instance
                            .checkConnection();
                        if (context.mounted && isConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã kết nối lại Internet'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Thử lại',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}
