import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../relance.dart';
import '../theme.dart';
import '../widgets.dart';

class CommandesTab extends StatelessWidget {
  const CommandesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Mes commandes')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: KColors.rose,
        foregroundColor: Colors.white,
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NouvelleCommandeScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle commande'),
      ),
      body: s.commandes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/couturiere.png', height: 190),
                  const SizedBox(height: 12),
                  const Text('Aucune commande pour le moment.'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: s.commandes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = s.commandes[i];
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => FicheCommandeScreen(commande: c))),
                    title: Text('${c.description} — ${c.cliente}'),
                    subtitle: Text('Livraison : ${dateFr(c.livraison)}\nReste : ${fcfa(c.reste)}'),
                    isThreeLine: true,
                    trailing: Chip(
                      label: Text(c.terminee ? 'Terminée' : 'En cours'),
                      backgroundColor: (c.terminee ? KColors.vert : KColors.orange).withValues(alpha: 0.2),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class NouvelleCommandeScreen extends StatefulWidget {
  const NouvelleCommandeScreen(
      {super.key, this.clienteInitiale, this.acompteInitial, this.descriptionInitiale});
  final String? clienteInitiale;
  final double? acompteInitial;
  final String? descriptionInitiale;

  @override
  State<NouvelleCommandeScreen> createState() => _NouvelleCommandeScreenState();
}

class _NouvelleCommandeScreenState extends State<NouvelleCommandeScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _cliente;
  late final TextEditingController _description;
  final _telephone = TextEditingController();
  final _prix = TextEditingController();
  late final TextEditingController _acompte;
  final _matiere = TextEditingController();
  final _coutMatiere = TextEditingController();
  DateTime _livraison = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _cliente = TextEditingController(text: widget.clienteInitiale ?? '');
    _description = TextEditingController(text: widget.descriptionInitiale ?? '');
    _acompte = TextEditingController(
        text: widget.acompteInitial == null ? '' : widget.acompteInitial!.round().toString());
  }

  @override
  void dispose() {
    for (final c in [_cliente, _description, _telephone, _prix, _acompte, _matiere, _coutMatiere]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.replaceAll(' ', '')) ?? 0;

  String? _requis(String? v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null;

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _livraison,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _livraison = d);
  }

  Future<void> _enregistrer() async {
    if (!_form.currentState!.validate()) return;
    if (_num(_acompte) > _num(_prix)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("L'acompte dépasse le prix total.")));
      return;
    }
    final nav = Navigator.of(context);
    final c = await context.read<AppStore>().addCommande(
          cliente: _cliente.text.trim(),
          telephone: _telephone.text.trim(),
          description: _description.text.trim(),
          prix: _num(_prix),
          acompte: _num(_acompte),
          matiere: _matiere.text.trim(),
          coutMatiere: _num(_coutMatiere),
          livraison: _livraison,
        );
    nav.pushReplacement(MaterialPageRoute(builder: (_) => FicheCommandeScreen(commande: c)));
  }

  @override
  Widget build(BuildContext context) {
    final metier = context.read<AppStore>().user!.metier!;
    final reste = (_num(_prix) - _num(_acompte)).clamp(0, double.infinity);
    const gap = SizedBox(height: 14);
    final nombre = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle commande')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            onChanged: () => setState(() {}),
            child: Column(
              children: [
                TextFormField(
                  controller: _cliente,
                  validator: _requis,
                  decoration: const InputDecoration(labelText: 'Nom de la cliente', prefixIcon: Icon(Icons.person)),
                ),
                gap,
                TextFormField(
                  controller: _telephone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Téléphone de la cliente (WhatsApp)',
                      hintText: '07 00 00 00 00',
                      prefixIcon: Icon(Icons.phone)),
                ),
                gap,
                TextFormField(
                  controller: _description,
                  validator: _requis,
                  decoration: InputDecoration(
                      labelText: 'Type de commande', hintText: metier.exemple, prefixIcon: const Icon(Icons.checkroom)),
                ),
                gap,
                TextFormField(
                  controller: _prix,
                  validator: _requis,
                  keyboardType: TextInputType.number,
                  inputFormatters: nombre,
                  decoration: const InputDecoration(labelText: 'Prix total (FCFA)', prefixIcon: Icon(Icons.sell)),
                ),
                gap,
                TextFormField(
                  controller: _acompte,
                  keyboardType: TextInputType.number,
                  inputFormatters: nombre,
                  decoration: const InputDecoration(labelText: 'Acompte versé (FCFA)', prefixIcon: Icon(Icons.savings)),
                ),
                gap,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: KColors.rose.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Text('Reste à payer : ${fcfa(reste)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: KColors.rose, fontSize: 16)),
                ),
                gap,
                TextFormField(
                  controller: _matiere,
                  decoration: InputDecoration(
                      labelText: '${metier.matiereLabel} utilisé(e)', prefixIcon: const Icon(Icons.inventory_2)),
                ),
                gap,
                TextFormField(
                  controller: _coutMatiere,
                  keyboardType: TextInputType.number,
                  inputFormatters: nombre,
                  decoration: InputDecoration(
                      labelText: 'Coût : ${metier.matiereLabel.toLowerCase()} (FCFA)',
                      prefixIcon: const Icon(Icons.shopping_cart)),
                ),
                gap,
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: const Icon(Icons.event),
                  title: const Text('Date de livraison'),
                  subtitle: Text(dateFr(_livraison)),
                  onTap: _choisirDate,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                  onPressed: _enregistrer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FicheCommandeScreen extends StatelessWidget {
  const FicheCommandeScreen({super.key, required this.commande});
  final Commande commande;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = commande;
    Widget ligne(String k, String v, {Color? couleur}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(k, style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 16),
              Flexible(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w700, color: couleur)),
              ),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche de commande')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(c.description,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: KColors.violet)),
                    const Divider(height: 28),
                    ligne('Cliente', c.cliente),
                    ligne('Prix total', fcfa(c.prix)),
                    ligne('Acompte versé', fcfa(c.acompte), couleur: KColors.vert),
                    ligne('Reste à payer', fcfa(c.reste), couleur: KColors.rose),
                    ligne(c.matiere.isEmpty ? 'Matière' : c.matiere, fcfa(c.coutMatiere)),
                    ligne('Livraison', dateFr(c.livraison)),
                    if (c.telephone.isNotEmpty) ligne('Téléphone', c.telephone),
                    ligne('Statut', c.terminee ? 'Terminée (soldée)' : 'En cours'),
                  ],
                ),
              ),
            ),
            if (!c.terminee && c.reste > 0) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Relance de paiement', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('Lien de paiement (simulé)',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(payLinkSimule(c), style: const TextStyle(color: KColors.bleu)),
                      const Text('Payable par Wave / Orange Money',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                        icon: const Icon(Icons.chat),
                        label: const Text('Relancer sur WhatsApp'),
                        onPressed: () async {
                          final ok = await relancerWhatsApp(c, s.user!);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Impossible d'ouvrir WhatsApp.")));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.terminee ? KColors.orange : KColors.vert),
              onPressed: () => s.basculerTerminee(c),
              child: Text(c.terminee ? 'Rouvrir la commande' : 'Marquer comme terminée et soldée'),
            ),
          ],
        ),
      ),
    );
  }
}
