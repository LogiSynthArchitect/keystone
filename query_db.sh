#!/bin/bash

# Keystone Cloud Database Query Utility
# Connects directly to the live Supabase Cloud

# Load environment variables from .env
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "$1" ]; then
  echo "Error: No SQL query provided."
  echo "Usage: ./query_db.sh \"YOUR SQL HERE\""
  exit 1
fi

# Extract project ref from URL
PROJECT_REF="ifzpdizxitlvjbmzozew"
HOST="db.$PROJECT_REF.supabase.co"

PGPASSWORD=$SUPABASE_DB_PASSWORD psql -h $HOST -p 5432 -U postgres -d postgres -c "$1"
