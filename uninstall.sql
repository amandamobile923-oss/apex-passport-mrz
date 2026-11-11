-- ============================================================================
-- apex-passport-mrz : uninstall
-- Removes the ORDS module and the MRZ_PARSER package.
-- ============================================================================
begin
  ords.delete_module(p_module_name => 'mrz.v1');
  commit;
exception
  when others then
    dbms_output.put_line('ORDS module not removed: ' || sqlerrm);
end;
/

drop package mrz_parser;
