\COPY (
WITH per_run AS (
  SELECT
    r.id,
    r.name,
    r.created_at,

    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'gpu_carbon_powermetrics_component'), 0) AS gpu_carbon_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'energy_impact_powermetrics_vm'), 0) AS energy_impact_powermetrics_vm,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cores_power_powermetrics_component'), 0) AS cores_power_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'disk_total_byteswritten_powermetrics_vm'), 0) AS disk_total_byteswritten_powermetrics_vm,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'disk_total_bytesread_powermetrics_vm'), 0) AS disk_total_bytesread_powermetrics_vm,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'embodied_carbon_share_machine'), 0) AS embodied_carbon_share_machine,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cpu_time_powermetrics_vm'), 0) AS cpu_time_powermetrics_vm,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'phase_time_syscall_system'), 0) AS phase_time_syscall_system,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'gpu_power_powermetrics_component'), 0) AS gpu_power_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cpu_utilization_mach_system'), 0) AS cpu_utilization_mach_system,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'disk_io_bytesread_powermetrics_vm'), 0) AS disk_io_bytesread_powermetrics_vm,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cores_carbon_powermetrics_component'), 0) AS cores_carbon_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'gpu_energy_powermetrics_component'), 0) AS gpu_energy_powermetrics_component,
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'cores_energy_powermetrics_component'), 0) AS cores_energy_powermetrics_component

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

  AVG(gpu_carbon_powermetrics_component) AS gpu_carbon_powermetrics_component,
  AVG(energy_impact_powermetrics_vm) AS energy_impact_powermetrics_vm,
  AVG(cores_power_powermetrics_component) AS cores_power_powermetrics_component,
  AVG(disk_total_byteswritten_powermetrics_vm) AS disk_total_byteswritten_powermetrics_vm,
  AVG(disk_total_bytesread_powermetrics_vm) AS disk_total_bytesread_powermetrics_vm,
  AVG(embodied_carbon_share_machine) AS embodied_carbon_share_machine,
  AVG(cpu_time_powermetrics_vm) AS cpu_time_powermetrics_vm,
  AVG(phase_time_syscall_system) AS phase_time_syscall_system,
  AVG(gpu_power_powermetrics_component) AS gpu_power_powermetrics_component,
  AVG(cpu_utilization_mach_system) AS cpu_utilization_mach_system,
  AVG(disk_io_bytesread_powermetrics_vm) AS disk_io_bytesread_powermetrics_vm,
  AVG(cores_carbon_powermetrics_component) AS cores_carbon_powermetrics_component,
  AVG(gpu_energy_powermetrics_component) AS gpu_energy_powermetrics_component,
  AVG(cores_energy_powermetrics_component) AS cores_energy_powermetrics_component

FROM valid_runs
GROUP BY name
ORDER BY name
) TO '/Users/claracornut/gmt/moyennes_runtime_valides.csv'
WITH CSV HEADER;