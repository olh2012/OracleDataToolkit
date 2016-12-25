set echo off;
set heading off;
set feedback off;
set newpage none;
set wrap off;
set termout off;
set termspool on;
set trimspool on;
set verify off;
set pagesize 0;
set pages 0;

spool &1

SELECT 'success' FROM dual;

spool off;
exit;
