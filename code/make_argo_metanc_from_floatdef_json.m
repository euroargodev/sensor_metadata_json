function m = make_argo_metanc_from_floatdef_json(float_id,dirnames)
%
% USE:
%  m = make_argo_metanc_from_floatdef_json(float_id,[dirnames])

% This script will read in a complete float json file and reorganise the
% shape of the contents to match what is required in an Argo meta.nc file
% OUTPUT:
%  m is a structure array that contains much of what is needed for an Argo
%  meta.nc file.
%
%  In addition to returning m as an output, the script will write a NetCDF
%  file to the directory identifed by dirnames.nc_meta
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
%  break.%
%
% dirnames is a structure that carries the location of directories for input and output files
%
% fieldnames in the dirnames structure can be any or all or none of
% dirnames.json_floats (used for input json file)
% dirnames.nc_meta     (used for output meta.nc file)
%
% if dirnames.json_floats is not defined, it is assumed to be the current directory
% if dirnames.nc_meta is not defined, it is assumed to be hthe same as dirnames.floats
%
% if the dirnames argument is omitted altogether, then all input and output files will be assumed to be in the current directory
%
%
%
% Matlab script to get everything ready for an Argo NetCDF meta file,
% starting with a floatdef json file that contains info about platform,
% sensors and parameters
%
% platform metadata are those that could be supplied by the platform maker, ie not mission specific.
%
% draft by BAK 20 Jan 2023
% revised BAK 4 Oct 2023
%
% An example floatdef json file could be
% float-SBE-NAVIS_EBR-1101.json
% in which case this is called with
% m = make_argo_metanc_from_floatdef_json('float-SBE-NAVIS_EBR-1101.json')
%
% The returned argument m is a structure containing the fields needed for
% an Argo meta.nc file, that should match the field names in the Argo users
% manual
%
% The field needed in an Argo meta.nc file is
% PREDEPLOYMENT_CALIB_COEFFICIENT
% This field is constructed inside this script from the fieldnames in
% PREDEPLOYMENT_CALIB_COEFFICIENT_LIST in the input json file
%

% First call a progam to create all the empty spaces for a complete argo
% nectdf meta file. This creates a structure m, which has all the needed
% fields.

if nargin < 2; dirnames.json_floats = '.'; end

if ~isfield(dirnames,'json_floats'); dirnames.json_floats = '.'; end
if ~isfield(dirnames,'nc_meta'); dirnames.nc_meta = dirnames.json_floats; end


make_empty_argo_meta

% Define the fields we expect to read in from a floatdef json file.
% These are matched up with the dimensions defined by the Argo users manual

fnin = [dirnames.json_floats '/float-' float_id '.json']; % input json file
fnot = [dirnames.nc_meta '/float-' float_id '_meta.nc']; % output netcdf file

fid = fopen(fnin);
raw = fread(fid,inf);
fclose(fid);

