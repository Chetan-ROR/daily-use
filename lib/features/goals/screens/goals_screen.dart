import 'package:flutter/widgets.dart';
import 'package:life_manager_pro/common/screens/feature_crud_screen.dart';
import 'package:life_manager_pro/core/constants/app_modules.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      FeatureCrudScreen(module: AppModules.byId('goals'));
}
