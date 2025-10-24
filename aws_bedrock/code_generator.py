#!/usr/bin/env python3
"""
Template-driven SQL and JSON code generator.
Uses template files to understand patterns, CSV to get company list.

CSV must have 'company' and 'org_group' columns.

Usage:
  ./code_generator.py --template-sql template.sql --csv companies.csv --sql-output output.sql
  ./code_generator.py --template-sql template.sql --template-json template.json --csv companies.csv --sql-output output.sql --json-output output.json
"""

import argparse
import csv
import json
import re
from pathlib import Path
from typing import List, Dict


def slugify(text):
    """Convert text to snake_case for SQL column names."""
    text = text.replace('&', '')
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '_', text)
    return text.lower().strip('_')


def load_companies(csv_path: str):
    """Load companies from CSV. Expects 'company' and 'org_group' columns."""
    companies = []
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            companies.append({
                'company': row['company'],
                'group': row['org_group'],
                'slug': slugify(row['company'])
            })
    return companies


def extract_template_companies(sql_content: str) -> List[Dict]:
    """Extract example companies from template SQL."""
    companies = []

    # Find companies_groups CTE
    cte_pattern = r"companies_groups as \((.*?)\)"
    match = re.search(cte_pattern, sql_content, re.DOTALL | re.IGNORECASE)

    if not match:
        return companies

    cte_content = match.group(1)

    # Extract company entries - pattern: 'Company Name' as company, 'Group Name' as group_col
    # or: 'Company Name', 'Group Name'
    company_pattern = r"select\s+'([^']+)'(?:\s+as\s+company)?(?:,\s*|\s+,\s*)'([^']+)'"

    for match in re.finditer(company_pattern, cte_content, re.IGNORECASE):
        company_name = match.group(1)
        group_name = match.group(2)
        companies.append({
            'company': company_name,
            'group': group_name,
            'slug': slugify(company_name)
        })

    return companies


def detect_group_column_name(sql_content: str) -> str:
    """Detect the group column name from template SQL."""
    # Look for pattern: 'value' as column_name in first select of companies_groups
    cte_pattern = r"companies_groups as \((.*?)\)"
    match = re.search(cte_pattern, sql_content, re.DOTALL | re.IGNORECASE)

    if match:
        first_line = match.group(1).strip().split('\n')[0]
        # Pattern: select 'value' as company, 'value' as group_column_name
        col_match = re.search(r"as\s+company[,\s]+.*?as\s+(\w+)", first_line, re.IGNORECASE)
        if col_match:
            return col_match.group(1)

    return "org_group"  # default


def generate_companies_cte(companies: List[Dict], group_col_name: str) -> str:
    """Generate companies_groups CTE."""
    lines = ["companies_groups as ("]

    for i, company in enumerate(companies):
        if i == 0:
            line = f"    select '{company['company']}' as company, '{company['group']}' as {group_col_name}"
        else:
            line = f"    select '{company['company']}', '{company['group']}'"

        if i < len(companies) - 1:
            line += " union all"

        lines.append(line)

    lines.append(")")
    return "\n".join(lines)


