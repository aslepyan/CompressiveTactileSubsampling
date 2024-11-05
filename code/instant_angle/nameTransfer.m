function num = nameTransfer(str)
% Use regular expressions to extract number
% Check if the string contains a negative number (starts with '_n')
if contains(str, '_n')
    % Extract the numeric part after '_n' and convert to negative
    numStr = regexp(str, '_n(\d+)', 'tokens');
    num = -str2double(numStr{1}{1});  % Convert to negative number
else
    % Extract the numeric part after '_'
    numStr = regexp(str, '_(\d+)', 'tokens');
    num = str2double(numStr{1}{1});  % Convert to positive number
end
