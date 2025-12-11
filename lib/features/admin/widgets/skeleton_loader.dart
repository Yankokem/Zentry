import 'package:flutter/material.dart';
import 'package:zentry/core/core.dart';

/// Alias for core SkeletonLoader to match expected API
typedef AdminSkeletonBase = SkeletonLoader;

/// Skeleton for loading a stat card
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 50, height: 50, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 12),
          SkeletonLoader(width: 100, height: 20, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          SkeletonLoader(width: 60, height: 16, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}

/// Skeleton for loading a list item card
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SkeletonLoader(width: 44, height: 44, borderRadius: BorderRadius.circular(22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 150, height: 16, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 8),
                SkeletonLoader(width: 200, height: 14, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 8),
                SkeletonLoader(width: 80, height: 14, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ),
          SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.circular(8)),
        ],
      ),
    );
  }
}

/// Skeleton for loading a chart
class SkeletonChart extends StatelessWidget {
  const SkeletonChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: 20),
          Column(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLoader(width: 60, height: 12),
                    SkeletonLoader(width: 100, height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for loading a profile card
class SkeletonProfileCard extends StatelessWidget {
  const SkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SkeletonLoader(width: 100, height: 100, borderRadius: BorderRadius.circular(50)),
          const SizedBox(height: 16),
          SkeletonLoader(width: 150, height: 20, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          SkeletonLoader(width: 180, height: 16, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 16),
          SkeletonLoader(width: 120, height: 32, borderRadius: BorderRadius.circular(16)),
        ],
      ),
    );
  }
}

/// Skeleton for loading a grid of stat cards
class SkeletonStatGrid extends StatelessWidget {
  final int itemCount;
  const SkeletonStatGrid({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: List.generate(itemCount, (index) => const SkeletonStatCard()),
    );
  }
}

/// Skeleton for loading a detail card with multiple rows
class SkeletonDetailCard extends StatelessWidget {
  final int rowCount;
  const SkeletonDetailCard({super.key, this.rowCount = 5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          rowCount,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < rowCount - 1 ? 16 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 80, height: 12),
                const SizedBox(height: 8),
                SkeletonLoader(width: 200, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
