-- ===========================================
-- DysonNetwork Database Initialization
-- Creates one database per microservice
-- ===========================================
-- This script runs automatically when PostgreSQL
-- container starts for the first time.
-- ===========================================

-- Ring: Authentication Core
SELECT 'CREATE DATABASE ring'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ring')\gexec

-- Pass: OAuth / Identity
SELECT 'CREATE DATABASE pass'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'pass')\gexec

-- Drive: File Storage
SELECT 'CREATE DATABASE drive'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'drive')\gexec

-- Sphere: Social / Timeline
SELECT 'CREATE DATABASE sphere'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'sphere')\gexec

-- Develop: Developer / Git Integration
SELECT 'CREATE DATABASE develop'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'develop')\gexec

-- Insight: Analytics / Monitoring
SELECT 'CREATE DATABASE insight'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'insight')\gexec

-- Notifications: Push / Alerting
SELECT 'CREATE DATABASE notifications'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'notifications')\gexec

-- Search: Full-text Search Index
SELECT 'CREATE DATABASE search'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'search')\gexec
