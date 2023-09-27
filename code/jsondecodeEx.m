%jsondecodeEx Decode JSON-formatted text
%
%   VALUE = jsondecodeEx(TEXT) decodes a character vector TEXT in JSON format.
%   VALUE depends on the data encoded in the JSON-formatted text. 
%
%   Extra functionality that with ALWAYS decodes top-level JSON properties 
%   from struct array to cell array (which MATLAB does itself sometimes anyway)
%   Then you can always access properties like this: 
%       js.SENSORS{ks}
%       js.PARAMETERS{kp}
% 
%   Note that this conversion is limited to top-level - it is NOT recursive.
%   See also jsondecode

function js = jsondecodeEx(str)

    arguments
        str string
    end
    
    % Decode string
    js = jsondecode(str);

    % Check each field name for an array of structs of length > 1
    % If so, convert array elements to cell array
    % For certain fields to always be cell array: SENSORS, PARAMETERS,
    % sensor_info_list
    fnames = fieldnames(js);

    for iname = 1:length(fnames)
        fname = fnames{iname};
        S = js.(fname);
        [N, ~] = size(S);
        if (N > 1) || strcmp(fname, 'SENSORS') ...
                   || strcmp(fname, 'PARAMETERS') ... 
                   || strcmp(fname, 'sensor_info_list') 
            SS = {};
            if isstruct(S)
                for ks = 1:length(S)
                    % Copy each array element from struct array to cell array
                    SS{ks, 1} = S(ks);
                end
                js.(fname) = SS;
            end
        end
    end
end