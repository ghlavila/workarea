#!/usr/bin/python3

import json
import csv
import sys
import os
import argparse

def load_json_file(filepath):
    with open(filepath, 'r') as f:
        return json.load(f)

def load_csv_file(filepath):
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        return [row['category'] for row in reader]

def get_existing_categories(maps_data):
    return {select['id']: select for select in maps_data['selects']}

def update_existing_select_with_group(existing_select, group):
    """Update an existing select entry to include the iab-group tag"""
    if existing_select.get('tags') is None:
        existing_select['tags'] = {}
    existing_select['tags']['iab-group'] = group
    return existing_select

def create_new_select(category, description, group):
    return {
        "id": f"stir_{category}",
        "label": f"- {description}",
        "description": "",
        "tags": {
            "field-hint": "date",
            "iab-group": group
        },
        "type": "select-map",
        "field-name": "trigger_date",
        "field-list": [],
        "keep-top-values": None,
        "other-label": None,
        "count-nulls": False,
        "value-label-map": {},
        "map-file": None,
        "skip-unmapped": False,
        "high-cardinality": True,
        "filter-field-regex": [
            "category",
            category + "$"
        ]
    }

def main():
    parser = argparse.ArgumentParser(description='Process category maps and descriptions')
    parser.add_argument('--maps', required=True, help='Path to maps JSON file (set 1)')
    parser.add_argument('--categories', required=True, action='append', help='Path to categories CSV file for set 1 (can be specified multiple times)')
    parser.add_argument('--descriptions', required=True, help='Path to descriptions JSON file')
    parser.add_argument('--output', required=True, help='Path to output JSON file for set 1')

    # Optional explicit second set
    parser.add_argument('--maps2', help='Path to maps JSON file (set 2)')
    parser.add_argument('--categories2', action='append', help='Path to categories CSV file for set 2 (can be specified multiple times)')
    parser.add_argument('--output2', help='Path to output JSON file for set 2')
    
    args = parser.parse_args()

    descriptions = load_json_file(args.descriptions)

    def process_set(maps_path, category_files, output_path):
        maps_data_local = load_json_file(maps_path)
        existing_categories_local = get_existing_categories(maps_data_local)

        seen_categories_local = set()
        added_count_local = 0
        updated_count_local = 0

        for categories_path in category_files:
            for category in load_csv_file(categories_path):
                if category in seen_categories_local:
                    continue
                seen_categories_local.add(category)

                if category in descriptions:
                    description_text = descriptions[category]['description']
                    group = descriptions[category]['group']

                    if category not in existing_categories_local:
                        new_select = create_new_select(category, description_text, group)
                        maps_data_local['selects'].append(new_select)
                        existing_categories_local[category] = new_select
                        added_count_local += 1
                        print(f"[{os.path.basename(maps_path)}] Added new category: {category} (group: {group})")
                    else:
                        existing_select = existing_categories_local[category]
                        if existing_select.get('tags') is None or 'iab-group' not in existing_select.get('tags', {}):
                            update_existing_select_with_group(existing_select, group)
                            updated_count_local += 1
                            print(f"[{os.path.basename(maps_path)}] Updated existing category: {category} (group: {group})")
                else:
                    print(f"[{os.path.basename(maps_path)}] No description found for category: {category}")

        print(f"\n[{os.path.basename(maps_path)}] Summary: Added {added_count_local} new categories, updated {updated_count_local} existing categories")

        with open(output_path, 'w') as f:
            json.dump(maps_data_local, f, indent=2)

    # Process required set 1
    process_set(args.maps, args.categories, args.output)

    # Process optional set 2 (if any of the set-2 flags provided, require all)
    if any([args.maps2 is not None, args.output2 is not None, args.categories2 is not None]):
        if not (args.maps2 and args.output2 and args.categories2):
            print('Error: When using set 2, you must provide --maps2, --categories2, and --output2 together.')
            sys.exit(1)
        process_set(args.maps2, args.categories2, args.output2)

if __name__ == "__main__":
    main()