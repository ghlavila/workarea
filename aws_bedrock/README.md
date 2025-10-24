# Code Generator - Template-Driven SQL & JSON Generation

Generate SQL queries and JSON configurations from CSV data using template files. No configuration files needed - the templates themselves define the patterns.

## Quick Start

### Home Insurance (Complex Pattern)

```bash
./code_generator_v3.py \
  --template-sql template.sql \
  --template-json template.json \
  --csv companies_groups.csv \
  --sql-output generated_home.sql \
  --json-output generated_home.json
```

**Result**: 18 companies × 8 variations = 144 columns

### Auto Insurance (Simple Pattern)

```bash
./code_generator_v3.py \
  --template-sql sample.sql \
  --template-json sample.json \
  --csv sample.csv \
  --sql-output generated_auto.sql \
  --json-output generated_auto.json
```

**Result**: 31 companies × 1 column = 31 columns

## How It Works

1. **Reads template SQL** to understand the pattern
   - Extracts example companies
   - Detects column variations (simple vs complex)
   - Identifies group column naming (`org_group` vs `grp`)

2. **Reads CSV file** to get the full company list
   - Auto-detects column names

3. **Generates SQL** by replacing template companies with CSV companies
   - Preserves all CTEs and structure
   - Expands column definitions for each company

4. **Generates JSON** (optional) by:
   - Parsing generated SQL to find all columns
   - Using template JSON to understand metadata pattern
   - Creating entry for each column with proper labels

## Files

- `code_generator_v3.py` - Main generator script (**RECOMMENDED**)
- `template.sql` / `template.json` - Home insurance templates
- `sample.sql` / `sample.json` - Auto insurance templates
- `companies_groups.csv` - Home insurance companies
- `sample.csv` - Auto insurance companies

## CSV Format

Templates auto-detect column names. Common patterns:

```csv
"company","org_group"          # Home insurance
"company","group"              # Auto insurance
"company","grp"                # Alternative
```

## Template Patterns

### Simple Pattern (1 column per company)

- One CASE statement per company
- Column name = company slug
- Example: `sample.sql`

### Complex Pattern (N columns per company)

- Multiple CASE statements per company
- Different conditions (age, coverage, etc.)
- Column name = company slug + suffix
- Example: `template.sql`

## Adding New Patterns

1. Create template SQL with 2-5 example companies
2. Create template JSON with matching examples
3. Run generator with your full CSV

The script automatically detects and replicates the pattern!
