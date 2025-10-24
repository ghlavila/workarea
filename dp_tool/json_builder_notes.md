# JSON Builder Tool - Design Notes

## Project Overview

**Purpose**: Build a tool that generates complex JSON table definitions for the query engine (described in dp_tool/README.md) from simple CSV input files, using a configuration-driven approach.

**Problem Statement**: Manual JSON creation is error-prone and requires thousands of lines of code. Current `make_json.py` is stateful, hardcoded, and difficult to maintain.

**Solution**: A CSV-driven JSON builder with:
- Simple one-row-per-field CSV input
- Reusable configuration file for common patterns (bucket strategies, value mappings)
- JSON template for table-level metadata
- Extensible architecture for future enhancements

---

## Design Evolution

### Initial Concept
Started with idea of transforming CSV to JSON (like current `make_json.py`).

### Key Insight
The real need is **intelligent JSON generation** from data dictionary information:
- Input: Field metadata (name, type, cardinality, sample values)
- Processing: Apply heuristics and rules to determine optimal select configurations
- Output: Fully-formed JSON for the query engine

### Final Direction
Minimal viable design with extensibility:
- CSV provides field-level decisions
- YAML config provides reusable strategies and mappings
- JSON template provides table-level structure
- Modular handler architecture allows easy additions

---

## Architecture

### File Structure
```
json_builder/
├── builder.py              # Main orchestrator script
├── config_loader.py        # Config file loader/validator
├── handlers/
│   ├── __init__.py
│   ├── base.py            # Base handler interface
│   ├── select_map.py      # Handles select-map generation
│   ├── select_list.py     # Handles select-list generation
│   └── select_all.py      # Handles select-all generation
├── strategies/
│   ├── __init__.py
│   ├── bucket_strategy.py # Processes bucket strategies from config
│   └── value_map.py       # Processes value mappings from config
└── validators/
    ├── __init__.py
    └── csv_validator.py   # CSV input validation
```

### Key Design Principles

1. **Separation of Concerns**
   - CSV = field-specific decisions
   - Config = reusable patterns and strategies
   - Template = table-level metadata

2. **Handler Pattern**
   - Each select type has its own handler
   - Easy to add new select types (e.g., select-geolist in future)
   - Handlers validate their own inputs

3. **Strategy Pattern**
   - Bucket strategies defined in config, not code
   - Value mappings reusable across datasets
   - No hardcoded business logic

4. **Template-Based Output**
   - User controls exact table structure
   - Script only populates `selects` array
   - Preserves tags, metadata, custom fields

---

## Input Files

### 1. JSON Template: `table_template.json`

User-provided file with complete table structure except `selects`:

```json
{
    "id": "demo_table",
    "label": "Demo Table",
    "description": "Example demonstration table",
    "tags": {
        "default_royalty": ["GENDER", "AGE"],
        "category": "consumer"
    },
    "node": 0,
    "parent": null,
    "selects": []
}
```

**Key Points**:
- Script only touches the `selects` array
- All other fields preserved exactly as provided
- Allows full control over table-level metadata

---

### 2. Configuration File: `builder_config.yaml`

Reusable strategies and mappings:

```yaml
# Version tracking for config file format
version: "1.0"

# Bucket strategies - the core reusable component
bucket_strategies:
  age_standard:
    data_type: integer
    ranges:
      - [0, 17, "Under 18"]
      - [18, 24, "18-24"]
      - [25, 34, "25-34"]
      - [35, 44, "35-44"]
      - [45, 54, "45-54"]
      - [55, 64, "55-64"]
      - [65, 999, "65+"]
    last_bucket_operator: "Ge"  # Last bucket uses >= instead of Between

  income_standard:
    data_type: integer
    ranges:
      - [0, 25000, "$0-$25,000"]
      - [25001, 50000, "$25,001-$50,000"]
      - [50001, 75000, "$50,001-$75,000"]
      - [75001, 100000, "$75,001-$100,000"]
      - [100001, 9999999, "$100,001+"]
    last_bucket_operator: "Gt"  # Last bucket uses > instead of Between

  credit_score_standard:
    data_type: integer
    ranges:
      - [300, 579, "Poor (300-579)"]
      - [580, 669, "Fair (580-669)"]
      - [670, 739, "Good (670-739)"]
      - [740, 799, "Very Good (740-799)"]
      - [800, 850, "Excellent (800-850)"]
    last_bucket_operator: "Between"

# Common value mappings
value_maps:
  gender_standard:
    M: "Male"
    F: "Female"
    U: "Unknown"

  yes_no:
    "true": "Yes"
    "false": "No"
    "1": "Yes"
    "0": "No"

  marital_status:
    S: "Single"
    M: "Married"
    D: "Divorced"
    W: "Widowed"

# Data type to comparison key mapping
data_type_mappings:
  string: "compare-string"
  integer: "compare-integer"
  float: "compare-float"
```

