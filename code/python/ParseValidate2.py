import os
import sys
import json
import jsonschema
import urnparse 
from jsonpointer import JsonPointer
from requests_cache import CachedSession
from datetime import timedelta
from pathlib import Path
from urllib.parse import urlparse
from dataclasses import dataclass
from typing import ClassVar
from referencing import Registry
from referencing.jsonschema import DRAFT7
from referencing import Resource
from typing import Dict, List
import requests

# Define NVS host
VOCAB_HOST = os.environ.get("VOCAB_HOST", "http://vocab.nerc.ac.uk")

# Path to schemas on local filesystem
SCHEMAS = Path("./schemas")

def load_json(file_path):
    return json.loads(file_path.read_text())
    
def resolve_references():
    '''Resolve references ($ref) in the main and sub schemas'''

    # This implementation retrieves schemas from filelocal  system
    
    # To retrieve via HTTP:
    # 1. See https://python-jsonschema.readthedocs.io/en/v4.19.1/referencing/#the-store-argument
    # amd retrieve_via_httpx below
    # 2. Modify base URL all $ref properties in all Argo schemas
    #    e.g., {"$ref" : "./argo.platform.schema.json"} -->  {"$ref" : "https://json.schemastore.org/argo.platform.schema.json"}

    registry = Registry(retrieve = retrieve_from_filesystem)
    # registry = Registry(retrieve = retrieve_via_httpx)
    return registry

def retrieve_from_filesystem(uri: str):
    '''Retrieve schemas from filesystem based on hard-coded path'''
    path = SCHEMAS / Path(uri.removeprefix("./"))
    contents = json.loads(path.read_text())
    return Resource.from_contents(contents)

import httpx
def retrieve_via_httpx(uri: str):
    '''Retrieve schemas via HTTP'''
    response = httpx.get(uri)
    return Resource.from_contents(response.json())
    
def validate_data(data, schema):

    # Identify method resolve references to subschemas
    registry = resolve_references()

    # Select the validator based on $schema property in schema
    # (validators correspond to various drafts of JSON Schema)
    validator = jsonschema.validators.validator_for(schema)

    # Create the validator using the registry and associated resolver
    v = validator(schema, registry=registry)
    
    try :
        # Validate the instance using the resolved schema
        v.validate(data)
    except jsonschema.exceptions.ValidationError as error:
        pass
        # print(error)
    except jsonschema.exceptions.SchemaError as error:
        print("SchemaError")
        return [error]
    except jsonschema.exceptions.UnknownType as error:
        print("UnknownType")
        return [error]
    except jsonschema.exceptions.UndefinedTypeCheck as error:
        print("UndefinedTypeCheck")
        return [error]

    # Create a list of errors, if any
    errors = list(v.iter_errors(validator, data))
    return errors

