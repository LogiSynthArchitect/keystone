#!/bin/bash

# Keystone Database Query Utility
# Usage: ./query_db.sh "SELECT * FROM public.jobs;"

if [ -z "$1" ]; then
  echo "Error: No SQL query provided."
  echo "Usage: ./query_db.sh \"YOUR SQL HERE\""
  exit 1
fi

docker exec supabase_db_keystone psql -U postgres -d postgres -c "$1"