**Extensibility**: Add new strategies/mappings without code changes.

---

### 3. Field Definitions CSV: `field_definitions.csv`

One row per field, minimal required columns:

```csv
field_name,select_id,select_label,select_type,data_type,value_map,high_cardinality,top_n,other_label,bucket_strategy,custom_ranges,comparison,skip
GENDER,GENDER,Gender,select-map,string,gender_standard,false,,,,,false
AGE,AGE,Age,select-list,integer,,false,,age_standard,,,false
INCOME,INCOME,Annual Income,select-list,integer,,false,,income_standard,,,false
STATE,STATE,State,select-map,string,,false,,,,,false
ZIP,ZIP,Zip Code,select-map,string,,true,,,,,false
LAST_NAME,LAST_NAME,Last Name,select-map,string,,false,100,Other Names,,,,false
CUSTOM_BUCKET,CUSTOM_BUCKET,Custom Buckets,select-list,integer,,false,,,,"[[0,100],[101,200],[201,500]]",,false
M_ZIP5,M_ZIP5,Starts with 274,select-list,string,,,,,,"StartsWith:274",false
ID,,,,,,,,,,,,true
```

#### Column Definitions

| Column | Required? | Description |
|--------|-----------|-------------|
| `field_name` | Yes | Exact field name from source data |
| `select_id` | Conditional | ID for the select (defaults to field_name if blank) |
| `select_label` | Conditional | Human-readable label for UI |
| `select_type` | Conditional | `select-map` or `select-list` |
| `data_type` | Conditional | `string`, `integer`, `float` |
| `value_map` | Optional | Name from config `value_maps`, or `MAP_ALL` (default), or inline JSON `{"M":"Male"}` |
| `high_cardinality` | Optional | `true` for high-cardinality select-maps |
| `top_n` | Optional | Integer - keep only top N most frequent values |
| `other_label` | Optional | Label for "other" bucket when using `top_n` |
| `bucket_strategy` | Optional | Name from config `bucket_strategies` |
| `custom_ranges` | Optional | JSON array `[[min,max,label],...]` for custom buckets |
| `comparison` | Optional | Simple comparison for single-item select-lists: `Eq:value`, `Gt:100`, `StartsWith:274` |
| `skip` | Optional | `true` to completely skip this field |

**Note**: "Conditional" means required unless `skip=true`.

---

## Output Example

Given the inputs above, generates:

