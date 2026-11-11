-- ============================================================================
-- Tests for MRZ_PARSER
-- Run from the repository root:  SQL> @tests/test_mrz_parser.sql
--
-- Test data is the fictional specimen published in ICAO Doc 9303
-- (Utopia, "UTO"). Never use real passport data in this repository.
-- ============================================================================
set serveroutput on size unlimited
set define off

declare
  -- ICAO Doc 9303 specimen (fictional person, fictional state)
  c_line1 constant varchar2(44) := 'P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<';
  c_line2 constant varchar2(44) := 'L898902C36UTO7408122F1204159ZE184226B<<<<<10';
  -- Same line 2 with the birth date changed from 740812 to 740813:
  -- the birth date and composite check digits no longer match.
  c_bad2  constant varchar2(44) := 'L898902C36UTO7408132F1204159ZE184226B<<<<<10';

  g_pass pls_integer := 0;
  g_fail pls_integer := 0;
  l_obj  json_object_t;

  procedure check_eq (p_test in varchar2, p_expected in varchar2, p_actual in varchar2) is
  begin
    if p_expected = p_actual or (p_expected is null and p_actual is null) then
      g_pass := g_pass + 1;
      dbms_output.put_line('PASS  ' || p_test);
    else
      g_fail := g_fail + 1;
      dbms_output.put_line('FAIL  ' || p_test
        || '   expected [' || p_expected || ']  got [' || p_actual || ']');
    end if;
  end check_eq;

  procedure fail (p_test in varchar2, p_reason in varchar2) is
  begin
    g_fail := g_fail + 1;
    dbms_output.put_line('FAIL  ' || p_test || '   ' || p_reason);
  end fail;

  function bool_str (p_value in boolean) return varchar2 is
  begin
    return case when p_value then 'true' when not p_value then 'false' else 'null' end;
  end bool_str;

  function str (p_key in varchar2) return varchar2 is
  begin
    return l_obj.get_string(p_key);
  end str;

  function flag (p_key in varchar2) return varchar2 is
  begin
    return bool_str(l_obj.get_boolean(p_key));
  end flag;

  function chk (p_key in varchar2) return varchar2 is
  begin
    return bool_str(l_obj.get_object('checks').get_boolean(p_key));
  end chk;

  procedure test_check_digit (p_value in varchar2, p_expected in pls_integer) is
    l_test varchar2(100) := 'check_digit(''' || p_value || ''') = ' || p_expected;
  begin
    check_eq(l_test, to_char(p_expected), to_char(mrz_parser.check_digit(p_value)));
  exception
    when others then fail(l_test, sqlerrm);
  end test_check_digit;

begin
  dbms_output.put_line('--- check_digit ---');
  test_check_digit('L898902C3', 6);
  test_check_digit('740812', 2);
  test_check_digit('120415', 9);
  test_check_digit('ZE184226B<<<<<', 1);
  test_check_digit('<<<', 0);

  begin
    dbms_output.put_line('check_digit returned ' || mrz_parser.check_digit('L8#9'));
    fail('check_digit rejects invalid characters', 'no exception raised');
  exception
    when others then
      check_eq('check_digit rejects invalid characters', '-20001', to_char(sqlcode));
  end;

  dbms_output.put_line('--- parse_td3: ICAO specimen ---');
  begin
    l_obj := json_object_t.parse(mrz_parser.parse_td3(c_line1, c_line2));
    check_eq('document_type',   'P',          str('document_type'));
    check_eq('issuing_country', 'UTO',        str('issuing_country'));
    check_eq('surname',         'ERIKSSON',   str('surname'));
    check_eq('given_names',     'ANNA MARIA', str('given_names'));
    check_eq('document_number', 'L898902C3',  str('document_number'));
    check_eq('nationality',     'UTO',        str('nationality'));
    check_eq('birth_date',      '1974-08-12', str('birth_date'));
    check_eq('sex',             'F',          str('sex'));
    check_eq('expiry_date',     '2012-04-15', str('expiry_date'));
    check_eq('personal_number', 'ZE184226B',  str('personal_number'));
    check_eq('checks.document_number', 'true', chk('document_number'));
    check_eq('checks.birth_date',      'true', chk('birth_date'));
    check_eq('checks.expiry_date',     'true', chk('expiry_date'));
    check_eq('checks.personal_number', 'true', chk('personal_number'));
    check_eq('checks.composite',       'true', chk('composite'));
    check_eq('valid',   'true', flag('valid'));
    check_eq('expired', 'true', flag('expired'));
  exception
    when others then fail('parse_td3 on the ICAO specimen', sqlerrm);
  end;

  dbms_output.put_line('--- parse_td3: tampered birth date ---');
  begin
    l_obj := json_object_t.parse(mrz_parser.parse_td3(c_line1, c_bad2));
    check_eq('tampered: checks.document_number', 'true',  chk('document_number'));
    check_eq('tampered: checks.birth_date',      'false', chk('birth_date'));
    check_eq('tampered: checks.composite',       'false', chk('composite'));
    check_eq('tampered: valid',                  'false', flag('valid'));
  exception
    when others then fail('parse_td3 on tampered data', sqlerrm);
  end;

  dbms_output.put_line('--- parse_td3: input handling ---');
  begin
    l_obj := json_object_t.parse(
      mrz_parser.parse_td3('  ' || lower(c_line1) || '  ', ' ' || c_line2 || ' '));
    check_eq('trims and upper-cases input', 'true', flag('valid'));
  exception
    when others then fail('trims and upper-cases input', sqlerrm);
  end;

  begin
    l_obj := json_object_t.parse(mrz_parser.parse_td3(substr(c_line1, 1, 43), c_line2));
    fail('rejects a 43-character line', 'no exception raised');
  exception
    when others then
      check_eq('rejects a 43-character line', '-20001', to_char(sqlcode));
  end;

  begin
    l_obj := json_object_t.parse(
      mrz_parser.parse_td3(c_line1, replace(c_line2, 'UTO', 'U#O')));
    fail('rejects invalid characters', 'no exception raised');
  exception
    when others then
      check_eq('rejects invalid characters', '-20001', to_char(sqlcode));
  end;

  dbms_output.put_line('---');
  dbms_output.put_line(g_pass || ' passed, ' || g_fail || ' failed');
  if g_fail > 0 then
    raise_application_error(-20999, g_fail || ' test(s) failed');
  end if;
end;
/
