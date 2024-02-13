#
# TRIOS-SAMcalToJSON.py
#
# 
import os
import json
import datetime
import pandas as pd
from pathlib import Path

def get_SAMcalfile(calname : Path) -> dict:
    """Get the SAM calfile (Tab delimited format)"""
    # Retain cal coefficients as strings to preserve precision
    dfcal = pd.read_csv(calname, delimiter='\t',  dtype = str ).replace('+NAN', 'NaN')
    return dfcal


def get_RAMSES_JSONtemplate(template : Path)  -> dict :
    """Get the RAMES JSON template to update with SAM calfile data"""
    with open(template, 'r') as f:
        # returns JSON object as a dictionary
        data = json.load(f)
        return data


def write_RAMSES_JSONinstance(data : dict, outfile : Path)  :
    """write the JSON metadata instance"""
    with open(outfile, 'w') as f:
        pretty_json_object = json.dumps(data, indent=4)
        f.write(pretty_json_object)
        return
    

def create_JSON_file(template, dest_dir, instrument_type, instrument_sn, fw_version, calib_date, calfile, dfcal ) :
    """
    Create a machine-readable JSON calibration file.

    The file is written in JSON format following emerging JSON Sensor Metadata standard

    """
    #
    # Update JSON TRIOS-RAMSES template with sensor cal file metadata
    #
    # Get JSON template 
    data = get_RAMSES_JSONtemplate(template)

    # Map RAMSES Instrument Type to SENSOR_MODEL in NVS
    TRIOS_model_map = { "ACC_UV"  : "SDN:L22::TOOL0810",
                        "ACC_VIS" : "SDN:R27::RAMSES_ACC",
                        "ARC"     : "SDN:L22::TOOL0774"}
    
    # Output filename : TRIOS-RAMSES_instrument_type-instrumnet_sn.json
    outputfile =  dest_dir / Path(str(template.name).replace('template', instrument_sn).replace('ACC', instrument_type))

    # sensor_info
    data['sensor_info']["created_by"] = os.path.basename(__file__)
    data['sensor_info']["date_creation"] = datetime.datetime.now().replace(microsecond=0).isoformat()
    format_version = data['sensor_info'].get("format_version")
    contents       = data['sensor_info'].get("contents")
    data['sensor_info']["contents"] = contents.replace('xx.xx.xx', format_version)
    data['sensor_info']["sensor_described"] = f"TRIOS-RAMSES_{instrument_type}-{instrument_sn}"

    # Argo SENSORS
    data['SENSORS'][0]["SENSOR_MODEL"] = TRIOS_model_map[instrument_type]
    data['SENSORS'][0]["SENSOR_MODEL_FIRMWARE"] = fw_version 
    data['SENSORS'][0]["SENSOR_SERIAL_NO"] = instrument_sn
    data['SENSORS'][0]["sensor_vendorinfo"]["TRIOS_RAMSESType"] = instrument_type

    # Argo PARAMETERS
    # Calibration Coefficients are added to last parameter (RAW_DOWNWELLING_IRRADIANCE)
    data['PARAMETERS'][-1]["parameter_vendorinfo"]["TRIOS_calfile"] = calfile

    key = 'OPTICAL_WAVELENGTH'
    data['PARAMETERS'][-1]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = \
        "[" + dfcal.Wave.str.cat(sep=", ") + "]"
        
    key = 'B0'
    data['PARAMETERS'][-1]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = \
        "[" + dfcal.B0.str.cat(sep=", ") + "]"
    
    key = 'B1'
    data['PARAMETERS'][-1]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = \
        "[" + dfcal.B1.str.cat(sep=", ") + "]"
    
    key = 'S'
    data['PARAMETERS'][-1]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = \
        "[" + dfcal.S.str.cat(sep=", ") + "]"
    
    key = 'Sair'
    data['PARAMETERS'][-1]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = \
        "[" + dfcal.Sair.str.cat(sep=", ") + "]"
    
    #  PREDEPLOYMENT_CALIB_DATE 
    data['PARAMETERS'][-1]['PREDEPLOYMENT_CALIB_DATE'] = calib_date

    # Write out JSON sensor metadata instance
    write_RAMSES_JSONinstance(data, outputfile)


if __name__ == '__main__':

    # Sensor data

    # Instrument type, fw version, and calib date to be supplied by TRIOS internallhy
    instrument_type = "ACC_VIS"
    fw_version = "1.0.9"
    calib_date = datetime.datetime.now().date().isoformat()

    # Calibration data
    calname = 'examples/SAM_876C_01600040_AllCal.txt'

    # template config
    config = {"output_dir" : './json_sensors', 
              "template" : "./examples/sensor-TRIOS-RAMSES_ACC-template.json"}
    
    # Path to JSON template 
    template = Path(config['template'])

    # Path to destination (output) directory
    dest_dir = Path(config["output_dir"])

    # Get RAMSES SAM cal file 
    calname = Path(calname)
    instrument_sn = calname.name.split("_")[2]
    dfcal = get_SAMcalfile(calname)

    # Create the sensor-TRIOS-xxxx-yyyy.json metadata file
    create_JSON_file(template, dest_dir, instrument_type, instrument_sn, fw_version, \
                     calib_date, calname.name, dfcal ) 
    exit()