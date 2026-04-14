-- Un run = plusieurs "phases" → il faut les sommer pour avoir le résultat total.
\COPY (
  SELECT
    r.name AS categorie,
    r.id AS run_id,
    r.created_at,
    SUM(CASE WHEN ps.metric = 'cores_energy_powermetrics_component' THEN ps.value ELSE 0 END) AS energie_cpu_uJ,
    SUM(CASE WHEN ps.metric = 'gpu_energy_powermetrics_component' THEN ps.value ELSE 0 END) AS energie_gpu_uJ,
    SUM(CASE WHEN ps.metric = 'phase_time_syscall_system' THEN ps.value ELSE 0 END) AS duree_us
  FROM runs r
  JOIN phase_stats ps ON ps.run_id = r.id
  WHERE r.name IN ('ytb-Ublock-v2', 'ytb-AdGuard-v2', 'ytb-AdBlockPlus-v2', 'ytb-noAddBlock-v2', 'ytb-premium-v2')
  GROUP BY r.id, r.name, r.created_at
  ORDER BY r.name, r.created_at
) TO '/Users/claracornut/gmt/csv\ files/runs_detail.csv' WITH CSV HEADER