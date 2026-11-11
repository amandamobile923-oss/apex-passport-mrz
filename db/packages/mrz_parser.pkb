create or replace package body mrz_parser
as
  -- ===========================================================================
  -- Author: Malik Aboud
  -- Implement the functions below against the contract in mrz_parser.pks,
  -- then run @tests/test_mrz_parser.sql until every test passes.
  -- ===========================================================================

  function check_digit (p_value in varchar2) return pls_integer
  is
  begin
    -- TODO: implement
    raise_application_error(-20000, 'mrz_parser.check_digit is not implemented yet');
  end check_digit;

  function parse_td3 (
    p_line1 in varchar2,
    p_line2 in varchar2
  ) return clob
  is
  begin
    -- TODO: implement
    raise_application_error(-20000, 'mrz_parser.parse_td3 is not implemented yet');
  end parse_td3;

end mrz_parser;
/
