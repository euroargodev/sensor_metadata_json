function jsp2 = make_float_json_from_floatdef(float_id,dirnames)
%
%
% USE:
%  make_float_json(float_id,[dirnames])
%
%
%
% This script will combine json files from one platform and multiple
% sensors to create a json file for the entire float
%
% INPUT:
%  float_id is a string that describes the float
%  is has three components separated by dashes, made up of components that
%  uniquley identify the float
%  platform_maker-platform_type-float_serial_number
%  eg 'SBE-NAVIS_EBR-1101'
%  Note that the paltform_maker and platform_type are controlled
%  vocabularies, and the float_serial_number is assumed to be uniquely
%  assigned to the platform by the platform_maker
%  The platform_maker and platform_type should not contain any dash
%  characters. The float_serial_number is defined by the platform_maker and
%  is uncontrolled. It might contain dashes which is OK. If it contains
%  characters that are not allowed in matlab file names, then code might
%  break.
%
%
% dirnames is a structure that carries the location of directories for input and output files
%
% fieldnames in the dirnames structure can be any or all or none of
% dirnames.json_floats
% dirnames.json_sensors
% dirnames.json_platforms
% dirnames.txt_floatdefs
%
% if dirnames.json_floats is not defined, it is assumed to be the current directory
% if dirnames.json_sensors is not defined, it is assumed to be hthe same as dirnames.floats
% if dirnames.json_platforms is not defined, it is assumed to be hthe same as dirnames.floats
% if dirnames.txt_floatdefs is not defined, it is assumed to be hthe same as dirnames.floats
%
% if the dirnames argument is omitted altogether, then all input and output files will be assumed to be in the current directory
%
%
%
%
%  dirnames.txt_floatdefs is the directory where float definintion txt files
%  reside.
%
%  dirnames.json_sensors
%  and
%  dirnames.json_platforms
%  are the directory where the platform and sensor json files reside
%
%  dirnames.json_floats is the directory where the float json file will
%  be written
%
%
%
%  The script will look for a plain text file in the floatdef_directory,
%  with the name
%  ['floatdef-' float_id '.txt']
%  That file should contain a list of json file names, one platform folowed
%  by any number of sensors. It can have comment lines introduced by %
%  characters, eg
%
% % example of a platform definition that contains a platform file and 2 sensor files.
% % here is a second comment line
% platform-SBE-NAVIS_EBR-1101.json
% sensor-SBE-SBE41CP-11643.json
% sensor-RBR-RBR_ARGO3-205908.json suffix=2
%
% The definition file can optionally request a suffix where it is known
% there are repeats of sensor or parameter names
%
% The script will manage cases whrere a sensor or parameter are repeated
% In that case, a suffix will be chosen and added to the sensor and
% parameter names for that file
%
% OUTPUT:
%  a new json file is written to a file, with filename
%  ['float-' float_id '.json']
%
%  The output argument is the full new json string
%
% Examples
%
% js = make_float_json_from_floatdef('SBE-NAVIS_EBR-1101')
% dirnames.json_floats = '/Users/bak/floats/json_floats'; js = make_float_json_from_floatdef('SBE-NAVIS_EBR-1101',dirnames)


if nargin < 2; dirnames.json_floats = '.'; end

if ~isfield(dirnames,'json_floats'); dirnames.json_floats = '.'; end
if ~isfield(dirnames,'json_sensors'); dirnames.json_sensors = dirnames.json_floats; end
if ~isfield(dirnames,'json_platforms'); dirnames.json_platforms = dirnames.json_floats; end
if ~isfield(dirnames,'txt_floatdefs'); dirnames.txt_floatdefs = dirnames.json_floats; end




def_file_in = [dirnames.txt_floatdefs '/floatdef-' float_id '.txt']; % this is a plain text list of json file names, which defines the float and its sensors
def_file_ot = [dirnames.json_floats '/float-' float_id '.json']; % The aggregated json is output to this file




created_by = 'BAK test'; % presently hardwired



