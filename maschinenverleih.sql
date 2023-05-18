DROP DATABASE IF EXISTS maschinenverleih_komplett;
CREATE DATABASE IF NOT EXISTS maschinenverleih_komplett DEFAULT CHARSET=UTF8;

USE maschinenverleih_komplett;

CREATE TABLE tbl_kunde
	(
		pk_id_kundennr INT AUTO_INCREMENT NOT NULL,
		kundenname VARCHAR(30) NOT NULL,
		kundenort CHAR(25) NOT NULL,
		kundenart VARCHAR(15) NULL,
		PRIMARY KEY (pk_id_kundennr)
	)
ENGINE=InnoDB;

CREATE TABLE tbl_maschinentyp
	(
		pk_typ VARCHAR(10) NOT NULL,
		maschinenart VARCHAR(15) NOT NULL,
		hersteller VARCHAR (15) NULL,
		fuehrerschein VARCHAR(2) NULL, -- es gibt maschinen ohne erforderlichen befähigungsnachweis
		werkstatt VARCHAR(25),
		tarif_tag DECIMAL(5,2) NULL, -- null möglich, falls abrechnung nach km
		tarif_km DECIMAL(4,2) NULL, -- null möglich falls abrechnung nach tag
		PRIMARY KEY(pk_typ)
	)
ENGINE=InnoDB;

CREATE TABLE tbl_ort
	(
		pk_id_ort INT AUTO_INCREMENT NOT NULL,
		ort_plz CHAR(5),
		ort_name VARCHAR(25),
		PRIMARY KEY(pk_id_ort)
	)
ENGINE=InnoDB;

CREATE TABLE tbl_ndl
	(
		pk_ndl_kennzeichen VARCHAR(30) NOT NULL, -- 4 Zeichen zur kennzeichnung der niederlassung
		ansprechpartner VARCHAR(30) NOT NULL,
		fk_ort INT NOT NULL,
		FOREIGN KEY(fk_ort)
			REFERENCES tbl_ort(pk_id_ort)
				ON UPDATE NO ACTION
				ON DELETE RESTRICT,
		PRIMARY KEY (pk_ndl_kennzeichen)
	)
ENGINE=InnoDB;

CREATE TABLE tbl_personal
	(
		pk_id_pers_nr INT AUTO_INCREMENT NOT NULL,
		pers_nachname VARCHAR(30) NOT NULL,
		pers_vorname VARCHAR(30) NOT NULL,
		pers_geb_datum DATE NOT NULL,
		pers_str_hnr VARCHAR(30),
		fk_ndl VARCHAR(30),
		fk_ort INT,
		FOREIGN KEY(fk_ndl)
			REFERENCES tbl_ndl(pk_ndl_kennzeichen)
				ON UPDATE NO ACTION
				ON DELETE RESTRICT,
		FOREIGN KEY(fk_ort)
			REFERENCES tbl_ort(pk_id_ort)
				ON UPDATE NO ACTION
				ON DELETE RESTRICT,
		PRIMARY KEY (pk_id_pers_nr)
	)
ENGINE=InnoDB;

CREATE TABLE tbl_qualifikation
	(
	pk_qualifikation VARCHAR(25) NOT NULL,
	besuchte_lehrgaenge VARCHAR(255),
	PRIMARY KEY(pk_qualifikation)
	)
ENGINE=InnoDB;
	
CREATE TABLE tbl_techniker
	(
		pk_techniker INT AUTO_INCREMENT NOT NULL,
		anrede CHAR(4) NOT NULL,
		fk_pers INT NOT NULL,
		fk_qualifikation VARCHAR(25),
		FOREIGN KEY(fk_pers)
			REFERENCES tbl_personal(pk_id_pers_nr)
				ON UPDATE cascade
				ON DELETE CASCADE,
		FOREIGN KEY(fk_qualifikation)
			REFERENCES tbl_qualifikation(pk_qualifikation)
				ON UPDATE CASCADE
				ON DELETE NO ACTION,
		PRIMARY KEY(pk_techniker)
	)
