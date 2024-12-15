-- Gestion des chambres, des factures et des stocks

-- 1. Fonction pour libérer un lit dans une chambre
-- Cette fonction décrémente le nombre de lits occupés dans une chambre donnée.
-- Si la chambre est déjà vide, elle affiche un message indiquant que la chambre est déjà vide.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION liberer_chambre(chambre VARCHAR, abbrev VARCHAR) RETURNS VOID AS $$
DECLARE
    chambre_rec RECORD;
    lits_occupees INT;
BEGIN
    SELECT * INTO chambre_rec FROM chambre_details
    WHERE numero_chambre=chambre::type_numero_chambre
      AND abbrev_type=abbrev;

    IF NOT FOUND THEN
        RAISE NOTICE 'La chambre % de type % n''existe pas.', chambre, abbrev;
        RETURN;
    END IF;

    IF chambre_rec.lits_occupees<=0 THEN
        RAISE NOTICE 'Cette chambre est déjà vide.';
    ELSE
        lits_occupees := chambre_rec.lits_occupees-1;
        UPDATE chambre_details SET lits_occupees=lits_occupees
        WHERE numero_chambre=chambre::type_numero_chambre
          AND abbrev_type=abbrev;
        RAISE NOTICE 'Un lit a été libéré dans la chambre %.', chambre;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 2. Fonction pour occuper un lit dans une chambre
-- Cette fonction incrémente le nombre de lits occupés dans une chambre donnée.
-- Si la chambre est pleine, elle affiche un message indiquant que la chambre est déjà pleine.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION occuper_chambre(chambre VARCHAR, abbrev VARCHAR) RETURNS VOID AS $$
DECLARE
    chambre_rec RECORD;
    lits_occupees INT;
BEGIN
    SELECT * INTO chambre_rec FROM chambre_details
    WHERE numero_chambre=chambre::type_numero_chambre
      AND abbrev_type=abbrev;

    IF NOT FOUND THEN
        RAISE NOTICE 'La chambre % de type % n''existe pas.', chambre, abbrev;
        RETURN;
    END IF;

    IF chambre_rec.lits_occupees>=chambre_rec.capacite THEN
        RAISE NOTICE 'Cette chambre est déjà pleine.';
    ELSE
        lits_occupees := chambre_rec.lits_occupees+1;
        UPDATE chambre_details SET lits_occupees=lits_occupees
        WHERE numero_chambre=chambre::type_numero_chambre
          AND abbrev_type=abbrev;
        RAISE NOTICE 'Un lit a été occupé dans la chambre %.', chambre;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Fonction de déclenchement pour la facture intermédiaire
-- Cette fonction calcule et met à jour les frais associés à une facture intermédiaire.
-- Elle met à jour les frais de consultation, les frais du médecin spécialisé, les frais de chambre, les frais de traitement et le total des frais.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculer_facture_intermediaire() RETURNS TRIGGER AS $$
DECLARE
    total INT;
BEGIN
    SELECT SUM(montant) INTO total
    FROM details_facture_intermediaire
    WHERE numero_cas_admission=NEW.numero_cas_admission
      AND facture_id=NEW.facture_id;

    UPDATE facture_intermediaire
    SET total_frais=COALESCE(total,0)
    WHERE numero_cas_admission=NEW.numero_cas_admission
      AND facture_id=NEW.facture_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 4. Déclencheur pour la facture intermédiaire
-- Ce déclencheur exécute la fonction calculer_facture_intermediaire après chaque insertion dans la table facture_intermediaire.
-- ------------------------------------------------------------
CREATE TRIGGER trigger_facture_intermediaire
AFTER INSERT ON hopital.facture_intermediaire
FOR EACH ROW EXECUTE PROCEDURE calculer_facture_intermediaire();

-- ------------------------------------------------------------
-- 5. Fonction de déclenchement pour la facture finale
-- Cette fonction calcule le total des frais et applique les montants de l'assurance si applicable.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculer_facture_finale() RETURNS TRIGGER AS $$
DECLARE
    total_charges INT := 0;
BEGIN
    SELECT SUM(total_frais) INTO total_charges
    FROM facture_intermediaire
    WHERE numero_cas_admission=NEW.numero_cas_admission;

    IF total_charges IS NULL THEN
        total_charges := 0;
    END IF;

    IF NEW.statut_assurance='A' THEN
        UPDATE facture_finale
        SET montant_total=total_charges,
            montant_remboursement=(total_charges * 80)/100,
            montant_a_payer=total_charges-((total_charges*80)/100)
        WHERE numero_cas_admission=NEW.numero_cas_admission;
    ELSE
        UPDATE facture_finale
        SET montant_total=total_charges,
            montant_remboursement=0,
            montant_a_payer=total_charges
        WHERE numero_cas_admission=NEW.numero_cas_admission;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 6. Déclencheur pour la facture finale
-- Ce déclencheur exécute la fonction calculer_facture_finale après chaque insertion dans la table facture_finale.
-- ------------------------------------------------------------
CREATE TRIGGER trigger_facture_finale
AFTER INSERT ON hopital.facture_finale
FOR EACH ROW EXECUTE PROCEDURE calculer_facture_finale();

-- ------------------------------------------------------------
-- 7. Fonction de déclenchement pour le stock d'équipement médical
-- Cette fonction vérifie si le stock atteint le niveau de réapprovisionnement et affiche un message en conséquence.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION verifier_stock_equipement() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantite<=NEW.niveau_reapprovisionnement THEN
        RAISE NOTICE 'L''équipement ID % dans le département % doit être réapprovisionné.', NEW.equipement_id, NEW.dep_no;
    ELSE
        RAISE NOTICE 'Il reste % unités avant de devoir réapprovisionner l''équipement ID %.', NEW.quantite - NEW.niveau_reapprovisionnement, NEW.equipement_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 8. Déclencheur pour le stock d'équipement médical
-- Ce déclencheur exécute la fonction verifier_stock_equipement après chaque mise à jour de la table stock_equipement.
-- ------------------------------------------------------------
CREATE TRIGGER trigger_verifier_stock_equipement
AFTER UPDATE ON hopital.stock_equipement
FOR EACH ROW EXECUTE PROCEDURE verifier_stock_equipement();


-- ------------------------------------------------------------
-- 9. Fonction de déclenchement pour la facture de consultation
-- Cette fonction met à jour les frais de consultation et calcule le total des frais pour une facture de consultation.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculer_facture_consultation() RETURNS TRIGGER AS $$
DECLARE
    frais_consultation INT :=50;
    total_charges INT;
BEGIN
    UPDATE facture_consultation
    SET consultation_charges=frais_consultation
    WHERE facture_id=NEW.facture_id;

    total_charges :=frais_consultation+COALESCE(NEW.extra_charges, 0);

    UPDATE facture_consultation
    SET total_charges=total_charges
    WHERE facture_id=NEW.facture_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------
-- 10. Déclencheur pour la facture de consultation
-- Ce déclencheur exécute la fonction calculer_facture_consultation après chaque insertion dans la table facture_consultation.
-- ------------------------------------------------------------
CREATE TRIGGER trigger_facture_consultation
AFTER INSERT ON hopital.facture_consultation
FOR EACH ROW EXECUTE PROCEDURE calculer_facture_consultation();