fn_platform = {};
fn_sensors = {};
if exist(def_file_in,'file') ~= 2
    warning('Floatdef file not found; check directory and filename;');
    keyboard
end
fid = fopen(def_file_in,'r');
while 1
    tline = fgetl(fid);
    if ~ischar(tline); break; end
    if strncmp('%',tline,1); continue; end % discard comment lines
    if strncmp('platform',tline,8)
        fn_platform = [fn_platform ; tline]; % expect only one of these
    end
    if strncmp('sensor',tline,6)
        fn_sensors = [fn_sensors ; tline];
    end
end
fclose(fid);

% The float_id when this script is called, the name of the floatdef file,
% the name of the platform json file and the contents of the platform json
% file should all match
%
% We already know the float_id matches the name of the floatdef file,
% otherwise that file will not have been found and read.
%
% now check that the filename of the floatdef file matches the filename of the platform
% json that is requested inside the floatdef file
%
% the platform json name should be made up of
% platform-floatid.json, where floatid is the input argument to this script
str1 = ['platform-' float_id '.json']; % made from the filename of the floatdef
str2 = fn_platform{1}; % platform file name read in from the floatdef
if ~strcmp(str1,str2)
    warning('json file name inside the floatdef file does not match the name of the floatdef file')
    fprintf(2,'%s\n%s\n%s\n%s\n','platform json file name should be',str1,'json file listed inside the floatdef is',str2)
    keyboard
end



% read the platform json file

fnin = fn_platform{1};
fnin(strfind(fnin,' ')) = []; % remove any spaces in filename

fprintf(1,'%s %s\n','Reading',fnin)

fid = fopen([dirnames.json_platforms '/' fnin]);
raw = fread(fid,inf);
fclose(fid);