```json
{
    "id": "demo_table",
    "label": "Demo Table",
    "description": "Example demonstration table",
    "tags": {
        "default_royalty": ["GENDER", "AGE"],
        "category": "consumer"
    },
    "node": 0,
    "parent": null,
    "selects": [
        {
            "id": "ALL",
            "label": "ALL",
            "type": "select-all"
        },
        {
            "id": "GENDER",
            "label": "Gender",
            "type": "select-map",
            "field-name": "GENDER",
            "count-nulls": false,
            "skip-unmapped": true,
            "value-label-map": {
                "M": "Male",
                "F": "Female",
                "U": "Unknown"
            }
        },
        {
            "id": "AGE",
            "label": "Age",
            "type": "select-list",
            "select-list": [
                {"label": "Under 18", "field-name": "AGE", "compare-integer": {"Between": [0, 17]}},
                {"label": "18-24", "field-name": "AGE", "compare-integer": {"Between": [18, 24]}},
                {"label": "25-34", "field-name": "AGE", "compare-integer": {"Between": [25, 34]}},
                {"label": "35-44", "field-name": "AGE", "compare-integer": {"Between": [35, 44]}},
                {"label": "45-54", "field-name": "AGE", "compare-integer": {"Between": [45, 54]}},
                {"label": "55-64", "field-name": "AGE", "compare-integer": {"Between": [55, 64]}},
                {"label": "65+", "field-name": "AGE", "compare-integer": {"Ge": 65}}
            ]
        },
        {
            "id": "ZIP",
            "label": "Zip Code",
            "type": "select-map",
            "field-name": "ZIP",
            "high-cardinality": true
        },
        {
            "id": "LAST_NAME",
            "label": "Last Name",
            "type": "select-map",
            "field-name": "LAST_NAME",
            "keep-top-values": 100,
            "other-label": "Other Names"
        },
        {
            "id": "M_ZIP5",
            "label": "Starts with 274",
            "type": "select-list",
            "select-list": [
                {"label": "Starts with 274", "field-name": "M_ZIP5", "compare-string": {"StartsWith": "274"}}
            ]
        }
    ]
}
```

---

## Code Architecture (Pseudocode)

### Base Handler Interface

```python
# handlers/base.py
class SelectHandler:
    """Base class for all select type handlers"""

    def __init__(self, config):
        self.config = config

    def can_handle(self, row):
        """Check if this handler can process this row"""
        raise NotImplementedError

    def build(self, row):
        """Build the select JSON object"""
        raise NotImplementedError

    def validate(self, row):
        """Validate row has required fields for this type"""
        return True, []  # (is_valid, error_messages)
```

### Select-Map Handler

```python
# handlers/select_map.py
class SelectMapHandler(SelectHandler):

    def can_handle(self, row):
        return row['select_type'] == 'select-map'

    def validate(self, row):
        errors = []
        if not row.get('field_name'):
            errors.append("field_name is required")
        if not row.get('select_label'):
            errors.append("select_label is required")
        return len(errors) == 0, errors

    def build(self, row):
        select = {
            "id": row['select_id'] or row['field_name'],
            "label": row['select_label'],
            "type": "select-map",
            "field-name": row['field_name']
        }

        # Add high-cardinality flag if present
        if row.get('high_cardinality') == 'true':
            select['high-cardinality'] = True

        # Add top-N logic if present
        if row.get('top_n'):
            select['keep-top-values'] = int(row['top_n'])
            if row.get('other_label'):
                select['other-label'] = row['other_label']

        # Handle value mapping
        if row.get('value_map') and row['value_map'] != 'MAP_ALL':
            value_map = self._get_value_map(row['value_map'])
            if value_map:
                select['value-label-map'] = value_map
                select['skip-unmapped'] = True

        # Default: don't count nulls
        select['count-nulls'] = False

        return select

    def _get_value_map(self, value_map_name):
        """Get value map from config or parse inline JSON"""
        if value_map_name.startswith('{'):
            # Inline JSON
            return json.loads(value_map_name)
        else:
            # Reference to config
            return self.config.get('value_maps', {}).get(value_map_name)
```

### Select-List Handler

