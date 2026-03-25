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
Vidéos youtube : 
https://youtu.be/Y4J_NYAQQEQ?si=BLcMRRYQMqy0-23l

Noms à donner pour les mesures :
```
ytb-Ublock
ytb-AdGuard
ytb-AdBlockPlus
ytb-noAddBlock
ytb-premium
```
```
ytb-Ublock-v2
ytb-AdGuard-v2
ytb-AdBlockPlus-v2
ytb-noAddBlock-v2
ytb-premium-v2
```

## Base de données

### Connexion
```bash
# Se connecter à la db (être dans le dossier docker ?)
psql -h localhost -p 9573 -U postgres -d green-coding
```

### Requête SQL — moyennes par catégorie
```sql
SELECT
  r.name AS categorie,
  COUNT(DISTINCT r.id) AS nb_runs,
  ROUND(AVG(totaux.energie_cpu_uJ)) AS energie_cpu_moyenne_uJ,
  ROUND(STDDEV(totaux.energie_cpu_uJ)) AS ecart_type_cpu,
  ROUND(AVG(totaux.energie_gpu_uJ)) AS energie_gpu_moyenne_uJ,
  ROUND(AVG(totaux.duree_us)) AS duree_moyenne_us
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
    ROUND(AVG(totaux.energie_cpu_uJ)) AS energie_cpu_moyenne_uJ,
    ROUND(STDDEV(totaux.energie_cpu_uJ)) AS ecart_type_cpu,
    ROUND(AVG(totaux.energie_gpu_uJ)) AS energie_gpu_moyenne_uJ,
    ROUND(AVG(totaux.duree_us)) AS duree_moyenne_us
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
  ORDER BY energie_cpu_moyenne_uJ DESC
) TO '/Users/claracornut/gmt/moyennes.csv' WITH CSV HEADER"
```

### Export CSV — détail par run

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
  WHERE r.name IN ('ytb-Ublock', 'ytb-AdGuard', 'ytb-AdBlockPlus', 'ytb-noAddBlock', 'ytb-premium')
  GROUP BY r.id, r.name, r.created_at
  ORDER BY r.name, r.created_at
) TO '/Users/claracornut/gmt/runs_detail.csv' WITH CSV HEADER";
```

### Structure de la DB

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

Commande : `SELECT * FROM runs;`
```
                  id                  |      name       |          created_at
--------------------------------------+-----------------+-------------------------------
 23ad03a5-52ac-45f4-9aff-3e3423389b6e | testAdBlockPlus | 2026-03-21 18:47:00.825505+01
 ba019163-7365-42d1-b013-e1d226b5d354 | testAdGuard     | 2026-03-21 18:09:30.785291+01
 f76b756e-9fcc-4f0c-93f0-ec428810b0c3 | testAdGuard     | 2026-03-21 17:54:55.145938+01
 db7c84e1-b7ae-46f2-984f-8a5a14eafc8c | testUblock      | 2026-03-21 17:35:39.290784+01
 d7a68257-5d78-461a-b955-46657048b7fb | testUblock      | 2026-03-21 17:04:41.57119+01
```