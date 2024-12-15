# Base de Données Hospitalière
Base de données hospitalière (PostgreSQL) normalisée et sécurisée avec RBAC et déclencheurs. Gère les patients, employés, chambres, traitements, équipements, assurances et facturation.

## Présentation du Projet

Ce projet met en œuvre une base de données relationnelle pour la gestion complète d’un hôpital. Elle permet de modéliser, de façon claire et normalisée, les activités clés : patients, employés (médecins, infirmières, techniciens), chambres, traitements, équipements, assurances et facturation. L’objectif est d’assurer une cohérence interne, une sécurité des données renforcée (via rôles et privilèges) et une maintenance aisée.

La base de données est conçue pour PostgreSQL, un SGBD robuste et performant, garantissant l’intégrité, la stabilité et la scalabilité des données.

---

## Contexte et Objectifs

# Objectifs principaux :

- Modélisation cohérente: Représenter fidèlement les entités hospitalières (patients, employés, chambres, départements, équipements, traitements, assurances, facturation).
- Intégrité et sécurité: Garantir la cohérence des données (clés primaires, clés étrangères, contraintes) et leur accès sécurisé (rôles, privilèges).
- Automatisation via Triggers: Automatiser certaines logiques métier (calculs de factures, gestion du stock, occupation des lits).
- Normalisation avancée: Éliminer redondances et anomalies, jusqu’à la BCNF, assurant des opérations (SELECT, INSERT, UPDATE, DELETE) fiables et performantes.

---

## Structure et Modélisation

La base repose sur le schéma `hopital`. Toutes les tables, contraintes et relations y sont définies. Les principales entités comprennent :

- Patients: Informations personnelles, contacts, conditions médicales.
- Employés: Infos sur le personnel (médecins, infirmières, techniciens), leurs rôles et contacts.
- Chambres: Types, capacités, occupation des lits.
- Départements: Organisation interne (ex. cardiologie), chef de département.
- Équipements Médicaux: Inventaire, stock, réapprovisionnement.
- Traitements: Catalogue de traitements, tarifs, prérequis, historique des soins.
- Assurances: Polices d’assurance, liens avec les patients, impact sur la facturation.
- Facturation: Factures intermédiaires, finales, montant total, remboursement, montant à payer.

Les contraintes (UNIQUE, NOT NULL, CHECK), les clés primaires, étrangères et les types énumérés (ex. type_numero_chambre) renforcent la cohérence interne et la validité des données.

---

## Normalisation et Intégrité

La base de données est normalisée jusqu’en BCNF :

- 1NF: Valeurs atomiques.
- 2NF: Aucune dépendance partielle sur partie de clé primaire.
- 3NF / BCNF: Aucune dépendance fonctionnelle non triviale entre attributs non clés.

Cette normalisation favorise une maintenance simplifiée, réduit les risques d’anomalies et améliore les performances des requêtes.

---

## Rôles, Utilisateurs et Privilèges

Pour sécuriser l’accès aux données, plusieurs rôles et utilisateurs sont définis :

Rôles :
- **`role_personnel` (Rôle de base)**  
  Rôle générique dont héritent certains rôles spécialisés. Il pourrait permettre un accès minimal en lecture à certaines données (ex. tables communes comme `patient_details` en lecture seule).

- **Rôles spécialisés héritant de `role_personnel` :**
  - **`role_medecin` :** Hérite de `role_personnel`.  
    Accès en lecture/écriture sur les données patients, admissions, traitements administrés, et certaines tables liées aux actes médicaux (ex. `consultations_externes`). Le médecin peut ainsi consulter et mettre à jour les informations relatives aux soins.
  
  - **`role_infirmiere` :** Hérite de `role_personnel`.  
    Accès principalement en lecture sur les patients et conditions médicales. Peut mettre à jour certains champs comme la présence aux consultations (ex. `presence_consultations`), gérer les admissions. L’infirmière a donc des droits intermédiaires entre la simple consultation et la mise à jour de certaines informations opérationnelles.
  
  - **`role_technicien` :** Hérite de `role_personnel`.  
    Accès pour gérer l’inventaire des équipements médicaux et le stock (`equipement_medical`, `stock_equipement`). Peut mettre à jour les quantités, surveiller le niveau de réapprovisionnement, etc.

