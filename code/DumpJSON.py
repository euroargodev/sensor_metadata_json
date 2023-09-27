import json

# files to test
# fname = 'sensor-AANDERAA-AANDERAA_OPTODE_3830-498.json'
fname = 'sensor-SBE-SBE41CP-11643.json'
fname = 'sensor-WETLABS-MCOMS_FLBBCD-0157.json'

# Open JSON file
with open('examples/'+fname) as f:

    # returns JSON object as a dictionary
    data = json.load(f)

    print('sensor_info:')
    for key, value in data['sensor_info'].items():
        print(f'{key}\t{value}')
    
    # Iterate through portions of the json list
    print('sensors:')
    for sensor in data['SENSORS']:
        for key, value in sensor.items() :
            print(f'{key}\t{value}')

    print('parameters:')
    for param in data['PARAMETERS']:
        for key, value in param.items() :
            if key != 'PREDEPLOYMENT_CALIB_COEFFICIENT_LIST' :
                print(f'{key}\t{value}')

        print('REDEPLOYMENT_CALIB_COEFFICIENT_LIST:')
        for key, calcoef in param['PREDEPLOYMENT_CALIB_COEFFICIENT_LIST'].items():
            print(f'\t{key}\t{calcoef}')