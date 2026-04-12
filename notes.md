# Green Metrics Tool — Notes

## Commandes de base
```bash
# Voir toutes les images et containers (être dans le dossier green-metrics-tool)
docker ps

# Activer le venv
source venv/bin/activate

# Lancer un test (être dans le dossier green-metrics-tool)
python3 runner.py --uri ~/gmt --name "testUblock"
```

## Débeugage

> **Rem :** si erreur `"connection to port … failed"` => Docker n'est pas lancé → ouvrir l'app Docker

### Réinitialiser Docker
```bash
# Restart les containers
docker restart green-coding-gunicorn-container
docker restart green-coding-nginx-container

# Rebuild complet
docker compose down -v
docker compose up --build

# OU simple restart
docker compose restart
```

### Redémarrer l'ordi
```bash
sudo reboot
```

### Options de lancement pour déboguer
```bash
# Avec sudo (éviter les problèmes d'autorisation)
sudo python3 runner.py --uri ~/gmt --name "debug"

# Flags utiles
python3 runner.py --uri ~/gmt --name "debug" --verbose
python3 runner.py --uri ~/gmt --name "debug" --docker-prune
python3 runner.py --uri ~/gmt --name "debug" --dev-no-system-checks
```

### Erreur "il y a déjà des mesures en cours"
```bash
# Voir les processus en cours
ps aux | grep powermetrics

# Tuer un process spécifique
sudo kill -9 <le_numero_de_pid>

# Tuer tous les process GMT qui traînent
sudo pkill -f "metric_providers"
sudo pkill -f powermetrics
sudo pkill -f metric_providers
```

## Conventions choisies
### Vidéos youtube : 

https://youtu.be/Y4J_NYAQQEQ?si=BLcMRRYQMqy0-23l

### Noms à donner pour les mesures :
```
ytb-Ublock
ytb-AdGuard
ytb-AdBlockPlus
ytb-noAddBlock
ytb-premium

# nouvelles vidéos
ytb-Ublock-v2
ytb-AdGuard-v2
ytb-AdBlockPlus-v2
ytb-noAddBlock-v2
ytb-premium-v2

#avec un flow PlayVideo qui mesure uniquement pendant que les vidéos jouent
ytb-Ublock-v3
ytb-AdGuard-v3
ytb-AdBlockPlus-v3
ytb-noAddBlock-v3
ytb-premium-v3

```

## Base de données

### Connexion
```bash
# Se connecter à la db (être dans le dossier green-metrics-tool ?)
psql -h localhost -p 9573 -U postgres -d green-coding
```

### Requête SQL — moyennes par catégorie - all phases
```sql
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
```

### Export CSV — moyennes (ligne de commande complète)
```bash
psql -h localhost -p 9573 -U postgres -d green-coding -c "\COPY (
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
  WHERE r.name IN ('ytb-Ublock-v2', 'ytb-AdGuard-v2', 'ytb-AdBlockPlus-v2', 'ytb-noAddBlock-v2', 'ytb-premium-v2')
  GROUP BY r.name
  ORDER BY energie_cpu_moyenne_uJ DESC
) TO '/Users/claracornut/gmt/moyennes.csv' WITH CSV HEADER"
```

### Export CSV — détail par run - sum of all pahses

> Un run = plusieurs "phases" → il faut les sommer pour avoir le résultat total.
```bash
psql -h localhost -p 9573 -U postgres -d green-coding -c "\COPY (
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
) TO '/Users/claracornut/gmt/runs_detail.csv' WITH CSV HEADER";
```

### Export CSV — détail++ par run - sum of all phases

