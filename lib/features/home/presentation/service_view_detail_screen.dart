import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/widgets/skeleton_shimmer.dart';
import '../application/service_detail_provider.dart';
import '../modal/service_detail_modal.dart';

class ServiceViewDetailScreen extends ConsumerStatefulWidget {
  const ServiceViewDetailScreen({super.key, required this.serviceId});

  final int serviceId;

  @override
  ConsumerState<ServiceViewDetailScreen> createState() =>
      _ServiceViewDetailScreenState();
}

class _ServiceViewDetailScreenState
    extends ConsumerState<ServiceViewDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(serviceDetailProvider(widget.serviceId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1F2937),
            size: 20,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Service Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: detailsAsync.when(
        loading: () => const _ServiceDetailLoadingState(),
        error: (error, stackTrace) => _ServiceDetailErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(serviceDetailProvider(widget.serviceId)),
        ),
        data: (details) => _ServiceDetailContent(details: details),
      ),
    );
  }
}

class _ServiceDetailContent extends StatefulWidget {
  const _ServiceDetailContent({required this.details});

  final ServiceDetailModal details;

  @override
  State<_ServiceDetailContent> createState() => _ServiceDetailContentState();
}

class _ServiceDetailContentState extends State<_ServiceDetailContent> {
  bool _expandedDescription = false;

