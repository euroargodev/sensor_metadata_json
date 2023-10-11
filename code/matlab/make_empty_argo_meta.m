% Start by making a comeplete empty argo meta file, to define fieldnames
% and dimensions.

% Not all of these can be set by the vendor

clear n d f m

% A number of structures are used
% m: All the ARGO manual metadata variables
% d: dimensions in the Argo NetCDF file. STRINGxxx and DATE_TIME
% n: dimensions that represent the number of certain things. All the
%    fieldnames begin N_
% f: fillvalues

% Define dimensions of arrays

% The following relate to the platform and are fixed to the float hardware

n.N_POSITIONING_SYSTEM = 1; % Number of positioning systems. Usually 1, but could be more
n.N_TRANS_SYSTEM = 1; % Number of transmission systems. Usually 1 , but could be more

% The following relate to both the float hardware and how the float is
% programmed by the operator

n.N_CONFIG_PARAM = 10; % Number of configuration parameters.
n.N_LAUNCH_CONFIG_PARAM = 10; % Number of pre-deployment or launch configuration parameters.
n.N_MISSIONS = 1; % Number of missions.

% The following relate to the sensors on the float

n.N_SENSOR = 1; % Number of sensors mounted on the float and used to measure the parameters.
n.N_PARAM = 1; % Number of parameters measured or calculated for a pressure sample.

% define other fixed dimensions

d.DATE_TIME = 14;
d.STRING4096 = 4096;
d.STRING1024 = 1024;
d.STRING256 = 256;
d.STRING128 = 128;
d.STRING64 = 64;
d.STRING32 = 32;
d.STRING16 = 16;
d.STRING8 = 8;
d.STRING4 = 4;
d.STRING2 = 2;
d.STRING1 = 1;

f.doublefillvalue99999 = double(99999);
f.intfillvalue99999 = int32(99999);



% General information on the meta-data file

m.DATA_TYPE = repmat(' ',1,d.STRING16);
m.FORMAT_VERSION = repmat(' ',1,d.STRING4);
m.HANDBOOK_VERSION = repmat(' ',1,d.STRING4);
m.DATE_CREATION = repmat(' ',1,d.DATE_TIME);
m.DATE_UPDATE = repmat(' ',1,d.DATE_TIME);

% Float characteristics, ie platform metadata

m.PLATFORM_NUMBER = repmat(' ',1,d.STRING8);
m.PTT = repmat(' ',1,d.STRING256);
m.TRANS_SYSTEM = repmat(' ',n.N_TRANS_SYSTEM,d.STRING16);
m.TRANS_SYSTEM_ID = repmat(' ',n.N_TRANS_SYSTEM,d.STRING32);
m.TRANS_FREQUENCY = repmat(' ',n.N_TRANS_SYSTEM,d.STRING16);
m.POSITIONING_SYSTEM = repmat(' ',n.N_POSITIONING_SYSTEM,d.STRING8);
m.PLATFORM_FAMILY = repmat(' ',1,d.STRING256);
m.PLATFORM_TYPE = repmat(' ',1,d.STRING32);
m.PLATFORM_MAKER = repmat(' ',1,d.STRING256);
m.FIRMWARE_VERSION = repmat(' ',1,d.STRING32);
m.MANUAL_VERSION = repmat(' ',1,d.STRING16);
m.FLOAT_SERIAL_NO = repmat(' ',1,d.STRING32);
m.STANDARD_FORMAT_ID = repmat(' ',1,d.STRING16);
m.DAC_FORMAT_ID = repmat(' ',1,d.STRING16);
m.WMO_INST_TYPE = repmat(' ',1,d.STRING4);
m.PROJECT_NAME = repmat(' ',1,d.STRING64);
m.DATA_CENTRE = repmat(' ',1,d.STRING2);
m.PI_NAME = repmat(' ',1,d.STRING64);
m.ANOMALY = repmat(' ',1,d.STRING256);
m.BATTERY_TYPE = repmat(' ',1,d.STRING64);
m.BATTERY_PACKS = repmat(' ',1,d.STRING64);
m.CONTROLLER_BOARD_TYPE_PRIMARY = repmat(' ',1,d.STRING32);
m.CONTROLLER_BOARD_TYPE_SECONDARY = repmat(' ',1,d.STRING32);
m.CONTROLLER_BOARD_SERIAL_NO_PRIMARY = repmat(' ',1,d.STRING32);
m.CONTROLLER_BOARD_SERIAL_NO_SECONDARY = repmat(' ',1,d.STRING32);
m.SPECIAL_FEATURES = repmat(' ',1,d.STRING1024);
m.FLOAT_OWNER = repmat(' ',1,d.STRING64);
m.OPERATING_INSTITUTION = repmat(' ',1,d.STRING64);
m.CUSTOMISATION = repmat(' ',1,d.STRING1024);

% Float deployment and mission information

m.LAUNCH_DATE = repmat(' ',1,d.DATE_TIME);
m.LAUNCH_LATITUDE = f.doublefillvalue99999;
m.LAUNCH_LONGITUDE = f.doublefillvalue99999;
m.LAUNCH_QC = ' ';
m.START_DATE = repmat(' ',1,d.DATE_TIME);
m.START_DATE_QC = ' ';
m.STARTUP_DATE = repmat(' ',1,d.DATE_TIME);
m.STARTUP_DATE_QC = ' ';
m.DEPLOYMENT_PLATFORM = repmat(' ',1,d.STRING32);
m.DEPLOYMENT_CRUISE_ID = repmat(' ',1,d.STRING32);
m.DEPLOYMENT_REFERENCE_STATION_ID = repmat(' ',1,d.STRING256);
m.END_MISSION_DATE = repmat(' ',1,d.DATE_TIME);
m.END_MISSION_STATUS = ' ';