```SQL
\COPY ( SELECT r.name as categrie, r.id as run_id, r.created_at, SUM(CASE WHEN ps.metric = 'gpu_carbon_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_carbon_powermetrics_component, SUM(CASE WHEN ps.metric = 'energy_impact_powermetrics_vm' THEN ps.value ELSE 0 END) as energy_impact_powermetrics_vm, SUM(CASE WHEN ps.metric = 'cores_power_powermetrics_component' THEN ps.value ELSE 0 END) as cores_power_powermetrics_component, SUM(CASE WHEN ps.metric = 'disk_total_byteswritten_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_total_byteswritten_powermetrics_vm, SUM(CASE WHEN ps.metric = 'disk_total_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_total_bytesread_powermetrics_vm, SUM(CASE WHEN ps.metric = 'embodied_carbon_share_machine' THEN ps.value ELSE 0 END) as embodied_carbon_share_machine,  SUM(CASE WHEN ps.metric = 'cpu_time_powermetrics_vm' THEN ps.value ELSE 0 END) as cpu_time_powermetrics_vm, SUM(CASE WHEN ps.metric = 'phase_time_syscall_system' THEN ps.value ELSE 0 END) as phase_time_syscall_system, SUM(CASE WHEN ps.metric = 'gpu_power_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_power_powermetrics_component, SUM(CASE WHEN ps.metric = 'cpu_utilization_mach_system' THEN ps.value ELSE 0 END) as cpu_utilization_mach_system, SUM(CASE WHEN ps.metric = 'disk_io_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_io_bytesread_powermetrics_vm, SUM(CASE WHEN ps.metric = 'cores_carbon_powermetrics_component' THEN ps.value ELSE 0 END) as cores_carbon_powermetrics_component, SUM(CASE WHEN ps.metric = 'gpu_energy_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_energy_powermetrics_component,SUM(CASE WHEN ps.metric = 'cores_energy_powermetrics_component' THEN ps.value ELSE 0 END) as cores_energy_powermetrics_component FROM runs r JOIN phase_stats ps ON ps.run_id = r.id WHERE r.name IN ('ytb-Ublock-v2', 'ytb-AdGuard-v2', 'ytb-AdBlockPlus-v2', 'ytb-noAddBlock-v2', 'ytb-premium-v2') GROUP BY r.id, r.name, r.created_at ORDER BY r.created_at) TO '/Users/claracornut/gmt/runs_detail.csv' WITH CSV HEADER;

```

### Export CSV — détail++ par run - only runtime phase 

```SQL
\COPY ( SELECT r.name as categrie, r.id as run_id, r.created_at, SUM(CASE WHEN ps.metric = 'gpu_carbon_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_carbon_powermetrics_component, SUM(CASE WHEN ps.metric = 'energy_impact_powermetrics_vm' THEN ps.value ELSE 0 END) as energy_impact_powermetrics_vm, SUM(CASE WHEN ps.metric = 'cores_power_powermetrics_component' THEN ps.value ELSE 0 END) as cores_power_powermetrics_component, SUM(CASE WHEN ps.metric = 'disk_total_byteswritten_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_total_byteswritten_powermetrics_vm, SUM(CASE WHEN ps.metric = 'disk_total_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_total_bytesread_powermetrics_vm, SUM(CASE WHEN ps.metric = 'embodied_carbon_share_machine' THEN ps.value ELSE 0 END) as embodied_carbon_share_machine, SUM(CASE WHEN ps.metric = 'cpu_time_powermetrics_vm' THEN ps.value ELSE 0 END) as cpu_time_powermetrics_vm, SUM(CASE WHEN ps.metric = 'phase_time_syscall_system' THEN ps.value ELSE 0 END) as phase_time_syscall_system, SUM(CASE WHEN ps.metric = 'gpu_power_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_power_powermetrics_component, SUM(CASE WHEN ps.metric = 'cpu_utilization_mach_system' THEN ps.value ELSE 0 END) as cpu_utilization_mach_system, SUM(CASE WHEN ps.metric = 'disk_io_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_io_bytesread_powermetrics_vm, SUM(CASE WHEN ps.metric = 'cores_carbon_powermetrics_component' THEN ps.value ELSE 0 END) as cores_carbon_powermetrics_component, SUM(CASE WHEN ps.metric = 'gpu_energy_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_energy_powermetrics_component, SUM(CASE WHEN ps.metric = 'cores_energy_powermetrics_component' THEN ps.value ELSE 0 END) as cores_energy_powermetrics_component FROM runs r JOIN phase_stats ps ON ps.run_id = r.id WHERE r.name IN ('ytb-Ublock-v2', 'ytb-AdGuard-v2', 'ytb-AdBlockPlus-v2', 'ytb-noAddBlock-v2', 'ytb-premium-v2') AND ps.phase = '004_[RUNTIME]' GROUP BY r.id, r.name, r.created_at ORDER BY r.created_at) TO '/Users/claracornut/gmt/runs_detail_runtime.csv' WITH CSV HEADER;

```

### Export CSV — moyenne par catégorie++ - only runtime phase - enlève les runs invalides

```SQL
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
```

### Export CSV — moyenne par catégorie GPU - normalisée par durée - only runtime phase - enlève les runs invalides

