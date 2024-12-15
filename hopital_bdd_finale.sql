-- Création du schéma 'hopital'
CREATE SCHEMA hopital;

SET search_path TO hopital;

-- Type énuméré pour les numéros de chambre (codes de chambres prédéfinis)
CREATE TYPE type_numero_chambre AS ENUM (
    'CH001', 'CH002', 'CH003', 'CH004', 'CH005',
    'CH101', 'CH102', 'CH103', 'CH104', 'CH105',
    'CH201', 'CH202', 'CH203', 'CH204', 'CH301',
    'CH302', 'CH303', 'CH304', 'CH305', 'CH401',
    'CH402', 'CH403', 'CH404', 'CH405'
);

-- Table patient_details : Informations générales sur les patients
CREATE TABLE patient_details (
    patient_id DECIMAL(9,0),
    prenom VARCHAR(20) NOT NULL,
    initiale CHAR(1),
    nom VARCHAR(20),
    sexe CHAR(1),
    date_naissance DATE,
    adresse VARCHAR(100),
    ville VARCHAR(50),
    etat VARCHAR(50),
    pays VARCHAR(50),
    numero_contact VARCHAR(15),
    numero_contact_parent VARCHAR(15),
    PRIMARY KEY (patient_id)
);

-- Table patient_conditions_medicales : Conditions médicales associées à chaque patient
CREATE TABLE patient_conditions_medicales (
    patient_id DECIMAL(9,0),
    condition_medicale VARCHAR(100),
    PRIMARY KEY (patient_id, condition_medicale),
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table patient_contacts : Différents types de contacts d’un patient (ex : principal, parent)
CREATE TABLE patient_contacts (
    patient_id DECIMAL(9,0),
    type_contact VARCHAR(20),
    numero_contact VARCHAR(15),
    PRIMARY KEY (patient_id, type_contact),
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table employe : Informations sur le personnel de l'hôpital (médecins, infirmières, administratifs, etc.)
CREATE TABLE employe (
    employe_id DECIMAL(9,0),
    type_employe VARCHAR(20) NOT NULL,
    prenom VARCHAR(20) NOT NULL,
    initiale CHAR(1),
    nom VARCHAR(20),
    date_naissance DATE,
    sexe CHAR(1),
    adresse VARCHAR(100),
    ville VARCHAR(50),
    etat VARCHAR(50),
    pays VARCHAR(50),
    date_embauche DATE NOT NULL,
    date_demission DATE,
    PRIMARY KEY (employe_id)
);

-- Table employe_contacts : Contacts des employés (ex : principal, urgence)
CREATE TABLE employe_contacts (
    employe_id DECIMAL(9,0),
    type_contact VARCHAR(20),
    numero_contact VARCHAR(15),
    PRIMARY KEY (employe_id, type_contact),
    FOREIGN KEY (employe_id) REFERENCES employe(employe_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table type_chambre : Types de chambres (avec une abréviation unique et un coût par lit)
CREATE TABLE type_chambre (
    type_chambre VARCHAR(30),
    abbrev_type VARCHAR(4) UNIQUE,
    cout_par_lit INT NOT NULL
);

-- Table chambre_details : Détails des chambres (numéro, type, capacité, lits occupés)
CREATE TABLE chambre_details (
    numero_chambre type_numero_chambre,
    abbrev_type VARCHAR(4) NOT NULL,
    capacite INT NOT NULL,
    lits_occupees INT,
    PRIMARY KEY (numero_chambre),
    FOREIGN KEY (abbrev_type) REFERENCES type_chambre(abbrev_type)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table departement : Départements de l’hôpital (ex : cardiologie, radiologie)
CREATE TABLE departement (
    dep_no SMALLINT,
    nom_departement VARCHAR(50) NOT NULL,
    chef_dep_id DECIMAL(9,0),
    PRIMARY KEY (dep_no)
);

-- Ajout de la clé étrangère chef_dep_id -> employe_id (le chef de département)
ALTER TABLE departement
ADD FOREIGN KEY (chef_dep_id) REFERENCES employe(employe_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Table medecins : Détails supplémentaires sur les médecins (leur département, qualification)
CREATE TABLE medecins (
    employe_id DECIMAL(9,0),
    qualification VARCHAR(50),
    dep_no SMALLINT NOT NULL,
    PRIMARY KEY (employe_id),
    FOREIGN KEY (employe_id) REFERENCES employe(employe_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (dep_no) REFERENCES departement(dep_no)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Table equipement_medical : Liste des équipements médicaux (nom, coût, type)
CREATE TABLE equipement_medical (
    equipement_id INT,
    nom VARCHAR(100) NOT NULL,
    cout INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    PRIMARY KEY (equipement_id)
);

-- Table stock_equipement : Gestion du stock des équipements par département
CREATE TABLE stock_equipement (
    equipement_id INT,
    dep_no SMALLINT NOT NULL,
    quantite INT,
    niveau_reapprovisionnement INT,
    PRIMARY KEY (equipement_id, dep_no),
    FOREIGN KEY (equipement_id) REFERENCES equipement_medical(equipement_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (dep_no) REFERENCES departement(dep_no)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table consultations_externes : Informations sur les consultations externes (frais, médecin concerné)
CREATE TABLE consultations_externes (
    employe_id DECIMAL(9,0),
    frais_consultation INT,
    PRIMARY KEY (employe_id),
    FOREIGN KEY (employe_id) REFERENCES medecins(employe_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table disponibilite_consultations : Disponibilités des médecins pour consultations externes
CREATE TABLE disponibilite_consultations (
    employe_id DECIMAL(9,0),
    jour_semaine CHAR(3), -- Ex : 'Lun', 'Mar', 'Mer'
    heure_entree TIME,
    heure_sortie TIME,
    PRIMARY KEY (employe_id, jour_semaine),
    FOREIGN KEY (employe_id) REFERENCES consultations_externes(employe_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table presence_consultations : Suivi de la présence des médecins lors des consultations
CREATE TABLE presence_consultations (
    employe_id DECIMAL(9,0),
    date_presence DATE,
    heure_entree TIME,
    heure_sortie TIME,
    PRIMARY KEY (employe_id, date_presence),
    FOREIGN KEY (employe_id) REFERENCES consultations_externes(employe_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table medecin_specialise : Informations sur les médecins spécialisés (tarif par visite)
CREATE TABLE medecin_specialise (
    employe_id DECIMAL(9,0),
    tarif_par_visite INT,
    PRIMARY KEY (employe_id),
    FOREIGN KEY (employe_id) REFERENCES medecins(employe_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table visite_medecin_specialise : Suivi des visites des médecins spécialisés
CREATE TABLE visite_medecin_specialise (
    employe_id DECIMAL(9,0),
    date_visite DATE,
    heure_entree TIME,
    heure_sortie TIME,
    PRIMARY KEY (employe_id, date_visite),
    FOREIGN KEY (employe_id) REFERENCES medecin_specialise(employe_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table traitements_disponibles : Liste des traitements proposés par l’hôpital
CREATE TABLE traitements_disponibles (
    traitement_id VARCHAR(10),
    nom_traitement VARCHAR(100) NOT NULL,
    dep_no SMALLINT NOT NULL,
    PRIMARY KEY (traitement_id),
    FOREIGN KEY (dep_no) REFERENCES departement(dep_no)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table tarifs_traitements : Tarifs associés aux traitements en fonction de la date d'effet
CREATE TABLE tarifs_traitements (
    traitement_id VARCHAR(10),
    date_effet DATE,
    tarif INT,
    PRIMARY KEY (traitement_id, date_effet),
    FOREIGN KEY (traitement_id) REFERENCES traitements_disponibles(traitement_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table prerequis_traitements : Tests prérequis pour certains traitements
CREATE TABLE prerequis_traitements (
    traitement_id VARCHAR(10),
    test_prerequis VARCHAR(100),
    PRIMARY KEY (traitement_id, test_prerequis),
    FOREIGN KEY (traitement_id) REFERENCES traitements_disponibles(traitement_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table details_assurance : Détails sur les polices (contrats) d’assurance
CREATE TABLE details_assurance (
    numero_police VARCHAR(15),
    type_police VARCHAR(50),
    compagnie_id SMALLINT,
    nom_compagnie VARCHAR(100),
    disponibilite_cashless CHAR(1),
    montant_remboursement INT,
    PRIMARY KEY (numero_police)
);

-- Table patient_assurance : Association entre un patient et une police d’assurance
CREATE TABLE patient_assurance (
    numero_police VARCHAR(15),
    patient_id DECIMAL(9,0),
    PRIMARY KEY (patient_id, numero_police),
    FOREIGN KEY (numero_police) REFERENCES details_assurance(numero_police)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table admissions : Informations sur l’admission d’un patient (chambre, dates, etc.)
CREATE TABLE admissions (
    numero_cas_admission DECIMAL(9,0),
    patient_id DECIMAL(9,0) NOT NULL,
    date_admission DATE NOT NULL,
    date_sortie DATE,
    numero_chambre type_numero_chambre NOT NULL,
    PRIMARY KEY (numero_cas_admission),
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (numero_chambre) REFERENCES chambre_details(numero_chambre)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table traitements_administres : Traçabilité des traitements administrés à un patient
CREATE TABLE traitements_administres (
    patient_id DECIMAL(9,0),
    numero_cas_admission DECIMAL(9,0),
    traitement_id VARCHAR(10),
    date_traitement DATE,
    PRIMARY KEY (patient_id, numero_cas_admission, traitement_id, date_traitement),
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (numero_cas_admission) REFERENCES admissions(numero_cas_admission)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (traitement_id) REFERENCES traitements_disponibles(traitement_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table facture_intermediaire : Factures intermédiaires (avant la facture finale)
CREATE TABLE facture_intermediaire (
    numero_cas_admission DECIMAL(9,0),
    facture_id DECIMAL(9,0),
    patient_id DECIMAL(9,0) NOT NULL,
    date_facture DATE NOT NULL,
    total_frais INT,
    PRIMARY KEY (numero_cas_admission, facture_id),
    FOREIGN KEY (numero_cas_admission) REFERENCES admissions(numero_cas_admission)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table details_facture_intermediaire : Détails des postes de facturation intermédiaires
CREATE TABLE details_facture_intermediaire (
    numero_cas_admission DECIMAL(9,0),
    facture_id DECIMAL(9,0),
    item_facture VARCHAR(100),
    montant INT,
    PRIMARY KEY (numero_cas_admission, facture_id, item_facture),
    FOREIGN KEY (numero_cas_admission, facture_id) REFERENCES facture_intermediaire(numero_cas_admission, facture_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table facture_finale : Facture finale prenant en compte assurances et totaux
CREATE TABLE facture_finale (
    numero_cas_admission DECIMAL(9,0),
    patient_id DECIMAL(9,0) NOT NULL,
    date_facture DATE NOT NULL,
    numero_police VARCHAR(15),
    statut_assurance CHAR(1),
    montant_total INT,
    montant_remboursement INT,
    montant_a_payer INT,
    PRIMARY KEY (numero_cas_admission),
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (numero_police) REFERENCES details_assurance(numero_police)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (numero_cas_admission) REFERENCES admissions(numero_cas_admission)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE hopital.facture_consultation (
    facture_id DECIMAL(9,0),
    patient_id DECIMAL(9,0) NOT NULL,
    date_facture DATE NOT NULL,
    extra_charges INT,
    consultation_charges INT,
    total_charges INT,
    PRIMARY KEY (facture_id),
    FOREIGN KEY (patient_id) REFERENCES hopital.patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table resume_sortie : Résumé de sortie d’un patient (diagnostic, statut)
CREATE TABLE resume_sortie (
    numero_cas_admission DECIMAL(9,0),
    patient_id DECIMAL(9,0),
    diagnostic VARCHAR(500),
    statut_patient VARCHAR(50),
    PRIMARY KEY (numero_cas_admission),
    FOREIGN KEY (numero_cas_admission) REFERENCES admissions(numero_cas_admission)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patient_details(patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Création des utilisateurs (admin, médecins, infirmières, techniciens)
CREATE USER admin_hopital WITH PASSWORD 'motdepasse_admin';
CREATE USER medecin_jean WITH PASSWORD 'motdepasse_jean';
CREATE USER infirmiere_claire WITH PASSWORD 'motdepasse_claire';
CREATE USER technicien_paul WITH PASSWORD 'motdepasse_paul';

-- Création des rôles
CREATE ROLE role_admin;
CREATE ROLE role_medecin;
CREATE ROLE role_infirmiere;
CREATE ROLE role_technicien;
CREATE ROLE role_personnel;

-- Attribution des rôles aux utilisateurs
GRANT role_admin TO admin_hopital;
GRANT role_medecin TO medecin_jean;
GRANT role_infirmiere TO infirmiere_claire;
GRANT role_technicien TO technicien_paul;

-- Héritage des rôles : le personnel englobe les rôles de médecin, infirmière, technicien
GRANT role_personnel TO role_medecin;
GRANT role_personnel TO role_infirmiere;
GRANT role_personnel TO role_technicien;

-- Attribution des privilèges aux rôles
-- Privilèges pour role_admin
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA hopital TO role_admin;

-- Privilèges pour role_medecin
GRANT SELECT, INSERT, UPDATE ON hopital.patient_details TO role_medecin;
GRANT SELECT, INSERT, UPDATE ON hopital.patient_conditions_medicales TO role_medecin;
GRANT SELECT ON hopital.equipement_medical TO role_medecin;
GRANT SELECT, INSERT, UPDATE ON hopital.consultations_externes TO role_medecin;
GRANT SELECT, INSERT, UPDATE ON hopital.admissions TO role_medecin;
GRANT SELECT, INSERT, UPDATE ON hopital.traitements_administres TO role_medecin;
GRANT SELECT ON hopital.traitements_disponibles TO role_medecin;
-- Note : "departements" n’existe pas, c’était sans doute departement
GRANT SELECT ON hopital.departement TO role_medecin;

-- Privilèges pour role_infirmiere
GRANT SELECT ON hopital.patient_details TO role_infirmiere;
GRANT SELECT ON hopital.patient_conditions_medicales TO role_infirmiere;
GRANT INSERT, UPDATE ON hopital.presence_consultations TO role_infirmiere;
GRANT SELECT ON hopital.equipement_medical TO role_infirmiere;
GRANT SELECT, INSERT, UPDATE ON hopital.admissions TO role_infirmiere;
GRANT SELECT, INSERT, UPDATE ON hopital.traitements_administres TO role_infirmiere;

-- Privilèges pour role_technicien
GRANT SELECT, INSERT, UPDATE ON hopital.equipement_medical TO role_technicien;
GRANT SELECT, INSERT, UPDATE ON hopital.stock_equipement TO role_technicien;
GRANT SELECT ON hopital.patient_details TO role_technicien;
