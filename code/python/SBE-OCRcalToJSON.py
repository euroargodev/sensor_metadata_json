"""
SBE-OCRcallToJSON.py
"""

import os
import json
import numpy as np
from datetime import datetime, timezone

import re
import argparse
import pandas as pd
from pathlib import Path
from collections import OrderedDict



def SATgetCal(calFile):

    """Read Satlantic-formated (H)OCR cal files for wavelength and scale Factors"""

    # Read HyperOCR cal file
    dfcal = pd.DataFrame(columns=['tag', 'w', 'a0', 'a1', 'lm'])
    iw = 1


    try:
        fid = open(calFile, 'r')
    except FileNotFoundError:
        print(f'Error: could not open cal file: {calFile}')
        exit()
    else:
        with fid :
            while True: 

                # get a line and split it 
                tline = fid.readline()
                if not tline:
                    break
                tsplit = tline.strip().split(' ')
                tag = tsplit[0]

                # check if valid tag and OPTICx field
                # If so, extract:
                #   first line: tag and lambda (w)
                #   second line: calcoef (scaleFactor)
                #   third line: blank
                match tag:
                    case '#':
                        fields = tline[1:].strip().split('|')
                        # print(fields[-1])
                        if (re.match(r"^Final Calibration", fields[-1].strip())):
                            calDate = fields[0].strip()
                            calOperator = fields[1].strip()

                    case 'SN':
                        serialNo = tsplit[1].strip()                  
                
                    # if tag in calTags :
                    case 'ED' | 'PAR':
                    # if (tsplit[6] == 'OPTIC3') :
                        if re.match(r'^OPTIC', tsplit[6]) :
                            if tag == 'ED'  :
                                w =float(tsplit[1])            # lambda
                            else :
                                w = 0                         # lambda  (w = 0 is flag for PAR)

                            tline = fid.readline()
                            tsplit = tline.strip().split('\t')
                            a0 = float(tsplit[0])     # a0 coeff
                            a1 = float(tsplit[1])     # a1 coeff (scale factor)
                            lm = float(tsplit[2])     # immersion coeff
                            dfrow = pd.DataFrame( [{'tag': tag, 'w':w, 'a0': a0, 'a1': a1, 'lm': lm}])
                            dfcal = pd.concat([dfcal, dfrow], ignore_index=True)
                        
                        tline = fid.readline();  # skip blank line
    
        meta = dict()
        meta['serialNo'] = serialNo
        meta['calDate'] = datetime.strptime(calDate, '%Y-%m-%d').replace(tzinfo=timezone.utc).isoformat()
        meta['calOperator'] = calOperator
        
        return (dfcal, meta)

def get_OCR_JSONtemplate(template : Path)  -> dict :
    """Get the SATLANTIC JSON template to update with SAM calfile data"""
    
    try:
        f = open(template, 'r')
    except FileNotFoundError:
        print(f'Error: could not open template: {template}')
        exit()
    else:
        with f:
            # returns JSON object as a dictionary
            data = json.load(f)
            return data


def write_OCR_JSONinstance(data : dict, outfile : Path)  :
    """write the JSON metadata instance"""
    try:
        f= open(outfile, 'w')
    except FileNotFoundError:
        print(f'Error: could not open output file: {outfile}')
        exit()
    else:
        with f:
            pretty_json_object = json.dumps(data, indent=4)
            f.write(pretty_json_object)
            return
    

