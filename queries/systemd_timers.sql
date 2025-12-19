SELECT 
    id, description, sub_state, active_state 
FROM 
    systemd_units WHERE id LIKE '%.timer';
