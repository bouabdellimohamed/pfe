import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/recommendation_service.dart';
import '../services/interaction_tracking_service.dart';
import '../screens/lawyer_profile_screen.dart';
import 'profile_avatar.dart';

/// Top lawyer picks — one clear list, relevance-first scoring.
class RecommendedLawyersSection extends StatefulWidget {
  final int refreshToken;

  const RecommendedLawyersSection({super.key, this.refreshToken = 0});

  @override
  State<RecommendedLawyersSection> createState() => _RecommendedLawyersSectionState();
}

class _RecommendedLawyersSectionState extends State<RecommendedLawyersSection> {
  final _service = RecommendationService();
  final _tracking = InteractionTrackingService();

  bool _loading = true;
  List<LawyerRecommendation> _items = [];

  static const Color _primary = Color(0xFF0052D4);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecommendedLawyersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.getRecommendations(limit: 6);
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openProfile(LawyerRecommendation rec) async {
    HapticFeedback.lightImpact();
    final lawyer = rec.lawyer;
    await _tracking.recordProfileView(
      lawyerId: lawyer.uid,
      speciality: lawyer.speciality.split(',').first.trim(),
      wilaya: lawyer.wilaya,
      source: 'feed_recommendation',
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawyerProfileScreen(lawyer: lawyer, trackProfileView: false),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _primary),
          ),
        ),
      );
    }

    if (_items.isEmpty) return _buildExploreEmpty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'rec_section_title'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            'rec_section_subtitle_v2'.tr(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _RecommendationCard(
              item: _items[index],
              rank: index + 1,
              onTap: () => _openProfile(_items[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.explore_rounded, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'rec_explore_platform'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final LawyerRecommendation item;
  final int rank;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.item,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lawyer = item.lawyer;
    final isTop = rank == 1;
    final reasonColor = RecommendationService.reasonColor(item.primaryReason);
    final reasonLabel =
        RecommendationService.reasonTranslationKey(item.primaryReason).tr();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTop ? reasonColor.withOpacity(0.4) : const Color(0xFFE2E8F0),
            width: isTop ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: reasonColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  imageBase64: lawyer.profileImageBase64,
                  name: lawyer.name,
                  size: 44,
                  borderColor: reasonColor.withOpacity(0.2),
                  backgroundColor: reasonColor,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: reasonColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.matchPercent}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: reasonColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lawyer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lawyer.speciality.split(',').first.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
                Text(
                  lawyer.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                if (lawyer.wilaya != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lawyer.wilaya!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: reasonColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reasonLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: reasonColor,
                  height:  1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
