#!/usr/bin/env bash
# Regenerate the edge functions' schema types from the local Supabase stack.
#
# Run after any migration that adds or changes a type, table, or column, and
# commit the result — `vocabularies.ts` re-exports its runtime arrays straight
# from this file's generated `Constants` object, so a stale copy means stale
# vocabularies reach the model, and can mean the module imports values that no
# longer exist.
#
# Reads the local stack, not the hosted project: the local one is the migrations
# in this repo, which is what the committed types should describe.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! supabase status >/dev/null 2>&1; then
  echo "Local Supabase stack is not running. Start it with: supabase start" >&2
  exit 1
fi

supabase gen types typescript --local > supabase/functions/_shared/database.types.ts
echo "Wrote supabase/functions/_shared/database.types.ts"
