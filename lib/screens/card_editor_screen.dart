import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/card_faces.dart';
import '../data/database.dart';
import '../models/bank_card.dart';
import '../services/notification_service.dart';
import '../widgets/card_face_view.dart';

class CardEditorScreen extends StatefulWidget {
  final String cardType;
  final String? cardId;

  const CardEditorScreen({super.key, required this.cardType, this.cardId});

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _limit = TextEditingController();
  final _note = TextEditingController();

  int _billingDate = 0;
  int _repaymentDate = 0;
  String _cardFace = builtInFaces.first.id;
  bool _loading = true;
  bool _saving = false;
  BankCard? _existing;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.cardId != null) {
      final card = await DatabaseHelper.instance.getCard(widget.cardId!);
      if (card != null) {
        setState(() {
          _existing = card;
          _name.text = card.name;
          _bank.text = card.bankName;
          _number.text = card.cardNumber;
          _holder.text = card.cardholderName;
          _expiry.text = card.expiryDate;
          _limit.text = card.creditLimit > 0
              ? card.creditLimit.toStringAsFixed(0)
              : '';
          _note.text = card.note;
          _billingDate = card.billingDate;
          _repaymentDate = card.repaymentDate;
          _cardFace = card.cardFace;
        });
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _bank.dispose();
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _limit.dispose();
    _note.dispose();
    super.dispose();
  }

  BankCard _previewCard() => BankCard(
        id: _existing?.id ?? 'preview',
        name: _name.text.isEmpty ? '卡片名称' : _name.text,
        bankName: _bank.text.isEmpty ? '银行名称' : _bank.text,
        cardType: widget.cardType,
        cardNumber: _mask(_number.text),
        cardholderName: _holder.text,
        expiryDate: _expiry.text,
        creditLimit: double.tryParse(_limit.text) ?? 0,
        billingDate: _billingDate,
        repaymentDate: _repaymentDate,
        cardFace: _cardFace,
        note: _note.text,
        createdAt: _existing?.createdAt ?? 0,
      );

  String _mask(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length <= 4) return '**** **** **** $digits';
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }

  Future<void> _pickImage() async {
    try {
      final xFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xFile == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/cardface_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(await xFile.readAsBytes());
      setState(() => _cardFace = 'custom:${file.path}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('读取图片失败：$e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final card = BankCard(
      id: _existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      bankName: _bank.text.trim(),
      cardType: widget.cardType,
      cardNumber: _mask(_number.text),
      cardholderName: _holder.text.trim(),
      expiryDate: _expiry.text.trim(),
      creditLimit: double.tryParse(_limit.text) ?? 0,
      billingDate: _billingDate,
      repaymentDate: _repaymentDate,
      cardFace: _cardFace,
      note: _note.text.trim(),
      createdAt: _existing?.createdAt ?? now,
    );
    final db = DatabaseHelper.instance;
    if (_existing == null) {
      await db.insertCard(card);
    } else {
      await db.updateCard(card);
    }
    final creditCards =
        await DatabaseHelper.instance.getCards(cardType: CardType.credit);
    await NotificationService.instance.scheduleRepaymentReminders(creditCards);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.cardType == CardType.credit;
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null
            ? '添加${isCredit ? '信用卡' : '借记卡'}'
            : '编辑${isCredit ? '信用卡' : '借记卡'}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CardFaceView(card: _previewCard()),
                    const SizedBox(height: 8),
                    Text(
                      '卡面仅保存在本机；上传的照片只存在你的证件/应用目录中。',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),
                    _faceGallery(),
                    const SizedBox(height: 20),
                    _field(_name, '卡片名称 *', '例如：经典白金卡',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? '请填写卡片名称' : null),
                    const SizedBox(height: 12),
                    _field(_bank, '发卡银行', '例如：招商银行'),
                    const SizedBox(height: 12),
                    _field(_number, '卡号', '建议只填后四位，系统会自动脱敏'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _field(_holder, '持卡人', '姓名拼音')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field(_expiry, '有效期', 'MM/YY')),
                      ],
                    ),
                    if (isCredit) ...[
                      const SizedBox(height: 12),
                      _field(_limit, '信用额度', '例如：50000',
                          keyboard: TextInputType.number),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _dayPicker('账单日', _billingDate, (v) =>
                              setState(() => _billingDate = v))),
                          const SizedBox(width: 12),
                          Expanded(child: _dayPicker('还款日', _repaymentDate, (v) =>
                              setState(() => _repaymentDate = v))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    _field(_note, '备注', '可选'),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(_saving ? '保存中...' : '保存卡片'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      );

  Widget _dayPicker(String label, int value, ValueChanged<int> onChanged) =>
      DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: 0, child: Text('未设置')),
          ...List.generate(31, (i) => i + 1).map(
                (d) => DropdownMenuItem(value: d, child: Text('$d 日')),
              ),
        ],
        onChanged: (v) => onChanged(v ?? 0),
      );

  Widget _faceGallery() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择卡面',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...builtInFaces.map((face) => _faceTile(face.id, face)),
                _uploadTile(),
              ],
            ),
          ),
        ],
      );

  Widget _faceTile(String id, CardFace face) {
    final selected = _cardFace == id;
    return GestureDetector(
      onTap: () => setState(() => _cardFace = id),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: face.colors),
                ),
                child: Center(
                  child: Text(face.name,
                      style: TextStyle(
                          color: face.dark ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.check_circle,
                      color: Colors.white, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadTile() {
    final selected = _cardFace.startsWith('custom:');
    File? file;
    if (selected) {
      final f = File(_cardFace.substring(7));
      if (f.existsSync()) file = f;
    }
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF2563EB) : Colors.grey.shade300,
              width: selected ? 2.5 : 1.5,
              style: selected ? BorderStyle.solid : BorderStyle.solid),
          color: Colors.grey.shade100,
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      color: Colors.grey.shade500, size: 26),
                  const SizedBox(height: 4),
                  Text('上传照片',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(file, fit: BoxFit.cover),
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(Icons.check_circle,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
