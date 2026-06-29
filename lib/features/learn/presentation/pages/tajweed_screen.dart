import 'package:al_qari/config/themes/app_colors.dart';
import 'package:al_qari/features/learn/data/models/tajweed_model.dart';
import 'package:al_qari/features/learn/presentation/widgets/tajweed_tile.dart';
import 'package:flutter/material.dart';

class TajweedScreen extends StatelessWidget {
  const TajweedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tajweedItems = [
      TajweedItem(
        title: 'Ghunna (Nasal sound)',
        image: 'assets/icons/ghunnah.svg',
        description:
            'Ghunna is a nasal sound produced from the nose. It occurs with Noon and Meem Mushaddad and is held for two counts.',
      ),
      TajweedItem(
        title: 'Izhar (Clarity)',
        image: 'assets/icons/izhaar.svg',
        description:
            'Izhar means clarity. Noon Sakinah or Tanween is pronounced clearly when followed by throat letters.',
      ),
      TajweedItem(
        title: 'Iqlab (Conversion)',
        image: 'assets/icons/iqlab.svg',
        description:
            'Iqlab means conversion. Noon Sakinah or Tanween changes into Meem sound when followed by Baa.',
      ),
      TajweedItem(
        title: 'Idgham (Merging)',
        image: 'assets/icons/idgham.svg',
        description:
            'Idgham means merging. Noon Sakinah or Tanween merges into the following letter with or without Ghunna.',
      ),
      TajweedItem(
        title: 'Ikhfaa (Concealment)',
        image: 'assets/icons/ikhfa.svg',
        description:
            'Ikhfaa means concealment. The sound is hidden between Izhar and Idgham with Ghunna.',
      ),
    ];

    return Scaffold(
      // appBar: AppBar(title: const Text('Tajweed Rules'), centerTitle: true),
      appBar: AppBar(
        title: Text(
          "Tajweed Rules",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w800,
            // letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tajweedItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = tajweedItems[index];
          return TajweedTile(item: item);
        },
      ),
    );
  }
}