def extract_column_pattern(sql_content: str, template_companies: List[Dict]) -> List[Dict]:
    """Extract column generation pattern from template SQL."""
    if not template_companies:
        return []

    # Use first template company to detect pattern
    first_company = template_companies[0]

    # Find fi CTE
    fi_pattern = r"fi as \((.*?)\)(?:,|\s*output)"
    match = re.search(fi_pattern, sql_content, re.DOTALL | re.IGNORECASE)

    if not match:
        return []

    fi_content = match.group(1)

    # Find all CASE statements for the first company
    variations = []

    # Pattern: MAX(CASE WHEN ... company = 'Company Name' ... THEN ... END) AS column_name
    case_pattern = rf"MAX\(CASE\s+WHEN\s+(.*?d\.company\s*=\s*'{re.escape(first_company['company'])}'.*?)\s+THEN\s+d\.(\w+)\s+END\)\s+AS\s+(\w+)"

    for match in re.finditer(case_pattern, fi_content, re.IGNORECASE | re.DOTALL):
        full_conditions = match.group(1).strip()
        value_col = match.group(2)
        column_name = match.group(3)

        # Parse conditions (exclude company condition)
        conditions = {}

        # Extract AND conditions like: d.dwellingage = '0', but skip d.company
        cond_pattern = r"d\.(\w+)\s*=\s*'([^']+)'"
        for cond_match in re.finditer(cond_pattern, full_conditions):
            field_name = cond_match.group(1)
            if field_name != 'company':  # Skip company condition
                conditions[field_name] = cond_match.group(2)

        # Extract suffix - find the part after company-related prefix
        # The column name pattern is: company_slug_suffix or just company_slug
        # We need to find where the suffix starts by matching conditions
        suffix = ''

        # Build expected suffix from conditions
        if conditions:
            # Has conditions - build suffix from them
            suffix_parts = []
            for field, value in sorted(conditions.items()):
                # Be specific about field names to avoid ambiguity
                if field == 'dwellingage':
                    suffix_parts.append(f"age{value}")
                elif field in ['dwellingcoverageamount', 'coverageamount', 'coverage']:
                    # Convert 200000 -> 200k
                    try:
                        amount_k = int(value) // 1000
                        suffix_parts.append(f"cov{amount_k}k")
                    except:
                        suffix_parts.append(f"{field}{value}")
                else:
                    # Generic fallback
                    suffix_parts.append(f"{field}{value}")

            if suffix_parts:
                suffix = '_'.join(suffix_parts)

        # If we couldn't build suffix from conditions, try to extract from column name
        if not suffix:
            # Try to find a recognizable pattern at the end
            # Common patterns: age0_cov200k, age30_cov750k, etc.
            pattern_match = re.search(r'_(age\d+_cov\d+k)$', column_name)
            if pattern_match:
                suffix = pattern_match.group(1)

        variations.append({
            'suffix': suffix,
            'conditions': conditions,
            'value_column': value_col,
            'column_name': column_name
        })

    return variations


def replace_companies_in_sql(sql_content: str, template_companies: List[Dict],
                             new_companies: List[Dict], group_col_name: str) -> str:
    """Replace template companies with new companies in SQL."""

    # Replace companies_groups CTE
    cte_pattern = r"companies_groups as \(.*?\)\s*[,\n]"
    new_cte = generate_companies_cte(new_companies, group_col_name) + ",\n"
    sql_content = re.sub(cte_pattern, new_cte, sql_content, flags=re.DOTALL)

    # Extract column pattern from template
    column_variations = extract_column_pattern(sql_content, template_companies)

    if not column_variations:
        # Simple pattern - one column per company
        return replace_simple_pattern(sql_content, template_companies, new_companies)

    # Complex pattern - multiple columns per company
    return replace_complex_pattern(sql_content, template_companies, new_companies, column_variations)


def replace_simple_pattern(sql_content: str, template_companies: List[Dict],
                           new_companies: List[Dict]) -> str:
    """Replace companies with simple pattern (one column per company)."""

    # Find fi CTE section with company columns
    fi_pattern = r"(fi as \([\s\S]*?)(MAX\(CASE.*?\)(?:,|\s)*)([\s\S]*?FROM)"
    match = re.search(fi_pattern, sql_content, re.DOTALL)

    if not match:
        return sql_content

    prefix = match.group(1)
    suffix = match.group(3)

    # Get first template company's pattern
    first_template = template_companies[0]
    case_pattern = rf"MAX\(CASE\s+WHEN\s+d\.company\s*=\s*'{re.escape(first_template['company'])}'.*?AS\s+\w+"
    template_match = re.search(case_pattern, sql_content, re.DOTALL | re.IGNORECASE)

    if not template_match:
        return sql_content

    template_line = template_match.group(0)

    # Extract value column
    value_col_match = re.search(r"THEN\s+d\.(\w+)", template_line)
    value_col = value_col_match.group(1) if value_col_match else "cps"

    # Generate new lines
    new_lines = []
    for i, company in enumerate(new_companies):
        comma = "," if i < len(new_companies) - 1 else ""
        line = f"      MAX(CASE WHEN d.company = '{company['company']}' THEN d.{value_col} END) AS {company['slug']}{comma}"
        new_lines.append(line)

    new_section = "\n".join(new_lines) + "\n  "

    # Replace entire fi CTE content
    fi_full_pattern = r"fi as \(([\s\S]*?)\s*FROM"

    def replacer(m):
        # Keep everything up to the company columns
        content = m.group(1)
        # Find where company columns start
        select_match = re.search(r"SELECT([\s\S]*?)(MAX\(CASE)", content, re.IGNORECASE)
        if select_match:
            return f"fi as (\nSELECT{select_match.group(1)}{new_section}FROM"
        return m.group(0)

    sql_content = re.sub(fi_full_pattern, replacer, sql_content, flags=re.DOTALL)

    # Replace output CTE
    return replace_output_columns(sql_content, template_companies, new_companies)


