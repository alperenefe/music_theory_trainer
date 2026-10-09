import 'package:flutter/material.dart';

import '../../audio/ear_audio_types.dart';
import '../../audio/ear_sound.dart';
import '../../l10n/ear_strings.dart';
import '../../models/practice_prefs.dart';
import '../../services/guitar_audio_service.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// Her aralık için kullanıcının kendi referans şarkısını (yükselen / alçalan)
/// yazdığı alt sayfa. Araştırmalar kişinin zaten bildiği bir şarkının, hazır
/// bir listeden çok daha kalıcı bir çapa olduğunu gösteriyor.
final class IntervalAnchorsSheet extends StatefulWidget {
  const IntervalAnchorsSheet({
    super.key,
    required this.prefsRepo,
    required this.initial,
    this.focusKey,
  });

  final PracticePrefsRepository prefsRepo;
  final Map<String, String> initial;

  /// Açılınca odaklanılacak alan (ör. `interval_minor3_down`).
  final String? focusKey;

  /// Sayfayı açar; kaydedildiyse güncel çapaları döner.
  static Future<Map<String, String>?> show(
    BuildContext context,
    PracticePrefsRepository prefsRepo, {
    String? focusKey,
  }) async {
    final prefs = await prefsRepo.load();
    if (!context.mounted) return null;
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IntervalAnchorsSheet(
        prefsRepo: prefsRepo,
        initial: prefs.intervalAnchors,
        focusKey: focusKey,
      ),
    );
  }

  @override
  State<IntervalAnchorsSheet> createState() => _IntervalAnchorsSheetState();
}

final class _IntervalAnchorsSheetState extends State<IntervalAnchorsSheet> {
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};
  var _saving = false;

  @override
  void initState() {
    super.initState();
    for (final t in EarIntervalType.values) {
      for (final down in const [false, true]) {
        final key = PracticePrefs.anchorKey(t.srsKey, descending: down);
        _controllers[key] = TextEditingController(text: widget.initial[key] ?? '');
        _focusNodes[key] = FocusNode();
      }
    }
    final focus = widget.focusKey;
    if (focus != null && _focusNodes.containsKey(focus)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[focus]!.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final anchors = <String, String>{
      for (final e in _controllers.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    final prefs = await widget.prefsRepo.load();
    await widget.prefsRepo.save(prefs.copyWith(intervalAnchors: anchors));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text(EarStrings.anchorsSaved)),
    );
    Navigator.of(context).pop(anchors);
  }

  void _listen(EarIntervalType t, bool down) {
    GuitarAudioService.instance.playSound(
      IntervalSound(rootMidi: 48, interval: t, descending: down),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scroll) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: p.dark ? DesignTokens.slate900 : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
            ),
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  EarStrings.anchorsTitle,
                  style: t.titleLarge?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(EarStrings.anchorsBody, style: t.bodySmall?.copyWith(color: p.textMuted)),
                const SizedBox(height: AppSpacing.md),
                for (final interval in EarIntervalType.values) ...[
                  Text(
                    interval.label,
                    style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  for (final down in const [false, true]) ...[
                    _AnchorField(
                      label: down ? EarStrings.anchorsDown : EarStrings.anchorsUp,
                      hint: EarStrings.anchorsHint(
                        EarStrings.anchorExample(interval, descending: down),
                      ),
                      controller: _controllers[PracticePrefs.anchorKey(interval.srsKey, descending: down)]!,
                      focusNode: _focusNodes[PracticePrefs.anchorKey(interval.srsKey, descending: down)]!,
                      onListen: () => _listen(interval, down),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(EarStrings.anchorsSave),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.earEmerald,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

final class _AnchorField extends StatelessWidget {
  const _AnchorField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.onListen,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            maxLength: PracticePrefs.maxAnchorLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              counterText: '',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          tooltip: EarStrings.lessonListen,
          onPressed: onListen,
          icon: const Icon(Icons.volume_up_rounded),
        ),
      ],
    );
  }
}