ENGINE=InnoDB;

CREATE TABLE tbl_ma_verwaltung
	(
		pk_ma_verwaltung INT NOT NULL,
		anrede CHAR(4) NOT NULL,
		fk_pers INT NOT NULL,
		ma_position ENUM('Sekretariat', 'Büroleiter-in', 'Ndl-Leiter-in','Finanzbuchhaltung'),
		FOREIGN KEY(fk_pers)
			REFERENCES tbl_personal(pk_id_pers_nr)
				ON UPDATE cascade
				ON DELETE CASCADE,
		PRIMARY KEY(pk_ma_verwaltung)
	)
ENGINE=InnoDB;

-- DROP TABLE tbl_maschine;

CREATE TABLE tbl_maschine
	(
		pk_maschinennr VARCHAR(10) NOT NULL,
		fk_typ VARCHAR(10) NOT NULL,
		kfz_kennzeichen VARCHAR (15) NULL, -- nicht ID, da wieder vergeben werden kann
		einsatzbereit boolean NOT NULL, -- wahrheitswert 0 entspricht falsch sonst wahr
		inspektionsdatum DATE NOT NULL,
		kaufdatum DATE NOT NULL,
		FOREIGN KEY (fk_typ)
			REFERENCES tbl_maschinentyp(pk_typ)
				ON UPDATE CASCADE
				ON DELETE NO ACTION, /*maschinen sollen historisch erhalten bleiben, auch wenn der typ nicht mehr vermietet wird*/
		PRIMARY KEY(pk_maschinennr)
	)
ENGINE=InnoDB;

-- DROP TABLE tbl_mieten;

CREATE TABLE tbl_mieten
	(
		fk_kundennr INT NOT NULL,
		fk_maschinennr VARCHAR(10) NOT NULL,
		fk_niederlassung VARCHAR(30) NOT NULL,
		mietbeginn DATE NOT NULL,
		mietende DATE NULL,
		anfang_km INT NULL, /*es gibt mietvorgänge, die über die Zeit abgerechnet werden. eingetragen wird ansonsten zu beginn*/
		ende_km INT, -- wird eingetragen bei Rückgabe
		FOREIGN KEY (fk_kundennr)
			REFERENCES tbl_kunde(pk_id_kundennr)
				ON UPDATE RESTRICT
				ON DELETE RESTRICT, /*der Mietvorgang ist aus steuer gründen zu erhalten*/
		FOREIGN KEY (fk_maschinennr)
			REFERENCES tbl_maschine(pk_maschinennr)
				ON UPDATE RESTRICT
				ON DELETE RESTRICT, /*s.o.*/
		FOREIGN KEY (fk_niederlassung)
			REFERENCES tbl_ndl(pk_ndl_kennzeichen)
				ON UPDATE RESTRICT
				ON DELETE RESTRICT /*s.o.*/
	)
ENGINE=InnoDB;

-- Daten einlesen

LOAD DATA LOCAL INFILE 'E://Import/maschinenverleih/kunden.csv'
INTO TABLE tbl_kunde
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\r\n'
(kundenname, kundenort, kundenart);

LOAD DATA LOCAL INFILE 'E://Import/maschinenverleih/typ.csv'
INTO TABLE tbl_maschinentyp
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'E://Import/maschinenverleih/ort_komplett.csv'
INTO TABLE tbl_ort
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\r\n'
(ort_plz, ort_name);

LOAD DATA LOCAL INFILE 'E://Import/maschinenverleih/niederlassung_komplett.txt'
INTO TABLE tbl_ndl
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\r\n';


LOAD DATA LOCAL INFILE 'E://Import/maschinenverleih/maschine.csv'
INTO TABLE tbl_maschine
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'E://Import/maschinenverleih/mieten_komplett.csv'
INTO TABLE tbl_mieten
FIELDS TERMINATED BY ';' LINES TERMINATED BY '\r\n';

