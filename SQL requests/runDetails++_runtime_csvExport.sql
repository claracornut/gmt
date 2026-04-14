\COPY (
    SELECT
        r.name AS categorie,
        r.id AS run_id,
        r.created_at,

        SUM(CASE WHEN ps.metric = 'gpu_carbon_powermetrics_component' THEN ps.value ELSE 0 END) AS gpu_carbon_powermetrics_component,
        SUM(CASE WHEN ps.metric = 'energy_impact_powermetrics_vm' THEN ps.value ELSE 0 END) AS energy_impact_powermetrics_vm,
        SUM(CASE WHEN ps.metric = 'cores_power_powermetrics_component' THEN ps.value ELSE 0 END) AS cores_power_powermetrics_component,
        SUM(CASE WHEN ps.metric = 'disk_total_byteswritten_powermetrics_vm' THEN ps.value ELSE 0 END) AS disk_total_byteswritten_powermetrics_vm,
        SUM(CASE WHEN ps.metric = 'disk_total_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) AS disk_total_bytesread_powermetrics_vm,
        SUM(CASE WHEN ps.metric = 'embodied_carbon_share_machine' THEN ps.value ELSE 0 END) AS embodied_carbon_share_machine,
        SUM(CASE WHEN ps.metric = 'cpu_time_powermetrics_vm' THEN ps.value ELSE 0 END) AS cpu_time_powermetrics_vm,
        SUM(CASE WHEN ps.metric = 'phase_time_syscall_system' THEN ps.value ELSE 0 END) AS phase_time_syscall_system,
        SUM(CASE WHEN ps.metric = 'gpu_power_powermetrics_component' THEN ps.value ELSE 0 END) AS gpu_power_powermetrics_component,
        SUM(CASE WHEN ps.metric = 'cpu_utilization_mach_system' THEN ps.value ELSE 0 END) AS cpu_utilization_mach_system,
        SUM(CASE WHEN ps.metric = 'disk_io_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) AS disk_io_bytesread_powermetrics_vm,
        SUM(CASE WHEN ps.metric = 'cores_carbon_powermetrics_component' THEN ps.value ELSE 0 END) AS cores_carbon_powermetrics_component,
        SUM(CASE WHEN ps.metric = 'gpu_energy_powermetrics_component' THEN ps.value ELSE 0 END) AS gpu_energy_powermetrics_component,
        SUM(CASE WHEN ps.metric = 'cores_energy_powermetrics_component' THEN ps.value ELSE 0 END) AS cores_energy_powermetrics_component

    FROM runs r
    JOIN phase_stats ps
        ON ps.run_id = r.id

    WHERE r.name IN (
        'ytb-Ublock-v2',
        'ytb-AdGuard-v2',
        'ytb-AdBlockPlus-v2',
        'ytb-noAddBlock-v2',
        'ytb-premium-v2'
    )
      AND ps.phase = '004_[RUNTIME]'

    GROUP BY
        r.id,
        r.name,
        r.created_at

    ORDER BY
        r.created_at
)
TO '/Users/claracornut/gmt/runs_detail_runtime.csv'
WITH CSV HEADER;