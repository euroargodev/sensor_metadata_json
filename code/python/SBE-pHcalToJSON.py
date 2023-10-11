
# SBE-pHcalToJSON.py
#
# 
import os
import json
import datetime
import tomlkit
from tomlkit.toml_document import TOMLDocument
from pathlib import Path
from collections import OrderedDict

def get_pHcalfile(calname : Path) -> dict:
    """Get the pH calfile (TOML format)"""
    caltxt = tomlkit.parse(calname.read_text())
    return caltxt


def get_pHJSONtemplate(template : Path)  -> dict :
    """Get the pH JSON template to update with pHcalfile data"""
    with open(template, 'r') as f:
        # returns JSON object as a dictionary
        data = json.load(f)
        return data


def write_pHJSONinstance(data : dict, outfile : Path)  :
    """write the JSON metadata instance"""
    with open(outfile, 'w') as f:
        pretty_json_object = json.dumps(data, indent=4)
        f.write(pretty_json_object)
        return



def create_JSON_file(template, dest_dir, instrument_type, instrument_sn, fet_sn, ref_sen, fP, K2P, K0, K0_date) :
    """
    Create a machine-readable JSON calibration file.

    The file is written in JSON format following emerging JSON Sensor Metadata standard

    """
    #
    # Update JSON pH template with data from pHcal file
    #
    # Get JSON template 
    data = get_pHJSONtemplate(template)

    # HACK! Use calfiledate as manufacturing date
    # Use calfiledate as PREDEPLOYMENT_CALIB_DATE for PARAMETERS with calibration coefficients
    calfiledate = datetime.datetime.now().date().isoformat()
    data['SENSORS'][0]['sensor_vendorinfo']['SBE_manufacturing_date'] = calfiledate
    data['PARAMETERS'][4]['PREDEPLOYMENT_CALIB_DATE'] = calfiledate
    data['PARAMETERS'][5]['PREDEPLOYMENT_CALIB_DATE'] = calfiledate

    # serial numbers

    outputfile =  Path(str(template).replace('template', instrument_sn))

    # sensor_info
    data['sensor_info']["created_by"] = "SBE " + os.path.basename(__file__)
    data['sensor_info']["creation_date"] : datetime.datetime.now().replace(microsecond=0).isoformat()
    format_version = data['sensor_info'].get("format_version")
    contents       = data['sensor_info'].get("contents")
    data['sensor_info']["contents"] = contents.replace('xx.xx.xx', format_version)
    data['sensor_info']["sensor_described"] = f"SBS-SEAFET-{instrument_sn}"

    # Argp SENSORS
    data['SENSORS'][0]["SENSOR_SERIAL_NO"] = instrument_sn
    data['SENSORS'][0]["sensor_vendorinfo"]["SBE_pHType"] = instrument_type
    data['SENSORS'][0]["sensor_vendorinfo"]["SBE_ISFET_SERIAL_NO"] = fet_sn
    data['SENSORS'][0]["sensor_vendorinfo"]["SBE_REFERENCE_SERIAL_NO"]   = ref_sn

    # ARGO PARAMETERS
    # Set K0 and K2 calibration dates accordingly in SBE-specific metadate
    key = 'PREDEPLOYMENT_SEAFET_K0_CALIB_DATE'
    # K0date = caltxt['K0'].get('K0_calibration_date').strftime('%Y-%m-%d')
    data['PARAMETERS'][4]['predeployment_vendorinfo'][key] = K0_date
    data['PARAMETERS'][5]['predeployment_vendorinfo'][key] = K0_date

    key = 'PREDEPLOYMENT_SEAFET_K2_CALIB_DATE'
    # K2date = caltxt['K2P'].get('K2_calibration_date').strftime('%Y-%m-%d')
    K2_date = K2P.get('K2_calibration_date').strftime('%Y-%m-%d')
    data['PARAMETERS'][4]['predeployment_vendorinfo'][key] = K2_date
    data['PARAMETERS'][5]['predeployment_vendorinfo'][key] = K2_date

    # Calibration Coefficiens
    # fP
    key = 'fP_poly_order'
    fP_poly_order = fP.get('poly_order')
    data['PARAMETERS'][4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(fP_poly_order)
    data['PARAMETERS'][5]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(fP_poly_order)
    for i in range(0,fP_poly_order+1) :
        key = f'f{i}'
        value = float(fP.get(key))
        data['PARAMETERS'][4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(value)
        data['PARAMETERS'][5]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(value)
    # rename fP.poly_order to fP_poly_order
    # fP = OrderedDict([('fP_poly_order', v) if k == 'poly_order' else (k, v) for k, v in fP.items()])  
    # data['PARAMETERS'][4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"].update(fP)
    # data['PARAMETERS'][5]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"].update(fP)

    # K0
    key = 'K0'
    # K0 = float(caltxt['K0'].get(key))
    data['PARAMETERS'][4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(K0[key])
    data['PARAMETERS'][5]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(K0[key])

    # K2 polynomial (K2P)
    key = 'K2_poly_order'
    # rename K2P.poly_order to K2_poly_order
    # K2P_poly_order = int(caltxt['K2P'].get('poly_order'))
    K2P_poly_order = K2P.get('poly_order')
    data['PARAMETERS'][4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(K2P_poly_order)
    data['PARAMETERS'][5]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(K2P_poly_order)
    for i in range(0,K2P_poly_order+1) :
        key = f'K2f{i}'
        value = float(K2P.get(key))
        data['PARAMETERS'][4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(value)
        data['PARAMETERS'][5]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][key] = str(value)
        
    # Write out JSON sensor metadata instance
    write_pHJSONinstance(data, outputfile)


if __name__ == '__main__':

    calname = 'examples/17683-11764 ISFET pH.cal'

    config = {"output_dir" : ',/examples', "template" : "./examples/sensor-SBE-SEAFET-template.json"}

    # Get JSON tempate 
    # template = Path('examples/sensor-SBE-SEAFET-template.json')
    template = Path(config['template'])

    # destination (output) director
    dest_dir = config["output_dir"]

  # Get pHcal file (See ph-calsheets/phcalsheets/ph_calsheet_creator.py)
    calname = Path(calname)
    caltxt = get_pHcalfile(calname)

    instrument_type = 'Float'
    instrument_sn = caltxt["Instrument"].get('serial_number')
    fet_sn = caltxt["Instrument"].get('ISFET_serial_number')
    ref_sn = caltxt["Instrument"].get('reference_serial_number')

    fP = caltxt.get('fP')
    K0 = caltxt.get('K0')
    K2P = caltxt.get('K2P')

    K0_date = K0.get('K0_calibration_date').strftime('%Y-%m-%d')

    create_JSON_file(template, dest_dir, instrument_type, instrument_sn, fet_sn, ref_sn, fP, K2P, K0, K0_date) 
    exit()