-- DÉTAIL PAR RUN
\COPY (
WITH video_windows AS (
  SELECT
    n.run_id,
    MIN(n.time) FILTER (WHERE n.note LIKE 'START%') AS t_start,
    MAX(n.time) FILTER (WHERE n.note LIKE 'END%')   AS t_end
  FROM notes n
  JOIN runs r ON r.id = n.run_id
  WHERE r.name IN (
    'ytb-Ublock-v2', 'ytb-AdGuard-v2', 'ytb-AdBlockPlus-v2',
    'ytb-noAddBlock-v2', 'ytb-premium-v2'
  )
  GROUP BY n.run_id
)
SELECT
  r.name AS categorie,
  r.id AS run_id,
  r.created_at,
  (vw.t_end - vw.t_start) / 1e6 AS duration_video_s,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'gpu_carbon_powermetrics_component'), 0)        AS gpu_carbon_powermetrics_component,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'energy_impact_powermetrics_vm'), 0)            AS energy_impact_powermetrics_vm,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'cores_power_powermetrics_component'), 0)       AS cores_power_powermetrics_component,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'disk_total_byteswritten_powermetrics_vm'), 0)  AS disk_total_byteswritten_powermetrics_vm,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'disk_total_bytesread_powermetrics_vm'), 0)     AS disk_total_bytesread_powermetrics_vm,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'embodied_carbon_share_machine'), 0)            AS embodied_carbon_share_machine,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'cpu_time_powermetrics_vm'), 0)                 AS cpu_time_powermetrics_vm,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'gpu_power_powermetrics_component'), 0)         AS gpu_power_powermetrics_component,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'cpu_utilization_mach_system'), 0)              AS cpu_utilization_mach_system,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'disk_io_bytesread_powermetrics_vm'), 0)        AS disk_io_bytesread_powermetrics_vm,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'cores_carbon_powermetrics_component'), 0)      AS cores_carbon_powermetrics_component,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'gpu_energy_powermetrics_component'), 0)        AS gpu_energy_powermetrics_component,
  COALESCE(SUM(m.value) FILTER (WHERE m.metric = 'cores_energy_powermetrics_component'), 0)      AS cores_energy_powermetrics_component
FROM runs r
JOIN video_windows vw ON vw.run_id = r.id
JOIN measurements m   ON m.run_id = r.id
                      AND m.time >= vw.t_start
                      AND m.time <= vw.t_end   -- ← <= et non >=
GROUP BY r.id, r.name, r.created_at, vw.t_start, vw.t_end
ORDER BY r.created_at
) TO '/Users/claracornut/gmt/csv files/runs_detail_video_only.csv'
WITH CSV HEADER;