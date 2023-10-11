% function [val] = JSONtest(fname)

% fname = 'sensor-DRUCK-DRUCK_2900PSIA-11698373.json';
% fname = 'sensor-AANDERAA-AANDERAA_OPTODE_3830-498.json';
% fname = 'sensor-SBE-SBE41CP-13875.json';
fname = 'sensor-WETLABS-MCOMS_FLBBCD-0157.json'; 

% Read file as binary in one go and then convert to JSON char string 
fid = fopen(fullfile("examples",fname)); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 

% Decode JSON char string into struct
% val.argo{1:3}, val.vendor{1:2}
val = jsondecodeEx(str);

N_SENSOR = length(val.SENSORS);
N_PARAM  = length(val.PARAMETERS);

fprintf('SENSORS:\n');
for i = 1:N_SENSOR
    fprintf('%s\n', val.SENSORS{i}.SENSOR);
end

fprintf('\nPARAMETERS:\n');
for i = 1:N_PARAM
    fprintf('%s\n', val.PARAMETERS{i}.PARAMETER);
end