@dataclass
class NVS :
    '''Object for mapping and validating NVS vocabulary terms via HTTP. '''
    data : str = ""
    clearCache : bool  = False
    context : str = ""
    session : ClassVar[str] = ""
    timeout : float = 20.0  # seconds

    def __post_init__(self) :

        # Grab context which has mapping from concept Uri to concept URL
        self.context = JsonPointer("/@context").get(self.data)  # Needs error handling
        
        # Initialize cached session if necesary.  Clear cache if asked to.
        if not self.session :
            self.session = CachedSession('nvs_argo_vocab_cache', expire_after=timedelta(hours=1))
        if self.clearCache :
            self.session.cache.clear()
        
        # Validate collections from context
        for key_uri, collection_url in self.context.items():
            r = self.session.get(collection_url, timeout=self.timeout)
            if r.status_code == 200 :
                print(f'uri {key_uri:s} ok')
            else:
                print(f'uri {key_uri:%s} url not resolved {collection_url:s}')
                            

    def validateTerm(self, termUrn) :
        '''Method for mapping short-form termUri into termUrl.  Then does HTTP get of termUrl succeed?
           Extended with code from Violetta Paba at NERC to also to attempt to validate the term
           as an altLabel
           
           This code does NOT yet handle repeated sensors, TEMP2, PSAL2, etc. 
           Why?  Because there are some terms that naturally end in numbers, e.g., 
           '''

        # termUrn        "SDN:R25::FLUOROMETER_CHLA"
        #                (Defined here: https://www.seadatanet.org/Standards/Common-Vocabularies)
        # self.context   {"SDN:R25::" : "http://vocab.nerc.ac.uk/collection/R25/current/",
        #                 "SDN:R25::" : "http://vocab.nerc.ac.uk/collection/R26/current/",
        #                 ...}
        # ==> termUrl     "http://vocab.nerc.ac.uk/collection/R25/current/FLUOROMETER_CHLA"
        
        # Parse term URN.  We'll map the collectionUri to a URL found in the context dict
        print(termUrn)
        parsedUrn = urnparse.NSSString(termUrn).parts
        collectionUrn = parsedUrn[0] + ":" + parsedUrn[1] + "::"
        term = parsedUrn[3]
        # Get collection Url from collection Url scheme (r25, r26, etc.)
        collectionUrl = self.context[collectionUrn]

        # Create the termURL and check if NVS server (or cache) responds with HTTP 200 (OK)
        termUrl = collectionUrl + term
        headers = {"Accept" : "application/ld+json"}
        r = self.session.get(termUrl, headers=headers, timeout=self.timeout)
        if r.status_code == 200:
            # testing ...
            if r.from_cache:
                print(f'(cache)  {termUrl}')
            else :
                print(f'(server) {termUrl}')
            return True
        else:
            # If not found on NVS server (or cache), assume term is actually an altLabel
            # Query NVS for a list of altLabels for this vocabulary Rxx and check to
            # see if the altLabel is associated with a termID Url.  If it is, then
            # this (mis)coding of a termID with an altLabel is OK.  Otherwise, fail.
            print(f'******** {termUrl} not found, HTTP status code {r.status_code}')
            print(f'Search prefLabels....')
            results = get_vocab_data(VOCAB_HOST,parsedUrn[1])
            termUrls= [result['uri'] for result in results if result['pref_label']==term]
            if (len(termUrls) == 1) :
                print(f'(prefLabel) {term} found --> {termUrls[0]}')
                return True
            else :
                print(f'******** {termUrl} not found as prefLabel either')
                return False

    def validate(self, jpointer, variables) :
        '''Validate terms of Sensors or Parameters variables'''

        # Note that not all variables / properties for each sensor/parameter/platform
        # have a controlled vocabulary.  That's why we pass in the "variables".

        sensors = JsonPointer(jpointer).get(self.data)

        # sensors and parameters are a list *multiple sensors / parameters per instrument .  platform is not, so make it one.
        if type(sensors) is not list:
            sensors = [sensors]

        N = len(variables)*len(sensors)
        sensorValid = 0

        # Loop through sensors/parameter, then variables for each sensor/parameter
        for sensor in sensors :

            for var in variables :
                try :
                    if var in sensor :
                        # terms may or may not be a list.  If not, make it one.
                        sensorTermList = sensor[var]
                        if type(sensorTermList) is not list :
                            sensorTermList = [sensorTermList]
                        for sensorTermUri in sensorTermList :
                            sensorValid = sensorValid + self.validateTerm(sensorTermUri)
                        N = N + len(sensorTermList) -1
                except Exception as error:
                    print(error)
                    return False

        # Ok, only if all controlled terms are valid
        if sensorValid == N :
            return True
        else:
            return False


def get_sparql_query(vocab_host: str, vocab_id: str) -> str:
    """Generates a SPARQL query for retrieving vocab data.

    Args:
        vocab_host (str): e.g. http://vocab.nerc.ac.uk
        vocab_id (str): e.g. P01, L22, etc.

    Returns:
        str: SPARQL query created based on input params.
    """
    sparql_query = """
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX owl: <http://www.w3.org/2002/07/owl#>
    SELECT DISTINCT (?c as ?uri) (?pl as ?prefLabel)
    WHERE {{
        <{0}/collection/{1}/current/> skos:member ?c .
        ?c skos:prefLabel ?pl .
        ?c owl:deprecated ?isDeprecated .
        FILTER (?isDeprecated = "false") .
    }}
    ORDER BY ?pl
    """
    return sparql_query.format(vocab_host, vocab_id)


def get_vocab_data(vocab_host: str, vocab_id: str) -> List[Dict]:
    """Retrieves data for a given vocab.

    Args:
        vocab_host (str): Where to fetch the data from, e.g. http://vocab.nerc.ac.uk
        vocab_id (str): Which vocab to fetch, e.g. L22

    Returns:
        List[Dict]: JSON data containing all terms in the specified vocab.
    """
    query_url = f"{vocab_host}/sparql/sparql"
    query = get_sparql_query(vocab_host, vocab_id)

    resp = requests.post(query_url, data=query, headers={"Content-Type": "application/sparql-query"}, timeout=60)
    results = [
        {"uri": x["uri"]["value"], "pref_label": x["prefLabel"]["value"]} for x in resp.json()["results"]["bindings"]
    ]
    return results

