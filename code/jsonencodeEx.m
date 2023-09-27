%jsonencodeEx Create JSON-formatted text from structured MATLAB data.
%
%   TEXT = jsonencodeEx(TYPE) returns a character vector TEXT in JSON format that
%   encodes MATLAB data TYPE as a JSON data type
%
%   Extra functionality  converts "x_context" to "@context" after JSON encoding.
%   See also jsonencode


function json = jsonencodeEx(type, options)

    arguments
        type    struct 
        options.PrettyPrint (1,1) logical = false
        options.ConvertInfAndNaN (1,1) logical = true
    end

    % undo jsondecode of "@context" to "x_context"  
    % (Matlab struct fielnames cannot begin with "@")
    json = regexprep( ...
        jsonencode(type, ...
            'PrettyPrint', options.PrettyPrint, ...
            'ConvertInfAndNaN', options.ConvertInfAndNaN), ...
                'x_context', '@context');

    return
end