```SQL
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
    COALESCE(SUM(ps.value) FILTER (WHERE ps.metric = 'phase_time_syscall_system'), 0) AS phase_time_syscall_system

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

  AVG(gpu_carbon_powermetrics_component::numeric / phase_time_syscall_system) AS gpu_carbon_rate_gco2_per_s,
  AVG(gpu_energy_powermetrics_component::numeric / phase_time_syscall_system) AS gpu_avg_power_w,
  AVG(gpu_power_powermetrics_component::numeric / 1000.0) AS gpu_power

FROM valid_runs
GROUP BY name
ORDER BY name
) TO '/Users/claracornut/gmt/gpu_metrics_normalisees.csv'
WITH CSV HEADER;
```
### Export CSV — moyenne par catégorie CPU - normalisée par durée - only runtime phase - enlève les runs invalides

```SQL
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
```

### Export CSV — moyenne par catégorie++ - only runtime phase - takes out 0s

```SQL
\COPY (WITH per_run AS (SELECT      r.name,     SUM(CASE WHEN ps.metric = 'gpu_carbon_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_carbon_powermetrics_component,     SUM(CASE WHEN ps.metric = 'energy_impact_powermetrics_vm' THEN ps.value ELSE 0 END) as energy_impact_powermetrics_vm,      SUM(CASE WHEN ps.metric = 'cores_power_powermetrics_component' THEN ps.value ELSE 0 END) as cores_power_powermetrics_component,      SUM(CASE WHEN ps.metric = 'disk_total_byteswritten_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_total_byteswritten_powermetrics_vm,      SUM(CASE WHEN ps.metric = 'disk_total_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_total_bytesread_powermetrics_vm,      SUM(CASE WHEN ps.metric = 'embodied_carbon_share_machine' THEN ps.value ELSE 0 END) as embodied_carbon_share_machine,      SUM(CASE WHEN ps.metric = 'cpu_time_powermetrics_vm' THEN ps.value ELSE 0 END) as cpu_time_powermetrics_vm,      SUM(CASE WHEN ps.metric = 'phase_time_syscall_system' THEN ps.value ELSE 0 END) as phase_time_syscall_system,     SUM(CASE WHEN ps.metric = 'gpu_power_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_power_powermetrics_component,      SUM(CASE WHEN ps.metric = 'cpu_utilization_mach_system' THEN ps.value ELSE 0 END) as cpu_utilization_mach_system,      SUM(CASE WHEN ps.metric = 'disk_io_bytesread_powermetrics_vm' THEN ps.value ELSE 0 END) as disk_io_bytesread_powermetrics_vm,     SUM(CASE WHEN ps.metric = 'cores_carbon_powermetrics_component' THEN ps.value ELSE 0 END) as cores_carbon_powermetrics_component,      SUM(CASE WHEN ps.metric = 'gpu_energy_powermetrics_component' THEN ps.value ELSE 0 END) as gpu_energy_powermetrics_component,     SUM(CASE WHEN ps.metric = 'cores_energy_powermetrics_component' THEN ps.value ELSE 0 END) as cores_energy_powermetrics_component   FROM runs r   JOIN phase_stats ps ON ps.run_id = r.id   WHERE r.name IN ('ytb-Ublock-v2', 'ytb-AdGuard-v2', 'ytb-AdBlockPlus-v2', 'ytb-noAddBlock-v2', 'ytb-premium-v2')   AND ps.phase = '004_[RUNTIME]'   GROUP BY r.id, r.name  ) SELECT   name as categorie, AVG(NULLIF(gpu_carbon_powermetrics_component,0)) as gpu_carbon_powermetrics_component,    AVG(NULLIF(energy_impact_powermetrics_vm,0)) as energy_impact_powermetrics_vm,   AVG(NULLIF(cores_power_powermetrics_component,0)) as cores_power_powermetrics_component,    AVG(NULLIF(disk_total_byteswritten_powermetrics_vm,0)) as disk_total_byteswritten_powermetrics_vm,    AVG(NULLIF(disk_total_bytesread_powermetrics_vm,0)) as disk_total_bytesread_powermetrics_vm,   AVG(NULLIF(cpu_time_powermetrics_vm,0)) as cpu_time_powermetrics_vm,    AVG(NULLIF(phase_time_syscall_system,0)) as phase_time_syscall_system,   AVG(NULLIF(gpu_power_powermetrics_component,0)) as gpu_power_powermetrics_component,   AVG(NULLIF(cpu_utilization_mach_system,0)) as cpu_utilization_mach_system,    AVG(NULLIF(disk_io_bytesread_powermetrics_vm,0)) as disk_io_bytesread_powermetrics_vm,    AVG(NULLIF(cores_carbon_powermetrics_component,0)) as cores_carbon_powermetrics_component,    AVG(NULLIF(cores_energy_powermetrics_component,0)) as cores_energy_powermetrics_component  FROM per_run GROUP BY name ORDER BY name) TO '/Users/claracornut/gmt/moyennes_runtime.csv' WITH CSV HEADER;
```

