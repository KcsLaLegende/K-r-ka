import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'theme.dart' show fcfa, dateFr;

/// Lien de paiement SIMULÉ (aucun vrai paiement dans le prototype).
String payLinkSimule(Commande c) {
  final id = c.id.length > 8 ? c.id.substring(c.id.length - 8) : c.id;
  return 'https://pay.koroba.ci/p/$id';
}

String messageRelance(Commande c, UserProfile u) {
  return 'Bonjour ${c.cliente}, c\'est ${u.prenom} (${u.metier!.label}). '
      'Petit rappel pour votre commande « ${c.description} » : '
      'il reste ${fcfa(c.reste)} à régler (acompte déjà versé : ${fcfa(c.acompte)}). '
      'Livraison prévue le ${dateFr(c.livraison)}. '
      'Vous pouvez payer par Wave ou Orange Money ici : ${payLinkSimule(c)} '
      'Merci !';
}

/// Normalise un numéro ivoirien au format international sans « + » (ex. 2250700000000).
String? numeroWhatsApp(String saisie) {
  var d = saisie.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return null;
  if (d.startsWith('00')) d = d.substring(2);
  if (d.length == 10 || d.length == 8) d = '225$d';
  return d;
}

/// Ouvre WhatsApp avec le message pré-rédigé. Sans numéro, WhatsApp
/// laisse choisir le contact.
Future<bool> relancerWhatsApp(Commande c, UserProfile u) async {
  final n = numeroWhatsApp(c.telephone);
  final texte = Uri.encodeComponent(messageRelance(c, u));
  final uri = Uri.parse(n == null ? 'https://wa.me/?text=$texte' : 'https://wa.me/$n?text=$texte');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
