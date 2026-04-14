import 'package:flutter/material.dart';

class ServiceViewDetailScreen extends StatefulWidget {
  const ServiceViewDetailScreen({
    super.key,
    required this.serviceTitle,
    required this.serviceImage,
    required this.price,
  });

  final String serviceTitle;
  final String serviceImage;
  final String price;

  @override
  State<ServiceViewDetailScreen> createState() =>
      _ServiceViewDetailScreenState();
}

class _ServiceViewDetailScreenState extends State<ServiceViewDetailScreen> {
  bool _liked = false;
  bool _expandedDescription = false;

  final List<_FaqItem> _faqs = const [
    _FaqItem(question: 'How long will the service take?'),
    _FaqItem(question: 'Do I need to be present during service?'),
    _FaqItem(question: 'What products do you use?'),
    _FaqItem(question: 'Can I reschedule the service?'),
  ];

  final List<_ReviewItem> _reviews = const [
    _ReviewItem(
      name: 'Priya Sharma',
      text: 'Excellent service! The professional was punctual and very thorough. My home looks brand new.',
      date: '2 days ago',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
    ),
    _ReviewItem(
      name: 'Greg Williams',
      text: 'Great experience overall. The team was polite and completed everything on time.',
      date: '5 days ago',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Light background like the image
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937), size: 20),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image and Main Info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.serviceImage,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.serviceTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Color(0xFFFACC15)),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(2.4k reviews)',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 4, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '3 hrs',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get your home sparkling clean with our professional deep cleaning service. Our trained experts use eco-friendly products to ensure every corner is spotless.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Read More',
                          style: TextStyle(
                            color: Color(0xFF0096C7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // How it works section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'How It Works',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 16),
            const _HowItWorksTimeline(),

            // Included / Not Included Sections
            _ServiceDetailsList(
              title: "What's Included",
              items: const [
                'Kitchen deep cleaning',
                'Bathroom scrubbing',
                'Floor mopping & vacuuming',
                'Dusting all surfaces'
              ],
              color: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF22C55E),
              icon: Icons.check_circle,
            ),
            _ServiceDetailsList(
              title: "What's Not Included",
              items: const [
                'Balcony cleaning',
                'Heavy furniture movement',
                'External areas'
              ],
              color: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFEF4444),
              icon: Icons.cancel,
            ),

            // Requirements Section
            _ServiceDetailsList(
              title: "What We Need From You",
              items: const [
                'Water availability throughout service',
                'Electricity access for vacuum and equipment',
                'Empty space for professional to work efficiently'
              ],
              color: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF0096C7),
              icon: Icons.info_outline,
              isIconSpecific: true, // Uses unique icons per line if true
            ),

            // FAQ
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            ..._faqs.map((faq) => _FaqTile(question: faq.question)),

            // Reviews
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '2.4k reviews',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _reviews.length,
                itemBuilder: (context, index) => _ReviewCard(review: _reviews[index]),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksTimeline extends StatelessWidget {
  const _HowItWorksTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          _TimelineItem(
            icon: Icons.calendar_month,
            title: 'Book Service',
            desc: 'Select your preferred date and time slot',
            isLast: false,
          ),
          _TimelineItem(
            icon: Icons.person_outline,
            title: 'Professional arrives',
            desc: 'Verified expert reaches your doorstep on time',
            isLast: false,
          ),
          _TimelineItem(
            icon: Icons.cleaning_services_outlined,
            title: 'Service Execution',
            desc: 'Thorough cleaning of all areas as per checklist',
            isLast: false,
          ),
          _TimelineItem(
            icon: Icons.check_circle_outline,
            title: 'Cleanup & Finish',
            desc: 'Final inspection and your home is ready',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F7FA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF0096C7)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: const Color(0xFFB3E5FC),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceDetailsList extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final Color iconColor;
  final IconData icon;
  final bool isIconSpecific;

  const _ServiceDetailsList({
    required this.title,
    required this.items,
    required this.color,
    required this.iconColor,
    required this.icon,
    this.isIconSpecific = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ...items.map((item) {
            IconData currentIcon = icon;
            if (isIconSpecific) {
              if (item.contains('Water')) currentIcon = Icons.opacity;
              if (item.contains('Electricity')) currentIcon = Icons.bolt;
              if (item.contains('Empty')) currentIcon = Icons.space_dashboard_outlined;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(currentIcon, size: 18, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  const _FaqTile({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.keyboard_arrow_down, size: 20),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _ReviewItem review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage(review.avatarUrl)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Row(
                    children: List.generate(5, (i) => const Icon(Icons.star, color: Colors.amber, size: 12)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
          const Spacer(),
          Text(review.date, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}

// Data models
class _FaqItem {
  final String question;
  const _FaqItem({required this.question});
}

class _ReviewItem {
  final String name;
  final String text;
  final String date;
  final String avatarUrl;
  const _ReviewItem({required this.name, required this.text, required this.date, required this.avatarUrl});
}