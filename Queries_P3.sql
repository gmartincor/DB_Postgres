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

-- GOLDEN RULES:: If guest is VIP or move is OUT --> always allowed
IF (isVIP OR (typeMov = 'OUT')) THEN
    allowed = true;
END IF;

-- Now we have all the information needed to make inserts
idGuestRef = idGuest;

-- Insert movement into tb_access log
INSERT INTO erp.tb_access_log (
    access_log_id, event_id, guest_id, access_log_date, access_log_type, access_rejected
)
VALUES (
    (SELECT MAX(access_log_id) + 1 FROM erp.tb_access_log),
    idEvent,
    idGuestRef,
    instant,
    typeMov,
    CASE allowed WHEN true THEN 'N' ELSE 'Y' END
);

-- Insert alert if needed on IN movements
IF ((typeMov = 'IN') AND (checkResult <> 0)) THEN
    alert_message = 'ACCESS ALERT:: Validation code ' || checkResult || '::' || erp.description_access_code(checkResult);

    -- Additional information if idGuest does not exist
    IF (idGuestRef IS NULL) THEN
        alert_message = alert_message || ' - Guest ID: ' || idGuest;
    END IF;

    INSERT INTO erp.tb_alerts (alert_access_id, alert_description)
    VALUES (
        (SELECT MAX(access_log_id) FROM erp.tb_access_log),
        alert_message
    );
END IF;

-- Insert on catering_hunters
IF ((typeMov = 'IN') AND (checkResult <> 0) AND cateringCost > 0) THEN
    alert_message = 'POSSIBLE CATERING HUNTER DETECTED';
    INSERT INTO erp.tb_catering_hunters (
        hunter_id, event_id, guest_id, remarks
    )
    VALUES (
        (SELECT MAX(access_log_id) FROM erp.tb_access_log),
        idEvent,
        idGuest,
        alert_message
    );
END IF;

RETURN allowed;