```python
# handlers/select_list.py
class SelectListHandler(SelectHandler):

    def can_handle(self, row):
        return row['select_type'] == 'select-list'

    def build(self, row):
        select = {
            "id": row['select_id'] or row['field_name'],
            "label": row['select_label'],
            "type": "select-list",
            "select-list": []
        }

        # Priority 1: Use bucket strategy from config
        if row.get('bucket_strategy'):
            strategy = BucketStrategy(self.config)
            items = strategy.build_items(
                row['field_name'],
                row['bucket_strategy'],
                row['data_type']
            )
            select['select-list'] = items

        # Priority 2: Use custom ranges
        elif row.get('custom_ranges'):
            items = self._build_custom_ranges(row)
            select['select-list'] = items

        # Priority 3: Use simple comparison
        elif row.get('comparison'):
            item = self._build_comparison(row)
            select['select-list'] = [item]

        return select

    def _build_custom_ranges(self, row):
        """Build select-list items from custom_ranges column"""
        ranges = json.loads(row['custom_ranges'])
        comparison_key = self.config['data_type_mappings'][row['data_type']]

        items = []
        for range_def in ranges:
            min_val, max_val, label = range_def
            item = {
                "label": label,
                "field-name": row['field_name'],
                comparison_key: {"Between": [min_val, max_val]}
            }
            items.append(item)

        return items

    def _build_comparison(self, row):
        """Build single comparison item from comparison column"""
        # Parse comparison string like "StartsWith:274" or "Gt:100"
        operator, value = row['comparison'].split(':', 1)
        comparison_key = self.config['data_type_mappings'][row['data_type']]

        # Convert value to appropriate type
        if row['data_type'] == 'integer':
            value = int(value)
        elif row['data_type'] == 'float':
            value = float(value)

        return {
            "label": row['select_label'],
            "field-name": row['field_name'],
            comparison_key: {operator: value}
        }
```

### Bucket Strategy Processor

```python
# strategies/bucket_strategy.py
class BucketStrategy:
    """Handles all bucketing logic from config"""

    def __init__(self, config):
        self.strategies = config.get('bucket_strategies', {})
        self.data_type_mappings = config.get('data_type_mappings', {})

    def build_items(self, field_name, strategy_name, data_type):
        """Build select-list items from a named strategy"""

        if strategy_name not in self.strategies:
            raise ValueError(f"Unknown bucket strategy: {strategy_name}")

        strategy = self.strategies[strategy_name]
        ranges = strategy['ranges']
        comparison_key = self.data_type_mappings.get(data_type, 'compare-string')
        last_operator = strategy.get('last_bucket_operator', 'Between')

        items = []
        for i, range_def in enumerate(ranges):
            min_val, max_val, label = range_def
            is_last = (i == len(ranges) - 1)

            # Handle last bucket specially if operator specified
            if is_last and last_operator in ['Ge', 'Gt', 'Le', 'Lt']:
                comparison = {comparison_key: {last_operator: min_val}}
            else:
                comparison = {comparison_key: {"Between": [min_val, max_val]}}

            item = {
                "label": label,
                "field-name": field_name
            }
            item.update(comparison)
            items.append(item)

        return items
```

### Main Builder

```python
# builder.py
class JSONBuilder:

    def __init__(self, config_path):
        self.config = self._load_config(config_path)
        self.handlers = self._register_handlers()

    def _load_config(self, config_path):
        """Load and validate config file"""
        with open(config_path) as f:
            config = yaml.safe_load(f)

        # Validate config structure
        required_keys = ['bucket_strategies', 'data_type_mappings']
        for key in required_keys:
            if key not in config:
                raise ValueError(f"Config missing required key: {key}")

        return config

    def _register_handlers(self):
        """Register all available handlers - EASY TO EXTEND"""
        return [
            SelectAllHandler(self.config),
            SelectMapHandler(self.config),
            SelectListHandler(self.config),
            # Future: SelectGeoListHandler(self.config),
        ]

    def build(self, template_path, csv_path, output_path):
        """Main build process"""

        # Load template
        with open(template_path) as f:
            template = json.load(f)

        # Always start with ALL select
        selects = [{"id": "ALL", "label": "ALL", "type": "select-all"}]

        # Process CSV rows
        with open(csv_path, newline='') as f:
            reader = csv.DictReader(f)
            for row_num, row in enumerate(reader, start=2):  # Start at 2 (header is 1)
                # Skip if marked
                if row.get('skip', '').lower() == 'true':
                    continue

                # Find appropriate handler
                handler = self._find_handler(row)
                if not handler:
                    print(f"Warning: No handler for row {row_num} ({row.get('field_name')})")
                    continue

                # Validate
                valid, errors = handler.validate(row)
                if not valid:
                    print(f"Validation errors on row {row_num} ({row.get('field_name')}):")
                    for error in errors:
                        print(f"  - {error}")
                    continue

                # Build select
                try:
                    select = handler.build(row)
                    selects.append(select)
                except Exception as e:
                    print(f"Error building row {row_num} ({row.get('field_name')}): {e}")
                    continue

        # Insert selects into template
        template['selects'] = selects

        # Write output with proper formatting
        with open(output_path, 'w') as f:
            json.dump(template, f, indent=4)

        print(f"Generated {len(selects)} selects to {output_path}")

    def _find_handler(self, row):
        """Find handler that can process this row"""
        for handler in self.handlers:
            if handler.can_handle(row):
                return handler
        return None


# CLI Interface
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Build query engine JSON from CSV')
    parser.add_argument('csv', help='Path to field definitions CSV')
    parser.add_argument('template', help='Path to table template JSON')
    parser.add_argument('output', help='Path to output JSON file')
    parser.add_argument('--config', default='builder_config.yaml',
                       help='Path to config file (default: builder_config.yaml)')

    args = parser.parse_args()

    builder = JSONBuilder(args.config)
    builder.build(args.template, args.csv, args.output)
```

