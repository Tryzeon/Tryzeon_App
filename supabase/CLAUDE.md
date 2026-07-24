# Supabase

## Migrations

- Schema is cumulative: to find a column/type/function's real state, `grep -rn "<name>" supabase/migrations/` and trace to the **last** file that touches it — never treat the baseline dump as current.
- New migration timestamps must be later than the newest existing file, or `supabase db push` rejects them as out-of-order.
- Enums can't drop/merge values in place: cast dependent columns to `text` → remap data → rebuild type → cast back → drop old type.
