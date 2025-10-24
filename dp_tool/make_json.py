#!/usr/bin/python3
import sys, json, csv, os, ast, re

def perror(*a):
    print(*a, file=sys.stderr)

def make_selects_json():
    # need to put these in csv to make more generic
    selects_json = json.loads(
        """{
            "id": null,
            "label": null,
            "description": null,
            "tags": { 
               "default_royalty": []
            },
            "node": 0,
            "parent": null,
            "selects": [
                {
                    "id": "ALL",
                    "label": "ALL",
                    "type": "select-all"
                }
            ]
        }"""
    )
    return selects_json
def make_select_map_json():
    select_map_json = json.loads(
        """{
            "id": null,
            "label": null,
            "description": null,
            "type" : "select-map",
            "tags": { },
            "count-nulls": false,
            "skip-unmapped": true,
            "value-label-map" : null, 
            "field-name": null
        }"""
    )
    return select_map_json

def make_select_list_json():
    select_list_json = json.loads(
        """{
            "id": null,
            "label": null,
            "description": null,
            "type": "select-list",
            "tags": { },
            "select-list" : []
        }"""
    )
    return select_list_json
def make_select_list_item():
    select_list_item = json.loads(
        """{
                "field-name": null,
                "label": null
        }"""
        )    
    return select_list_item

select_list_field_label = ""

def make_gui_group(data):
    # in case we need something like this
    # need to refine
    gg = {}
    for k in ("id", "label"):
        if data.get(k) is not None:
            gg[k] = data.get(k)

    gg["logic"] = "and"
    children = []
    for select in data["selects"]:
        select = {"select": {"table-id": data["id"], "select-id": select["id"]}}
        children.append(select)
    gg["children"] = children

    return gg

row_count = 0