---

## Usage Example

```bash
python builder.py \
    field_definitions.csv \
    table_template.json \
    output_table.json \
    --config builder_config.yaml
```

---

## Future Enhancements

### Phase 2: Additional Features

1. **Tags Support**
   - Add columns: `tags_sortable`, `tags_visible`, `tags_orderable`, etc.
   - Or: Single `tags` column with JSON object
   - Extend handlers to process and include tags in output

2. **Field Descriptions**
   - Add `description` column to CSV
   - Include in select objects for help text

3. **Select Groups**
   - Add `group_id` column to group multiple fields into one select-list
   - Useful for complex multi-field comparisons

4. **Geo Support (select-geolist)**
   - Add `SelectGeoListHandler`
   - Config for lat/lon field detection
   - Support radius and polygon comparisons

5. **Computed Bucket Strategies**
   - `equal_width`: Automatically calculate N equal-width buckets
   - `equal_frequency`: Automatically calculate N equal-frequency buckets (requires data profiling)
   - Add `bucket_params` CSV column for parameters like `num_buckets`

### Phase 3: Advanced Features

1. **Data Profiling Integration**
   - Automatically analyze source data to suggest select types
   - Calculate cardinality, distribution, null rates
   - Generate suggested CSV from data analysis

2. **Validation Reports**
   - HTML report showing all validation warnings/errors
   - Field coverage statistics
   - Cardinality warnings

3. **Value Map Files**
   - Support external CSV files for value mappings: `file://gender_map.csv`
   - Format: `source_value,display_label`

4. **Multiple Output Formats**
   - Generate both `_maps.json` and `_groups.json` (like current make_json.py)
   - Support output variants for different environments

5. **Config Versioning**
   - Support multiple config versions
   - Migration tools for config updates

6. **Auto-Detection Rules**
   - Define rules in config to suggest select_type based on field patterns
   - Example: Fields ending in `_FLAG` → select-map with yes_no mapping

---

## Design Decisions & Rationale

### Why JSON Template Instead of YAML/Config?
- Users may have custom table-level fields not known to the tool
- JSON template preserves exact structure, including unknown fields
- Separates concerns: tool builds selects, user controls table metadata

### Why YAML Config Instead of JSON?
- More readable for large bucket strategy definitions
- Supports comments for documentation
- Easier to edit manually
- Can switch to JSON if preferred (code supports both)

### Why Handlers Pattern?
- Each select type has unique validation and build logic
- Easy to add new types without modifying existing code
- Clear separation of concerns
- Testable in isolation

### Why Separate Strategies Module?
- Bucket strategies are complex enough to deserve their own module
- Reusable across different handlers
- Can be extended with computed strategies later

### Why One-Row-Per-Field Instead of Multi-Row?
- Simpler for most use cases (95%+ of selects are single-field)
- Easier to maintain in spreadsheet software
- Can add `group_id` column later for multi-field selects if needed

---

## Common Use Cases

### Use Case 1: Simple Binary Field
```csv
field_name,select_id,select_label,select_type,data_type,value_map,skip
HAS_CHILDREN,HAS_CHILDREN,Has Children,select-map,boolean,yes_no,false
```