def create_JSON_file(template, dest_dir, serialNo, calDate, calOperator, calFile, dfcal ) :
    """
    Create a machine-readable JSON calibration file.

    The file is written in JSON format following emerging JSON Sensor Metadata standard

    """
    #
    # Update JSON SATLANTIC_OCR504 template with sensor cal file metadata
    #
    # Get JSON template 
    data = get_OCR_JSONtemplate(template)

    serialNo = '4' + serialNo   # Argo convention for OCR-504
    
    # Output filename : sensor-SATLANTIC-SATLANTIC_OCR504-serialNo.json
    outputfile =  dest_dir / Path(str(template.name).replace('template', serialNo))

    # Valid wavelengths for Argo (0 = PAR)
    # Actual OCR-504 wavelengths may round up or down +/- 1 nm
    valid_wavelengths = [0, 380, 412, 443, 490, 555]

    # sensor_info
    data['sensor_info']["created_by"] = os.path.basename(__file__)
    data['sensor_info']["date_creation"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    format_version = data['sensor_info'].get("format_version")
    contents       = data['sensor_info'].get("contents")
    data['sensor_info']["contents"] = contents.replace('xx.xx.xx', format_version)
    data['sensor_info']["sensor_described"] = f"SATLANTIC-SATLANTIC_OCR504_ICSW-{serialNo}"

    for i, row in dfcal.iterrows():

        w = find_nearest(valid_wavelengths, row.w)

        # Argo SENSORS and PARAMETERS (raw and calibrated)
        if dfcal.tag[i] == 'PAR':
            data['SENSORS'][i]["SENSOR"] = f"SDN:R25::RADIOMETER_PAR"
            keyw = f"CONFIG_OcrDownIrrWavelength{i+1}_nm"
            keyb = f"CONFIG_OcrDownIrrBandwidth{i+1}_nm"
            if keyw in data['SENSORS'][i]["sensor_vendorinfo"] :
                del data['SENSORS'][i]["sensor_vendorinfo"][keyw]
            if keyb in data['SENSORS'][i]["sensor_vendorinfo"] :
                del data['SENSORS'][i]["sensor_vendorinfo"][keyb]
            
            data["PARAMETERS"][i][ "PARAMETER"] = "SDN:R03::RAW_DOWNWELLING_PAR"
            data["PARAMETERS"][i]["PARAMETER_SENSOR"] =  "SDN:R25::RADIOMETER_PAR"
            data["PARAMETERS"][i+4][ "PARAMETER"] = "SDN:R03::DOWNWELLING_PAR"
            data["PARAMETERS"][i+4]["PARAMETER_SENSOR"] =  "SDN:R25::RADIOMETER_PAR"
            data["PARAMETERS"][i+4]["PARAMETER_UNITS"] = "microMoleQuanta/m^2/sec"


            data["PARAMETERS"][i]["PREDEPLOYMENT_CALIB_COMMENT"]  = f"Uncalibrated downwelling PAR measurement"
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COMMENT"]  = f"Calibrated downwelling PAR measurement"
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_EQUATION"] = "DOWNWELLING_PAR=0.01*A1_PAR*(RAW_DOWNWELLING_PAR-A0_PAR)*lm_PAR"
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][f"A0_PAR"]= str(row.a0)
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][f"A1_PAR"]= str(row.a1)
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][f"lm_PAR"]= str(row.lm)

        else:

            data['SENSORS'][i]["SENSOR"] = f"SDN:R25::RADIOMETER_DOWN_IRR{w:3.0f}"
            data['SENSORS'][i]["sensor_vendorinfo"][f"CONFIG_OcrDownIrrWavelength{i+1}_nm"] = int(w)
            data['SENSORS'][i]["sensor_vendorinfo"][f"CONFIG_OcrDownIrrBandwidth{i+1}_nm"] = 10

            data["PARAMETERS"][i]["PARAMETER"] = f"SDN:R03::RAW_DOWNWELLING_IRRADIANCE{w:3.0f}"
            data["PARAMETERS"][i]["PARAMETER_SENSOR"] = f"SDN:R25::RADIOMETER_DOWN_IRR{w:3.0f}"
            data["PARAMETERS"][i+4]["PARAMETER"] = f"SDN:R03::DOWN_IRRADIANCE{w:3.0f}"
            data["PARAMETERS"][i+4]["PARAMETER_SENSOR"] = f"SDN:R25::RADIOMETER_DOWN_IRR{w:3.0f}"
            data["PARAMETERS"][i+4]["PARAMETER_UNITS"] = "W/m^2/nm"

            data["PARAMETERS"][i]["PREDEPLOYMENT_CALIB_COMMENT"]  = f"Uncalibrated downwelling irradiance measurement at {w:3.0f} nm"
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COMMENT"]  = f"Calibrated downwelling irradiance measurement at {w:3.0f} nm"
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_EQUATION"] = f"DOWN_IRRADIANCE{w:3.0f}=0.01*A1_{w:3.0f}*(RAW_DOWNWELLING_IRRADIANCE{w:3.0f}-A0_{w:3.0f})*lm_{w:3.0f}"
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][f"A0_{w:3.0f}"]= str(row.a0)
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][f"A1_{w:3.0f}"]= str(row.a1)
            data["PARAMETERS"][i+4]["PREDEPLOYMENT_CALIB_COEFFICIENT_LIST"][f"lm_{w:3.0f}"]= str(row.lm)
        
        # data['SENSORS'][0]["SENSOR_MODEL_FIRMWARE"] = fw_version 
        data['SENSORS'][i]["SENSOR_SERIAL_NO"] = serialNo

        # Argo PARAMETERS
        # Calibration Coefficients are added to last parameter (RAW_DOWNWELLING_IRRADIANCE)
        data['PARAMETERS'][i+4]["parameter_vendorinfo"]["SBE_calfile"] = calFile
        
        #  PREDEPLOYMENT_CALIB_DATE 
        data['PARAMETERS'][i]['PREDEPLOYMENT_CALIB_DATE'] = calDate
        data['PARAMETERS'][i+4]['PREDEPLOYMENT_CALIB_DATE'] = calDate

    # Write out JSON sensor metadata instance
    write_OCR_JSONinstance(data, outputfile)

    return

def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return array[idx]


def main() :

    """Main routine to parse args, read cal files, and plot scale Factors of two (H)OCR Cal files"""

  # template config
    config = {"outputDir" : './json_sensors', 
              "template" : "./examples/sensor-SATLANTIC-SATLANTIC_OCR504_ICSW-template.json"}
    
    # rootDir = '/Volumes/Public/Calib/Radiometers/504/504I/OCR504ICSA-2339/'
    # cal = 'Cal01/Cal Data/CalA/DI42339A.cal'
    # template = 'Cal02/CalC2/DI42339C.cal'

    # Instantiate the command line argument parser
    parser = argparse.ArgumentParser(description='SBE-OCRcaltoJSON: Generate Argo JSON metadata file for SATLANTIC_OCR504 sensor')

    # Required positional argument
    parser.add_argument('cal', type=str,
                    help='OCR cal file')

    # Optional arguments
    parser.add_argument('-t', '--template', type=str, dest='template', default=config['template'],
                    help='JSON metadata template file')

    parser.add_argument("-o", "--outputDir", type=str, dest='outputDir', default=config['outputDir'],
                    help="directory to place output JSON file")
   
    # Parse command line arguments
    args = parser.parse_args()
    
    # Path to cal file
    cal = Path(args.cal)

     # Path to JSON template 
    template = Path(args.template)

    # Path to destination (output) directory
    dest_dir = Path(args.outputDir)

    # Get calibration files and compute RPD
    retlist = SATgetCal(cal)
    dfcal = retlist[0]
    meta = retlist[1]
    
    # Create the sensor-SATLANTIC-SATLANTIC_OCR504-yyyy.json metadata file
    create_JSON_file(template, dest_dir, meta['serialNo'], meta['calDate'], meta['calOperator'], cal.name, dfcal ) 

    return


if __name__ == '__main__' :
    main()