if __name__ == "__main__":
    if len(sys.argv) < 2:
        perror(f"usage: python3 {sys.argv[0]} <dataset.csv> ")
        perror("Generates json for query engine")
        sys.exit(1)

    selects_json = make_selects_json()
    with open(sys.argv[1], newline="") as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            row_count = row_count + 1
            if row_count == 1:
                selects_json["id"] = row["table-id"]
                selects_json["label"] = row["t-label"]
                selects_json["description"] = row["t-desc"]
                #selects_json["tags"]["default_royalty"] = ast.literal_eval(row["royalty"])
                selects_json["tags"]["default_royalty"] = eval(row["royalty"])

            # remove version if field name ends with _v and one more character 
            #last_3 = row["field-name"][len(row["field-name"])-3:] 
            #if  last_3[:2] == "_v":
            #    select_id = row["table-id"]+"_"+row["field-name"].replace(f"{last_3}","")
            #else:
            #    select_id = row["table-id"]+"_"+row["field-name"]

	    # Use regex to match _v followed by one or more digits at the end of the string
            pattern = r'_v\d+$'
            # Remove _v and trailing numbers if present, otherwise keep the original field name
            cleaned_field_name = re.sub(pattern, '', row["field-name"])
            select_id = row["table-id"] + "_" + cleaned_field_name

	    # if we have an alternate ID use it in place of field-name
            if row["alt-id"] != "":
                select_id = row["table-id"]+"_"+row["alt-id"]

            if row["select-type"] == "select-map":
                # finalize pending select-list
                if select_list_field_label != "":
                    selects_json["selects"].append(select_list_json)
                    # unset select-list flag
                    select_list_field_label = ""

                select_map_json = make_select_map_json()
                select_map_json["id"] = select_id 
                select_map_json["label"] = row["field-label"]
                select_map_json["description"] = row["field-description"]


                if row['values'] == 'map_all':
                    del select_map_json["value-label-map"]
                else:
                    #select_map_json["value-label-map"] = ast.literal_eval(row['values'])
                    if row["high-cardinality"] == "":
                        select_map_json["value-label-map"] = eval(row['values'])
                    else:
                        del select_map_json["value-label-map"]
                        del select_map_json["skip-unmapped"]
                        select_map_json["high-cardinality"] = True
                    
                # get TAGS
                select_map_json["tags"]["sortable"] = row["sortable"] if row["sortable"] != "" else None
                select_map_json["tags"]["visible"] = "true" if row["orderable"] == "" else "false"
                select_map_json["tags"]["orderable"] = "true" if row["orderable"] == "" else "false"
                if row["data-level"] != "":
                    select_map_json["tags"]["data-level"] = row["data-level"]
                if row["actual"] == "A":
                    select_map_json["tags"]["actual"] = "true"
                if row["modeled"] == "M":
                    select_map_json["tags"]["modeled"] = "true"
                if row["inferred"] == "I":
                    select_map_json["tags"]["inferred"] = "true"
                if row["field-hint"] != "":
                    select_map_json["tags"]["field-hint"] = row["field-hint"]



                select_map_json["field-name"] = row["field-name"]
                selects_json["selects"].append(select_map_json)

            elif row["select-type"] == "select-list":
                if select_list_field_label == "":
                    # start new one
                    select_list_json = make_select_list_json()
                    select_list_json["id"] = select_id
                    select_list_json["label"] = row["field-label"]
                    select_list_json["description"] = row["field-description"]

                    # get TAGS
                    select_list_json["tags"]["sortable"] = row["sortable"] if row["sortable"] != "" else None
                    select_list_json["tags"]["visible"] = "true" if row["orderable"] == "" else "false"
                    select_list_json["tags"]["orderable"] = "true" if row["orderable"] == "" else "false"
                    if row["data-level"] != "":
                        select_list_json["tags"]["data-level"] = row["data-level"]
                    if row["actual"] == "A":
                        select_list_json["tags"]["actual"] = "true"
                    if row["modeled"] == "M":
                        select_list_json["tags"]["modeled"] = "true"
                    if row["inferred"] == "I":
                        select_list_json["tags"]["inferred"] = "true"
                    if row["field-hint"] != "":
                        select_list_json["tags"]["field-hint"] = row["field-hint"]


                else:
                    if row["field-label"] != select_list_field_label:
                        # add to main json
                        selects_json["selects"].append(select_list_json)
                        # build new one
                        select_list_json = make_select_list_json()
                        select_list_json["id"] = select_id 
                        select_list_json["label"] = row["field-label"]
                        select_list_json["description"] = row["field-description"]

                        # get TAGS
                        select_list_json["tags"]["sortable"] = row["sortable"] if row["sortable"] != "" else None
                        select_list_json["tags"]["visible"] = "true" if row["orderable"] == "" else "false"
                        select_list_json["tags"]["orderable"] = "true" if row["orderable"] == "" else "false"
                        if row["data-level"] != "":
                            select_list_json["tags"]["data-level"] = row["data-level"]
                        if row["actual"] == "A":
                            select_list_json["tags"]["actual"] = "true"
                        if row["modeled"] == "M":
                            select_list_json["tags"]["modeled"] = "true"
                        if row["inferred"] == "I":
                            select_list_json["tags"]["inferred"] = "true"
                        if row["field-hint"] != "":
                            select_list_json["tags"]["field-hint"] = row["field-hint"]

                # set current select-list label
                select_list_field_label = row["field-label"]
                # build item, fill it and append 
                select_list_item = make_select_list_item()
                select_list_item["field-name"]=row["field-name"]
                select_list_item["label"]=row["select-list-item-label"]
                #select_list_item[row["comparison-element"]] = ast.literal_eval(row['values'])
                select_list_item[row["comparison-element"]] = eval(row['values'])
                select_list_json["select-list"].append(select_list_item)
            else:
                perror(
                    "Every row MUST have a valid select-type of select-map or select-list"
                 )
                sys.exit(1)

    # finalize select-list if we have one pending           
    if select_list_field_label != "":
        selects_json["selects"].append(select_list_json)

    # Convert JSON to string to find and replace quoted nulls
    json_str = json.dumps(selects_json, indent=4)
    json_str = json_str.replace('"null"', 'null')
    
    # Write the corrected JSON
    with open(os.path.splitext(sys.argv[1])[0] + "_maps.json", "w") as outfile:
        outfile.write(json_str)

    with open(os.path.splitext(sys.argv[1])[0] + "_groups.json", "w") as gfile:
        groups_json = make_gui_group(selects_json)
        json.dump(groups_json, gfile, indent=4)
