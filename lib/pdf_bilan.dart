import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'store.dart';
import 'theme.dart' show fcfa, dateFr;

/// Génère le « Pass Bilan » (PDF global sur toutes les données enregistrées).
/// Police standard du package pdf : on évite volontairement les caractères
/// hors Latin-1 (tirets longs, apostrophes courbes) pour ne pas casser le rendu.
Future<Uint8List> genererBilanPdf(AppStore s) async {
  final doc = pw.Document();
  final u = s.user!;
  const violet = PdfColor.fromInt(0xFF6A1B9A);
  final now = DateTime.now();
  final idRapport = 'KOR-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

  // Période couverte par les données
  final dates = <DateTime>[
    ...s.commandes.map((c) => c.creeLe),
    ...s.depenses.map((d) => d.date),
  ]..sort();
  final periode = dates.isEmpty
      ? 'Aucune donnée enregistrée'
      : 'Du ${dateFr(dates.first)} au ${dateFr(dates.last)}';

  pw.Widget titre(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
        child: pw.Text(t,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: violet)),
      );

  pw.Widget ligne(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [pw.Text(k), pw.Text(v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
        ),
      );

  pw.Widget tableau(List<String> entetes, List<List<String>> lignes) =>
      pw.TableHelper.fromTextArray(
        headers: entetes,
        data: lignes,
        headerDecoration: const pw.BoxDecoration(color: violet),
        headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      );

  // Dépenses = dépenses saisies + coût des matières des commandes
  final lignesDepenses = <List<String>>[
    for (final d in s.depenses) [d.libelle, dateFr(d.date), fcfa(d.montant)],
    for (final c in s.commandes)
      if (c.coutMatiere > 0)
        [
          '${c.matiere.isEmpty ? 'Matiere' : c.matiere} (${c.cliente})',
          dateFr(c.creeLe),
          fcfa(c.coutMatiere),
        ],
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Divider(color: PdfColors.grey400),
          pw.Text(
            'Rapport genere par Kôrôba. Donnees declarees par l\'utilisatrice, non certifiees a ce stade.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text('Identifiant du rapport : $idRapport   |   Page ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
      build: (ctx) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Kôrôba',
                style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: violet)),
            pw.Text('Pass Bilan',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Text('Mon activite, mon argent, mon avenir.',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
        pw.SizedBox(height: 14),
        ligne('Titulaire', '${u.prenom} ${u.nom}'),
        ligne('Activite', u.metier!.label),
        ligne('Periode couverte', periode),
        ligne('Date d\'edition', dateFr(now)),
        titre('Synthese financiere'),
        ligne('Recettes encaissees', fcfa(s.recettes)),
        ligne('Depenses (matieres incluses)', fcfa(s.totalDepenses)),
        ligne('Benefice estime', fcfa(s.benefice)),
        ligne('Commandes terminees', '${s.terminees}'),
        ligne('Commandes en cours', '${s.enCours}'),
        ligne('Paiements en attente', fcfa(s.enAttente)),
        titre('Commandes'),
        s.commandes.isEmpty
            ? pw.Text('Aucune commande.')
            : tableau(
                ['Cliente', 'Commande', 'Prix', 'Acompte', 'Statut'],
                [
                  for (final c in s.commandes)
                    [c.cliente, c.description, fcfa(c.prix), fcfa(c.acompte), c.terminee ? 'Terminee' : 'En cours'],
                ],
              ),
        titre('Depenses'),
        lignesDepenses.isEmpty
            ? pw.Text('Aucune depense.')
            : tableau(['Libelle', 'Date', 'Montant'], lignesDepenses),
      ],
    ),
  );
  return doc.save();
}
