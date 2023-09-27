# sensor_metadata_json
Tools, schemas and example files for metadata for ocean platforms and sensors

Follows Argo float, sensor, paramater, and configuration schemes as well as identifying [NVS](https://vocab.nerc.ac.uk/) controlled vocabulary terms using their Indentifier URN (e.g., [SDN:R25::FLUOROMETER_CHLA](http://vocab.nerc.ac.uk/collection/R25/current/FLUOROMETER_CHLA/)).

| Directory | Description|
| --- | --- |
| **code** | Demonstration Python code to validate and parse JSON metadata instances againt the schema as well as validate controlled vocabulary terms using NVS server REST API.|
| **examples** | Schema-compliant examples for numerous sensors, platforms, and floats|
| **schema** | JSON schema for sensors, platforms, and floats.  Needed by validating JSON parsers.|

Current effort involves SBS-EREHM (Eric Rehm, Sea-Bird Scientific) and BAK (Brian King, NOC)