str = char(raw(:)');
jsplat = jsondecodeEx(str);
context_plat = jsplat.x_context;

float_described = jsplat.platform_info.platform_described; % the present logic is that the 'platform' is the hull, and the 'float' is the platform+sensors

% The float_id when this script is called, the name of the floatdef file,
% the name of the platform json file and the contents of the platform json
% file should all match
%
% We already know the float_id matches the name of the floatdef file,
% otherwise that file will not have been found and read.
%
% And we already checked that the filename of the floatdef file matches the filename of the platform
% json that is requested inside the floatdef file
%
% now check that the contents of the platform json file that has been requested also match the
% float_id
str1 = float_id; % the argument passed in to this script
str2 = [remove_nvs_tablenum(jsplat.PLATFORM.PLATFORM_MAKER) '-' remove_nvs_tablenum(jsplat.PLATFORM.PLATFORM_TYPE) '-' jsplat.PLATFORM.FLOAT_SERIAL_NO];
if ~strcmp(str1,str2)
    warning('float_id called in this script does not match the values saved inside the platform json file')
    fprintf(2,'%s\n%s\n%s\n%s\n','float_id is',str1,'values inside platform json file correspond to float_id',str2)
    keyboard
end


% now read the sensor json files

num_sensorfiles = length(fn_sensors);

sufnumin = zeros(num_sensorfiles,1); % initialise array to store required suffix for multiple sensors. sufnumin is filled if a suffix is requested in the definition file
sufstrin = cell(num_sensorfiles,1);
sufnumot = zeros(num_sensorfiles,1); % initialise array to store required suffix for multiple sensors
sufstrot = cell(num_sensorfiles,1);

for kl = 1:num_sensorfiles
    fnin = fn_sensors{kl};

    % look for suffix instructions

    kmat = strfind(fnin,'suffix');
    if ~isempty(kmat)
        sufstrin{kl} = fnin(kmat:end);
        keq = strfind(sufstrin{kl},'=');
        sufstrin{kl} = sufstrin{kl}(keq+1:end);
        sufnumin(kl) = str2num(sufstrin{kl});

        fnin = fnin(1:kmat-1);
    end

    fnin(strfind(fnin,' ')) = []; % remove any spaces in filename
    fn_sensors{kl} = fnin;

    fprintf(1,'%s %s\n','Reading',fnin)

    fid = fopen([dirnames.json_sensors '/' fnin],'r');
    raw = fread(fid,inf);
    fclose(fid);

    % Decode the JSON file into MATLAB structures
    %
    % jsondecodeEx() forces cell arrays for SENSORS, PARAMETERS so that
    % each SENSOR or PARAMETER can have varying content (e.g.,
    % sensor_vendorinfo)

    str = char(raw(:)');
    js = jsondecodeEx(str);


    % Now we have read a sensor json file. Check that the values saved in
    % the sensor json file match the file name of the json file
    %
    % In the case where there are several sensors in one sensor json file,
    % eg a SBE41 or FLBBCD, then the sensor filename can only be made from
    % one SENSOR_SERIAL_NO. In the case of a SBE41, the PRES is usually
    % quoted first, but the SENSOR_SERIAL_NO is usally takemn from the TEMP
    % or PSAL, quoted after the PRES. So in a first cut of this check, we
    % look for the SENSOR_SERIAL_NO of the last sensor in the sensor json
    % file, and comapre that with the sensor serial number used to make the
    % sensor json filename. This is not guaranteed to work robustly.
    %
    str1 = fnin; % the sensor filename
    str1 = str1(8:end-5); % remove the 'sensor-' and '.json' part of the filename
    str2 = [remove_nvs_tablenum(js.SENSORS{end}.SENSOR_MAKER) '-' remove_nvs_tablenum(js.SENSORS{end}.SENSOR_MODEL) '-' js.SENSORS{end}.SENSOR_SERIAL_NO];
    if ~strcmp(str1,str2)
        warning('sensor_id in sensor json filename does not match the values saved inside the sensor json file')
        fprintf(2,'%s\n%s\n%s\n%s\n','sensor_id from filename is',str1,'values inside sensor json file correspond to sensor_id',str2)
        keyboard
    end


    % Grab the context from first sensor file -  @context in all sensor
    % files is the same.  (Note that MATLAB's jsondecode has munged
    % @context --> x_context)
    if kl == 1
        context_sensor = js.x_context;
    end

    % keep a note of the length of the sensor and parameter names as read
    % in, to use when looking for multiple sensors
    num_s = length(js.SENSORS);
    num_p = length(js.PARAMETERS);

    jsall{kl} = js;
end

fprintf(1,'\n');

% For debugging; not used later
platformfields = fieldnames(jsplat.PLATFORM);
sensorfields = fieldnames(jsall{1}.SENSORS{1});
parameterfields = fieldnames(jsall{1}.PARAMETERS{1});

% At this point, we expect the following fields to be present
% platformfields =
%     {'version'                             }
%     {'DATA_TYPE'                           }
%     {'POSITIONING_SYSTEM'                  }
%     {'PLATFORM_FAMILY'                     }
%     {'PLATFORM_TYPE'                       }
%     {'PLATFORM_MAKER'                      }
%     {'FIRMWARE_VERSION'                    }
%     {'FLOAT_SERIAL_NO'                     }
%     {'WMO_INST_TYPE'                       }
%     {'BATTERY_TYPE'                        }
%     {'BATTERY_PACKS'                       }
%     {'CONTROLLER_BOARD_TYPE_PRIMARY'       }
%     {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'  }
%     {'CONTROLLER_BOARD_TYPE_SECONDARY'     }
%     {'CONTROLLER_BOARD_SERIAL_NO_SECONDARY'}
%     Optional {'platform_vendorinfo'}
% sensorfields =
%     {'SENSOR'          }
%     {'SENSOR_MAKER'    }
%     {'SENSOR_MODEL'    }
%     {'SENSOR_SERIAL_NO'}
%     {'SENSOR_FIRMWARE' }
%     Optional {'sensor_vendorinfo'}
% parameterfields =
%     {'PARAMETER'                       }
%     {'PARAMETER_SENSOR'                }
%     {'PARAMETER_UNITS'                 }
%     {'PARAMETER_ACCURACY'              }
%     {'PARAMETER_RESOLUTION'            }
%     {'PREDEPLOYMENT_CALIB_EQUATION'    }
%     {'PREDEPLOYMENT_CALIB_COEFFICIENT' }
%     {'PREDEPLOYMENT_CALIB_COEFFICIENTS'}
%     {'PREDEPLOYMENT_CALIB_COMMENT'     }
%     {'PREDEPLOYMENT_CALIB_DATE'        }
%     Optional {'parameter_vendorinfo'}
%     Optional {'predeployment_vendorinfo'}
%     Optional {'instrument_vendorinfo'}

% now merge all the sensor and parameter definitions
%
% If there is only one input file, no appending is needed
%
% If there are multiple sensor and parameter names that haven't already been
% taken care of by defining a suffix at the inpuut stage, take care of that
% below

clear SENSORS PARAMETERS
SENSORS = []; % empty to start with
PARAMETERS = [];
num_s = length(SENSORS);
num_p = length(PARAMETERS);

for kl = 1:num_sensorfiles

    % create a cell array of sensor and parameter names from all files read
    % before this one

    num_s = length(SENSORS);
    num_p = length(PARAMETERS);
    sensornames = {};
    paramnames = {};
    for ks = 1:num_s
        sensornames = [sensornames {SENSORS{ks}.SENSOR}];
    end
    for kp = 1:num_p
        paramnames = [paramnames {PARAMETERS{kp}.PARAMETER}];
    end

    js = jsall{kl}; % This is the new file definition being added
    % if any of the SENSORs or PARAMETERs already exist, we will need to
    % add a new unique suffix for this file

    S = js.SENSORS;
    P = js.PARAMETERS;

    numnew_s = length(S); % the number of sensors and parameters to be added from this file
    numnew_p = length(P);

    % This section of code should find the highest previous suffix for
    % either sensor or parameter names, and increase it by 1 if needed.
    % If any of the sensor or parameter names are found to have been used
    % before, then all the sensor and parameter names for the new file
    % get the new suffix.


    used_suffix_sensor = [];
    for ks = 1:numnew_s
        sname = S{ks}.SENSOR; % This is the next sensor name
        snamelen = length(sname);
        kmat = find(strncmp(sname,sensornames,length(sname))); % find if this sensor name has been used before
        if length(kmat) > 0
            % This name, has been found before.
            % Find all previous instances of this sensor name
            for km = 1:length(kmat)
                oldname = sensornames{kmat(km)};
                suffixstr = oldname(snamelen+1:end); % find the chars after the sensor name
                if isempty(suffixstr)
                    suffixnum = 0;
                else
                    suffixnum = str2num(suffixstr);
                end
                used_suffix_sensor = [used_suffix_sensor suffixnum];
            end
        end
    end

    % used_suffix_sensior now contains the list of all suffixes previously
    % used for any sensors in this file

    used_suffix_param = [];
    for ks = 1:numnew_p
        pname = P{ks}.PARAMETER;
        pnamelen = length(pname);
        kmat = find(strncmp(pname,paramnames,length(pname))); % find if this parameter name has been used before
        if length(kmat) > 0
            % This name, has been found before.
            % Find all previous instances of this sensor name
            for km = 1:length(kmat)
                oldname = paramnames{kmat(km)};
                suffixstr = oldname(pnamelen+1:end); % find the chars after the sensor name
                if isempty(suffixstr)
                    suffixnum = 0;
                else
                    suffixnum = str2num(suffixstr);
                end
                used_suffix_param = [used_suffix_param suffixnum];
            end
        end
    end

    % used_suffix_param now contains the list of all suffixes previously
    % used for any parameters in this file

    % Now decide whether to use a suffix for this file

    used_suffix_all = unique([used_suffix_sensor used_suffix_param]);
    requested_suffix = sufnumin(kl);
    min_available_suffix = min(setdiff([0 2:1000],used_suffix_all)); % zero corresponds to no suffix, 1 is never used, 2 is the first suffix for a replicate sensor or parameter

    % There are four possibilities now
    % 1) A suffix was requested and it is available, so use it
    % 2) A suffix was requested and it is not available, so use the lowest
    % available
    % 3) A suffix was not requested and is not needed, so no suffix used
    % 4) A suffix was not requetsed but one is needed, so use the next
    % available

    if requested_suffix > 1 % suffix requested, is it available
        if isempty(find(used_suffix_all == requested_suffix))
            % the requested suffix is available, use it
            sufnumot(kl) = requested_suffix;
        else
            % the requested suffix has already been used
            sufnumot(kl) = min_available_suffix;
        end
    else % suffix not requested
        if ~isempty(used_suffix_all)
            % sensor or parameter name has been used before, so find the
            % next available
            sufnumot(kl) = min_available_suffix;
        else
            sufnumot(kl) = 0; % empty suffix string
        end
    end

    if sufnumot(kl) == 0
        sufstrot{kl} = '';
        fprintf(1,'%s %40s\n','adding file',fn_sensors{kl})
    else
        sufstrot{kl} = sprintf('%d',sufnumot(kl));
        fprintf(1,'%s %40s %s %s\n','adding file',fn_sensors{kl},'with suffix',sufstrot{kl})
    end

    for ks = 1:numnew_s
        S{ks}.SENSOR = [S{ks}.SENSOR sufstrot{kl}];
    end

    for kp = 1:numnew_p
        P{kp}.PARAMETER = [P{kp}.PARAMETER sufstrot{kl}];
        P{kp}.PARAMETER_SENSOR = [P{kp}.PARAMETER_SENSOR sufstrot{kl}];
    end

    SENSORS = [SENSORS ; S];
    PARAMETERS = [PARAMETERS ; P];


