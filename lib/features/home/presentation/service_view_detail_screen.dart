import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/service_detail_provider.dart';
import '../modal/service_detail_modal.dart';

class ServiceViewDetailScreen extends ConsumerStatefulWidget {
  const ServiceViewDetailScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceImage,
    required this.price,
  });

  final int serviceId;
  final String serviceTitle;
  final String serviceImage;
  final String price;

  @override
  ConsumerState<ServiceViewDetailScreen> createState() =>
      _ServiceViewDetailScreenState();
}

class _ServiceViewDetailScreenState
    extends ConsumerState<ServiceViewDetailScreen> {
  bool _liked = false;

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
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _liked = !_liked),
            icon: Icon(
              _liked ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: _liked ? Colors.red : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => _ServiceDetailLoadingState(
          title: widget.serviceTitle,
          image: widget.serviceImage,
          price: widget.price,
        ),
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

class _ServiceDetailContent extends StatelessWidget {
  const _ServiceDetailContent({required this.details});

  final ServiceDetailModal details;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(imageUrl: details.imageUrl),
                const SizedBox(height: 16),
                Text(
                  details.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: Color(0xFFFACC15)),
                    const SizedBox(width: 4),
                    Text(
                      details.rating == 0
                          ? 'New'
                          : details.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      details.formattedDuration,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      details.formattedPrice,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    details.safeDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (details.included.isNotEmpty)
            _DetailSectionCard(
              title: "What's Included",
              backgroundColor: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF16A34A),
              icon: Icons.check_circle,
              items: details.included,
            ),
          if (details.notIncluded.isNotEmpty)
            _DetailSectionCard(
              title: "What's Not Included",
              backgroundColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFDC2626),
              icon: Icons.cancel,
              items: details.notIncluded,
            ),
          if (details.requirements.isNotEmpty)
            _DetailSectionCard(
              title: 'What We Need From You',
              backgroundColor: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF0284C7),
              icon: Icons.info_outline,
              items: details.requirements,
              useAdaptiveIcons: true,
            ),
          if (details.faqs.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            ...details.faqs.map((faq) => _FaqTile(faq: faq)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ServiceDetailLoadingState extends StatelessWidget {
  const _ServiceDetailLoadingState({
    required this.title,
    required this.image,
    required this.price,
  });

  final String title;
  final String image;
  final String price;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroImage(imageUrl: image),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
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

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.items,
    this.useAdaptiveIcons = false,
  });

  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final List<String> items;
  final bool useAdaptiveIcons;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    useAdaptiveIcons ? _adaptiveIconFor(item, icon) : icon,
                    size: 18,
                    color: iconColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
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
        height: 190,
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
