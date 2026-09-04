-- Pass339 I0 privilege-role scaffold. No LOGIN credentials or secrets live here.
-- Execute as a PostgreSQL administrator before assigning LOGIN identities.

DO $gxb$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gxb_owner') THEN
        CREATE ROLE gxb_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gxb_app') THEN
        CREATE ROLE gxb_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gxb_realtime') THEN
        CREATE ROLE gxb_realtime NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gxb_scheduler') THEN
        CREATE ROLE gxb_scheduler NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION;
    END IF;
END
$gxb$;

-- I2 migrations will define table-specific grants. Runtime roles deliberately
-- receive no broad CREATE, ownership, superuser, or schema-migration authority.
