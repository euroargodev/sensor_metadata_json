function value = remove_nvs_tablenum(value)

% remove NVS table reference if it occurs at the start of a string
% eg SDN:R01::xxxx

if length(value) < 10; return; end % short string can't contain table number plus other characters
test_str = value([1 2 3 4 5 8 9]); % ignore chars 6 and 7 which are the table number

if strcmp(test_str,'SDN:R::')
    value = value(10:end);
end


return
end