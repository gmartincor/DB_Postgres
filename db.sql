  ------------------------------------------------------------------------------------------------
  --
  -- Create database
  --
  ------------------------------------------------------------------------------------------------
  -- CREATE DATABASE dbdw_pec3;
  ------------------------------------------------------------------------------------------------
  --
  -- Drop tables
  --
  ------------------------------------------------------------------------------------------------
  DROP VIEW  IF EXISTS erp.vw_event_occupation; 
  DROP TABLE IF EXISTS erp.tb_alerts;
  DROP TABLE IF EXISTS erp.tb_catering_hunters;
  DROP TABLE IF EXISTS erp.tb_access_log;
  DROP TABLE IF EXISTS erp.tb_event_guest;
  DROP TABLE IF EXISTS erp.tb_guest;
  DROP TABLE IF EXISTS erp.tb_guest_type;
  DROP TABLE IF EXISTS erp.tb_event;
  
  ------------------------------------------------------------------------------------------------
  --
  -- Drop schema
  --
  ------------------------------------------------------------------------------------------------
  DROP SCHEMA IF EXISTS erp CASCADE;
  ------------------------------------------------------------------------------------------------
  --
  -- Create schema
  --
  ------------------------------------------------------------------------------------------------
  CREATE SCHEMA erp;
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_guest_type
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_guest_type  (
    guest_type_id 		CHARACTER (3) NOT NULL, 
    name 			CHARACTER VARYING(40) NOT NULL,
    CONSTRAINT pk_guest_type 	PRIMARY KEY (guest_type_id )  
  );
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_guest
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_guest  (
    guest_id 			INT NOT NULL, 
    name 			CHARACTER VARYING(40) NOT NULL,
    email			CHARACTER VARYING(40) NOT NULL,
    phone_number		CHARACTER VARYING(40) NOT NULL,
    date_of_birth		DATE,
    guest_type_id		CHARACTER (3),
    CONSTRAINT pk_guest 	PRIMARY KEY (guest_id ),
    CONSTRAINT u_guest_email 	UNIQUE(email),
    CONSTRAINT fk_guest_type 	FOREIGN KEY (guest_type_id) REFERENCES erp.tb_guest_type(guest_type_id )	
  );
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_event
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_event  (
    event_id 			INT NOT NULL, 
    name 			CHARACTER VARYING(100) NOT NULL,
    event_date			DATE NOT NULL,
    max_guest_count		INT NOT NULL,
    event_location 		CHARACTER VARYING(50) NOT NULL,
    event_parent		INT,
    catering_cost_guest 	NUMERIC(6,2) DEFAULT NULL,
    CONSTRAINT pk_event 	PRIMARY KEY (event_id ),
    CONSTRAINT fk_event_parent 	FOREIGN KEY (event_parent) REFERENCES erp.tb_event(event_id),
    CONSTRAINT chk_event_date CHECK (event_date > TO_DATE('01/01/2025','dd/mm/yyyy')),
    CONSTRAINT chk_catering_cost_guest CHECK (catering_cost_guest IS NULL OR catering_cost_guest >= 0)
  );
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_event_guest
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_event_guest  (
    event_id 			INT NOT NULL,
    guest_id			INT NOT NULL,
    confirmed			CHAR(1),
    CONSTRAINT pk_event_guest 	PRIMARY KEY (event_id,guest_id),
    CONSTRAINT fk_eg_guest 	FOREIGN KEY (guest_id) REFERENCES erp.tb_guest(guest_id),
    CONSTRAINT fk_eg_event 	FOREIGN KEY (event_id) REFERENCES erp.tb_event(event_id)  
  );
  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_access_log
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_access_log  (
    access_log_id		INT NOT NULL,
    event_id 			INT NULL,
    guest_id			INT NULL,
    access_log_date		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    access_log_type		CHAR(3) NOT NULL,
    access_rejected             CHAR(1) NOT NULL DEFAULT 'N',
    CONSTRAINT pk_access_log 	PRIMARY KEY (access_log_id),
    CONSTRAINT fk_al_guests 	FOREIGN KEY (guest_id) REFERENCES erp.tb_guest(guest_id),
    CONSTRAINT fk_al_event 	FOREIGN KEY (event_id) REFERENCES erp.tb_event(event_id),
    CONSTRAINT chk_access_log_type CHECK (access_log_type IN ('IN', 'OUT')),
    CONSTRAINT chk_access_rejected CHECK (access_rejected IN ('Y','N'))	
  );

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_catering_hunters
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_catering_hunters  (
    hunter_id     INT NOT NULL,
    event_id      INT NOT NULL,
    guest_id      INT NOT NULL,
    remarks       CHARACTER VARYING(100) NOT NULL,
    CONSTRAINT pk_catering_hunters PRIMARY KEY (hunter_id),
    CONSTRAINT fk_ch_access_log    FOREIGN KEY (hunter_id) REFERENCES erp.tb_access_log(access_log_id),
    CONSTRAINT fk_ch_event         FOREIGN KEY (event_id) REFERENCES erp.tb_event(event_id),
    CONSTRAINT fk_ch_guests        FOREIGN KEY (guest_id) REFERENCES erp.tb_guest(guest_id)	
  );

  ------------------------------------------------------------------------------------------------
  --
  -- Create table tb_alerts
  --
  ------------------------------------------------------------------------------------------------
  CREATE TABLE erp.tb_alerts  (
    alert_id 		    UUID DEFAULT gen_random_uuid(),
    alert_access_id         INT NOT NULL,
    alert_description CHARACTER VARYING(100) NOT NULL,
    CONSTRAINT pk_alerts PRIMARY KEY (alert_id),
    CONSTRAINT fk_alerts_access_log FOREIGN KEY (alert_access_id) REFERENCES erp.tb_access_log(access_log_id)
  );
  
  ------------------------------------------------------------------------------------------------
  --
  -- Create view vw_event_occupation
  --
  ------------------------------------------------------------------------------------------------
  
  CREATE OR REPLACE VIEW erp.vw_event_occupation AS
  SELECT te.event_id AS event_id, te.name AS event_name,te.max_guest_count AS max_guests,count(*) AS guests_count,
  (count(*)*100)/te.max_guest_count AS occupation_percentage
  FROM erp.tb_event AS te LEFT JOIN erp.tb_event_guest AS tg ON te.event_id=tg.event_id
  GROUP by te.event_id
  ORDER BY occupation_percentage DESC;

