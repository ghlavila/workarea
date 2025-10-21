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
    parser.add_argument('--maps', required=True, help='Path to maps JSON file')
    parser.add_argument('--categories', required=True, action='append', help='Path to categories CSV file (can be specified multiple times)')
    parser.add_argument('--descriptions', required=True, help='Path to descriptions JSON file')
    parser.add_argument('--output', required=True, help='Path to output JSON file')
    
    args = parser.parse_args()

    # Load all files
    maps_data = load_json_file(args.maps)
    category_files = args.categories
    descriptions = load_json_file(args.descriptions)

    # Get existing categories from maps (now returns dict with category_id -> select_object)
    existing_categories = get_existing_categories(maps_data)

    # Process categories from each provided file sequentially, deduplicating across files
    seen_categories = set()
    added_count = 0
    updated_count = 0
    
    for categories_path in category_files:
        for category in load_csv_file(categories_path):
            if category in seen_categories:
                continue
            seen_categories.add(category)
            
            if category in descriptions:
                description_text = descriptions[category]['description']
                group = descriptions[category]['group']
                
                if category not in existing_categories:
                    # Add new select to maps
                    new_select = create_new_select(category, description_text, group)
                    maps_data['selects'].append(new_select)
                    existing_categories[category] = new_select
                    added_count += 1
                    print(f"Added new category: {category} (group: {group})")
                else:
                    # Update existing select with iab-group tag
                    existing_select = existing_categories[category]
                    if existing_select.get('tags') is None or 'iab-group' not in existing_select.get('tags', {}):
                        update_existing_select_with_group(existing_select, group)
                        updated_count += 1
                        print(f"Updated existing category: {category} (group: {group})")
            else:
                print(f"No description found for category: {category}")
    
    print(f"\nSummary: Added {added_count} new categories, updated {updated_count} existing categories")

    # Write updated maps to output file
    with open(args.output, 'w') as f:
        json.dump(maps_data, f, indent=2)

if __name__ == "__main__":
    main()
