# query_engine

### Library and tools for creating and operating on Roaring bitmap indexes.

The primary data structure for the query engine is the '**Table**'. A _Table_ is a logical grouping of selectable
data elements and is usually closely related to a physical input data file or SQL table.
Indexes and metadata are generated via the **xfilter-build** step in **dp_tool**.
The output of this process will be a **.bmap** file that contains all the roaring bitmaps for this _Table_
and a **.sql3** sqlite3 file that contains the metadata for this _Table_.

A JSON _Table_ definition describes identifiers, textual labels, multi-purpose key-value tags, billing, and query indexes for
the various **Field**s contained. A _Table_ defitinition DOES NOT contain grouping and ordering information.

### Table definition

| Key         | Optional | Value                                                                 |
| ----------- | -------- | --------------------------------------------------------------------- |
| id          |          | A unique identifier for the table (will be used in file names )       |
| label       |          | A human friendly label for displaying to users                        |
| description | Yes      | A longer description used for help text                               |
| tags        | Yes      | A JSON object                                                         |
| node        |          | A u32 value describing the "tree" node in a hierarchical relationship |
| parent      | Yes      | The parent "tree" node in a hierarchical relationship (table "id")    |
| selects     |          | A list of _selection definitions_                                     |

### Selection definition

| Key   | Optional | Value                                                                                             |
| ----- | -------- | ------------------------------------------------------------------------------------------------- |
| id    |          | A unique identifier for the table (will be used in file names )                                   |
| label |          | A human friendly label for displaying to users (usually the chart header)                         |
| tags  | Yes      | A JSON object                                                                                     |
| type  |          | _select-all_ <sub>has no elements associated</sub>, _select-map_, _select-list_, _select-geolist_ |

Depending on the selection _type_ the following elements are part of the _Selection definition_:

| Type           | Key              | Optional                | Value                                                                                                         |
| -------------- | ---------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------- |
| select-map     | field-name       | name or list needed     | Name of the _Field_ to index. By default all distinct values will be indexed                                  |
| select-map     | field-list       | name or list needed     | List of *Field*s to index in the same map. By default all distinct values will be indexed                     |
| select-map     | keep-top-values  | Yes                     | An optional integer value. If present only the top-N occuring values will be in the index                     |
| select-map     | other-label      | Yes                     | If _keep-top-values_ is set you can optionally lump all lower occuring values into one bucket with this label |
| select-map     | count-nulls      | Yes                     | By default null values are ignored for _select-map_. This overrides that behaviour                            |
| select-map     | value-label-map  | Yes                     | An optional key/value mapping allowing you to map input values to others prior to indexing.                   |
| select-map     | map-file         | Yes                     | An optional csv file containing "key","value" to load into _value-label-map_. No header.                      |
| select-map     | skip-unmapped    | Yes                     | Boolean - optionally drop values that don't map to something in _value-label-map_                             |
| select-map     | high-cardinality | Yes                     | A boolean indicating that we should not summarize and send back each value for this selection                 |
| select-list    | select-list      |                         | List of _comparison elements_                                                                                 |
| select-geolist | lat-field        | defaults to _latitude_  | Name of the latitude _Field_                                                                                  |
| select-geolist | lon-field        | defaults to _longitude_ | Name of the longitude _Field_                                                                                 |
| select-geolist | select-geolist   |                         | List of _geo comparison elements_                                                                             |

#### Comparison element

| Key             | Optional               | Value                                                                                                                                    |
| --------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| field-name      |                        | Name of the _Field_ to test for inclusion                                                                                                |
| label           |                        | A human friendly label for displaying to users (on the element level, usually a checkbox)                                                |
| compare-string  | Must have 1 comparison | A single key to value map describing the comparison to be made                                                                           |
| compare-integer | Must have 1 comparison | A single key to value map describing the comparison to be made                                                                           |
| compare-float   | Must have 1 comparison | A single key to value map describing the comparison to be made                                                                           |
| virtual         | Must have 1 comparison | Denotes a select that will be populated by the query engine at runtime. use null as the value                                            |
| derived         | Must have 1 comparison | Denotes a select that will be populated by the query engine at startup. Value is a Filter object and can contain selects from any table. |

|_For the All, Null, and NotNull comparison types the compare-string value will simply be the key, not a map_

#### Comparison types (not all available for all data types)

| Key        | Value(s)                                                           |
| ---------- | ------------------------------------------------------------------ |
| All        | Always return true, sets bit for each ID encountered               |
| Eq         | Test record value equals this literal                              |
| Neq        | Test record value not equals this literal                          |
| Gt         | Test record value greater than this literal                        |
| Lt         | Test record value less than this literal                           |
| Ge         | Test record value greater or equal than this literal               |
| Le         | Test record value less or equal than this literal                  |
| Between    | Test record value between these 2 values represented as array of 2 |
| In         | Test record value is in list of literals                           |
| NotIn      | Test record value is not in list of literals                       |
| StartsWith | Test record value starts with this literal                         |
| Contains   | Test if this literal contains the record value                     |
| Null       | Test if the record value is null                                   |
| NotNull    | Test if the record value is not null                               |

#### Geo comparison element

| Key               | Optional               | Value                                                                                     |
| ----------------- | ---------------------- | ----------------------------------------------------------------------------------------- |
| label             |                        | A human friendly label for displaying to users (on the element level, usually a checkbox) |
| radius-meters     | Must have 1 comparison | map { radius, lat, lon }                                                                  |
| radius-kilometers | Must have 1 comparison | map { radius, lat, lon }                                                                  |
| radius-miles      | Must have 1 comparison | map { radius, lat, lon }                                                                  |
| polygon-contains  | Must have 1 comparison | [ [lat1, lon1], [lat2, lon2]... ]                                                         |

Example _Table_ configuration:

```json
{
    "id": "demo_table",
    "label": "Example label",
    "description": "Long text",
    "tags": { },
    "node": 0,
    "parent": null,
    "selects": [
        {
            "id": "ALL",
            "label": "ALL",
            "type": "select-all"
        },
        {
            "id": "select1",
            "label": "Zip code",
            "high-cardinality": true,
            "type" : "select-map",
            "field-name": "zip"
        },
        {
            "id": "select2",
            "label": "lname",
            "type" : "select-map",
            "keep-top-values": 100,
            "other-label" : "Other Last Name",
            "count-nulls": false,
            "value-label-map" : {
                "KING": "THAT GUY",
                "SMITH": "COMMON"
            },
            "field-name": "N_LNAME"
        },
        {
            "id": "test_radius",
            "label": "Service Areas",
            "count-nulls": false,
            "type" : "select-geolist",
            "select-geolist" : [
                { "label": "Primary service area", "radius-miles" : { "radius": 10.0, "lat": 34.967400, "lon": -78.930428 } }
                { "label": "Secondary service area", "radius-miles" : { "radius": 25.0, "lat": 34.967400, "lon": -78.930428 } }
            ]
        },
        {
            "id": "testlist",
            "label": "testlist",
            "type": "select-list",
            "select-list" : [
                {
                    "field-name": "M_ZIP5",
                    "label": "starts w 274",
                    "compare-string": {
                        "StartsWith": "274"
                    }
                }
            ]
        }
    ]
}
```
