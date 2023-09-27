% function [val] = JSONtest(fname)

% fname = 'sensor-DRUCK-DRUCK_2900PSIA-11698373.json';
% fname = 'sensor-AANDERAA-AANDERAA_OPTODE_3830-498.json';
% fname = 'sensor-SBE-SBE41CP-13875.json';
fname = 'sensor-WETLABS-MCOMS_FLBBCDx-0157.json'; 

% Read file as binary in one go and then convert to JSON char string 
fid = fopen(fullfile("examples",fname)); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 

% Decode JSON char string into struct
% val.argo{1:3}, val.vendor{1:2}
val = jsondecode(str);

N_SENSOR = length(val.argo{1}.SENSOR);
N_PARAM  = length(val.argo{2}.PARAMETER);

fprintf('SENSOR:\n');
for i = 1:N_SENSOR
    fprintf('%s\n', val.argo{1}.SENSOR{i});
end

fprintf('\nPARAMETER:\n');
for i = 1:N_PARAM
    fprintf('%s\n', val.argo{2}.PARAMETER{i});
end

fprintf(1, '\nvendor:\n');
fprintf(1, '%s\n', val.vendor{1}.SENSOR_MAKER);