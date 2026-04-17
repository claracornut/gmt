\COPY (
WITH video_windows AS (
  SELECT
    n.run_id,
    MIN(n.time) FILTER (WHERE n.note LIKE 'START%') AS t_start,
    MAX(n.time) FILTER (WHERE n.note LIKE 'END%')   AS t_end
  FROM notes n
  JOIN runs r ON r.id = n.run_id
  WHERE r.name IN (
    'ytb-Ublock-v3', 'ytb-AdGuard-v3', 'ytb-AdBlockPlus-v3',
    'ytb-noAddBlock-v3', 'ytb-premium-v3'
  )
  GROUP BY n.run_id
)
SELECT
    r.id, r.name, r.created_at,
    (vw.t_end - vw.t_start) / 1e6 AS duration_video_s,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'gpu_carbon_powermetrics_component'), 0)        AS gpu_carbon_powermetrics_component,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'energy_impact_powermetrics_vm'), 0)            AS energy_impact_powermetrics_vm,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'cores_power_powermetrics_component'), 0)       AS cores_power_powermetrics_component,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'disk_total_byteswritten_powermetrics_vm'), 0)  AS disk_total_byteswritten_powermetrics_vm,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'disk_total_bytesread_powermetrics_vm'), 0)     AS disk_total_bytesread_powermetrics_vm,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'embodied_carbon_share_machine'), 0)            AS embodied_carbon_share_machine,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'cpu_time_powermetrics_vm'), 0)                 AS cpu_time_powermetrics_vm,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'gpu_power_powermetrics_component'), 0)         AS gpu_power_powermetrics_component,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'cpu_utilization_mach_system'), 0)              AS cpu_utilization_mach_system,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'disk_io_bytesread_powermetrics_vm'), 0)        AS disk_io_bytesread_powermetrics_vm,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'cores_carbon_powermetrics_component'), 0)      AS cores_carbon_powermetrics_component,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'gpu_energy_powermetrics_component'), 0)        AS gpu_energy_powermetrics_component,
    COALESCE(SUM(mv.value) FILTER (WHERE m.metric = 'cores_energy_powermetrics_component'), 0)      AS cores_energy_powermetrics_component
  FROM runs r
  JOIN video_windows vw ON vw.run_id = r.id
  JOIN measurement_metrics m ON m.run_id = r.id
  JOIN measurement_values mv ON mv.measurement_metric_id = m.id
                        AND mv.time >= vw.t_start
                        AND mv.time <= vw.t_end
  GROUP BY r.id, r.name, r.created_at, vw.t_start, vw.t_end
  ORDER BY r.created_at
) TO '/Users/claracornut/gmt/csv files/runs_detail_video_only.csv'
WITH CSV HEADER;