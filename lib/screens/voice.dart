import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../theme.dart';
import '../voice_parser.dart';
import '../widgets.dart';
import 'commandes.dart';

/// Assistant vocal : dictée réelle (français) via le micro, avec repli sur
/// une phrase d'exemple si la reconnaissance n'est pas disponible.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  static const _exemple = "Kôrôba, j'ai reçu 5000 francs d'Aminata pour sa commande de robe";

  final SpeechToText _speech = SpeechToText();
  bool _ecoute = false;
  String _texte = '';
  DicteeResultat? _resultat;
  String? _message;
  Timer? _demo;

  Future<void> _demarrer() async {
    setState(() {
      _texte = '';
      _resultat = null;
      _message = null;
    });
    var dispo = false;
    try {
      dispo = await _speech.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && _ecoute) _terminer();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _ecoute = false;
            _message = "Je n'ai rien entendu. Réessayez ou utilisez la démo.";
          });
        },
      );
    } catch (_) {
      dispo = false;
    }
    if (!dispo) {
      setState(() => _message = 'Reconnaissance vocale indisponible : mode démonstration.');
      _lancerDemo();
      return;
    }
    final locales = await _speech.locales();
    final fr = locales.where((l) => l.localeId.toLowerCase().startsWith('fr')).toList();
    String? localeId;
    if (fr.isNotEmpty) {
      localeId = fr.firstWhere((l) => l.localeId.toLowerCase().replaceAll('-', '_') == 'fr_ci',
          orElse: () => fr.first).localeId;
    }
    if (!mounted) return;
    setState(() => _ecoute = true);
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _texte = r.recognizedWords);
        if (r.finalResult) _terminer();
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      ),
    );
  }

  Future<void> _terminer() async {
    if (!_ecoute) return;
    _ecoute = false;
    await _speech.stop();
    if (!mounted) return;
    setState(() => _resultat = analyserDictee(_texte));
  }

  void _lancerDemo() {
    _demo?.cancel();
    setState(() {
      _ecoute = true;
      _texte = '';
      _resultat = null;
    });
    _demo = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _ecoute = false;
        _texte = _exemple;
        _resultat = analyserDictee(_exemple);
      });
    });
  }

  @override
  void dispose() {
    _demo?.cancel();
    _speech.cancel();
    super.dispose();
  }

  Widget _info(IconData i, String k, String? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(i, size: 18, color: KColors.violet),
            const SizedBox(width: 8),
            Text('$k : ', style: const TextStyle(color: Colors.black54)),
            Expanded(child: Text(v ?? '—', style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = _resultat;
    return Scaffold(
      appBar: AppBar(title: const Text('Parler à Kôrôba'), backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: KGradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _ecoute ? _terminer : _demarrer,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _ecoute ? 150 : 120,
                    height: _ecoute ? 150 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: _ecoute ? [KColors.rose, KColors.orange] : [KColors.violet, KColors.rose]),
                      boxShadow: [BoxShadow(color: KColors.violet.withValues(alpha: 0.35), blurRadius: 24)],
                    ),
                    child: Icon(_ecoute ? Icons.stop : Icons.mic, color: Colors.white, size: 56),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _ecoute ? 'Kôrôba écoute…' : 'Appuyez et parlez',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: KColors.violet),
                ),
                const SizedBox(height: 12),
                if (_message != null)
                  Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: KColors.rose)),
                if (_texte.isEmpty && r == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      "Exemple : « Kôrôba, j'ai reçu 5 000 francs d'Aminata pour sa commande de robe. »",
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_texte.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Text('« $_texte »', textAlign: TextAlign.center),
                  ),
                if (r != null) ...[
                  const SizedBox(height: 16),
                  if (r.vide)
                    const Text("Je n'ai pas bien compris. Dites par exemple : « j'ai reçu 5000 francs d'Aminata pour sa commande de robe ».",
                        textAlign: TextAlign.center)
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: KColors.violet.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          _info(Icons.person, 'Cliente', r.cliente),
                          _info(Icons.payments, 'Montant', r.montant == null ? null : fcfa(r.montant!)),
                          _info(Icons.checkroom, 'Commande', r.type),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (!r.vide)
                    FilledButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NouvelleCommandeScreen(
                            clienteInitiale: r.cliente,
                            acompteInitial: r.montant,
                            descriptionInitiale: r.type,
                          ),
                        ),
                      ),
                      child: const Text('Valider la commande'),
                    ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _ecoute ? null : _lancerDemo,
                  child: const Text("Essayer la phrase d'exemple (démo)"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
