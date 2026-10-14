/// Analyse très simple d'une phrase dictée en français pour en extraire
/// le nom de la cliente, le montant et le type de commande.
class DicteeResultat {
  const DicteeResultat({this.cliente, this.montant, this.type});
  final String? cliente;
  final double? montant;
  final String? type;
  bool get vide => cliente == null && montant == null && type == null;
}

const _mots = <String, int>{
  'un': 1, 'une': 1, 'deux': 2, 'trois': 3, 'quatre': 4, 'cinq': 5, 'six': 6, 'sept': 7,
  'huit': 8, 'neuf': 9, 'dix': 10, 'onze': 11, 'douze': 12, 'treize': 13, 'quatorze': 14,
  'quinze': 15, 'seize': 16, 'vingt': 20, 'vingts': 20, 'trente': 30, 'quarante': 40,
  'cinquante': 50, 'soixante': 60,
};

const _arret = <String>{
  'la', 'le', 'les', 'l', 'un', 'une', 'ma', 'mon', 'sa', 'son', 'ses', 'mes', 'du', 'des',
  'pour', 'robe', 'robes', 'pagne', 'tenue', 'commande', 'francs', 'franc', 'fcfa', 'cfa',
  'mille', 'repas', 'tresses', 'tissu',
};

double? _montantEnChiffres(String t) {
  var s = t;
  final groupe = RegExp(r'(\d)[\s\u00a0\u202f.](\d{3})(?!\d)');
  while (groupe.hasMatch(s)) {
    s = s.replaceAllMapped(groupe, (m) => '${m[1]}${m[2]}');
  }
  final m = RegExp(r'(\d+)(?:\s*(mille|k)\b)?').firstMatch(s);
  if (m == null) return null;
  var v = double.parse(m[1]!);
  if (m[2] != null) v *= 1000;
  return v;
}

double? _montantEnMots(String t) {
  final tokens = t
      .split(RegExp(r"[^a-zàâäéèêëîïôöùûüç]+"))
      .where((e) => e.isNotEmpty)
      .toList();
  var meilleur = 0;
  var total = 0, courant = 0;
  var actif = false;
  var prec = '';

  void fin() {
    final v = total + courant;
    if (actif && v > meilleur) meilleur = v;
    total = 0;
    courant = 0;
    actif = false;
    prec = '';
  }

  for (final w in tokens) {
    if (_mots.containsKey(w)) {
      if ((w == 'vingt' || w == 'vingts') && prec == 'quatre') {
        courant = courant - 4 + 80;
      } else {
        courant += _mots[w]!;
      }
      actif = true;
      prec = w;
    } else if (w == 'cent' || w == 'cents') {
      courant = (courant == 0 ? 1 : courant) * 100;
      actif = true;
      prec = w;
    } else if (w == 'mille') {
      total += (courant == 0 ? 1 : courant) * 1000;
      courant = 0;
      actif = true;
      prec = w;
    } else if (w == 'et') {
      continue;
    } else {
      fin();
    }
  }
  fin();
  return meilleur >= 100 ? meilleur.toDouble() : null;
}

String _majuscule(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String? _cliente(String t) {
  final re = RegExp(r"(?:^|\s)(?:de\s+|d['’]\s*|chez\s+|madame\s+|mme\s+|dame\s+|cliente\s+)([\p{L}-]{2,})", unicode: true);
  for (final m in re.allMatches(t)) {
    final nom = m[1]!;
    if (!_arret.contains(nom)) return _majuscule(nom);
  }
  return null;
}

String? _type(String t) {
  final m = RegExp(r"commande\s+(?:de|d['’]|du|des)\s*([\p{L}-]+(?:\s+de\s+[\p{L}-]+)?)", unicode: true)
      .firstMatch(t);
  return m == null ? null : _majuscule(m[1]!);
}

DicteeResultat analyserDictee(String texte) {
  final t = texte.toLowerCase().trim();
  if (t.isEmpty) return const DicteeResultat();
  return DicteeResultat(
    cliente: _cliente(t),
    montant: _montantEnChiffres(t) ?? _montantEnMots(t),
    type: _type(t),
  );
}
