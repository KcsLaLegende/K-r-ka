import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../theme.dart';
import 'commandes.dart';
import 'finances.dart';
import 'voice.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(onVoirBilan: () => setState(() => _index = 2)),
      const CommandesTab(),
      const FinancesTab(),
      const ProfilTab(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Commandes'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finances'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.valeur, required this.couleur, required this.icone});
  final String label;
  final String valeur;
  final Color couleur;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: couleur, radius: 18, child: Icon(icone, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(valeur, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.onVoirBilan});
  final VoidCallback onVoirBilan;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final metier = s.user!.metier!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [KColors.violet, KColors.rose]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: KColors.violet.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour ${s.user!.prenom} !',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Activité : ${metier.label}', style: const TextStyle(color: Colors.white70)),
                    const Text('Voici votre situation du jour.', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Image.asset('assets/images/silhouette.png', height: 92),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: [
            StatCard(label: 'Recettes', valeur: fcfa(s.recettes), couleur: KColors.vert, icone: Icons.payments),
            StatCard(label: 'Dépenses', valeur: fcfa(s.totalDepenses), couleur: KColors.rose, icone: Icons.shopping_bag),
            StatCard(label: 'Bénéfice estimé', valeur: fcfa(s.benefice), couleur: KColors.bleu, icone: Icons.trending_up),
            StatCard(label: 'Commandes en cours', valeur: '${s.enCours}', couleur: KColors.violet, icone: Icons.assignment),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Actions rapides', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Action(Icons.add, 'Nouvelle\ncommande', KColors.rose,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NouvelleCommandeScreen()))),
            _Action(Icons.account_balance_wallet, 'Ajouter\nune dépense', KColors.orange,
                () => showAjoutDepense(context)),
            _Action(Icons.bar_chart, 'Voir\nmon bilan', KColors.vert, onVoirBilan),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.mic),
          label: const Text('Parler à Kôrôba'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceScreen())),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icone, this.label, this.couleur, this.onTap);
  final IconData icone;
  final String label;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: couleur, child: Icon(icone, color: Colors.white, size: 28)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final u = s.user!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/images/silhouette.png'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('${u.prenom} ${u.nom}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KColors.violet)),
        ),
        Center(child: Text(u.metier!.label)),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          onPressed: () => s.deconnecter(),
        ),
      ],
    );
  }
}
