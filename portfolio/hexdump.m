%%%
% DESCRIPTION:
% Function hexdump() takes in a 2-dimensional array and creates an ASCII hex
% dump. It returns the dump as a 2-dimensional character array with the same
% number of rows as the input. The width of the output is such that the
% individual element values are fully expressed in hex characters, with
% delimiting.
%
% It is recommended to convert hexdump() output to a string vector using
% cellstr() for increased flexibility, such as pre-pending a header line with an
% arbitrary number of characters.
%
% For very large arrays, call hexdump() on subarrays.
%
% REQUIRED INPUT:
% data_array              A numeric typed, 2D array to be converted.
%
% OPTIONAL INPUTS:
% Any of the following key-value pairs.
%
% 'elemsizebyte', value   Size, in 8-bit bytes, of data contained in the array.
%                         (Ex: 'elemsizebyte',1 if data are 8-bit.) (Default=1)
% 'delimiter', value      Delimiting string to place after each value.
%                         (Default=',')
% 'dumpfile', value       Name of a file to dump the ASCII hex into.
%                         (Default=none)
% 'writemethod', value    File writing permission, as supported by fopen().
%                         I.e., 'w' for overwrite or 'a' for append. Append
%                         is recommended if a large array is to be hex dumped
%                         to file as smaller subarrays.
% OUTPUT:
% A structure with the following field name:
%
% 'dump'                  Field value is a 2D character array of ASCII hex.
%
% USAGE:
%
% dump = hexdump(...
%     tlm_data, ...
%     'elemsizebyte', 16, ...
%     'delimiter', '\t', ...
%     'dumpfile', 'dump.txt', ...
%     'writemethod', 'w'
% )
%
%%%
function dump = hexdump(data_array, varargin)
    % Parse the optional key-value pair inputs
    if nargin > 1
        if boolean(mod(length(varargin), 2))
            disp('Warning, odd number of optional key-value arguments.')

    % Retrieve the value following each supported key name, or set a default
    else
        valueId = find(strcmp('elemsizebyte', varargin)) + 1;
        if ~isempty(value_id)
            elemSizByte = varargin{valueId};
        else
            elemSizByte = 1;
        end
        valueId = find(strcmp('delimiter', varargin)) + 1;
        if ~isempty(value_id)
            delim = varargin{valueId};
        else
            delim = ',';
        end
        valueId = find(strcmp('dumpfile', varargin)) + 1;
        if ~isempty(value_id)
            dumpFile = varargin{valueId};
        else
            dumpFile = false;
        end
        valueId = find(strcmp('writemethod', varargin)) + 1;
        if ~isempty(value_id)
            writeMethod = varargin{valueId};
        else
            writeMethod = 'w';
        end
    end

    % Get row and column sizes of the array
    [nRows, nCols] = size(data_array);

    % Calculate num. of characters required to express the value of one element
    elemSizChar = 2*elemSizByte;

    % Get size of the delimiter string
    delimSizChar = length(delim);

    % Construct the character array
    dump = reshape(...
        [...
            dec2hex(data_array', elemSizChar)'; ...
            repmat(delim, delimSiz, nCols*nRows)' ...
        ], ...
        nCols*(elemSizChar + delimSizChar), nRows ...
    );

    % Dump to a file, if requested
      if dump_fname
        % Open the file with `writeMethod` as the permission
        [fid, message] = fopen(dumpFile, writeMethod);
        disp(message)

        % Iterate over the rows and dump them
        for i = 1:nRows
            fprintf(fid, '%s', dump(i,:));
        end

        % Close the file
        fclose(fid);
      end
  end