### Use Case 2: Age Ranges
```csv
field_name,select_id,select_label,select_type,data_type,bucket_strategy,skip
AGE,AGE,Age,select-list,integer,age_standard,false
```

### Use Case 3: High-Cardinality Field
```csv
field_name,select_id,select_label,select_type,data_type,high_cardinality,skip
ZIP,ZIP,Zip Code,select-map,string,true,false
```

### Use Case 4: Top-N Field
```csv
field_name,select_id,select_label,select_type,data_type,top_n,other_label,skip
LAST_NAME,LAST_NAME,Last Name,select-map,string,100,Other Names,false
```

### Use Case 5: Custom Buckets
```csv
field_name,select_id,select_label,select_type,data_type,custom_ranges,skip
CUSTOM_SCORE,CUSTOM_SCORE,Custom Score,select-list,integer,"[[0,100,'Low'],[101,200,'Medium'],[201,300,'High']]",false
```

### Use Case 6: Simple Comparison
```csv
field_name,select_id,select_label,select_type,data_type,comparison,skip
ZIP_274,ZIP_274,Starts with 274,select-list,string,StartsWith:274,false
```

### Use Case 7: Skip Field (e.g., ID, Lat/Lon)
```csv
field_name,skip
ID,true
LATITUDE,true
LONGITUDE,true
```

---

## Migration from Current make_json.py

The current `make_json.py` expects CSV with these columns:
- `table-id`, `t-label`, `t-desc`, `royalty`
- `field-name`, `field-label`, `field-description`, `select-type`
- `values`, `high-cardinality`, `alt-id`
- Various tag columns: `sortable`, `orderable`, `data-level`, `actual`, `modeled`, `inferred`, `field-hint`

### Migration Strategy

1. **Phase 1**: Create conversion script
   - Read old CSV format
   - Generate new CSV + JSON template + config entries
   - Validate output matches old output

2. **Phase 2**: Run both in parallel
   - Use old script for production
   - Use new script for testing/validation
   - Compare outputs

3. **Phase 3**: Cutover
   - Switch to new script
   - Deprecate old script
   - Update documentation

### Conversion Mapping

| Old CSV Column | New Location |
|----------------|--------------|
| `table-id` | JSON template `id` |
| `t-label` | JSON template `label` |
| `t-desc` | JSON template `description` |
| `royalty` | JSON template `tags.default_royalty` |
| `field-name` | CSV `field_name` |
| `field-label` | CSV `select_label` |
| `field-description` | CSV `description` (future) |
| `select-type` | CSV `select_type` |
| `values` | CSV `value_map` or `custom_ranges` |
| `high-cardinality` | CSV `high_cardinality` |
| `alt-id` | CSV `select_id` |
| Tag columns | CSV `tags_*` columns (future) |

---

## Testing Strategy

### Unit Tests
- Test each handler independently
- Test bucket strategy processor
- Test value map processor
- Test config loader/validator

### Integration Tests
- End-to-end: CSV + template + config → JSON
- Compare output structure to expected
- Validate against query engine schema

### Test Cases
1. Minimal valid input
2. All select types represented
3. All bucket strategies used
4. Custom ranges
5. Simple comparisons
6. High-cardinality fields
7. Top-N fields
8. Value mappings (config and inline)
9. Invalid inputs (missing required fields)
10. Edge cases (empty CSV, malformed JSON template)

### Validation Tests
- Config schema validation
- CSV column validation
- Required field checking
- Data type compatibility
- Reference checking (bucket_strategy, value_map names exist)

---

## Error Handling

### Validation Errors (Stop Build)
- Missing required CSV columns
- Invalid config file format
- Template file not valid JSON
- Referenced bucket_strategy not in config
- Referenced value_map not in config

### Row-Level Errors (Skip Row, Continue)
- Missing required fields for select type
- Invalid data type
- Malformed custom_ranges JSON
- Invalid comparison format

### Warnings (Log, Continue)
- High cardinality without high_cardinality flag
- top_n without other_label
- Unusual bucket ranges (e.g., overlapping)

