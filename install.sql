-- ============================================================================
-- apex-passport-mrz : install
-- Run as the target schema from the repository root, in SQLcl or SQL*Plus:
--   SQL> @install.sql
-- ============================================================================
set define off
set serveroutput on

prompt Installing package MRZ_PARSER ...
@@db/packages/mrz_parser.pks
show errors package mrz_parser
@@db/packages/mrz_parser.pkb
show errors package body mrz_parser

prompt Publishing ORDS module mrz.v1 ...
@@db/ords/mrz_api.sql

prompt Installation complete. Run @tests/test_mrz_parser.sql to verify.
