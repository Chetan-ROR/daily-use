import 'package:flutter/widgets.dart';
import 'package:life_manager_pro/common/screens/feature_crud_screen.dart';
import 'package:life_manager_pro/core/constants/app_modules.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      FeatureCrudScreen(module: AppModules.byId('habits'));
}
