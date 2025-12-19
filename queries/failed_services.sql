SELECT 
    id, sub_state, description 
FROM 
    systemd_units 
WHERE 
    active_state = 'failed' OR sub_state = 'dead';