### Error Output Format
```
ERROR: Config file invalid: Missing required key 'data_type_mappings'

Row 5 (GENDER): Validation errors:
  - select_label is required for select-map

Row 12 (INCOME): Error building select:
  - Unknown bucket strategy: income_custom

Warning: Row 8 (ZIP) has 42000 distinct values but high_cardinality not set

Build completed with 3 errors, 1 warning
Generated 15 selects to output_table.json
```

---

## Questions to Resolve Later

### CSV Structure
1. Should we support a `description` column for select descriptions?
2. Do we need `count_nulls` and `skip_unmapped` columns, or use config defaults?
3. Should `select_id` default to `field_name` if blank, or be required?

### Configuration
1. Should config support label templates (e.g., `"${min:,} - ${max:,}"`)?
2. Should we include default values in config or hardcode in handlers?
3. Support multiple config files that merge (base + project-specific)?

### Custom Ranges Format
1. Prefer JSON `[[0,100,"Low"]]` or simplified `0-100:Low|101-200:High`?
2. Support single-value ranges (e.g., `Eq:specific_value` in custom_ranges)?

### Comparison Column
1. Current format: `Operator:Value` (e.g., `StartsWith:274`, `Gt:100`)
2. Should we support multiple comparisons in one cell? `Gt:100,Lt:200`?
3. Or should complex comparisons use `custom_ranges`?

### Error Handling
1. Stop build on first error or collect all errors?
2. Generate partial output with errors/warnings embedded as comments?
3. Exit code: 0 = success, 1 = validation errors, 2 = build errors?

### Output
1. Always include `count-nulls: false` even if default?
2. Should we remove null-valued keys from output JSON?
3. Include generation metadata in output (timestamp, source files)?

---

## Performance Considerations

### Large CSV Files
- Current design: Load entire CSV into memory
- For 10,000+ fields: Consider streaming/chunking
- Progress indicators for long builds

### Complex Bucket Strategies
- Computed strategies (equal_width) may need data access
- Consider caching computed results
- Pre-validation to avoid expensive computation on invalid rows

### Multiple Outputs
- If generating multiple JSON files from one CSV
- Batch processing mode
- Parallel processing for independent tables

---

## Reference: Query Engine Select Types

From `dp_tool/README.md`:

### select-all
```json
{
    "id": "ALL",
    "label": "ALL",
    "type": "select-all"
}
```

### select-map
```json
{
    "id": "select_id",
    "label": "Display Label",
    "type": "select-map",
    "field-name": "FIELD_NAME",
    "count-nulls": false,
    "skip-unmapped": true,
    "value-label-map": {"M": "Male", "F": "Female"},
    "high-cardinality": false,
    "keep-top-values": 100,
    "other-label": "Other"
}
```

### select-list
```json
{
    "id": "select_id",
    "label": "Display Label",
    "type": "select-list",
    "select-list": [
        {
            "field-name": "FIELD_NAME",
            "label": "Item Label",
            "compare-integer": {"Between": [0, 100]}
        }
    ]
}
```

### Comparison Types
- `All`: Always true, sets bit for each ID
- `Eq`, `Neq`: Equals, Not equals
- `Gt`, `Lt`, `Ge`, `Le`: Greater/Less than (or equal)
- `Between`: Between two values `[min, max]`
- `In`, `NotIn`: In/not in list of values
- `StartsWith`, `Contains`: String matching
- `Null`, `NotNull`: Null checking

### Data Type to Comparison Key
- String → `compare-string`
- Integer → `compare-integer`
- Float → `compare-float`

---

## Implementation Checklist

### Phase 1: Core Functionality
- [ ] Config loader with validation
- [ ] CSV reader with validation
- [ ] JSON template loader
- [ ] Base handler interface
- [ ] SelectAllHandler (simple, always included)
- [ ] SelectMapHandler
  - [ ] Basic field mapping
  - [ ] Value mapping (config reference)
  - [ ] High-cardinality flag
  - [ ] Top-N support
- [ ] SelectListHandler
  - [ ] Bucket strategy processor
  - [ ] Custom ranges support
  - [ ] Simple comparison support
- [ ] Main builder orchestrator
- [ ] CLI interface
- [ ] Error handling and reporting
- [ ] README and usage documentation