def replace_complex_pattern(sql_content: str, template_companies: List[Dict],
                            new_companies: List[Dict], column_variations: List[Dict]) -> str:
    """Replace companies with complex pattern (multiple columns per company)."""

    # Build new fi CTE columns
    fi_lines = []
    for comp_idx, company in enumerate(new_companies):
        # Add comment
        fi_lines.append(f"      -- {company['company']}")

        for var_idx, variation in enumerate(column_variations):
            # Build column name - always use suffix if present
            if variation['suffix']:
                col_name = f"{company['slug']}_{variation['suffix']}"
            else:
                # No suffix in pattern
                col_name = company['slug']

            # Build conditions
            conditions = [f"d.company = '{company['company']}'"]
            for cond_field, cond_value in variation['conditions'].items():
                conditions.append(f"d.{cond_field} = '{cond_value}'")

            condition_str = " AND ".join(conditions)

            # Determine if comma needed
            is_last = (comp_idx == len(new_companies) - 1 and var_idx == len(column_variations) - 1)
            comma = "" if is_last else ","

            line = f"      MAX(CASE WHEN {condition_str} THEN d.{variation['value_column']} END) AS {col_name}{comma}"
            fi_lines.append(line)

    new_fi_columns = "\n".join(fi_lines)

    # Replace fi CTE columns
    # Find the section between primary columns and FROM
    fi_pattern = r"(fi as \(\s*SELECT\s*.*?(?:d\.zipcode|d\.zip)(?:\s*,\s*d\.\w+)*,)(.*?)(FROM)"

    def fi_replacer(m):
        return f"{m.group(1)}\n{new_fi_columns}\n  {m.group(3)}"

    sql_content = re.sub(fi_pattern, fi_replacer, sql_content, flags=re.DOTALL | re.IGNORECASE)

    # Replace output CTE
    return replace_output_columns(sql_content, template_companies, new_companies, column_variations)


def replace_output_columns(sql_content: str, template_companies: List[Dict],
                           new_companies: List[Dict], column_variations: List[Dict] = None) -> str:
    """Replace output CTE column list."""

    output_lines = []

    if column_variations:
        # Complex pattern
        for comp_idx, company in enumerate(new_companies):
            output_lines.append(f"      -- {company['company']}")

            for var_idx, variation in enumerate(column_variations):
                if variation['suffix']:
                    col_name = f"{company['slug']}_{variation['suffix']}"
                else:
                    col_name = company['slug']

                is_last = (comp_idx == len(new_companies) - 1 and var_idx == len(column_variations) - 1)
                comma = "" if is_last else ","

                output_lines.append(f"      {col_name}{comma}")
    else:
        # Simple pattern
        for i, company in enumerate(new_companies):
            comma = "," if i < len(new_companies) - 1 else ""
            output_lines.append(f"      {company['slug']}{comma}")

    new_output_columns = "\n".join(output_lines)

    # Replace output CTE column section
    # Pattern: after primary columns (mpid, zip, etc.) up to "from aiq"
    output_pattern = r"(output as \(\s*select\s+.*?(?:mpid|b\.zipcode)(?:\s*,\s*\w+(?:\.\w+)?)*,)(.*?)(from aiq)"

    def output_replacer(m):
        return f"{m.group(1)}\n{new_output_columns}\n    {m.group(3)}"

    sql_content = re.sub(output_pattern, output_replacer, sql_content, flags=re.DOTALL | re.IGNORECASE)

    return sql_content


def extract_columns_from_sql(sql_content: str) -> List[str]:
    """Extract all company column names from generated SQL."""
    columns = []

    # Find fi CTE which has all the column definitions
    fi_pattern = r"fi as \((.*?)\s*FROM"
    match = re.search(fi_pattern, sql_content, re.DOTALL | re.IGNORECASE)

    if not match:
        return columns

    fi_content = match.group(1)

    # Extract column names from AS clauses
    # Pattern: AS column_name,  or AS column_name\n
    col_pattern = r"\s+AS\s+([a-z_][a-z0-9_]*)\s*,?"

    for match in re.finditer(col_pattern, fi_content, re.IGNORECASE):
        col_name = match.group(1)
        # Skip system columns
        if col_name not in ['zip', 'zipcode', 'mpid', 'gender', 'age', 'marital_status']:
            columns.append(col_name)

    return columns


