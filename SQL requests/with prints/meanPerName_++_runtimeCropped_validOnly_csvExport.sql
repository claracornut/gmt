-- MOYENNES
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
),
per_run AS (
  SELECT
    r.id, r.name, r.created_at,
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
                        AND m.time <= vw.t_end
  GROUP BY r.id, r.name, r.created_at, vw.t_start, vw.t_end
),
valid_runs AS (
  SELECT * FROM per_run
  WHERE cpu_time_powermetrics_vm > 0
    AND cores_energy_powermetrics_component > 0
    AND energy_impact_powermetrics_vm > 0
)
SELECT
  name AS categorie,
  COUNT(*) AS n_runs_valides,
  AVG(duration_video_s)                    AS avg_duration_video_s,
  AVG(gpu_carbon_powermetrics_component)   AS gpu_carbon_powermetrics_component,
  AVG(energy_impact_powermetrics_vm)       AS energy_impact_powermetrics_vm,
  AVG(cores_power_powermetrics_component)  AS cores_power_powermetrics_component,
  AVG(disk_total_byteswritten_powermetrics_vm) AS disk_total_byteswritten_powermetrics_vm,
  AVG(disk_total_bytesread_powermetrics_vm)    AS disk_total_bytesread_powermetrics_vm,
  AVG(embodied_carbon_share_machine)       AS embodied_carbon_share_machine,
  AVG(cpu_time_powermetrics_vm)            AS cpu_time_powermetrics_vm,
  AVG(gpu_power_powermetrics_component)    AS gpu_power_powermetrics_component,
  AVG(cpu_utilization_mach_system)         AS cpu_utilization_mach_system,
  AVG(disk_io_bytesread_powermetrics_vm)   AS disk_io_bytesread_powermetrics_vm,
  AVG(cores_carbon_powermetrics_component) AS cores_carbon_powermetrics_component,
  AVG(gpu_energy_powermetrics_component)   AS gpu_energy_powermetrics_component,
  AVG(cores_energy_powermetrics_component) AS cores_energy_powermetrics_component
FROM valid_runs
GROUP BY name
ORDER BY name
) TO '/Users/claracornut/gmt/csv files/moyennes_video_only.csv'
WITH CSV HEADER;