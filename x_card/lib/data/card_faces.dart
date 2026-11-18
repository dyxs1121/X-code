import 'package:flutter/material.dart';

/// 内置卡面为原创渐变设计，不复制任何银行的版权图案。
/// 如需真实银行卡面，请使用"上传照片"添加你自己的卡片照片。
class CardFace {
  final String id;
  final String name;
  final List<Color> colors;
  final Color accent;
  final bool dark;
  final String pattern; // chip | wave | dots | plain

  const CardFace({
    required this.id,
    required this.name,
    required this.colors,
    required this.accent,
    required this.dark,
    required this.pattern,
  });
}

const List<CardFace> builtInFaces = [
  CardFace(
    id: 'obsidian',
    name: '曜石黑',
    colors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
    accent: Color(0xFFE5C07B),
    dark: true,
    pattern: 'chip',
  ),
  CardFace(
    id: 'ocean',
    name: '深海蓝',
    colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
    accent: Color(0xFF7DD3FC),
    dark: true,
    pattern: 'wave',
  ),
  CardFace(
    id: 'champagne',
    name: '香槟金',
    colors: [Color(0xFFA67C00), Color(0xFFF5E6A8)],
    accent: Color(0xFF4A3800),
    dark: false,
    pattern: 'chip',
  ),
  CardFace(
    id: 'rose',
    name: '玫瑰金',
    colors: [Color(0xFFB76E79), Color(0xFFF1D7D5)],
    accent: Color(0xFF7A3B45),
    dark: false,
    pattern: 'dots',
  ),
  CardFace(
    id: 'forest',
    name: '森林绿',
    colors: [Color(0xFF134E5E), Color(0xFF71B280)],
    accent: Color(0xFFFFFFFF),
    dark: true,
    pattern: 'wave',
  ),
  CardFace(
    id: 'crimson',
    name: '赤焰红',
    colors: [Color(0xFF7F0000), Color(0xFFE53935)],
    accent: Color(0xFFFDE68A),
    dark: true,
    pattern: 'chip',
  ),
  CardFace(
    id: 'violet',
    name: '幻彩紫',
    colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
    accent: Color(0xFFFFFFFF),
    dark: true,
    pattern: 'dots',
  ),
  CardFace(
    id: 'pearl',
    name: '极简白',
    colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
    accent: Color(0xFF334155),
    dark: false,
    pattern: 'plain',
  ),
  CardFace(
    id: 'graphite',
    name: '石墨灰',
    colors: [Color(0xFF2B2B2B), Color(0xFF737373)],
    accent: Color(0xFFE5E7EB),
    dark: true,
    pattern: 'plain',
  ),
  CardFace(
    id: 'twilight',
    name: '暮光橙',
    colors: [Color(0xFFF12711), Color(0xFFF5AF19)],
    accent: Color(0xFFFFFFFF),
    dark: true,
    pattern: 'wave',
  ),
  CardFace(
    id: 'mint',
    name: '薄荷绿',
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    accent: Color(0xFF064E3B),
    dark: false,
    pattern: 'dots',
  ),
  CardFace(
    id: 'stellar',
    name: '星空',
    colors: [Color(0xFF0B0F2B), Color(0xFF1B2A6B)],
    accent: Color(0xFFFCD34D),
    dark: true,
    pattern: 'dots',
  ),
];

CardFace? findBuiltInFace(String id) {
  for (final face in builtInFaces) {
    if (face.id == id) return face;
  }
  return null;
}