------------------------------------------------
--  Load data
------------------------------------------------

INSERT INTO erp.tb_guest_type (guest_type_id,name) VALUES ('IE','Industry Executives');
INSERT INTO erp.tb_guest_type (guest_type_id,name) VALUES ('MP','Media & Press');
INSERT INTO erp.tb_guest_type (guest_type_id,name) VALUES ('VIP','VIP Guests');
INSERT INTO erp.tb_guest_type (guest_type_id,name) VALUES ('E&D','Engineers & Developers');
INSERT INTO erp.tb_guest_type (guest_type_id,name) VALUES ('G&R','Government & Regulatory Officials');

INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (1,'Jamie Farley','jamie_farley@yahoo.com','+34 624500814',TO_TIMESTAMP('1953-05-28','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (2,'Mary Ryan','mary.ryan@companymail.com','+34 727138073',TO_TIMESTAMP('1951-04-27','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (3,'Cassandra Pittman','cassandrapittman@companymail.com','+34 663031383',TO_TIMESTAMP('1967-09-18','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (4,'Cassandra Lee','cassandra.lee@outlook.com','+34 653345838',TO_TIMESTAMP('1977-04-24','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (5,'Patrick Wells','patrickwells@outlook.com','+34 625564634',TO_TIMESTAMP('1966-10-02','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (6,'Mary Bryan','bryan.mary@yahoo.com','+34 612526524',TO_TIMESTAMP('1983-01-19','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (7,'Tonya Frazier','tfrazier@gmail.com','+34 602847110',TO_TIMESTAMP('1973-05-15','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (8,'Mark Fields','markfields@yahoo.com','+34 786621878',TO_TIMESTAMP('1951-08-26','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (9,'Michael Ross','ross.michael@yahoo.com','+34 777945863',TO_TIMESTAMP('1962-07-18','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (10,'Eric Brooks','ericbrooks@companymail.com','+34 768359948',TO_TIMESTAMP('2004-06-22','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (11,'Tyler Sandoval','tylersandoval@yahoo.com','+34 768246954',TO_TIMESTAMP('2001-02-01','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (12,'Scott Grant','scott_grant@gmail.com','+34 697523822',TO_TIMESTAMP('1977-12-22','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (13,'Rebecca Elliott','rebeccaelliott@gmail.com','+34 724452748',TO_TIMESTAMP('1974-12-20','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (14,'Kerry Allen','allen.kerry@gmail.com','+34 636088524',TO_TIMESTAMP('1954-11-03','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (15,'Yvonne Oconnor','yvonne17@hotmail.com','+34 691271521',TO_TIMESTAMP('1961-03-16','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (16,'Kathryn Gallagher','kathryn20@outlook.com','+34 783514614',TO_TIMESTAMP('1980-02-26','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (17,'Derrick Sutton','derrick99@gmail.com','+34 775068571',TO_TIMESTAMP('1971-03-17','YYYY/MM/DD'),'G&R');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (18,'Crystal Miller','crystal73@companymail.com','+34 795894286',TO_TIMESTAMP('1973-04-11','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (19,'Mary Walker','mary60@outlook.com','+34 714778867',TO_TIMESTAMP('1950-11-29','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (20,'Brittany Zimmerman','bzimmerman@companymail.com','+34 770242538',TO_TIMESTAMP('1974-09-04','YYYY/MM/DD'),NULL);
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (21,'Howard Bonilla','howard44@yahoo.com','+34 726356726',TO_TIMESTAMP('1989-07-30','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (22,'Brittany Rodgers','brittany_rodgers@hotmail.com','+34 657536252',TO_TIMESTAMP('1999-10-05','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (23,'Robert Meyers','meyers.robert@outlook.com','+34 629766306',TO_TIMESTAMP('1990-07-20','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (24,'Anthony Johnston','anthonyjohnston@hotmail.com','+34 627356591',TO_TIMESTAMP('1950-05-15','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (25,'Jeffrey Snow','jsnow@hotmail.com','+34 710625215',TO_TIMESTAMP('1976-05-24','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (26,'Robert Li','robert.li@gmail.com','+34 796728658',TO_TIMESTAMP('1957-06-06','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (27,'Daniel Vincent','vincent.daniel@gmail.com','+34 751859622',TO_TIMESTAMP('1957-07-19','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (28,'Laura Foster','foster.laura@outlook.com','+34 620956584',TO_TIMESTAMP('1960-01-15','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (29,'James Vincent','jamesvincent@yahoo.com','+34 791349178',TO_TIMESTAMP('1986-07-27','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (30,'Mrs. Vicki Ashley','mrs._vicki@hotmail.com','+34 737780829',TO_TIMESTAMP('1997-01-23','YYYY/MM/DD'),NULL);
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (31,'Brandon Turner','brandon.turner@companymail.com','+34 794756854',TO_TIMESTAMP('1967-12-17','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (32,'Danny Frost','danny_frost@companymail.com','+34 600182092',TO_TIMESTAMP('1995-07-31','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (33,'Kenneth Rubio','kenneth53@companymail.com','+34 697964753',TO_TIMESTAMP('1975-12-12','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (34,'Jay Johnson','jayjohnson@yahoo.com','+34 772822160',TO_TIMESTAMP('1999-08-01','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (35,'Brittney Orr MD','borr@gmail.com','+34 688073047',TO_TIMESTAMP('1964-07-16','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (36,'John Humphrey','john_humphrey@outlook.com','+34 621844813',TO_TIMESTAMP('1956-10-20','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (37,'Lisa Hernandez','hernandez.lisa@companymail.com','+34 660356812',TO_TIMESTAMP('1950-10-02','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (38,'Shelby Wright','shelby_wright@outlook.com','+34 756711753',TO_TIMESTAMP('1998-12-31','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (39,'John Pratt','john_pratt@outlook.com','+34 615327592',TO_TIMESTAMP('1990-06-02','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (40,'Thomas Weiss','thomas_weiss@yahoo.com','+34 669909975',TO_TIMESTAMP('1962-01-03','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (41,'Audrey Hall','audrey59@yahoo.com','+34 702182466',TO_TIMESTAMP('1964-11-27','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (42,'Jeremy Jones','jones.jeremy@gmail.com','+34 684922538',TO_TIMESTAMP('1989-02-13','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (43,'Monica Christensen','monica.christensen@companymail.com','+34 630853741',TO_TIMESTAMP('2002-04-17','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (44,'Meghan Ellis','mellis@yahoo.com','+34 693189730',TO_TIMESTAMP('1980-09-27','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (45,'Stacie Trevino','stacie24@yahoo.com','+34 747373882',TO_TIMESTAMP('1951-07-07','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (46,'Joseph Morton','joseph55@outlook.com','+34 643574496',TO_TIMESTAMP('1950-11-21','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (47,'Elaine Williams','ewilliams@yahoo.com','+34 701594224',TO_TIMESTAMP('1995-02-04','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (48,'Mario Wheeler','mario_wheeler@yahoo.com','+34 729641310',TO_TIMESTAMP('1989-10-05','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (49,'David Ellis','david_ellis@gmail.com','+34 654611097',TO_TIMESTAMP('1992-09-24','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (50,'Eric Castro','ericcastro@hotmail.com','+34 795883884',TO_TIMESTAMP('1967-03-07','YYYY/MM/DD'),NULL);
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (51,'Raymond Evans','revans@gmail.com','+34 668243745',TO_TIMESTAMP('2002-04-03','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (52,'Benjamin Carney','carney.benjamin@hotmail.com','+34 687054339',TO_TIMESTAMP('2006-06-17','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (53,'Barbara Baldwin','barbara_baldwin@gmail.com','+34 798483860',TO_TIMESTAMP('1955-04-16','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (54,'Joshua Hayes','hayes.joshua@gmail.com','+34 652394452',TO_TIMESTAMP('1973-11-22','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (55,'Amanda Brennan','brennan.amanda@companymail.com','+34 607708215',TO_TIMESTAMP('2003-02-04','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (56,'Shelby Chen','schen@gmail.com','+34 743948593',TO_TIMESTAMP('1997-06-19','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (57,'Timothy Manning','timothy.manning@hotmail.com','+34 753575575',TO_TIMESTAMP('1977-10-07','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (58,'Anthony Boyer','anthonyboyer@hotmail.com','+34 632676893',TO_TIMESTAMP('1972-10-20','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (59,'Ethan Baker','baker@microsoft.com','+34 601610089',TO_TIMESTAMP('1974-08-02','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (60,'Tina Shepherd','tina40@outlook.com','+34 668964629',TO_TIMESTAMP('1961-08-15','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (61,'Brett Miller','miller.brett@companymail.com','+34 684645893',TO_TIMESTAMP('1958-08-14','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (62,'Erik Contreras','econtreras@yahoo.com','+34 728002159',TO_TIMESTAMP('1975-03-31','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (63,'Marissa Gray','marissa.gray@gmail.com','+34 648082272',TO_TIMESTAMP('1979-10-21','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (64,'Heidi Rivers','heidi_rivers@companymail.com','+34 715554987',TO_TIMESTAMP('1980-11-09','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (65,'Angel Jennings','angel26@gmail.com','+34 619144493',TO_TIMESTAMP('1997-04-02','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (66,'Eric Hudson','ehudson@cloudtty.com','+34 682900766',TO_TIMESTAMP('1969-11-15','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (67,'Katie Smith','katiesmith@gmail.com','+34 628707608',TO_TIMESTAMP('1980-12-11','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (68,'William Lopez','william88@hotmail.com','+34 790678154',TO_TIMESTAMP('1988-02-13','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (69,'Mark Scott','markscott@hotmail.com','+34 778796872',TO_TIMESTAMP('2001-08-20','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (70,'Damon Potts','potts.damon@outlook.com','+34 603757093',TO_TIMESTAMP('1975-08-02','YYYY/MM/DD'),NULL);
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (71,'Christopher Miller','cmiller@gmail.com','+34 770762029',TO_TIMESTAMP('1974-05-02','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (72,'Cheryl Lang','cheryl12@yahoo.com','+34 664196260',TO_TIMESTAMP('1951-06-01','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (73,'Joshua Sherman','sherman.joshua@yahoo.com','+34 780182871',TO_TIMESTAMP('1954-09-05','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (74,'Kathryn Martin','kathryn_martin@hotmail.com','+34 613738579',TO_TIMESTAMP('1955-11-24','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (75,'Frank Cummings','frank.cummings@companymail.com','+34 647527071',TO_TIMESTAMP('2003-12-10','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (76,'Samantha Harris','harris.samantha@companymail.com','+34 784413626',TO_TIMESTAMP('1993-09-06','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (77,'Beth Andrews','bethandrews@companymail.com','+34 776859609',TO_TIMESTAMP('1955-05-15','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (78,'Curtis Harris','curtis88@gmail.com','+34 689753868',TO_TIMESTAMP('1964-05-16','YYYY/MM/DD'),'G&R');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (79,'Jack Alvarez','jack_alvarez@outlook.com','+34 662945820',TO_TIMESTAMP('1966-01-27','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (80,'Martin Boyd','martin_boyd@companymail.com','+34 632852428',TO_TIMESTAMP('2004-04-07','YYYY/MM/DD'),NULL);
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (81,'Christina Campbell','christina64@outlook.com','+28 061345223',TO_TIMESTAMP('1956-04-06','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (82,'Andrew Ramos','aramos@hotmail.com','+18 222747774',TO_TIMESTAMP('1957-02-25','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (83,'Jenna Torres','jenna62@outlook.com','+52 489236652',TO_TIMESTAMP('1982-12-21','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (84,'Donald Lewis','donald.lewis@gmail.com','+5 569543088',TO_TIMESTAMP('1997-05-04','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (85,'Jennifer Suarez','jsuarez@outlook.com','+80 340055028',TO_TIMESTAMP('1960-07-27','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (86,'Mary Bowers','mary69@gmail.com','+52 309433832',TO_TIMESTAMP('1973-12-12','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (87,'Kimberly Myers','kimberly.myers@gmail.com','+69 796693407',TO_TIMESTAMP('2004-05-13','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (88,'Evan Jackson','evan59@hotmail.com','+59 189946012',TO_TIMESTAMP('1988-01-16','YYYY/MM/DD'),'G&R');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (89,'James Rivera','james_rivera@yahoo.com','+62 038668941',TO_TIMESTAMP('1952-10-02','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (90,'Drew Shepherd','drew_shepherd@gmail.com','+8 553523295',TO_TIMESTAMP('1975-01-25','YYYY/MM/DD'),NULL);
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (91,'James Thomas','thomas.james@hotmail.com','+17 526479940',TO_TIMESTAMP('1976-12-31','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (92,'Rebecca Baker','rebecca_baker@companymail.com','+56 919875075',TO_TIMESTAMP('1977-04-14','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (93,'Jonathan Boyle','jonathanboyle@hotmail.com','+46 515997843',TO_TIMESTAMP('1984-01-23','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (94,'Dr. Jessica Ford','djessica@gmail.com','+32 592962606',TO_TIMESTAMP('2005-05-26','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (95,'Brandon Carroll','carroll.brandon@companymail.com','+54 007646605',TO_TIMESTAMP('1971-05-24','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (96,'Dennis Brown','dennis_brown@yahoo.com','+51 511278876',TO_TIMESTAMP('1973-10-14','YYYY/MM/DD'),'IE');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (97,'Paul Adams','adams@teamyyy.com','+34 438100740',TO_TIMESTAMP('1948-04-21','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (98,'Michael Vasquez','vasquez.michael@gmail.com','+89 762554026',TO_TIMESTAMP('1972-07-06','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (99,'Dr. Derrick Durham','dr.91@gmail.com','+45 905374282',TO_TIMESTAMP('1984-04-13','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (100,'Tonya Wade','tonyawade@companymail.com','+44 380902878',TO_TIMESTAMP('1960-06-17','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (101,'Katie Andrews','kandrews@gmail.com','+34 639710271',TO_TIMESTAMP('1980-01-01','YYYY/MM/DD'),'MP');

INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (110,'Peter Saint Cheese','pedrooo@gmail.com','+34 654321987',TO_TIMESTAMP('1962-02-02','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (111,'Marta Robirosa','martarob@hotmail.com','+34 123456789',TO_TIMESTAMP('1965-03-03','YYYY/MM/DD'),'MP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) VALUES (112,'Joan Testing','jtest@hotmail.com','+34 111111111',TO_TIMESTAMP('1975-04-04','YYYY/MM/DD'),'E&D');


INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (1,'Opening party',TO_TIMESTAMP('03/03/2025','DD/MM/YYYY'),60,NULL,'The Grand Hotel');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (2,'General Entrance Day 1',TO_TIMESTAMP('04/03/2025','DD/MM/YYYY'),80,NULL,'Exhibition Hall PII');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (3,'General Entrance Day 2',TO_TIMESTAMP('05/03/2025','DD/MM/YYYY'),80,NULL,'Exhibition Hall PII');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (4,'CEO gala dinner',TO_TIMESTAMP('06/03/2025','DD/MM/YYYY'),30,NULL,'The Grand Hotel');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (5,'Closing party',TO_TIMESTAMP('06/03/2025','DD/MM/YYYY'),75,NULL,'The Grand Hotel');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (6,'Future of Software Development - Speakers from Microsoft and IBM',TO_TIMESTAMP('04/03/2025','DD/MM/YYYY'),30,2,'Auditorium');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (7,'Global Software Engineering Conference - With experts from Intel and Oracle',TO_TIMESTAMP('04/03/2025','DD/MM/YYYY'),25,2,'Event Hall A');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (8,'CloudNext: Building the Future - Hosted by industry cloud leaders',TO_TIMESTAMP('04/03/2025','DD/MM/YYYY'),20,2,'Event Hall B');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (9,'Software in the Cloud: Innovations and Trends - Hosted by Cloud Tech Visionaries',TO_TIMESTAMP('04/03/2025','DD/MM/YYYY'),30,2,'Auditorium');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (10,'CloudVision Conference - Presented by AWS and Google Cloud',TO_TIMESTAMP('05/03/2025','DD/MM/YYYY'),30,3,'Auditorium');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (11,'The Cloud Security Revolution - With experts from Cisco and IBM',TO_TIMESTAMP('05/03/2025','DD/MM/YYYY'),20,3,'Event Hall A');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (12,'CloudSecurityTech: Best Practices - Panel with cloud providers and security consultants',TO_TIMESTAMP('05/03/2025','DD/MM/YYYY'),30,3,'Auditorium');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (13,'Cloud Data Security: Safeguarding Your Assets - Hosted by cybersecurity innovators',TO_TIMESTAMP('05/03/2025','DD/MM/YYYY'),20,3,'Event Hall B');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (14,'NextGen Cloud Innovations',TO_TIMESTAMP('04/03/2025','DD/MM/YYYY'),30,2,'Auditorium');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) VALUES (15,'Visionary Cloud Conference',TO_TIMESTAMP('05/03/2025','DD/MM/YYYY'),30,3,'Auditorium');

UPDATE erp.tb_event SET catering_cost_guest = 73.67 WHERE name IN ('Opening party','Closing party');
UPDATE erp.tb_event SET catering_cost_guest = 8.76 WHERE name IN ('General Entrance Day 1','General Entrance Day 2');
UPDATE erp.tb_event SET catering_cost_guest = 158.00 WHERE name = 'CEO gala dinner';

INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,3,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,4,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,5,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,9,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,10,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,11,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,12,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,13,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,18,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,19,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,22,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,23,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,26,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,27,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,28,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,29,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,30,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,33,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,35,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,36,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,37,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,38,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,39,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,48,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,49,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,51,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,55,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,56,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,57,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,60,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,61,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,62,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,66,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,69,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,70,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,72,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,74,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,75,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,76,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,77,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,80,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,81,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,83,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,84,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,85,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,86,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,87,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,89,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,90,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,96,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,97,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,98,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,1,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,1,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,2,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,1,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,3,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,2,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,3,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,2,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,3,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,6,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,6,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,6,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,4,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,4,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,7,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,4,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,6,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,7,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,7,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,8,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,8,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,5,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,5,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,14,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,7,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,15,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,7,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,8,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,16,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,8,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,9,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,20,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,9,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,10,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,21,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,14,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,24,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,15,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,16,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,25,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,10,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,31,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,11,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,32,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,20,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,21,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,34,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,11,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,40,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,12,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,24,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,41,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,25,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,12,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,42,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,13,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,43,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,13,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,44,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,5,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,9,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,10,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,22,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,26,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,28,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,55,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,62,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,74,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,87,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,16,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,16,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,16,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,16,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,18,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,18,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,19,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,19,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,31,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,32,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,20,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,21,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,34,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,22,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,22,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,23,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,23,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,24,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,25,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,26,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,26,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,40,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,41,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,42,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,27,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,43,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,44,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,28,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,45,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,46,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,47,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,28,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,29,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,29,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,30,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,50,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,30,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,52,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,33,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,33,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,53,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,54,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,35,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,35,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,36,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,36,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,37,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,37,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,58,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,59,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,38,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,38,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,39,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,39,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,46,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,63,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,64,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,48,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,48,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,49,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,65,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,49,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,44,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,51,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,9,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,51,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,67,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,54,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,45,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,18,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,55,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,68,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,55,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,56,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,27,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,56,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,57,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,58,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,46,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,35,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,59,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,60,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,60,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,61,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,71,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,48,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,61,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,61,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,62,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,47,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,57,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,62,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,66,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,66,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,73,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,69,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,69,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,69,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,70,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,70,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,71,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,76,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,72,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,72,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,74,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,50,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,84,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,74,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,75,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,75,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,76,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,77,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,77,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,79,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,97,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,80,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,52,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,80,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,53,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,81,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,54,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,54,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,82,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,58,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,81,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,59,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,59,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,83,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,63,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,83,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,64,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,84,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,65,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,83,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,67,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,85,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,68,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,83,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,71,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,84,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,86,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,73,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,84,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,79,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,79,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,87,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,82,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,88,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,83,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,84,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,84,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,89,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,85,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,85,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,86,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,90,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,87,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,91,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,88,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,92,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,89,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,89,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,93,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,90,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,94,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,91,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,95,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,92,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,85,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,93,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,85,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (7,94,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,86,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (8,95,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (6,95,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,99,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (9,99,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,100,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (14,100,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (13,86,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,86,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,87,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,87,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,87,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,89,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,89,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,89,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (11,90,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,90,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,95,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,95,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,96,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,96,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (10,96,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,97,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (15,98,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,98,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (12,98,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,99,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,100,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,98,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,3,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,1,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,46,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,71,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,3,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,11,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,18,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,23,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,29,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,39,null);
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,48,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,96,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,37,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,66,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,17,'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,78,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (4,88,'S');

INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,110,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (1,111, null);
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,110, null);
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (2,111, 'N');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (3,111, 'S');

INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1000,1,3,TO_TIMESTAMP('03/03/2025 18:45','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1001,1,4,TO_TIMESTAMP('03/03/2025 18:46','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1002,1,5,TO_TIMESTAMP('03/03/2025 18:47','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1003,1,9,TO_TIMESTAMP('03/03/2025 18:47','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1004,1,10,TO_TIMESTAMP('03/03/2025 18:47','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1005,1,11,TO_TIMESTAMP('03/03/2025 18:50','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1006,1,12,TO_TIMESTAMP('03/03/2025 18:50','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1007,1,13,TO_TIMESTAMP('03/03/2025 18:50','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1008,1,18,TO_TIMESTAMP('03/03/2025 18:50','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1009,1,19,TO_TIMESTAMP('03/03/2025 18:51','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1010,1,22,TO_TIMESTAMP('03/03/2025 18:51','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1011,1,23,TO_TIMESTAMP('03/03/2025 18:51','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1012,1,26,TO_TIMESTAMP('03/03/2025 18:52','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1013,1,28,TO_TIMESTAMP('03/03/2025 18:52','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1014,1,29,TO_TIMESTAMP('03/03/2025 18:52','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1015,1,30,TO_TIMESTAMP('03/03/2025 18:52','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1016,1,33,TO_TIMESTAMP('03/03/2025 18:53','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1017,1,35,TO_TIMESTAMP('03/03/2025 18:53','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1018,1,36,TO_TIMESTAMP('03/03/2025 18:53','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1019,1,37,TO_TIMESTAMP('03/03/2025 18:54','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1020,1,38,TO_TIMESTAMP('03/03/2025 18:54','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1021,1,39,TO_TIMESTAMP('03/03/2025 18:54','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1022,1,48,TO_TIMESTAMP('03/03/2025 18:54','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1023,1,49,TO_TIMESTAMP('03/03/2025 18:54','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1024,1,51,TO_TIMESTAMP('03/03/2025 18:54','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1025,1,55,TO_TIMESTAMP('03/03/2025 18:54','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1026,1,56,TO_TIMESTAMP('03/03/2025 18:55','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1027,1,57,TO_TIMESTAMP('03/03/2025 18:55','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1028,1,60,TO_TIMESTAMP('03/03/2025 18:55','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1029,1,61,TO_TIMESTAMP('03/03/2025 18:55','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1030,1,62,TO_TIMESTAMP('03/03/2025 18:55','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1031,1,66,TO_TIMESTAMP('03/03/2025 18:55','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1032,1,69,TO_TIMESTAMP('03/03/2025 18:55','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1033,1,70,TO_TIMESTAMP('03/03/2025 18:56','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1034,1,72,TO_TIMESTAMP('03/03/2025 18:56','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1035,1,74,TO_TIMESTAMP('03/03/2025 18:56','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1036,1,75,TO_TIMESTAMP('03/03/2025 18:56','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1037,1,76,TO_TIMESTAMP('03/03/2025 18:56','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1038,1,77,TO_TIMESTAMP('03/03/2025 18:56','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1039,1,80,TO_TIMESTAMP('03/03/2025 18:56','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1040,1,81,TO_TIMESTAMP('03/03/2025 18:57','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1041,1,83,TO_TIMESTAMP('03/03/2025 18:58','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1042,1,84,TO_TIMESTAMP('03/03/2025 18:59','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1043,1,85,TO_TIMESTAMP('03/03/2025 19:00','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1044,1,86,TO_TIMESTAMP('03/03/2025 19:02','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1045,1,87,TO_TIMESTAMP('03/03/2025 19:03','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1046,1,89,TO_TIMESTAMP('03/03/2025 19:10','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1047,1,96,TO_TIMESTAMP('03/03/2025 18:57','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1048,1,97,TO_TIMESTAMP('03/03/2025 18:59','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1049,1,98,TO_TIMESTAMP('03/03/2025 18:59','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1050,1,3,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1051,1,4,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1052,1,5,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1053,1,9,TO_TIMESTAMP('03/03/2025 20:50','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1054,1,10,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1055,1,11,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1056,1,12,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1057,1,13,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1058,1,18,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1059,1,19,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1060,1,22,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1061,1,23,TO_TIMESTAMP('03/03/2025 20:51','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1062,1,26,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1063,1,28,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1064,1,29,TO_TIMESTAMP('03/03/2025 21:15','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1065,1,30,TO_TIMESTAMP('03/03/2025 20:45','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1066,1,33,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1067,1,35,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1068,1,36,TO_TIMESTAMP('03/03/2025 21:13','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1069,1,37,TO_TIMESTAMP('03/03/2025 21:13','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1070,1,38,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1071,1,39,TO_TIMESTAMP('03/03/2025 21:13','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1072,1,48,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1073,1,49,TO_TIMESTAMP('03/03/2025 20:37','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1074,1,51,TO_TIMESTAMP('03/03/2025 21:11','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1075,1,55,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1076,1,56,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1077,1,57,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1078,1,60,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1079,1,61,TO_TIMESTAMP('03/03/2025 21:15','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1080,1,62,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1081,1,66,TO_TIMESTAMP('03/03/2025 21:10','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1082,1,69,TO_TIMESTAMP('03/03/2025 21:14','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1083,1,70,TO_TIMESTAMP('03/03/2025 20:53','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1084,1,72,TO_TIMESTAMP('03/03/2025 21:14','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1085,1,74,TO_TIMESTAMP('03/03/2025 21:14','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1086,1,75,TO_TIMESTAMP('03/03/2025 21:14','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1087,1,76,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1088,1,77,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1089,1,80,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1090,1,81,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1091,1,83,TO_TIMESTAMP('03/03/2025 21:11','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1092,1,84,TO_TIMESTAMP('03/03/2025 21:14','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1093,1,85,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1094,1,86,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1095,1,87,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1096,1,89,TO_TIMESTAMP('03/03/2025 21:15','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1097,1,96,TO_TIMESTAMP('03/03/2025 21:05','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1098,1,97,TO_TIMESTAMP('03/03/2025 21:06','dd/MM/yyyy hh24:mi'),'OUT');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1099,1,98,TO_TIMESTAMP('03/03/2025 21:07','dd/MM/yyyy hh24:mi'),'OUT');


INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1100,1,110,TO_TIMESTAMP('03/03/2025 08:00','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1101,1,111,TO_TIMESTAMP('03/03/2025 08:00','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1102,3,111,TO_TIMESTAMP('04/03/2025 08:00','dd/MM/yyyy hh24:mi'),'IN');
INSERT INTO erp.tb_access_log (access_log_id,event_id,guest_id,access_log_date,access_log_type) VALUES (1103,3,111,TO_TIMESTAMP('04/03/2025 08:22','dd/MM/yyyy hh24:mi'),'OUT');
