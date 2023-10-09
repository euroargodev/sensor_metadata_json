fnin = 'sensor-AANDERAA-AANDERAA_OPTODE_4330-3901.json';

% simple demo of loading a json file and listing out the SENSOR and
% PARAMETER info contained in it



fid = fopen(fnin);
raw = fread(fid,inf);
fclose(fid);

str = char(raw(:)');
js = jsondecodeEx(str);

for ks = 1:length(js.SENSORS)
    js.SENSORS{ks}
end


for kp = 1:length(js.PARAMETERS)
    js.PARAMETERS{kp}
    js.PARAMETERS{kp}.PREDEPLOYMENT_CALIB_COEFFICIENT_LIST
end
