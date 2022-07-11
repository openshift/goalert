-- name: ForeignKeyRefs :many
SELECT src.relname::text,
    dst.relname::text
FROM pg_catalog.pg_constraint con
    JOIN pg_catalog.pg_namespace ns ON ns.nspname = 'public'
    AND ns.oid = con.connamespace
    JOIN pg_catalog.pg_class src ON src.oid = con.conrelid
    JOIN pg_catalog.pg_class dst ON dst.oid = con.confrelid
WHERE con.contype = 'f'
    AND NOT con.condeferrable;

-- name: TableColumns :many
SELECT col.table_name,
    col.column_name,
    col.data_type,
    col.ordinal_position
FROM information_schema.columns col
    JOIN information_schema.tables t ON t.table_catalog = col.table_catalog
    AND t.table_schema = col.table_schema
    AND t.table_name = col.table_name
    AND t.table_type = 'BASE TABLE'
WHERE col.table_catalog = current_database()
    AND col.table_schema = 'public';

-- name: SequenceNames :many
SELECT sequence_name
FROM information_schema.sequences
WHERE sequence_catalog = current_database()
    AND sequence_schema = 'public'
    AND sequence_name != 'change_log_id_seq';

-- name: ServerVersion :one
SELECT version();
