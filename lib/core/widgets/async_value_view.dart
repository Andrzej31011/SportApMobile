import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/widgets/app_error_view.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const AppLoadingView(),
      error: (error, _) =>
          AppErrorView(message: error.toString(), onRetry: onRetry),
    );
  }
}