  @override
  Widget build(BuildContext context) {
    final details = widget.details;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(imageUrl: details.imageUrl),
                const SizedBox(height: 14),
                Text(
                  details.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 5),
                    Text(
                      details.rating == 0
                          ? 'New'
                          : details.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '(2.3k reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      details.formattedDuration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.safeDescription,
                  maxLines: _expandedDescription ? null : 3,
                  overflow: _expandedDescription
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedDescription = !_expandedDescription;
                    });
                  },
                  child: Text(
                    _expandedDescription ? 'Read Less' : 'Read More',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'How It Works',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const _HowItWorksTimeline(),
          const SizedBox(height: 14),
          if (details.included.isNotEmpty)
            _DetailSectionCard(
              title: "What's Included",
              backgroundColor: const Color(0xFFEFFAF1),
              iconColor: const Color(0xFF16A34A),
              icon: Icons.check_circle,
              items: details.included,
              titleFontSize: 17,
              itemFontSize: 11.5,
              containerPadding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            ),
          if (details.notIncluded.isNotEmpty)
            _DetailSectionCard(
              title: "What's Not Included",
              backgroundColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
              icon: Icons.cancel,
              items: details.notIncluded,
              titleFontSize: 17,
              itemFontSize: 11.5,
              containerPadding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            ),
          if (details.requirements.isNotEmpty)
            _DetailSectionCard(
              title: 'What We Need From You',
              backgroundColor: Colors.white,
              iconColor: const Color(0xFF38BDF8),
              icon: Icons.water_drop,
              items: details.requirements,
              useAdaptiveIcons: true,
              titleFontSize: 18,
              itemFontSize: 13,
              containerPadding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              elevated: false,
              plainSection: true,
            ),
          if (details.faqs.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            ...details.faqs.map((faq) => _FaqTile(faq: faq)),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Text(
                  'Customer Reviews',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Spacer(),
                Text(
                  '2.6k reviews',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const _CustomerReviewsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ServiceDetailLoadingState extends StatelessWidget {
  const _ServiceDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShimmerBox(
                  height: 210,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                SizedBox(height: 14),
                SkeletonShimmerBox(
                  height: 24,
                  width: 220,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    SkeletonShimmerBox(
                      height: 14,
                      width: 42,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    SizedBox(width: 8),
                    SkeletonShimmerBox(
                      height: 12,
                      width: 92,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    SizedBox(width: 8),
                    SkeletonShimmerBox(
                      height: 8,
                      width: 8,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    SizedBox(width: 8),
                    SkeletonShimmerBox(
                      height: 12,
                      width: 50,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShimmerBox(
                  height: 12,
                  width: double.infinity,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 8),
                SkeletonShimmerBox(
                  height: 12,
                  width: double.infinity,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 8),
                SkeletonShimmerBox(
                  height: 12,
                  width: 220,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 12),
                SkeletonShimmerBox(
                  height: 12,
                  width: 74,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SkeletonShimmerBox(
              height: 18,
              width: 120,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          const _LoadingHowItWorksSkeleton(),
          const SizedBox(height: 14),
          const _LoadingSectionSkeleton(titleWidth: 110),
          const _LoadingSectionSkeleton(titleWidth: 140),
          const _LoadingSectionSkeleton(titleWidth: 150),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: SkeletonShimmerBox(
              height: 18,
              width: 180,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          const _LoadingFaqSkeleton(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: SkeletonShimmerBox(
              height: 18,
              width: 150,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          const _LoadingReviewSkeleton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ServiceDetailErrorState extends StatelessWidget {
  const _ServiceDetailErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _LoadingHowItWorksSkeleton extends StatelessWidget {
  const _LoadingHowItWorksSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          _LoadingTimelineRow(showLine: true),
          _LoadingTimelineRow(showLine: true),
          _LoadingTimelineRow(showLine: true),
          _LoadingTimelineRow(showLine: false),
        ],
      ),
    );
  }
}

class _LoadingTimelineRow extends StatelessWidget {
  const _LoadingTimelineRow({required this.showLine});

  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: showLine ? 18 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                SkeletonShimmerBox(
                  width: 30,
                  height: 30,
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                ),
                if (showLine)
                  Container(
                    width: 1.5,
                    height: 42,
                    margin: const EdgeInsets.only(top: 6),
                    color: const Color(0xFFD7E3EC),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonShimmerBox(
                    height: 14,
                    width: 150,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  SizedBox(height: 6),
                  SkeletonShimmerBox(
                    height: 11,
                    width: 200,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSectionSkeleton extends StatelessWidget {
  const _LoadingSectionSkeleton({required this.titleWidth});

  final double titleWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonShimmerBox(
            height: 16,
            width: titleWidth,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShimmerBox(
                  height: 12,
                  width: double.infinity,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 10),
                SkeletonShimmerBox(
                  height: 12,
                  width: 220,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 10),
                SkeletonShimmerBox(
                  height: 12,
                  width: 190,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingFaqSkeleton extends StatelessWidget {
  const _LoadingFaqSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(children: const [_LoadingFaqTile(), _LoadingFaqTile()]);
  }
}

class _LoadingFaqTile extends StatelessWidget {
  const _LoadingFaqTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonShimmerBox(
            height: 14,
            width: 200,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          SizedBox(height: 10),
          SkeletonShimmerBox(
            height: 12,
            width: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ],
      ),
    );
  }
}

class _LoadingReviewSkeleton extends StatelessWidget {
  const _LoadingReviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 158,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonShimmerBox(
                      width: 26,
                      height: 26,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: SkeletonShimmerBox(
                        height: 12,
                        width: 130,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SkeletonShimmerBox(
                  height: 12,
                  width: 90,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: SkeletonShimmerBox(
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 2,
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.items,
    this.useAdaptiveIcons = false,
    this.titleFontSize = 16,
    this.itemFontSize = 12,
    this.containerPadding = const EdgeInsets.fromLTRB(14, 14, 14, 6),
    this.elevated = false,
    this.plainSection = false,
  });

  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final List<String> items;
  final bool useAdaptiveIcons;
  final double titleFontSize;
  final double itemFontSize;
  final EdgeInsetsGeometry containerPadding;
  final bool elevated;
  final bool plainSection;

  @override
  Widget build(BuildContext context) {
    if (plainSection) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      useAdaptiveIcons ? _adaptiveIconFor(item, icon) : icon,
                      size: 16,
                      color: iconColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: itemFontSize,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: containerPadding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: elevated
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
              border: elevated
                  ? Border.all(color: const Color(0xFFE8EEF5))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          useAdaptiveIcons
                              ? _adaptiveIconFor(item, icon)
                              : icon,
                          size: 16,
                          color: iconColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: itemFontSize,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _adaptiveIconFor(String value, IconData fallback) {
  final normalized = value.toLowerCase();
  if (normalized.contains('water')) {
    return Icons.opacity;
  }
  if (normalized.contains('electric')) {
    return Icons.bolt;
  }
  if (normalized.contains('space') || normalized.contains('empty')) {
    return Icons.space_dashboard_outlined;
  }
  if (normalized.contains('mop')) {
    return Icons.cleaning_services_outlined;
  }
  return fallback;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final ServiceDetailFaqModal faq;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          iconColor: const Color(0xFF94A3B8),
          collapsedIconColor: const Color(0xFF94A3B8),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq.answer,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: imageUrl.trim().isEmpty
            ? Container(
                color: const Color(0xFFE5EAF1),
                child: const Icon(
                  Icons.cleaning_services_outlined,
                  size: 44,
                  color: Color(0xFF94A3B8),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE5EAF1),
                    child: const Icon(
                      Icons.cleaning_services_outlined,
                      size: 44,
                      color: Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _HowItWorksTimeline extends StatelessWidget {
  const _HowItWorksTimeline();

  @override
  Widget build(BuildContext context) {
    const steps = <({String title, String subtitle, IconData icon})>[
      (
        title: 'Book Service',
        subtitle: 'Select your preferred date and time slot',
        icon: Icons.calendar_today,
      ),
      (
        title: 'Professional Arrives',
        subtitle: 'Verified expert reaches your doorstep on time',
        icon: Icons.person,
      ),
      (
        title: 'Service Execution',
        subtitle: 'Thorough cleaning of all areas as per checklist',
        icon: Icons.cleaning_services,
      ),
      (
        title: 'Cleanup & Finish',
        subtitle: 'Final inspection and your home is ready',
        icon: Icons.verified,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(
              title: steps[i].title,
              subtitle: steps[i].subtitle,
              icon: steps[i].icon,
              showLine: i != steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.showLine,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: showLine ? 18 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9EFFB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: Color(0xFF0EA5E9)),
                ),
                if (showLine)
                  Container(
                    width: 1.5,
                    height: 42,
                    margin: const EdgeInsets.only(top: 6),
                    color: const Color(0xFF0EA5E9),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerReviewsSection extends StatelessWidget {
  const _CustomerReviewsSection();

  @override
  Widget build(BuildContext context) {
    const items = <({String name, String review, String days})>[
      (
        name: 'Piya Sharma',
        review:
            'Excellent service! The professional was punctual and very thorough. My home looks spotless now.',
        days: '2 days ago',
      ),
      (
        name: 'Gaurav Verma',
        review:
            'Great deep cleaning experience. Team was polite and completed everything on time.',
        days: '5 days ago',
      ),
    ];

    return SizedBox(
      height: 158,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: Text(
                        item.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                    SizedBox(width: 2),
                    Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                    SizedBox(width: 2),
                    Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                    SizedBox(width: 2),
                    Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                    SizedBox(width: 2),
                    Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.review,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.days,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: items.length,
      ),
    );
  }
}
