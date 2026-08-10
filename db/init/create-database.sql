-- INFRA-02 — create ONLY the application database.
--
-- Flyway (prod profile) is the sole owner of ALL schema objects (tables, indexes, constraints) via
-- db/migration/V1__initial_schema.sql. This script MUST NOT create any table or duplicate the schema —
-- SQL Server simply cannot auto-create the database itself, so this one-shot fills that single gap.
--
-- Idempotent: safe to run on every startup. APP_DB_NAME is supplied by sqlcmd -v (see docker-compose db-init).
IF DB_ID(N'$(APP_DB_NAME)') IS NULL
BEGIN
    PRINT 'INFRA-02: creating database [' + N'$(APP_DB_NAME)' + ']';
    EXEC('CREATE DATABASE [' + N'$(APP_DB_NAME)' + ']');
END
ELSE
    PRINT 'INFRA-02: database [' + N'$(APP_DB_NAME)' + '] already exists — preserved';
GO
