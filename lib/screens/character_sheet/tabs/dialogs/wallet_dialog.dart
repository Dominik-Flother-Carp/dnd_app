// lib/screens/character_sheet/tabs/dialogs/wallet_dialog.dart

import 'package:flutter/material.dart';
import 'package:dnd_app/theme/app_text_styles.dart';
import 'package:dnd_app/utils/coin_utils.dart';

class WalletDialogResult {
  final int newWalletCp;
  const WalletDialogResult(this.newWalletCp);
}

class WalletDialog extends StatefulWidget {
  final int walletCp;
  final Color themeColor;

  const WalletDialog({super.key, required this.walletCp, required this.themeColor});

  @override
  State<WalletDialog> createState() => _WalletDialogState();
}

class _WalletDialogState extends State<WalletDialog> {
  late final TextEditingController _ppCtrl;
  late final TextEditingController _gpCtrl;
  late final TextEditingController _epCtrl;
  late final TextEditingController _spCtrl;
  late final TextEditingController _cpCtrl;

  bool _isAdding = true;

  @override
  void initState() {
    super.initState();
    final b = breakdownCopper(widget.walletCp);
    _ppCtrl = TextEditingController(text: b['PP']!.toString());
    _gpCtrl = TextEditingController(text: b['GM']!.toString());
    _epCtrl = TextEditingController(text: b['EM']!.toString());
    _spCtrl = TextEditingController(text: b['SM']!.toString());
    _cpCtrl = TextEditingController(text: b['KM']!.toString());
  }

  @override
  void dispose() {
    _ppCtrl.dispose();
    _gpCtrl.dispose();
    _epCtrl.dispose();
    _spCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  int get _enteredCp =>
      coinToCopper(int.tryParse(_ppCtrl.text) ?? 0, 'PP') +
      coinToCopper(int.tryParse(_gpCtrl.text) ?? 0, 'GM') +
      coinToCopper(int.tryParse(_epCtrl.text) ?? 0, 'EM') +
      coinToCopper(int.tryParse(_spCtrl.text) ?? 0, 'SM') +
      (int.tryParse(_cpCtrl.text) ?? 0);

  void _onSave() {
    final delta  = _enteredCp;
    final newVal = _isAdding
        ? widget.walletCp + delta
        : (widget.walletCp - delta).clamp(0, 999999999);
    Navigator.pop(context, WalletDialogResult(newVal));
  }

  Widget _coinField(String label, TextEditingController ctrl) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTextStyles.labelXs.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Geldbeutel', style: AppTextStyles.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true,  label: Text('Hinzufügen')),
                    ButtonSegment(value: false, label: Text('Ausgeben')),
                  ],
                  selected: {_isAdding},
                  onSelectionChanged: (s) =>
                      setState(() => _isAdding = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return widget.themeColor;
                      }
                      return null;
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _coinField('PP', _ppCtrl),
              const SizedBox(width: 8),
              _coinField('GM', _gpCtrl),
              const SizedBox(width: 8),
              _coinField('EM', _epCtrl),
              const SizedBox(width: 8),
              _coinField('SM', _spCtrl),
              const SizedBox(width: 8),
              _coinField('KM', _cpCtrl),
            ],
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Abbrechen', style: AppTextStyles.body),
            ),
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: widget.themeColor),
              onPressed: _onSave,
              child: Text('OK', style: AppTextStyles.body),
            ),
          ],
        ),
      ],
    );
  }
}
