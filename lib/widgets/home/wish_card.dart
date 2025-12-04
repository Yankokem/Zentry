import 'package:flutter/material.dart';

class WishCard extends StatelessWidget {
  final String title;
  final String price;
  final IconData image;
  final Color? backgroundColor;

  const WishCard({
    super.key,
    required this.title,
    required this.price,
    required this.image,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;
    
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 75,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                image,
                size: 36,
                color: bgColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (price.isNotEmpty)
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: bgColor,
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