% Configuration parameters

m.LAUNCH_CONFIG_PARAMETER_NAME = repmat(' ',n.N_LAUNCH_CONFIG_PARAM,d.STRING128);
m.LAUNCH_CONFIG_PARAMETER_VALUE  = repmat(f.doublefillvalue99999,n.N_LAUNCH_CONFIG_PARAM,1);
m.CONFIG_PARAMETER_NAME = repmat(' ',n.N_CONFIG_PARAM,d.STRING128);
m.CONFIG_PARAMETER_VALUE = repmat(f.doublefillvalue99999,n.N_CONFIG_PARAM,1);
m.CONFIG_MISSION_NUMBER = repmat(f.intfillvalue99999,n.N_MISSIONS,1);
m.CONFIG_MISSION_COMMENT = repmat(' ',n.N_MISSIONS,d.STRING256);

% Float sensor information

m.SENSOR = repmat(' ',n.N_SENSOR,d.STRING32);
m.SENSOR_MAKER = repmat(' ',n.N_SENSOR,d.STRING256);
m.SENSOR_MODEL = repmat(' ',n.N_SENSOR,d.STRING256);
m.SENSOR_SERIAL_NO = repmat(' ',n.N_SENSOR,d.STRING16);

% Float parameter information

m.PARAMETER = repmat(' ',n.N_PARAM,d.STRING64);
m.PARAMETER_SENSOR = repmat(' ',n.N_PARAM,d.STRING128);
m.PARAMETER_UNITS = repmat(' ',n.N_PARAM,d.STRING32);
m.PARAMETER_ACCURACY = repmat(' ',n.N_PARAM,d.STRING32);
m.PARAMETER_RESOLUTION = repmat(' ',n.N_PARAM,d.STRING32);

% Float calibration information

m.PREDEPLOYMENT_CALIB_EQUATION = repmat(' ',n.N_PARAM,d.STRING4096);
m.PREDEPLOYMENT_CALIB_COEFFICIENT = repmat(' ',n.N_PARAM,d.STRING4096);
m.PREDEPLOYMENT_CALIB_COMMENT = repmat(' ',n.N_PARAM,d.STRING4096);


generalinformation_fieldnames = {
    'DATA_TYPE'
    'FORMAT_VERSION'
    'HANDBOOK_VERSION'
    'DATE_CREATION'
    'DATE_UPDATE'
    };
floatcharacteristics_fieldnames = {
    'PLATFORM_NUMBER'
    'PTT'
    'TRANS_SYSTEM'
    'TRANS_SYSTEM_ID'
    'TRANS_FREQUENCY'
    'POSITIONING_SYSTEM'
    'PLATFORM_FAMILY'
    'PLATFORM_TYPE'
    'PLATFORM_MAKER'
    'FIRMWARE_VERSION'
    'MANUAL_VERSION'
    'FLOAT_SERIAL_NO'
    'STANDARD_FORMAT_ID'
    'DAC_FORMAT_ID'
    'WMO_INST_TYPE'
    'PROJECT_NAME'
    'DATA_CENTRE'
    'PI_NAME'
    'ANOMALY'
    'BATTERY_TYPE'
    'BATTERY_PACKS'
    'CONTROLLER_BOARD_TYPE_PRIMARY'
    'CONTROLLER_BOARD_TYPE_SECONDARY'
    'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'
    'CONTROLLER_BOARD_SERIAL_NO_SECONDARY'
    'SPECIAL_FEATURES'
    'FLOAT_OWNER'
    'OPERATING_INSTITUTION'
    'CUSTOMISATION'
    };
floatdeployment_fieldnames = {
    'LAUNCH_DATE'
    'LAUNCH_LATITUDE'
    'LAUNCH_LONGITUDE'
    'LAUNCH_QC'
    'START_DATE'
    'START_DATE_QC'
    'STARTUP_DATE'
    'STARTUP_DATE_QC'
    'DEPLOYMENT_PLATFORM'
    'DEPLOYMENT_CRUISE_ID'
    'DEPLOYMENT_REFERENCE_STATION_ID'
    'END_MISSION_DATE'
    'END_MISSION_STATUS'
    };
configuration_fieldnames = {
    'LAUNCH_CONFIG_PARAMETER_NAME'
    'LAUNCH_CONFIG_PARAMETER_VALUE'
    'CONFIG_PARAMETER_NAME'
    'CONFIG_PARAMETER_VALUE'
    'CONFIG_MISSION_NUMBER'
    'CONFIG_MISSION_COMMENT'
    };
sensor_fieldnames = {
    'SENSOR'
    'SENSOR_MAKER'
    'SENSOR_MODEL'
    'SENSOR_SERIAL_NO'
    };
parameter_fieldnames = {
    'PARAMETER'
    'PARAMETER_SENSOR'
    'PARAMETER_UNITS'
    'PARAMETER_ACCURACY'
    'PARAMETER_RESOLUTION'
    'PREDEPLOYMENT_CALIB_EQUATION'
    'PREDEPLOYMENT_CALIB_COEFFICIENT'
    'PREDEPLOYMENT_CALIB_COMMENT'
    };