def main():
    '''Validate a Argo JSON instance (SENSOR, PLATFORM, FLOAT) against schema and NVS controlled vocabularies'''

    # get file to validate from command line if it's there
    if (len(sys.argv) == 2):
        fname = sys.argv[1]
    else:
        # fname = 'json_sensors/sensor-WETLABS-MCOMS_FLBBCD-0157.json'
        # fname = 'json_sensors/sensor-SATLANTIC-SATLANTIC_OCR504_ICSW-42139.json'
        # fname = 'json_sensors/sensor-SBE-SBE63_OPTODE-2739.json'
        # fname = 'json_sensors/sensor-AANDERAA-AANDERAA_OPTODE_4330-3901.json'
        # fname = 'json_sensors/sensor-SATLANTIC-SUNA_V2-1527.json'
        # fname = 'json_sensors/sensor-WETLABS-ECO_FLBBCD-3666.json'
        # fname = 'json_sensors/sensor-SBE-SEAFET-11341.json'
        fname = 'json_platforms/platform-SBE-NAVIS_EBR-1101.json'
        # fname = 'json_floats/float-SBE-NAVIS_EBR-1101.json'
        fname = 'json_sensors/sensor-SATLANTIC-SATLANTIC_OCR504_ICSW-42442.json'
        
    # Load JSON sensor instance data 
    data_dir = Path.cwd() 
    fpath = data_dir / Path(fname)
    try :
        data = load_json(fpath)
    except Exception as error:
        print(error)
        exit()
    print(fpath)

    # Load root JSON schema that applies to this JSON instance
    schema_dir = Path.cwd() / Path('schemas')
    schema_type = fpath.name.split('-')[0]
    schema_path = schema_dir / Path('argo.'+f'{schema_type}'+'.schema.json')
    try: 
        main_schema = load_json(schema_path)
    except Exception as error:
        print(error)
        exit()
    
    print(schema_path)

    # Validate data (instance) against the resolved main schema.  
    validation_errors = validate_data(data, main_schema)
    if validation_errors:
        print("Validation errors:")
        for error in validation_errors:
            print(error)
    else:
        print("JSON instance is valid.")
        # If the data is valid, you can pretty print it.
        pretty_data = json.dumps(data, indent=4)
        # print("Parsed data:\n", pretty_data)

        # Validate the JSON entries that have NVS controlled vocabularies
        # Use json pointer notation, e.g., /SENSORS/SENSOR, /SENSORS/SENSOR_MAKER, ...
        nvs = NVS(data, clearCache = False)

        # Check against Argo metadata properties with NVS controlled vocabularies.
        # Not elegant, but it works.
        if 'SENSORS' in data :
            if nvs.validate("/SENSORS", ['SENSOR', 'SENSOR_MAKER', 'SENSOR_MODEL']) :
                print("All controlled terms in SENSORS are valid")
            else:
                print("One or more controlled terms in SENSORS are invalid or could not be resolved")

        if 'PARAMETERS' in data :                         
            if nvs.validate("/PARAMETERS", ['PARAMETER', 'PARAMETER_SENSOR']) :
                print("All controlled terms in PARAMETERS are valid") 
            #     nvs.validate("/PARAMETERS", ['PARAMETER', 'PARAMETER_SENSOR'])) :
            #     print("All controlled terms are valid")
            else:
                print("One or more controlled terms in PARAMETERS are invalid or could not be resolved")

        if 'PLATFORM' in data :                         
            if nvs.validate("/PLATFORM", ["DATA_TYPE", "POSITIONING_SYSTEM",  "TRANS_SYSTEM",  "PLATFORM_FAMILY", "PLATFORM_TYPE", "PLATFORM_MAKER",  "WMO_INST_TYPE",  "CONTROLLER_BOARD_TYPE_PRIMARY",  "CONTROLLER_BOARD_TYPE_SECONDARY"]) :
                print("All controlled terms in PLATFROM are valid")
            else:
                print("One or more controlled terms in PLATFORM are invalid or could not be resolved")

if __name__ == "__main__":
    main()