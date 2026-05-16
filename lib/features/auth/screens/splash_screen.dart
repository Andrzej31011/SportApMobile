import 'package:flutter/material.dart';
import 'package:sport_ap_mobile/core/widgets/app_loading_view.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: AppLoadingView(message: 'Ladowanie sesji...'));
  }
}
