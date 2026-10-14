import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Source unique des données. Tout passe par ici : le jour où un backend
/// sera branché, seul ce fichier devra changer.
class AppStore extends ChangeNotifier {
  late SharedPreferences _p;
  UserProfile? user;
  bool connecte = false;
  List<Commande> commandes = [];
  List<Depense> depenses = [];

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final u = _p.getString('user');
    if (u != null) user = UserProfile.fromJson(jsonDecode(u));
    connecte = user != null && (_p.getBool('connecte') ?? false);
    commandes = (_p.getStringList('commandes') ?? [])
        .map((s) => Commande.fromJson(jsonDecode(s)))
        .toList();
    depenses = (_p.getStringList('depenses') ?? [])
        .map((s) => Depense.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<void> _save() async {
    if (user != null) await _p.setString('user', jsonEncode(user!.toJson()));
    await _p.setBool('connecte', connecte);
    await _p.setStringList('commandes', commandes.map((c) => jsonEncode(c.toJson())).toList());
    await _p.setStringList('depenses', depenses.map((d) => jsonEncode(d.toJson())).toList());
    notifyListeners();
  }

  // ---- Authentification (compte unique sur l'appareil pour le prototype)
  Future<void> inscrire(String nom, String prenom, String mdp) async {
    user = UserProfile(nom: nom.trim(), prenom: prenom.trim(), motDePasse: mdp);
    commandes = [];
    depenses = [];
    connecte = true;
    await _save();
  }

  Future<bool> connecter(String prenom, String mdp) async {
    final u = user;
    if (u == null) return false;
    if (u.prenom.toLowerCase() != prenom.trim().toLowerCase() || u.motDePasse != mdp) {
      return false;
    }
    connecte = true;
    await _save();
    return true;
  }

  Future<void> deconnecter() async {
    connecte = false;
    await _save();
  }

  Future<void> setMetier(Metier m) async {
    user!.metier = m;
    await _save();
  }

  // ---- Commandes et dépenses
  Future<Commande> addCommande({
    required String cliente,
    required String description,
    required double prix,
    required double acompte,
    required String matiere,
    required double coutMatiere,
    required DateTime livraison,
    String telephone = '',
  }) async {
    final c = Commande(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      cliente: cliente,
      description: description,
      prix: prix,
      acompte: acompte,
      matiere: matiere,
      coutMatiere: coutMatiere,
      livraison: livraison,
      creeLe: DateTime.now(),
      telephone: telephone,
    );
    commandes.insert(0, c);
    await _save();
    return c;
  }

  Future<void> basculerTerminee(Commande c) async {
    c.terminee = !c.terminee;
    await _save();
  }

  Future<void> addDepense(String libelle, double montant) async {
    depenses.insert(
      0,
      Depense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        libelle: libelle,
        montant: montant,
        date: DateTime.now(),
      ),
    );
    await _save();
  }

  // ---- Calculs du bilan
  double get recettes => commandes.fold(0, (s, c) => s + c.encaisse);
  double get totalDepenses =>
      depenses.fold<double>(0, (s, d) => s + d.montant) +
      commandes.fold<double>(0, (s, c) => s + c.coutMatiere);
  double get benefice => recettes - totalDepenses;
  int get enCours => commandes.where((c) => !c.terminee).length;
  int get terminees => commandes.where((c) => c.terminee).length;
  double get enAttente =>
      commandes.where((c) => !c.terminee).fold(0, (s, c) => s + c.reste);
}