### Structure de la DB complète

Commande : `\dt`
```
                   List of tables
 Schema |            Name             | Type  |  Owner
--------+-----------------------------+-------+----------
 public | carbon_intensity            | table | postgres
 public | carbondb_data               | table | postgres
 public | carbondb_data_raw           | table | postgres
 public | carbondb_machines           | table | postgres
 public | carbondb_projects           | table | postgres
 public | carbondb_sources            | table | postgres
 public | carbondb_tags               | table | postgres
 public | carbondb_types              | table | postgres
 public | categories                  | table | postgres
 public | ci_measurements             | table | postgres
 public | client_status               | table | postgres
 public | cluster_changelog           | table | postgres
 public | cluster_status_messages     | table | postgres
 public | hog_simplified_measurements | table | postgres
 public | hog_top_processes           | table | postgres
 public | ip_data                     | table | postgres
 public | jobs                        | table | postgres
 public | machines                    | table | postgres
 public | measurement_metrics         | table | postgres
 public | measurement_values          | table | postgres
 public | network_intercepts          | table | postgres
 public | notes                       | table | postgres
 public | optimizations               | table | postgres
 public | phase_stats                 | table | postgres
 public | runs                        | table | postgres
 public | users                       | table | postgres
 public | warnings                    | table | postgres
 public | watchlist                   | table | postgres
```

### Table `runs`

Commande : `\d runs`
```
                                       Table "public.runs"
          Column          |           Type           | Collation | Nullable |      Default       
--------------------------+--------------------------+-----------+----------+--------------------
 id                       | uuid                     |           | not null | uuid_generate_v4()
 job_id                   | integer                  |           |          | 
 name                     | text                     |           |          | 
 uri                      | text                     |           | not null | 
 branch                   | text                     |           | not null | 
 commit_hash              | text                     |           |          | 
 commit_timestamp         | timestamp with time zone |           |          | 
 category_ids             | integer[]                |           |          | 
 usage_scenario           | json                     |           |          | 
 usage_scenario_variables | jsonb                    |           | not null | '{}'::jsonb
 filename                 | text                     |           | not null | 
 relations                | jsonb                    |           |          | 
 machine_specs            | jsonb                    |           |          | 
 runner_arguments         | json                     |           |          | 
 machine_id               | integer                  |           | not null | 
 gmt_hash                 | text                     |           |          | 
 measurement_config       | jsonb                    |           |          | 
 start_measurement        | bigint                   |           |          | 
 end_measurement          | bigint                   |           |          | 
 containers               | jsonb                    |           |          | 
 container_dependencies   | jsonb                    |           |          | 
 phases                   | json                     |           |          | 
 logs                     | jsonb                    |           |          | 
 failed                   | boolean                  |           | not null | false
 archived                 | boolean                  |           | not null | false
 note                     | text                     |           | not null | ''::text
 public                   | boolean                  |           | not null | false
 user_id                  | integer                  |           | not null | 
 created_at               | timestamp with time zone |           | not null | now()
 updated_at               | timestamp with time zone |           |          | 
Indexes:
    "runs_pkey" PRIMARY KEY, btree (id)
    "runs_job_id_key" UNIQUE CONSTRAINT, btree (job_id)
Foreign-key constraints:
    "runs_job_id_fkey" FOREIGN KEY (job_id) REFERENCES jobs(id) ON UPDATE CASCADE ON DELETE SET NULL
    "runs_machine_id_fkey" FOREIGN KEY (machine_id) REFERENCES machines(id) ON UPDATE CASCADE ON DELETE RESTRICT
    "runs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT
Referenced by:
    TABLE "client_status" CONSTRAINT "client_status_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
    TABLE "jobs" CONSTRAINT "jobs_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE SET NULL
    TABLE "measurement_metrics" CONSTRAINT "measurement_metrics_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
    TABLE "network_intercepts" CONSTRAINT "network_intercepts_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
    TABLE "notes" CONSTRAINT "notes_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
    TABLE "optimizations" CONSTRAINT "optimizations_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
    TABLE "phase_stats" CONSTRAINT "phase_stats_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
    TABLE "warnings" CONSTRAINT "warnings_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
Triggers:
    runs_moddatetime BEFORE UPDATE ON runs FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at')
    trg_validate_category_ids BEFORE INSERT OR UPDATE ON runs FOR EACH ROW EXECUTE FUNCTION validate_category_ids()


### Différentes metrics
Commande : `select distinct(metric) from phase_stats;`
                 metric                  
-----------------------------------------
 gpu_carbon_powermetrics_component
 energy_impact_powermetrics_vm
 cores_power_powermetrics_component
 disk_total_byteswritten_powermetrics_vm
 disk_io_byteswritten_powermetrics_vm
 cpu_time_powermetrics_vm
 ane_energy_powermetrics_component --> 0
 embodied_carbon_share_machine
 disk_total_bytesread_powermetrics_vm
 phase_time_syscall_system
 ane_power_powermetrics_component --> 0
 gpu_power_powermetrics_component
 cpu_utilization_mach_system
 disk_io_bytesread_powermetrics_vm
 cores_carbon_powermetrics_component
 gpu_energy_powermetrics_component
 ane_carbon_powermetrics_component --> 0
 cores_energy_powermetrics_component
(18 rows)

green-coding=# select distinct(metric) from phase_stats order by metric;
                 metric                  
-----------------------------------------
 ane_carbon_powermetrics_component
 ane_energy_powermetrics_component
 ane_power_powermetrics_component
 cores_carbon_powermetrics_component
 cores_energy_powermetrics_component
 cores_power_powermetrics_component
 cpu_time_powermetrics_vm
 cpu_utilization_mach_system
 disk_io_bytesread_powermetrics_vm
 disk_io_byteswritten_powermetrics_vm
 disk_total_bytesread_powermetrics_vm
 disk_total_byteswritten_powermetrics_vm
 embodied_carbon_share_machine
 energy_impact_powermetrics_vm
 gpu_carbon_powermetrics_component
 gpu_energy_powermetrics_component
 gpu_power_powermetrics_component
 phase_time_syscall_system
(18 rows)
```

