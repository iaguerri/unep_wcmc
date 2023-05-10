# source run_indicators.sh (inside docker)
# tail -f -n 100 log.out


set -a
. ../config.env
set +a


PGPASSWORD=$pwd psql -h $etl_server -p $port -d $etl_dbname -U $user \
-f wdpa_wdoecm_subset.sql

PGPASSWORD=$pwd psql -h $etl_server -p $port -d $etl_dbname -U $user \
-f index.sql
