import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KGradientBg(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                const KLogo(),
                const SizedBox(height: 6),
                const Text('Mon activité, mon argent, mon avenir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: KColors.rose, fontStyle: FontStyle.italic)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Image.asset('assets/images/couturiere.png', fit: BoxFit.contain),
                  ),
                ),
                const Text(
                  'Gérez facilement vos commandes, acomptes, dépenses, bénéfices et paiements.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: KColors.rose),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AuthScreen(inscription: true))),
                  child: const Text('Commencer'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AuthScreen(inscription: false))),
                  child: const Text('Déjà inscrite ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.inscription});
  final bool inscription;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _mdp = TextEditingController();
  bool _masque = true;

  String? _requis(String? v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  Future<void> _valider() async {
    if (!_form.currentState!.validate()) return;
    final store = context.read<AppStore>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (widget.inscription) {
      await store.inscrire(_nom.text, _prenom.text, _mdp.text);
      nav.popUntil((r) => r.isFirst);
    } else {
      final ok = await store.connecter(_prenom.text, _mdp.text);
      if (ok) {
        nav.popUntil((r) => r.isFirst);
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(store.user == null
              ? "Aucun compte trouvé. Veuillez vous inscrire."
              : 'Prénom ou mot de passe incorrect.'),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _mdp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.inscription ? 'Inscription' : 'Connexion')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              children: [
                if (widget.inscription) ...[
                  TextFormField(
                    controller: _nom,
                    validator: _requis,
                    decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _prenom,
                  validator: _requis,
                  decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mdp,
                  obscureText: _masque,
                  validator: (v) => (v == null || v.length < 4) ? '4 caractères minimum' : null,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_masque ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _masque = !_masque),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _valider,
                  child: Text(widget.inscription ? "S'inscrire" : 'Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MetierScreen extends StatefulWidget {
  const MetierScreen({super.key});

  @override
  State<MetierScreen> createState() => _MetierScreenState();
}

class _MetierScreenState extends State<MetierScreen> {
  Metier? _choix;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text('Quel est votre métier ?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: KColors.violet)),
              const SizedBox(height: 8),
              const Text('Choisissez votre activité principale'),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    for (final m in Metier.values)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _choix = m),
                        child: Container(
                          decoration: BoxDecoration(
                            color: m.couleur.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _choix == m ? m.couleur : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(m.icone, size: 52, color: m.couleur),
                              const SizedBox(height: 10),
                              Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _choix == null ? null : () => context.read<AppStore>().setMetier(_choix!),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
