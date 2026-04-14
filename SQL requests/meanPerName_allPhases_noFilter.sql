SELECT
  r.name AS categorie,
  COUNT(DISTINCT r.id) AS nb_runs,
  ROUND(AVG(NULLIF(totaux.energie_cpu_uJ,0))) AS energie_cpu_moyenne_uJ,
  ROUND(STDDEV(totaux.energie_cpu_uJ)) AS ecart_type_cpu,
  ROUND(AVG(NULLIF(totaux.energie_gpu_uJ,0))) AS energie_gpu_moyenne_uJ,
  ROUND(AVG(NULLIF(totaux.duree_us,0))) AS duree_moyenne_us
FROM runs r JOIN (
  SELECT
    ps.run_id,
    SUM(CASE WHEN ps.metric = 'cores_energy_powermetrics_component' THEN ps.value ELSE 0 END) AS energie_cpu_uJ,
    SUM(CASE WHEN ps.metric = 'gpu_energy_powermetrics_component' THEN ps.value ELSE 0 END) AS energie_gpu_uJ,
    SUM(CASE WHEN ps.metric = 'phase_time_syscall_system' THEN ps.value ELSE 0 END) AS duree_us
  FROM phase_stats ps
  GROUP BY ps.run_id
) totaux ON totaux.run_id = r.id
WHERE r.name IN ('ytb-Ublock', 'ytb-AdGuard', 'ytb-AdBlockPlus', 'ytb-noAddBlock', 'ytb-premium')
GROUP BY r.name
ORDER BY energie_cpu_moyenne_uJ DESC;