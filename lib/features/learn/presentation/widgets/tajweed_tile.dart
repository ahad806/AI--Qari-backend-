import 'package:al_qari/features/learn/data/models/tajweed_model.dart';
import 'package:al_qari/features/learn/presentation/pages/tajweed_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TajweedTile extends StatelessWidget {
  final TajweedItem item;

  const TajweedTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TajweedDetailScreen(item: item)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            SvgPicture.asset(
              item.image,
              height: 48,
              width: 48,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            // Arrow
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
