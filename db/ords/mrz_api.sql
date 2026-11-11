-- ============================================================================
-- ORDS module mrz.v1
--
--   POST /mrz/v1/parse
--   Content-Type: application/json
--   Body    : {"line1": "<44 chars>", "line2": "<44 chars>"}
--   200     : the JSON document returned by mrz_parser.parse_td3
--   400     : {"error": "..."} for missing or malformed input
--   500     : {"error": "Unexpected error."}
--
-- The endpoint stores nothing. It is public for demo purposes; protect it with
-- an ORDS privilege (OAuth2 or first-party auth) before any real use.
-- ============================================================================

-- If your schema is not REST-enabled yet, uncomment and run this block once:
-- begin
--   ords.enable_schema(
--     p_enabled             => true,
--     p_schema              => sys_context('userenv', 'current_schema'),
--     p_url_mapping_type    => 'BASE_PATH',
--     p_url_mapping_pattern => lower(sys_context('userenv', 'current_schema')),
--     p_auto_rest_auth      => false);
--   commit;
-- end;
-- /

begin
  ords.define_module(
    p_module_name    => 'mrz.v1',
    p_base_path      => '/mrz/v1/',
    p_items_per_page => 0,
    p_status         => 'PUBLISHED',
    p_comments       => 'Passport MRZ parsing and validation (ICAO Doc 9303, TD3)');

  ords.define_template(
    p_module_name => 'mrz.v1',
    p_pattern     => 'parse',
    p_comments    => 'Parse and validate a two-line TD3 MRZ');

  ords.define_handler(
    p_module_name   => 'mrz.v1',
    p_pattern       => 'parse',
    p_method        => 'POST',
    p_source_type   => ords.source_type_plsql,
    p_mimes_allowed => 'application/json',
    p_comments      => 'Body: {"line1": "...", "line2": "..."}',
    p_source        => q'~
declare
  l_error json_object_t := json_object_t();
begin
  if :line1 is null or :line2 is null then
    owa_util.status_line(400, 'Bad Request', false);
    owa_util.mime_header('application/json', true);
    l_error.put('error', 'Both line1 and line2 are required.');
    htp.prn(l_error.to_string);
  else
    owa_util.mime_header('application/json', true);
    htp.prn(mrz_parser.parse_td3(:line1, :line2));
  end if;
exception
  when others then
    if sqlcode = -20001 then
      owa_util.status_line(400, 'Bad Request', false);
      l_error.put('error', regexp_replace(sqlerrm, '^ORA-20001: '));
    else
      owa_util.status_line(500, 'Internal Server Error', false);
      l_error.put('error', 'Unexpected error.');
    end if;
    owa_util.mime_header('application/json', true);
    htp.prn(l_error.to_string);
end;~');

  commit;
end;
/
