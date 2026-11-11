create or replace package mrz_parser
  authid definer
as
  /*
  ==============================================================================
  MRZ_PARSER: parse and validate passport MRZ data (ICAO Doc 9303, TD3 format)
  Author : Malik Aboud
  ==============================================================================

  This specification is the CONTRACT used by the ORDS module, the APEX demo
  and the test script. Change it freely, but update tests/ and db/ords/ to
  match.

  parse_td3 returns a JSON document of this shape (ICAO specimen shown):

  {
    "document_type"   : "P",
    "issuing_country" : "UTO",
    "surname"         : "ERIKSSON",
    "given_names"     : "ANNA MARIA",
    "document_number" : "L898902C3",
    "nationality"     : "UTO",
    "birth_date"      : "1974-08-12",
    "sex"             : "F",
    "expiry_date"     : "2012-04-15",
    "personal_number" : "ZE184226B",
    "checks" : {
      "document_number" : true,
      "birth_date"      : true,
      "expiry_date"     : true,
      "personal_number" : true,
      "composite"       : true
    },
    "valid"   : true,
    "expired" : true
  }

  Rules:
  - Both lines are trimmed and upper-cased before validation.
  - Each line must be exactly 44 characters from [0-9A-Z<]; otherwise
    ORA-20001 is raised with a readable message.
  - Filler characters '<' become spaces in names and are removed from
    document and personal numbers.
  - Dates are returned as YYYY-MM-DD. Birth date: YY greater than the current
    two-digit year means 19YY, otherwise 20YY. Expiry date: always 20YY.
    A YYMMDD value that is not a real calendar date is returned as null.
  - Sex: 'M', 'F', or 'X' when the MRZ holds '<'.
  - An empty personal number is returned as null; its check digit may be
    '<', which counts as 0.
  - A failed check digit is NOT an error: it is reported as false in
    "checks". "valid" is true only when every check passes.
  - "expired" compares expiry_date with the current date.
  */

  -- ICAO 9303 check digit for p_value (0-9).
  -- Weights 7, 3, 1 repeating; digits keep their value, A-Z = 10-35, '<' = 0.
  -- Raises ORA-20001 if p_value contains any other character.
  function check_digit (p_value in varchar2) return pls_integer;

  -- Parses a TD3 (passport) MRZ and returns the JSON document described above.
  function parse_td3 (
    p_line1 in varchar2,
    p_line2 in varchar2
  ) return clob;

end mrz_parser;
/
