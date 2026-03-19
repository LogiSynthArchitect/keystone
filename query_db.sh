#!/bin/bash

# Keystone Cloud Database Query Utility
# Connects directly to the live Supabase Cloud

# Load environment variables from .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

SQL_QUERY=$1
ENV_FLAG=$2

if [ -z "$SQL_QUERY" ]; then
  echo "Error: No SQL query provided."
  echo "Usage: ./query_db.sh \"YOUR SQL HERE\" --staging | --prod"
  exit 1
fi

if [ "$ENV_FLAG" == "--staging" ]; then
  PROJECT_REF="mxkkntxemrcjbxvlzfbt"
  echo "Targeting STAGING environment..."
elif [ "$ENV_FLAG" == "--prod" ]; then
  PROJECT_REF="ifzpdizxitlvjbmzozew"
  echo "Targeting PRODUCTION environment..."
else
  echo "Error: You must specify an environment flag."
  echo "Usage: ./query_db.sh \"YOUR SQL HERE\" --staging | --prod"
  exit 1
fi

HOST="db.$PROJECT_REF.supabase.co"

PGPASSWORD=$SUPABASE_DB_PASSWORD psql -h $HOST -p 5432 -U postgres -d postgres -c "$SQL_QUERY"
