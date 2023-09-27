% Dump a JSTON file to screen and put into struct.
%
% Demonstrates use of jsondecodeEx() function that fixes MATLAB's "array of struct
% or cell" ambiguity

clear jsall;

exlist = {
    'sensor-SBE-SBE41CP-11643.json'
    'sensor-AANDERAA-AANDERAA_OPTODE_4330-3901.json'
    'sensor-SATLANTIC-OCR504_ICSW-42139.json'
    'sensor-SATLANTIC-SUNA_V2-1527.json'
    'sensor-SBE-SBE41CP-11643.json'
    'sensor-SBE-SBE63-2739.json'
    'sensor-SBE-SEAFET-11341.json'
    'sensor-WETLABS-ECO_FLBBCD-3666.json'
    'sensor-WETLABS-MCOMS_FLBBCD-0157.json'
    'platform-TWR-APEX-7660.json'
    'float-SBE-NAVIS_EBR-1101.json'
    };

numex = length(exlist);
numex = 11
for kl = 1:numex
    fnin = exlist{kl};
    fid = fopen(fnin,'r');
    raw = fread(fid,inf);
    fclose(fid);
    str = char(raw(:)');
    clear js
    js = jsondecodeEx(str);
    fprintf(1,'\n\n%s\n',fnin);
    js
    jsall{kl}.js = js;
end

jsonencodeEx(jsall{numex}, "PrettyPrint", true)