- **`role_admin` (Rôle Administrateur) :**  
  Dispose de tous les privilèges (ALL PRIVILEGES) sur toutes les tables du schéma `hopital`. L’administrateur peut gérer la structure de la base (ajouter des tables, modifier des colonnes, gérer les rôles et privilèges).

### Utilisateurs et Attribution des Rôles

- `admin_hopital` : Assigné à `role_admin`. Peut tout faire.
- `medecin_jean` : Assigné à `role_medecin`. Peut consulter et mettre à jour les données médicales nécessaires.
- `infirmiere_claire` : Assignée à `role_infirmiere`. Peut consulter les patients, mettre à jour la présence aux consultations, gérer les admissions.
- `technicien_paul` : Assigné à `role_technicien`. Peut gérer les équipements, mettre à jour le stock et surveiller les réapprovisionnements.

Cette hiérarchie de rôles permet un contrôle d’accès adapté aux besoins fonctionnels de chaque type de personnel. Les médecins ont plus de droits que les infirmières, lesquelles en ont plus que le simple rôle de personnel de base, tandis que le technicien opère sur un domaine spécifique (équipements). L’administrateur a une vue et des droits complets.

---

## Triggers (Fonctions de Déclenchement)

Des triggers PL/pgSQL implémentent la logique métier :

- **Facture Intermédiaire :** Calcul automatique des coûts (consultations, médecins spécialisés, chambres, traitements) lors de l’insertion d’une facture intermédiaire.
- **Facture Finale :** Application du pourcentage de remboursement d’assurance, calcul du montant final à payer lors de l’insertion d’une facture finale.
- **Gestion du Stock :** Notification lors de la mise à jour du stock, si le niveau descend sous le seuil de réapprovisionnement.
- **Gestion des Lits :** Mise à jour automatique du nombre de lits occupés lors d’admissions ou de sorties de patients.

---

## Guide d’Utilisation

### Installation

1. Installer PostgreSQL.
2. Créer la base de données `hopital` :
   ```sql
   CREATE DATABASE hopital;


#    Se connecter à la base de données :
- \c hopital


#    Exécuter le script SQL principal hopital_bdd_finale.sql :
- psql -U votre_utilisateur -d hopital -f hopital_bdd_finale.sql

#    Intégration des Données :
- Insérez les données initiales (patients, employés, départements, etc.) selon vos besoins.
- Les tables sont normalisées, ce qui simplifie l’écriture de requêtes pour récupérer des informations cohérentes.

#    Exploitation :
- Les rôles utilisateurs peuvent être testés en se connectant au SGBD avec l’utilisateur correspondant (ex. medecin_jean) pour vérifier les privilèges accordés.
- Les triggers fonctionneront automatiquement lors des insertions, mises à jour ou suppressions d’enregistrements (selon leur définition).

#    Maintenance :
- En cas de modifications structurelles, mettez à jour les schémas, contraintes et triggers.
- Utilisez les rôles admin pour intervenir en profondeur (création de nouvelles tables, ajustements de colonnes, etc.).

# Conclusion

Ce projet constitue une base solide pour la gestion informatisée et sécurisée d’un hôpital. La conception a été réalisée en suivant les bonnes pratiques de normalisation, d’intégrité référentielle, de mise en place de rôles et de privilèges, ainsi que de logique métier au moyen de triggers. Le résultat est une base de données robuste, évolutive et claire, adaptée à l’implémentation future d’applications front-end ou d’outils d’analyse de données (Data Analytics, BI).# Base_de_donnees_hopital_normalisee
