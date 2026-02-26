import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/base_scaffold.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static final _services = [
    {
      'name': 'Puja at Home',
      'description': 'Professional pandit visits your home for any ceremony.',
      'icon': Icons.home,
      'color': AppColors.primary,
    },
    {
      'name': 'Online Puja',
      'description': 'Live-streamed rituals performed on your behalf.',
      'icon': Icons.videocam,
      'color': AppColors.secondary,
    },
    {
      'name': 'Kundali Making',
      'description': 'Detailed birth-chart analysis by expert astrologers.',
      'icon': Icons.auto_graph,
      'color': AppColors.success,
    },
    {
      'name': 'Vastu Shastra',
      'description': 'Harmonise your space with ancient Vastu principles.',
      'icon': Icons.architecture,
      'color': AppColors.warning,
    },
    {
      'name': 'Marriage Muhurta',
      'description': 'Auspicious date & time selection for weddings.',
      'icon': Icons.favorite,
      'color': AppColors.error,
    },
    {
      'name': 'Annadanam',
      'description': 'Organise community food donation drives.',
      'icon': Icons.restaurant,
      'color': AppColors.info,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: AppStrings.services,
      showBackButton: false,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final s = _services[i];
          final color = s['color'] as Color;
          return InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(s['icon'] as IconData, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(s['description'] as String,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: color.withOpacity(0.6)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