def generate_json(template_json_path: str, sql_content: str, companies: List[Dict]) -> str:
    """Generate JSON configuration based on template and generated SQL."""

    # Load template JSON
    with open(template_json_path, 'r') as f:
        template = json.load(f)

    # Extract columns from SQL
    columns = extract_columns_from_sql(sql_content)

    # Get template entry to understand pattern
    template_entries = [s for s in template['selects'] if s.get('type') == 'select-map']
    if not template_entries:
        return json.dumps(template, indent=2)

    template_entry = template_entries[0]

    # Build new selects
    selects = [{"id": "ALL", "label": "ALL", "type": "select-all"}]

    # Create entry for each column
    for col_name in columns:
        # Find matching company
        matching_company = None
        for company in companies:
            if col_name.startswith(company['slug']):
                matching_company = company
                break

        if not matching_company:
            continue

        # Build label
        suffix = col_name.replace(matching_company['slug'], '').lstrip('_')

        if suffix:
            # Try to parse suffix for meaningful label
            label = f"{matching_company['company']} [{matching_company['group']}]"
            # Add suffix details if parseable
            if 'age' in suffix and 'cov' in suffix:
                # Parse home insurance pattern
                age_match = re.search(r'age(\d+)', suffix)
                cov_match = re.search(r'cov(\d+)k', suffix)
                if age_match and cov_match:
                    age = age_match.group(1)
                    cov = cov_match.group(1)
                    age_label = "New Home (0yr)" if age == "0" else f"Older Home ({age}yr)"
                    label = f"{label} - {age_label}, ${cov}k Coverage"
        else:
            label = f"{matching_company['company']} [{matching_company['group']}]"

        entry = {
            "id": f"{template['id']}_{col_name}",
            "label": label,
            "description": template_entry['description'],
            "type": template_entry['type'],
            "tags": template_entry['tags'],
            "count-nulls": template_entry['count-nulls'],
            "field-name": col_name
        }

        selects.append(entry)

    # Build final JSON
    result = {
        "id": template['id'],
        "label": template['label'],
        "description": template['description'],
        "tags": template['tags'],
        "node": template['node'],
        "selects": selects
    }

    return json.dumps(result, indent=2)


def main():
    parser = argparse.ArgumentParser(
        description="Generate SQL and JSON from templates and CSV"
    )
    parser.add_argument(
        "--template-sql",
        type=str,
        required=True,
        help="Path to template SQL file"
    )
    parser.add_argument(
        "--template-json",
        type=str,
        default=None,
        help="Path to template JSON file (optional)"
    )
    parser.add_argument(
        "--csv",
        type=str,
        required=True,
        help="Path to CSV file with company data"
    )
    parser.add_argument(
        "--sql-output",
        type=str,
        required=True,
        help="Path for output SQL file"
    )
    parser.add_argument(
        "--json-output",
        type=str,
        default=None,
        help="Path for output JSON file (optional)"
    )

    args = parser.parse_args()

    # Load template SQL
    print(f"Loading template SQL from {args.template_sql}...")
    template_sql = Path(args.template_sql).read_text(encoding="utf-8")

    # Extract template companies
    template_companies = extract_template_companies(template_sql)
    print(f"Found {len(template_companies)} example companies in template")

    # Detect group column name
    group_col_name = detect_group_column_name(template_sql)
    print(f"Detected group column name: {group_col_name}")

    # Load CSV companies
    print(f"Loading companies from {args.csv}...")
    companies = load_companies(args.csv)
    print(f"Found {len(companies)} companies in CSV")

    # Generate SQL
    print("Generating SQL...")
    generated_sql = replace_companies_in_sql(template_sql, template_companies, companies, group_col_name)

    # Write SQL
    sql_path = Path(args.sql_output)
    sql_path.write_text(generated_sql, encoding="utf-8")
    print(f"Wrote SQL to {sql_path}")

    # Generate JSON if requested
    if args.json_output and args.template_json:
        print("Generating JSON...")
        generated_json = generate_json(args.template_json, generated_sql, companies)

        json_path = Path(args.json_output)
        json_path.write_text(generated_json, encoding="utf-8")
        print(f"Wrote JSON to {json_path}")

    print("Done!")


if __name__ == "__main__":
    main()