### Phase 2: Enhancements
- [ ] Inline JSON value maps (not just config references)
- [ ] Field descriptions
- [ ] Tags support
- [ ] External value map files (`file://map.csv`)
- [ ] Validation report output
- [ ] Progress indicators
- [ ] Multiple output formats

### Phase 3: Advanced
- [ ] Data profiling integration
- [ ] Auto-detection rules
- [ ] Computed bucket strategies
- [ ] Select groups (multi-field selects)
- [ ] Migration tool from old format
- [ ] Config versioning/migration

---

## Related Files

- `dp_tool/README.md` - Query engine documentation
- `dp_tool/make_json.py` - Current (old) JSON builder script
- This serves as reference for requirements and current behavior

---

## Contact & Decisions

When resuming this project, decisions needed on:
1. Finalize CSV column names and defaults
2. Choose error handling strategy
3. Select custom_ranges format (JSON vs simplified)
4. Determine initial bucket strategies to include
5. Decide on tag support approach

---

## Notes for Future Development

### Key Design Goals
- **Minimal viable product first**: Start with core functionality
- **Easy to extend**: Adding features shouldn't require refactoring
- **Configuration over code**: Business logic in config, not hardcoded
- **Clear error messages**: Help users fix problems quickly
- **One row per field**: Keep CSV manageable in spreadsheets

### Things We Explicitly Decided NOT to Support (v1)
- Geo selects (select-geolist) - Can add later
- Multi-field select-lists - Can add via `group_id` later
- Auto-detection of select types - Manual specification for now
- Data profiling - Future enhancement
- Computed bucket strategies - Future enhancement
- Complex tag systems - Add as needed

### Things to Watch Out For
- **Versioning in field names**: Current make_json.py strips `_v\d+$` from field names - do we need this?
- **Null handling**: Default `count-nulls: false` but need CSV override?
- **Label generation**: For custom ranges without labels, auto-generate from values?
- **Comparison operators**: Are all operators supported for all data types?

### Development Approach
1. Start with `builder.py` + minimal handlers
2. Test with small example CSV/template
3. Add one feature at a time
4. Validate against real use cases
5. Build up config with common strategies as discovered

---

## Example Complete Workflow

```bash
# 1. Create table template
cat > my_table_template.json <<EOF
{
    "id": "customer_data",
    "label": "Customer Data",
    "description": "Customer demographic and behavior data",
    "tags": {
        "default_royalty": ["GENDER", "AGE", "STATE"]
    },
    "node": 0,
    "parent": null,
    "selects": []
}
EOF

# 2. Create field definitions CSV (or in Excel/Google Sheets)
# Save as my_fields.csv

# 3. Review/customize builder_config.yaml
# Add custom bucket strategies or value maps as needed

# 4. Run builder
python builder.py \
    my_fields.csv \
    my_table_template.json \
    customer_data_maps.json \
    --config builder_config.yaml

# 5. Validate output
cat customer_data_maps.json | jq .

# 6. Use in query engine
# Copy customer_data_maps.json to appropriate location for xfilter-build
```

---

## Git Repository Structure Suggestion

```
json_builder/
├── README.md              # User documentation
├── DESIGN.md              # This file (design notes)
├── requirements.txt       # Python dependencies (pyyaml)
├── builder.py             # Main script
├── config_loader.py
├── handlers/
│   ├── __init__.py
│   ├── base.py
│   ├── select_all.py
│   ├── select_map.py
│   └── select_list.py
├── strategies/
│   ├── __init__.py
│   ├── bucket_strategy.py
│   └── value_map.py
├── validators/
│   ├── __init__.py
│   └── csv_validator.py
├── tests/
│   ├── test_handlers.py
│   ├── test_strategies.py
│   └── test_integration.py
├── examples/
│   ├── builder_config.yaml
│   ├── example_template.json
│   ├── example_fields.csv
│   └── expected_output.json
└── docs/
    ├── csv_reference.md
    ├── config_reference.md
    └── migration_guide.md
```

---

## Revision History

- 2025-10-24: Initial design document created during brainstorming session
- Project paused for future development
