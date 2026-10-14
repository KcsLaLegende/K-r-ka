import 'package:flutter/material.dart';

enum Metier {
  couture('Couture', Icons.checkroom, KColorsRef.rose, 'Tissu', 'Ex. : Robe de cérémonie'),
  coiffure('Coiffure', Icons.face_3, KColorsRef.violet, 'Produits', 'Ex. : Tresses, mèches'),
  restauration('Restauration', Icons.restaurant, KColorsRef.orange, 'Ingrédients', 'Ex. : Repas pour 20 personnes'),
  artisanat('Artisanat', Icons.palette, KColorsRef.vert, 'Matière première', 'Ex. : Panier, poterie');

  const Metier(this.label, this.icone, this.couleur, this.matiereLabel, this.exemple);
  final String label;
  final IconData icone;
  final Color couleur;
  final String matiereLabel;
  final String exemple;
}

// Couleurs dupliquées ici pour pouvoir être utilisées dans l'enum (const).
class KColorsRef {
  static const violet = Color(0xFF6A1B9A);
  static const rose = Color(0xFFD81B8A);
  static const orange = Color(0xFFF59E0B);
  static const vert = Color(0xFF2E9E5B);
}

class UserProfile {
  UserProfile({required this.nom, required this.prenom, required this.motDePasse, this.metier});
  String nom;
  String prenom;
  String motDePasse; // Prototype : stocké en clair. À hasher côté serveur plus tard.
  Metier? metier;

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prenom': prenom,
        'mdp': motDePasse,
        'metier': metier?.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        nom: j['nom'],
        prenom: j['prenom'],
        motDePasse: j['mdp'],
        metier: j['metier'] == null ? null : Metier.values.byName(j['metier']),
      );
}

class Commande {
  Commande({
    required this.id,
    required this.cliente,
    required this.description,
    required this.prix,
    required this.acompte,
    required this.matiere,
    required this.coutMatiere,
    required this.livraison,
    required this.creeLe,
    this.telephone = '',
    this.terminee = false,
  });

  final String id;
  final String cliente;
  final String description;
  final double prix;
  final double acompte;
  final String matiere;
  final double coutMatiere;
  final DateTime livraison;
  final DateTime creeLe;
  final String telephone;
  bool terminee;

  double get reste => (prix - acompte).clamp(0, double.infinity).toDouble();
  double get encaisse => terminee ? prix : acompte;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente': cliente,
        'description': description,
        'prix': prix,
        'acompte': acompte,
        'matiere': matiere,
        'coutMatiere': coutMatiere,
        'livraison': livraison.toIso8601String(),
        'creeLe': creeLe.toIso8601String(),
        'telephone': telephone,
        'terminee': terminee,
      };

  factory Commande.fromJson(Map<String, dynamic> j) => Commande(
        id: j['id'],
        cliente: j['cliente'],
        description: j['description'],
        prix: (j['prix'] as num).toDouble(),
        acompte: (j['acompte'] as num).toDouble(),
        matiere: j['matiere'],
        coutMatiere: (j['coutMatiere'] as num).toDouble(),
        livraison: DateTime.parse(j['livraison']),
        creeLe: DateTime.parse(j['creeLe']),
        telephone: j['telephone'] ?? '',
        terminee: j['terminee'] ?? false,
      );
}

class Depense {
  Depense({required this.id, required this.libelle, required this.montant, required this.date});
  final String id;
  final String libelle;
  final double montant;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'libelle': libelle,
        'montant': montant,
        'date': date.toIso8601String(),
      };

  factory Depense.fromJson(Map<String, dynamic> j) => Depense(
        id: j['id'],
        libelle: j['libelle'],
        montant: (j['montant'] as num).toDouble(),
        date: DateTime.parse(j['date']),
      );
}