create table tbl_maschinentyp_hist as
  (select * from tbl_maschinentyp);

ALTER TABLE tbl_maschinentyp_hist 
ADD COLUMN zeitstempel timestamp;

update tbl_maschinentyp_hist
set zeitstempel = current_timestamp;

-- Trigger für das Aktualisieren bei INSERT und UPDATE der Tabelle tbl_maschinentyp_hist

Delimiter //
create trigger TR_maschinentyp_ins
before insert on tbl_maschinentyp
for each row
begin
insert into tbl_maschinentyp_hist
values
(new.pk_typ,
new.maschinenart,
new.hersteller,
new.fuehrerschein,
new.werkstatt,
new.tarif_tag,
new.tarif_km,
current_timestamp);
end;
//
create trigger TR_maschinentyp_upd
before update on tbl_maschinentyp
for each row
begin
insert into tbl_maschinentyp_hist
values
(new.pk_typ,
new.maschinenart,
new.hersteller,
new.fuehrerschein,
new.werkstatt,
new.tarif_tag,
new.tarif_km,
current_timestamp);
end;
//
create trigger TR_maschinentyp_del
before delete on tbl_maschinentyp
for each row
begin
insert into tbl_maschinentyp_hist
values
(old.pk_typ,
old.maschinenart,
old.hersteller,
old.fuehrerschein,
old.werkstatt,
old.tarif_tag,
old.tarif_km,
current_timestamp);
end;				
//	
DELIMITER ;

-- Abfragen für Rechnungsstelle

CREATE VIEW qry_Rechnung as
SELECT tbl_kunde.pk_id_kundennr AS `Kunden-Nummer`, tbl_kunde.kundenname AS `Kunde`,
tbl_kunde.kundenort AS 'Wohnort',
SUM((COALESCE(tbl_mieten.ende_km,0)-COALESCE(tbl_mieten.anfang_km,0))*COALESCE(tbl_maschinentyp.tarif_km,0)) AS `Kilometerpauschale`,
SUM(DATEDIFF(COALESCE(tbl_mieten.mietende, CURDATE()),tbl_mieten.mietbeginn)*COALESCE(tbl_maschinentyp.tarif_tag,0)) AS `Tagespauschale`,
SUM((COALESCE(tbl_mieten.ende_km,0)-COALESCE(tbl_mieten.anfang_km,0))*COALESCE(tbl_maschinentyp.tarif_km,0) + 
DATEDIFF(COALESCE(tbl_mieten.mietende,CURDATE()),tbl_mieten.mietbeginn)*COALESCE(tbl_maschinentyp.tarif_tag,0)) AS `Gesamtkosten`
FROM tbl_kunde
INNER JOIN tbl_mieten ON tbl_kunde.pk_id_kundennr=tbl_mieten.fk_kundennr
INNER JOIN tbl_maschine ON tbl_mieten.fk_maschinennr=tbl_maschine.pk_maschinennr
INNER JOIN tbl_maschinentyp ON tbl_maschine.fk_typ=tbl_maschinentyp.pk_typ
GROUP BY tbl_maschine.pk_maschinennr, tbl_mieten.mietbeginn
ORDER BY `Gesamtkosten` DESC;

-- Rechtevergabe

-- SELECT * FROM mysql.user\G

DROP USER 'rma'@'localhost';

CREATE USER 'rma'@'localhost' IDENTIFIED BY 'rechnung';

GRANT SELECT ON maschinenverleih_komplett.qry_Rechnung TO 'rma'@'localhost'; -- nur SELECT auf qry_rechnung

FLUSH PRIVILEGES; -- aktiviert gerade veränderte Rechte der Benutzer

GRANT ALL PRIVILEGES ON maschinenverleih_tr_usr.* TO 'andreas'@'localhost'; -- alle Rechte auf maschinenverleih_tr_usr