str = char(raw(:)');
js = jsondecodeEx(str);

clear def

def.platform_argo_fields = {
    16  'DATA_TYPE'
    256 'PTT'
    16  'TRANS_SYSTEM'
    32  'TRANS_SYSTEM_ID'
    16  'TRANS_FREQUENCY'
    8   'POSITIONING_SYSTEM' % can be more than one. If more than one,
    % it will need some sort of dimension
    % maybe do transmission system here too
    256 'PLATFORM_FAMILY'
    32  'PLATFORM_TYPE'
    256 'PLATFORM_MAKER'
    32  'FIRMWARE_VERSION'
    32  'FLOAT_SERIAL_NO'
    4   'WMO_INST_TYPE'
    64  'BATTERY_TYPE'
    64  'BATTERY_PACKS'
    32  'CONTROLLER_BOARD_TYPE_PRIMARY'
    32  'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'
    32  'CONTROLLER_BOARD_TYPE_SECONDARY'
    32  'CONTROLLER_BOARD_SERIAL_NO_SECONDARY'
    };

def.platform_nonargo_fields = {
    };

def.sensor_argo_fields = {
    32  'SENSOR'
    256 'SENSOR_MAKER'
    256 'SENSOR_MODEL'
    16  'SENSOR_SERIAL_NO'
    };

def.sensor_nonargo_fields = {
    'SENSOR_FIRMWARE_VERSION' % not an argo field
    };

def.parameter_argo_fields = {
    64 'PARAMETER'
    128 'PARAMETER_SENSOR'
    32 'PARAMETER_UNITS'
    32 'PARAMETER_ACCURACY'
    32 'PARAMETER_RESOLUTION'
    4096 'PREDEPLOYMENT_CALIB_EQUATION'
    4096 'PREDEPLOYMENT_CALIB_COEFFICIENT'
    4096  'PREDEPLOYMENT_CALIB_COMMENT'
    };

def.parameter_nonargo_fields ={
    'PREDEPLOYMENT_CALIB_DATE' % not an argo field
    'PREDEPLOYMENT_CALIB_COEFFICIENTS' % a structure
    };


% Now write the metadata from json into the m structure

clear m

fields = def.platform_argo_fields;
nfield = size(fields,1);
N_TRANS_SYSTEM = 0;
N_TRANS_SYSTEM_ID = 0;
N_TRANS_FREQUENCY = 0;
for kl = 1:nfield
    fieldname = fields{kl,2};
    fieldlen = fields{kl,1};
    if ~isfield(js.PLATFORM,fieldname)
        fprintf(2,'%s %s %s\n','Expected platform fieldname',fieldname,'not found, filling with blanks');
        vv = [];
        vv = [vv repmat(' ',1,fieldlen-length(vv))];
        value = vv;
    else
        % TRANS_SYSTEM and POSITIONING_SYSTEM can have multiple values, so
        % the arrays may need an extra dimension
        switch fieldname
            case 'POSITIONING_SYSTEM'
                N_POSITIONING_SYSTEM = length(js.PLATFORM.POSITIONING_SYSTEM);
                clear value
                for kpos = 1:N_POSITIONING_SYSTEM
                    vv = js.PLATFORM.POSITIONING_SYSTEM{kpos};
                    vv = remove_nvs_tablenum(vv);
                    vv = [vv repmat(' ',1,fieldlen-length(vv))];
                    value(kpos,:) = vv;
                end
            case 'TRANS_SYSTEM'
                N_TRANS_SYSTEM = length(js.PLATFORM.TRANS_SYSTEM);
                clear value
                for ktrans = 1:N_TRANS_SYSTEM
                    vv = js.PLATFORM.TRANS_SYSTEM{ktrans};
                    vv = remove_nvs_tablenum(vv);
                    vv = [vv repmat(' ',1,fieldlen-length(vv))];
                    value(ktrans,:) = vv;
                end
            case 'TRANS_SYSTEM_ID'
                N_TRANS_SYSTEM_ID = length(js.PLATFORM.TRANS_SYSTEM_ID);
                clear value
                for ktrans = 1:N_TRANS_SYSTEM_ID
                    vv = js.PLATFORM.TRANS_SYSTEM_ID{ktrans};
                    vv = remove_nvs_tablenum(vv);
                    vv = [vv repmat(' ',1,fieldlen-length(vv))];
                    value(ktrans,:) = vv;
                end
            case 'TRANS_FREQUENCY'
                N_TRANS_FREQUENCY = length(js.PLATFORM.TRANS_FREQUENCY);
                clear value
                for ktrans = 1:TRANS_FREQUENCY
                    vv = js.PLATFORM.TRANS_FREQUENCY{ktrans};
                    vv = remove_nvs_tablenum(vv);
                    vv = [vv repmat(' ',1,fieldlen-length(vv))];
                    value(ktrans,:) = vv;
                end
            otherwise
                vv = js.PLATFORM.(fieldname);
                vv = remove_nvs_tablenum(vv);
                vv = [vv repmat(' ',1,fieldlen-length(vv))];
                value = vv;
        end
    end
    m.(fieldname) = value;
end

% If any of
% TRANS_SYSTEM
% TRANS_STSTEM_ID
% TRANS_FREQUENCY
% has been found with dimension greater than 1, then pad them all to that
% dimension with blanks. Do it here outside the loop in case oen of the TRANS fields is not
% defined in the input file. In due course those might become mandatory in
% the json file.

nmax = max([N_TRANS_SYSTEM N_TRANS_SYSTEM_ID N_TRANS_FREQUENCY]);
m.TRANS_SYSTEM(N_TRANS_SYSTEM+1:nmax,:) = repmat(' ',nmax-N_TRANS_SYSTEM,16);
% m.TRANS_SYSTEM_ID(N_TRANS_SYSTEM_ID+1:nmax,:) = repmat(' ',nmax-N_TRANS_SYSTEM_ID,32);
% m.TRANS_FREQUENCY(N_TRANS_FREQUENCY+1:nmax,:) = repmat(' ',nmax-N_TRANS_FREQUENCY,16);
n_TRANS_SYSTEM = nmax;



fields = def.sensor_argo_fields;
nfield = size(fields,1);
for kl = 1:nfield
    fieldname = fields{kl,2};
    fieldlen = fields{kl,1};
    num_s = length(js.SENSORS);
    for ks = 1:num_s
        if ~isfield(js.SENSORS{ks},fieldname)
            fprintf(2,'%s %s %s %3d %s\n','Expected sensor fieldname',fieldname,'not found in sensor',ks,'filling with blanks');
            value = [];
        else
            value = js.SENSORS{ks}.(fieldname);
        end
        value = remove_nvs_tablenum(value);
        value = [value repmat(' ',1,fieldlen-length(value))];
        m.(fieldname)(ks,:) = value;
    end
end

fields = def.parameter_argo_fields;
nfield = size(fields,1);

% First, make the PREDEPLOYMENT_CALIBRATION_COEFFICIENT from the
% PREDEPLOYMENT_CALIBRATION_COEFFICIENT_LIST
nparam = length(js.PARAMETERS);

for kpar = 1:nparam
    list = js.PARAMETERS{kpar}.PREDEPLOYMENT_CALIB_COEFFICIENT_LIST; % this should be a structure whose fildnames are calibration coefficient names and whose values are string representation of the coefficient values
    cnames = fieldnames(list);
    coefstr = [];
    for kc = 1:length(cnames)
        cnam = cnames{kc};
        cval = list.(cnames{kc});
        % if cval is not a string, make it one
        if ischar(cval)
            valstr = cval;
        else
            % assume cval is an array of real numbers
            cval = cval(:)';
            b1 = '';
            b2 = '';
            if length(cval) > 1
                b1 = '['; % make brackets for arrays
                b2 = ']';
            end
            valstr = [];
            for kv = 1:length(cval)
                val = cval(kv);
                if val-round(val) == 0
                    % integer
                    valstr1 = sprintf('%d',val);
                else
                    valstr1 = sprintf('%17.10e',val); % use e notation with 10 decimal places
                end
                valstr = [valstr ' ' valstr1];
            end
            valstr = [b1 valstr b2];

        end
        coefstr = [coefstr cnam ' = ' valstr ' ; '];
    end
    if length(coefstr) > 4096
        fprintf(2,'%s\n','PREDEPLOYMENT_CALIB_COEFFICIENT string too long')
        return
    end
    vv = [coefstr repmat(' ',1,4096-length(coefstr))];
    js.PARAMETERS{kpar}.PREDEPLOYMENT_CALIB_COEFFICIENT = vv;
end

for kl = 1:nfield
    fieldname = fields{kl,2};
    fieldlen = fields{kl,1};
    num_p = length(js.PARAMETERS);
    for kp = 1:num_p
        if ~isfield(js.PARAMETERS{kp},fieldname)
            fprintf(2,'%s %s %s %3d %s\n','Expected parameter fieldname',fieldname,'not found in parameter',kp,'filling with blanks');
            value = [];
        else
            value = js.PARAMETERS{kp}.(fieldname);
        end
        value = remove_nvs_tablenum(value);
        value = [value repmat(' ',1,fieldlen-length(value))];
        m.(fieldname)(kp,:) = value;
    end
end

% The strcuture m is now ready to have its fields written to an Argo NetCDF
% meta file, using whatever NetCDF toolbox you like


n.N_SENSOR = size(m.SENSOR,1);
n.N_PARAM = size(m.PARAMETER,1);


ncid = netcdf.create(fnot,'CLOBBER');
% dimensions of strings

dimnamesd = fieldnames(d);
numdimd = length(dimnamesd)
dimidsd = nan(numdimd,1);
for kl = 1:numdimd
    dimname = dimnamesd{kl};
    dimval = d.(dimname);
    dimidsd(kl) = netcdf.defDim(ncid,dimname,dimval);
end

% other dimensions

dimnamesn = fieldnames(n);
numdimn = length(dimnamesn)
dimidsn = nan(numdimn,1);
for kl = 1:numdimn
    dimname = dimnamesn{kl};
    dimval = n.(dimname);
    dimidsn(kl) = netcdf.defDim(ncid,dimname,dimval);
end

%variables

varnames = fieldnames(m);
numvar = length(varnames)
varids = nan(numvar,1);

netcdf.endDef(ncid);

for kl = 1:numvar
    varname = varnames{kl};
    varval = m.(varname);
    varsize = size(varval);



    if strcmp('FIRMWARE_VERSION',varname)
        varval = [varval repmat(' ',1,1000)];
        varval = varval(1:32);
        varsize = size(varval);
    end

    if strncmp('SENSOR',varname,6)
        dimid1 = netcdf.inqDimID(ncid,'N_SENSOR');
        required_stringdim = ['STRING' sprintf('%d',varsize(2))];
        dimid2 = netcdf.inqDimID(ncid,required_stringdim);
    elseif strncmp('PARAMETER',varname,9)
        dimid1 = netcdf.inqDimID(ncid,'N_PARAM');
        required_stringdim = ['STRING' sprintf('%d',varsize(2))];
        dimid2 = netcdf.inqDimID(ncid,required_stringdim);
    elseif strncmp('PREDEPLOYMENT',varname,13)
        dimid1 = netcdf.inqDimID(ncid,'N_PARAM');
        required_stringdim = ['STRING' sprintf('%d',varsize(2))];
        dimid2 = netcdf.inqDimID(ncid,required_stringdim);
    else
        dimid1 = netcdf.inqDimID(ncid,'STRING1');
        required_stringdim = ['STRING' sprintf('%d',varsize(2))];
        try dimid2 = netcdf.inqDimID(ncid,required_stringdim);
        catch
            dimid2 = netcdf.inqDimID(ncid,'DATE_TIME');
        end

    end
    netcdf.reDef(ncid);
    varids(kl) = netcdf.defVar(ncid,varname,2,[dimid1 dimid2]); % data type 2 is 'nc_char'
    netcdf.endDef(ncid);
    try  netcdf.putVar(ncid,varids(kl),varval);
    catch
        %        keyboard
    end


end


netcdf.close(ncid)

% this doesnt work yet with the few meta parameters that are double
% values instead of char, eg lat and lon

end


