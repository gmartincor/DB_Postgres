CREATE OR REPLACE FUNCTION erp.description_access_code(code INTEGER) 
RETURNS VARCHAR(20) AS
DECLARE
   description VARCHAR(100);
BEGIN
	description = CASE (code)
		WHEN 1 THEN 'The guest does not exists'
		WHEN 2 THEN 'The guest has not registered for the event.'
		WHEN 3 THEN 'The guest has not confirmed attendance at the event.'
		WHEN 4 THEN 'The guest has already accessed the event, but not today'
		WHEN 5 THEN 'The guest has already accessed the event today.'
		WHEN 6 THEN 'The guest left the event less than 5 minutes ago.'
		WHEN 7 THEN 'The guest left the event more than 5 minutes ago.'
		END;
	RETURNS description;
END LANGUAGE plpgsql;
		


CREATE OR REPLACE FUNCTION erp.validateAccess(idGuest INTEGER, idEvent INTEGER, typeMov CHAR(3), instant TIMESTAMP) 
RETURN BOOLEAN AS 
DECLARE 
	allowed  BOOLEAN;
	isVIP    BOOLEAN;
	checkResult INTEGER;
	eventIsComplete BOOLEAN;
	cateringCost NUMERIC(6,2);
	alert_message VARCHAR(100);
	last_access TIMESTAMP;
	idGuestRef INTEGER;
BEGIN
	-- Initial values
	checkResult = 0;
	allowed = true;

	-- IN movements must be checked
	IF (typeMov = 'IN') THEN
		checkResult = erp.check_access(instant, idGuest, idEvent);
		allowed = (checkResult = 0) OR (checkResult = 4) OR (checkResult = 7);
	END IF;
					   
	-- Get info about guest to check if is VIP
	SELECT (guest_type_id = 'VIP') INTO isVIP
	FROM erp.tb_guest
	WHERE guest_id = idGuest;
	
	-- Get info about event to check if it's full and if it has catering
	SELECT (occupation_percentage >= 100), catering_cost_guest INTO eventIsComplete, cateringCost
	FROM erp.vw_event_occupation eo JOIN erp.tb_event ev ON ev.event_id = eo.event_id
	WHERE ev.event_id = idEvent;
							
	-- Event not completed, does not has catering and not allowed with reason 2 or 3 (not registered or not confirmed)
	IF (NOT eventIsComplete AND cateringCost = 0 AND (checkResult = 2 OR checkResult = 3)) THEN
		
		-- Get time of last rejected access for this guest in this event
		SELECT MAX(access_log_date) INTO last_access
		FROM erp.tb_access_log
		WHERE event_id = idEvent AND guest_id = idGuest AND access_rejected = 'Y';
		
		IF (FOUND AND last_access + INTERVAL '1 minutes' >= instant) THEN
			allowed = true;
			IF (checkResult = 2) THEN
			   INSERT INTO erp.tb_event_guest (event_id, guest_id, confirmed) 
			   VALUES (idEvent, idGuest, 'S');
			ELSE 
			   UPDATE erp.tb_event_guest 
			   SET confirmed = 'S'
			   WHERE event_id = idEvent AND guest_id = idGuest;
			END IF;
			checkResult = 0;
		END IF;
	
	END IF;
		
	-- GOLDEN RULES:: If guest is VIP or move is OUT --> always allowed
	IF (isVIP OR (typeMov = 'OUT' ) ) THEN
		allowed = true;
	END IF;
					   
	-- Now we have all the information needed to make inserts
	idGuestRef = idGuest;
	
	-- Insert movement into tb_access log
	INSERT INTO erp.tb_access_log (access_log_id, event_id, guest_id, access_log_date, access_log_type, access_rejected) 
	VALUES ((SELECT MAX(access_log_id)+1 FROM erp.tb_access_log), idEvent, idGuestRef, instant, typeMov, CASE allowed WHEN true THEN 'N' ELSE 'Y' END );
		
	--Insert alert if needed on IN movements
	IF ( (typeMov = 'IN') AND (checkResult <> 0) ) THEN
		alert_message = "ACCESS ALERT:: Validation code " || checkResult || "::" || erp.description_access_code(checkResult);
		-- Additional information if idGuest does not exists
		IF (idGuestRef IS NULL) THEN
			alert_message = alert_message || " - Guest ID: " || idGuest;
		END IF;
	    INSERT INTO erp.tb_alerts(alert_access_id, alert_description)
		VALUES ((SELECT MAX(access_log_id) FROM erp.tb_access_log), alert_message);
	END IF;
						   
	--Insert on catering_hunters
	IF ( (typeMov = 'IN') AND (checkResult <> 0) AND cateringCost > 0 ) THEN

		alert_message = 'POSSIBLE CATERING HUNTER DETECTED';
		INSERT INTO erp.tb_catering_hunters (hunter_id, event_id, guest_id, remarks)
		VALUES ((SELECT MAX(access_log_id) FROM erp.tb_access_log), idEvent, idGuest, alert_message);
	END IF;
	
	RETURN allowed;  

END LANGUAGE pgplsql;


