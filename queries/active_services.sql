SELECT 
    id, sub_state, description 
FROM 
    systemd_units 
WHERE 
    active_state = 'active' OR sub_state = 'running';
