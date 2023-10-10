fnin = 'sensor-AANDERAA-AANDERAA_OPTODE_4330-3901.json';

% simple demo of loading a json file and listing out the SENSOR and
% PARAMETER info contained in it


%read in the whole json file as a string, and convert it to a row vector.
fid = fopen(fnin);
raw = fread(fid,inf);
fclose(fid);
str = char(raw(:)'); 

% matlab built in function jsondecode converts json text to a matlab
% structure


js = jsondecodeEx(str);  % This version of jsonencode is needed because the 
% json files contain @context, which would generate invalid matlab names.
% @context is mapped to x_context on the way from json to matlab, and
% mapped back from x_context to @context on the way from matlab to json.


% Now print some things out as a demo

for ks = 1:length(js.SENSORS)
    js.SENSORS{ks}
end


for kp = 1:length(js.PARAMETERS)
    js.PARAMETERS{kp}
end

% and here is an example for one parameter extracted from the whole
% structure, complete with calibration coefficients.

doxy_info = js.PARAMETERS{4}
doxy_info.PREDEPLOYMENT_CALIB_COEFFICIENT_LIST