### Table `phase_stats`

Commande : `\d phase_stats`
                                          Table "public.phase_stats"
      Column       |           Type           | Collation | Nullable |                 Default                 
-------------------+--------------------------+-----------+----------+-----------------------------------------
 id                | integer                  |           | not null | nextval('phase_stats_id_seq'::regclass)
 run_id            | uuid                     |           | not null | 
 metric            | text                     |           | not null | 
 detail_name       | text                     |           | not null | 
 phase             | text                     |           | not null | 
 value             | bigint                   |           | not null | 
 type              | text                     |           | not null | 
 max_value         | bigint                   |           |          | 
 min_value         | bigint                   |           |          | 
 sampling_rate_avg | integer                  |           |          | 
 sampling_rate_max | integer                  |           |          | 
 sampling_rate_95p | integer                  |           |          | 
 unit              | text                     |           | not null | 
 hidden            | boolean                  |           | not null | false
 created_at        | timestamp with time zone |           | not null | now()
 updated_at        | timestamp with time zone |           |          | 
Indexes:
    "phase_stats_pkey" PRIMARY KEY, btree (id)
    "phase_stats_run_id" hash (run_id)
Foreign-key constraints:
    "phase_stats_run_id_fkey" FOREIGN KEY (run_id) REFERENCES runs(id) ON UPDATE CASCADE ON DELETE CASCADE
Triggers:
    phase_stats_moddatetime BEFORE UPDATE ON phase_stats FOR EACH ROW EXECUTE FUNCTION moddatetime('updated_at')


## Cloud Runner 
https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fmetrics.green-coding.io%2Fauthentication.html&data=05%7C02%7Cclara.cornut%40ulb.be%7C492315c6d12143f6ae1a08de96556233%7C30a5145e75bd4212bb028ff9c0ea4ae9%7C0%7C0%7C639113490614696199%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=BPCR4V%2FlGxltDtSAng2SWML8wUkC3PFlhjczAI9%2Ftrw%3D&reserved=0

token: h5j8rhu48HFas3_agj488imfeimuun3iuguiBDUIui39jfh90s

machine : GUI application - TX 1330 M4