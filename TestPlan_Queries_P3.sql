

-- CLEAN TEST SCENARIO
DELETE FROM erp.tb_catering_hunters;
DELETE FROM erp.tb_alerts WHERE alert_access_id >= 10000;
DELETE FROM erp.tb_access_log WHERE access_log_id >= 10000;
DELETE FROM erp.tb_access_log WHERE event_id >= 100 OR guest_id>=200;
DELETE FROM erp.tb_event_guest WHERE event_id >= 100 OR guest_id>=200;
DELETE FROM erp.tb_guest WHERE guest_id >= 200;
DELETE FROM erp.tb_event WHERE event_id >= 100;



-- Create new scenario for test
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) 
VALUES (100,'Event test 100',TO_TIMESTAMP('01/05/2025','DD/MM/YYYY'),3,NULL,'Auditorium');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location) 
VALUES (101,'Event test 101',TO_TIMESTAMP('01/05/2025','DD/MM/YYYY'),5,NULL,'Auditorium');
INSERT INTO erp.tb_event (event_id,name,event_date,max_guest_count,event_parent,event_location, catering_cost_guest) 
VALUES (102,'Event test 102',TO_TIMESTAMP('01/05/2025','DD/MM/YYYY'),5,NULL,'Auditorium', 10.25);

INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) 
VALUES (200,'Mary Testing','mtest@hotmail.com','+34 111111111',TO_TIMESTAMP('1975-04-04','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) 
VALUES (201,'Tom Testing','ttest@hotmail.com','+34 222222222',TO_TIMESTAMP('1980-01-01','YYYY/MM/DD'),'VIP');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) 
VALUES (202,'Charles Testing','ctest@hotmail.com','+34 333333333',TO_TIMESTAMP('1985-01-01','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) 
VALUES (203,'Anne Testing','atest@hotmail.com','+34 444444444',TO_TIMESTAMP('1990-01-01','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) 
VALUES (204,'William Testing','wtest@hotmail.com','+34 555555555',TO_TIMESTAMP('1995-01-01','YYYY/MM/DD'),'E&D');
INSERT INTO erp.tb_guest (guest_id,name,email,phone_number,date_of_birth,guest_type_id) 
VALUES (205,'Hans Testing','htest@hotmail.com','+34 666666666',TO_TIMESTAMP('1998-01-01','YYYY/MM/DD'),'E&D');


INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (100,200,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (100,202,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (100,203,'S');
INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (100,204,'N');

INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (101,204,'N');

INSERT INTO erp.tb_event_guest (event_id,guest_id,confirmed) VALUES (102,204,'S');

-- Set access_log_id to 10000 just for facilitate the follow-up of the tests
INSERT INTO erp.tb_access_log VALUES (10000,1,1,TO_TIMESTAMP('2025-04-01','YYYY/MM/DD')::TIMESTAMP WITHOUT TIME ZONE,'OUT','N');

-- ********************
-- **** TEST CASES ****
-- ********************

-- TEST 1: Trying to access guest 200 into event 100 --> must return TRUE
select erp.validateAccess( 200, 100, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 1
-- No new alerts
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id = 100 ;

-- TEST 2: Trying to access again guest 200 into event 100 --> must return FALSE
select erp.validateAccess( 200, 100, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 2
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y
select * from erp.tb_access_log WHERE event_id = 100;

-- TEST 3: Trying to access guest 205 into event 100 --> must return FALSE (not registered)
select erp.validateAccess( 205, 100, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 3
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y
select * from erp.tb_access_log WHERE event_id = 100;

-- TEST 4: Trying again to access guest 205 into event 100 --> must return FALSE (not registered), event is full so can not register automatically
select erp.validateAccess( 205, 100, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 4
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y
select * from erp.tb_access_log WHERE event_id = 100;

-- TEST 5: Trying to access guest 205 into event 101 --> must return FALSE (not registered)
select erp.validateAccess( 205, 101, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 5
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y
select * from erp.tb_access_log WHERE event_id>= 100;
-- No automatically registered
select * from erp.tb_event_guest WHERE event_id = 101;

-- TEST 6: Trying  to access guest 205 into event 101 --> true and automatic registration if done in less than 1 minute after test 5
select erp.validateAccess( 205, 101, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 6
-- No new alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;
-- Automatically registered and confirmed
select * from erp.tb_event_guest WHERE event_id = 101;


-- TEST 7: Trying to access guest 201 into event 100 --> true (is VIP)
select erp.validateAccess( 201, 100, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 7
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;
-- Not automatically registered 
select * from erp.tb_event_guest WHERE event_id = 100;


-- TEST 8: Trying to access guest 204 into event 101 --> false (registed but not confirmed)
select erp.validateAccess( 204, 101, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 8
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;
-- Not automatically registered
select * from erp.tb_event_guest WHERE event_id = 101;


-- TEST 9: Trying to access guest 204 into event 101 --> true and automatic registration if done in less than 1 minute after test 7
select erp.validateAccess( 204, 101, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 9
-- No new alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;
-- Automatically registered and confirmed
select * from erp.tb_event_guest WHERE event_id = 101;


-- TEST 10: Trying to access guest 500 (does not exists) into event 101 --> false
select erp.validateAccess( 500, 101, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 10
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y, and guest_id = NULL
select * from erp.tb_access_log WHERE event_id>= 100;


-- TEST 11: Trying to exit guest 204 from event 101 --> true
select erp.validateAccess( 204, 101, 'OUT', (CURRENT_TIMESTAMP + INTERVAL '1 minutes')::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 11
-- No new alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;


-- TEST 12: Trying to re-enter guest 204 into event 101 -->false, exit registered less than 5 minutes after OUT
select erp.validateAccess( 204, 101, 'IN', (CURRENT_TIMESTAMP + INTERVAL '3 minutes')::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 12
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y
select * from erp.tb_access_log WHERE event_id>= 100;


-- TEST 13: Trying to re-enter guest 204 into event 101 -->true, exit registered more than 5 minutes after OUT
select erp.validateAccess( 204, 101, 'IN', (CURRENT_TIMESTAMP + INTERVAL '7 minutes')::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 13
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;


-- TEST 14:  Trying to access guest 204 into event 101 at next day --> true, with alert 4 (already IN but not today)
select erp.validateAccess( 204, 101, 'IN', (CURRENT_TIMESTAMP + INTERVAL '1 day')::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 14
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;

-- TEST 15:  Trying to access guest 204 into event 102 --> true  (registered and confirmed)
select erp.validateAccess( 204, 102, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 14
-- No new alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = N
select * from erp.tb_access_log WHERE event_id>= 100;



-- TEST 16:  Trying to access guest 203 into event 102 --> false (not registered)
select erp.validateAccess( 203, 102, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 16
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y
select * from erp.tb_access_log WHERE event_id>= 100;


-- TEST 17:  Trying again to access guest 203 into event 102 --> false (not registered, retry but the event has catering)
select erp.validateAccess( 203, 102, 'IN', CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);
-- Checks to do after test 17
-- New alert registered
select * from erp.tb_alerts;
-- Registered on tb_access_log with rejected = Y
select * from erp.tb_access_log WHERE event_id>= 100;



-- CHECK FINAL SCENARIO
select * from erp.tb_alerts where alert_access_id >= 10000 order by alert_access_id;
select * from erp.tb_access_log where access_log_id > 10000 order by access_log_id;
select * from erp.tb_catering_hunters;
select * from erp.tb_event_guest WHERE event_id >= 100 order by event_id, guest_id;


DELETE FROM erp.tb_access_log WHERE access_log_id >= 10000;
