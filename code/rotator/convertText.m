% This helper function is for converting text.
function output = convertText(input)
    % This function converts text like 'xxxx3p5V' to '3.5V'
    
    % Find where the digits and the 'p' (for decimal point) are located
    pattern = '\d+p\d+|\d+';
    numericPart = regexp(input, pattern, 'match', 'once');
    
    % Replace 'p' with '.' to create the decimal format
    if contains(numericPart, 'p')
        numericPart = strrep(numericPart, 'p', '.');
    end
    
    % Extract the trailing character (like 'V')
    trailingChar = regexp(input, '[A-Za-z]+$', 'match', 'once');
    
    % Combine the numeric part and the trailing character
    output = [numericPart trailingChar];
end