end

clear allout info

% Add any metadata about the float json file
info.created_by = created_by;
info.date_creation = string(datetime('now', 'TimeZone', 'Z', 'Format','yyyy-MM-dd''T''hh:mm:ss'))+"Z";
info.format_version = '0.2.0'; % schema version
info.link = './argo.float.schema.json';
info.contents = 'json file to describe a platform with sensors for Argo';
info.float_described = float_described;

% Create sensor_info_list as unique name from sensor_info so there's no
% confusion
sensor_info_list = [];
files_merged = fn_platform(1);
for kl = 1:num_sensorfiles
    sensor_info_list = [sensor_info_list ; jsall{kl}.sensor_info];
    files_merged = [files_merged ; fn_sensors{kl}];
end

% Now combine the contexts from platform and one sensor, and sort them for
% neatness
fnames1 = fieldnames(context_plat);
fnames2 = fieldnames(context_sensor);
% make name-value pairs
cpairsall = {};
for kn = 1:length(fnames1)
    cpair = {fnames1{kn} context_plat.(fnames1{kn})};
    cpairsall = [cpairsall; cpair];
end
for kn = 1:length(fnames2)
    cpair = {fnames2{kn} context_sensor.(fnames2{kn})};
    cpairsall = [cpairsall; cpair];
end

cpairsall = sortrows(cpairsall,1);

for kn = 1:size(cpairsall,1)
    context_all.(cpairsall{kn,1}) = cpairsall{kn,2};
end

% Meta metadata
allout.float_info = info;
allout.files_merged = files_merged;
allout.x_context = context_all;
allout.platform_info = jsplat.platform_info;
allout.sensor_info_list = sensor_info_list;

% Platform and sensor metadata
allout.PLATFORM = jsplat.PLATFORM;
allout.SENSORS = SENSORS;
allout.PARAMETERS = PARAMETERS;

% Encode it
jsp = jsonencodeEx(allout,'PrettyPrint',true);
jsp_struct = jsondecodeEx(jsp);
jsp2 = jsonencodeEx(jsp_struct,'PrettyPrint',true);

% Write out float JSON metadata file
fid = fopen(def_file_ot,'w');
fprintf(fid,'%s\n',jsp2);
fclose(fid);
