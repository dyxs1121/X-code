import 'dart:io';

import 'package:flutter/material.dart';

import '../data/card_faces.dart';
import '../models/bank_card.dart';

class CardFaceView extends StatelessWidget {
  final BankCard card;
  final double? width;
  final bool compact;

  const CardFaceView({
    super.key,
    required this.card,
    this.width,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final customPath = card.cardFace.startsWith('custom:')
        ? card.cardFace.substring(7)
        : null;
    final face = findBuiltInFace(card.cardFace) ?? builtInFaces.first;
    final bool lightText = customPath != null ? true : face.dark;
    final Color textColor = lightText ? Colors.white : const Color(0xFF1F2937);
    final Color subColor = lightText
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black54;

    Widget background;
    if (customPath != null && File(customPath).existsSync()) {
      background = Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(customPath), fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xAA000000)],
              ),
            ),
          ),
        ],
      );
    } else {
      background = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: face.colors,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 14 : 20),
      child: SizedBox(
        width: width ?? double.infinity,
        child: AspectRatio(
          aspectRatio: 1.586,
          child: Stack(
            children: [
              background,
              if (customPath == null) _PatternOverlay(face: face),
              Padding(
                padding: EdgeInsets.all(compact ? 14 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            card.bankName.isNotEmpty ? card.bankName : 'X-CARD',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: compact ? 14 : 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            card.isCredit ? 'CREDIT' : 'DEBIT',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!compact) const _Chip(),
                    if (!compact) const SizedBox(height: 18),
                    Text(
                      card.cardNumber.isNotEmpty
                          ? card.cardNumber
                          : '**** **** **** ****',
                      style: TextStyle(
                        color: textColor,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            card.cardholderName.isEmpty
                                ? 'CARDHOLDER'
                                : card.cardholderName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: textColor,
                                fontSize: compact ? 10 : 12,
                                letterSpacing: 1),
                          ),
                        ),
                        Text(
                          card.expiryDate.isEmpty ? 'MM/YY' : card.expiryDate,
                          style: TextStyle(
                              color: textColor,
                              fontSize: compact ? 10 : 12,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFE6C27A), Color(0xFFB8860B)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              Container(height: 1, width: 22, color: Colors.black38),
            ],
          ),
          Container(height: 1, width: 42, color: Colors.black38),
          Row(
            children: [
              const SizedBox(width: 10),
              Container(height: 1, width: 22, color: Colors.black38),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatternOverlay extends StatelessWidget {
  final CardFace face;
  const _PatternOverlay({required this.face});

  @override
  Widget build(BuildContext context) {
    if (face.pattern == 'plain') return const SizedBox.shrink();
    return Positioned.fill(
      child: ClipRect(
        child: CustomPaint(painter: _PatternPainter(face: face)),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final CardFace face;
  _PatternPainter({required this.face});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: face.dark ? 0.09 : 0.16)
      ..style = PaintingStyle.fill;

    if (face.pattern == 'wave') {
      canvas.drawCircle(
          Offset(size.width * 0.88, size.height * 0.12), size.width * 0.34, paint);
      canvas.drawCircle(
          Offset(size.width * 1.05, size.height * 0.46), size.width * 0.26, paint);
    } else if (face.pattern == 'dots') {
      for (int i = 0; i < 22; i++) {
        final x = (i * 71 % 100) / 100 * size.width;
        final y = (i * 43 % 100) / 100 * size.height;
        canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 4 : 2.2, paint);
      }
    } else if (face.pattern == 'chip') {
      canvas.drawCircle(
          Offset(size.width * 0.92, -size.height * 0.08), size.width * 0.38, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) => false;
}
