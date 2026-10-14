import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../theme.dart';
import 'package:printing/printing.dart';
import '../pdf_bilan.dart';
import 'home.dart';

Future<void> showAjoutDepense(BuildContext context) async {
  final libelle = TextEditingController();
  final montant = TextEditingController();
  final store = context.read<AppStore>();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ajouter une dépense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: libelle, decoration: const InputDecoration(labelText: 'Libellé')),
          const SizedBox(height: 12),
          TextField(
            controller: montant,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () {
            final m = double.tryParse(montant.text) ?? 0;
            if (libelle.text.trim().isEmpty || m <= 0) return;
            store.addDepense(libelle.text.trim(), m);
            Navigator.pop(ctx);
          },
          child: const Text('Ajouter'),
        ),
      ],
    ),
  );
}

class FinancesTab extends StatelessWidget {
  const FinancesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final maxVal = [s.recettes, s.totalDepenses, s.benefice.abs(), s.enAttente]
        .reduce((a, b) => a > b ? a : b);
    Widget barre(String label, double v, Color c) {
      final h = maxVal == 0 ? 4.0 : (v.abs() / maxVal * 110).clamp(4.0, 110.0);
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
              width: 34, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Mon bilan')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: KColors.orange,
        foregroundColor: Colors.white,
        onPressed: () => showAjoutDepense(context),
        icon: const Icon(Icons.add),
        label: const Text('Dépense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          StatCard(label: 'Recettes', valeur: fcfa(s.recettes), couleur: KColors.vert, icone: Icons.payments),
          const SizedBox(height: 8),
          StatCard(label: 'Dépenses (matières incluses)', valeur: fcfa(s.totalDepenses), couleur: KColors.rose, icone: Icons.shopping_bag),
          const SizedBox(height: 8),
          StatCard(label: 'Bénéfice estimé', valeur: fcfa(s.benefice), couleur: KColors.bleu, icone: Icons.trending_up),
          const SizedBox(height: 8),
          StatCard(label: 'Commandes terminées', valeur: '${s.terminees}', couleur: KColors.violet, icone: Icons.check_circle),
          const SizedBox(height: 8),
          StatCard(label: 'Paiements en attente', valeur: fcfa(s.enAttente), couleur: KColors.orange, icone: Icons.hourglass_bottom),
          const SizedBox(height: 20),
          const Text("Graphique de l'activité", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                barre('Recettes', s.recettes, KColors.vert),
                barre('Dépenses', s.totalDepenses, KColors.rose),
                barre('Bénéfice', s.benefice, KColors.bleu),
                barre('Attente', s.enAttente, KColors.orange),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Télécharger mon rapport PDF'),
            onPressed: () => Printing.layoutPdf(
              name: 'pass_bilan_koroba.pdf',
              onLayout: (_) => genererBilanPdf(s),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Dépenses enregistrées', style: TextStyle(fontWeight: FontWeight.w700)),
          if (s.depenses.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text('Aucune dépense ajoutée.')),
          for (final d in s.depenses)
            ListTile(
              dense: true,
              title: Text(d.libelle),
              subtitle: Text(dateFr(d.date)),
              trailing: Text(fcfa(d.montant), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
