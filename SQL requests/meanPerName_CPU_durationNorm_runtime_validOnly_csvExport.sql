\COPY (
WITH per_run AS (
  SELECT
    r.id,
    r.name,
    r.created_at,

    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'gpu_carbon_powermetrics_component'), 0) AS gpu_carbon_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'gpu_power_powermetrics_component'), 0) AS gpu_power_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'gpu_energy_powermetrics_component'), 0) AS gpu_energy_powermetrics_component,

    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'energy_impact_powermetrics_vm'), 0) AS energy_impact_powermetrics_vm,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cpu_time_powermetrics_vm'), 0) AS cpu_time_powermetrics_vm,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cores_energy_powermetrics_component'), 0) AS cores_energy_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'phase_time_syscall_system'), 0) AS phase_time_syscall_system,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cores_carbon_powermetrics_component'), 0) AS cores_carbon_powermetrics_component,
    COALESCE((ps.value) FILTER (WHERE ps.metric = 'cores_power_powermetrics_component'), 0) AS cores_power_powermetrics_component


  FROM runs r
  JOIN phase_stats ps ON ps.run_id = r.id
  WHERE r.name IN (
    'ytb-Ublock-v2',
    'ytb-AdGuard-v2',
    'ytb-AdBlockPlus-v2',
    'ytb-noAddBlock-v2',
    'ytb-premium-v2'
  )
    AND ps.phase = '004_[RUNTIME]'
  GROUP BY r.id, r.name, r.created_at
),

valid_runs AS (
  SELECT *
  FROM per_run
  WHERE phase_time_syscall_system > 0
    AND cpu_time_powermetrics_vm > 0
    AND cores_energy_powermetrics_component > 0
    AND energy_impact_powermetrics_vm > 0
)

SELECT
  name AS categorie,
  COUNT(*) AS n_runs_valides,

  AVG(cores_carbon_powermetrics_component::numeric / phase_time_syscall_system) AS cpu_carbon_rate_gco2_per_s,
  AVG(cores_energy_powermetrics_component::numeric / phase_time_syscall_system) AS cpu_avg_power_w,
  AVG(cores_power_powermetrics_component::numeric / 1000.0) AS cpu_power

FROM valid_runs
GROUP BY name
ORDER BY name
) TO '/Users/claracornut/gmt/cpu_metrics_normalisees.csv'
WITH CSV HEADER;