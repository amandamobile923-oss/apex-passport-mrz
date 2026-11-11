# Building the APEX demo page

A single page where an agent pastes the two MRZ lines, presses **Parse**, and sees the extracted data and the result of every check digit.

## 1. Application

Create an application (for example **MRZ Demo**) in the schema where `MRZ_PARSER` is installed.

To show your name on every page (and in every screenshot), open the Global Page (page 0), add a **Static Content** region in the **Footer** position with the text:

```
Built by Malik Aboud · Oracle ACE Apprentice
```

## 2. Page items

| Item | Type | Settings |
|---|---|---|
| `P1_LINE1` | Text Field | Label "MRZ line 1", maximum length 44, monospace font |
| `P1_LINE2` | Text Field | Label "MRZ line 2", maximum length 44, monospace font |
| `P1_RESULT` | Hidden | Holds the JSON returned by the parser |

For the monospace font, add `style="font-family: monospace"` to each text field's **Custom Attributes**.

## 3. Button and process

Add a button **PARSE** (action: Submit Page) and a page process that runs on it:

```sql
begin
  :P1_RESULT := mrz_parser.parse_td3(:P1_LINE1, :P1_LINE2);
exception
  when others then
    if sqlcode = -20001 then
      :P1_RESULT := null;
      apex_error.add_error(
        p_message          => regexp_replace(sqlerrm, '^ORA-20001: '),
        p_display_location => apex_error.c_inline_in_notification);
    else
      raise;
    end if;
end;
```

## 4. Result regions

Both regions use the server-side condition **Item is NOT NULL: `P1_RESULT`**.

**Passport data** (Classic Report, template *Value Attribute Pairs - Row*):

```sql
select jt.*
  from json_table(:P1_RESULT, '$'
         columns (
           surname         varchar2(100) path '$.surname',
           given_names     varchar2(100) path '$.given_names',
           document_number varchar2(20)  path '$.document_number',
           nationality     varchar2(3)   path '$.nationality',
           birth_date      varchar2(10)  path '$.birth_date',
           sex             varchar2(1)   path '$.sex',
           expiry_date     varchar2(10)  path '$.expiry_date',
           personal_number varchar2(20)  path '$.personal_number',
           expired         varchar2(5)   path '$.expired')) jt
```

**Check digits** (Classic Report):

```sql
select check_name,
       case passed when 'true' then 'Passed' else 'Failed' end as result
  from json_table(:P1_RESULT, '$.checks'
         columns (
           "Document number" varchar2(5) path '$.document_number',
           "Birth date"      varchar2(5) path '$.birth_date',
           "Expiry date"     varchar2(5) path '$.expiry_date',
           "Personal number" varchar2(5) path '$.personal_number',
           "Composite"       varchar2(5) path '$.composite'))
unpivot (passed for check_name in (
  "Document number", "Birth date", "Expiry date", "Personal number", "Composite"))
```

## 5. Test it

Valid (ICAO specimen):

```
P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
L898902C36UTO7408122F1204159ZE184226B<<<<<10
```

Tampered (birth date changed, so two checks fail):

```
P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<
L898902C36UTO7408132F1204159ZE184226B<<<<<10
```

## 6. Export into the repository

From **App Builder > Export**:

1. Export in the original (SQL) format and save it as `apex/f<app_id>.sql`. This is the installable file.
2. Export again in the readable (YAML) format and put the files in `apex/readable/`. This version is for reviewing the app on GitHub, not for importing.

Save screenshots of the valid and tampered runs in `docs/screenshots/` using the file names referenced in the README.
