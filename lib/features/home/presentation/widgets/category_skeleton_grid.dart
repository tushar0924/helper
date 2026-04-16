import 'package:flutter/material.dart';

import '../../../../app/widgets/skeleton_shimmer.dart';

class CategorySkeletonGrid extends StatelessWidget {
  const CategorySkeletonGrid({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        return const _SkeletonTile();
      },
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAF0), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SkeletonShimmerBox(
              borderRadius: BorderRadius.all(Radius.circular(11)),
            ),
          ),
          const SizedBox(height: 8),
          const SkeletonShimmerBox(
            height: 10,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 6),
          SkeletonShimmerBox(
            height: 10,
            width: MediaQuery.sizeOf(context).width * 0.18,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ],
      ),
    );
  }
}
