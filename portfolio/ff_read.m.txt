%%%
% DESCRIPTION
% Read a "full frame" format telemetry file into the workspace and, optionally,
% dump the data to a file as ASCII hex characters.
%
% For very large telemetry files, it is recommended to call ff_read() on subsets
% of telemetry frames using 'firstframe' and 'lastframe' arguments.
%
% REQUIRED INPUTS:
% ffName  The complete path name of the full frame file.
% frmSizWd  The number of data words per telemetry frame.
% wdSizBit  The number of bits per data word.
%
% OPTIONAL INPUTS:
% Any of the following inputs may be specified as key-value pairs.
% 
% 'getwords', value      Vector of word numbers to be retrieved. They will be
%                        returned in order of request. (Default = entire frame)
% 'firstframe', value    Number of the first frame to be retrieved.
%                        (Default = 1)
% 'lastframe', value     Number of the last frame to be retrieved.
%                        (Default = last complete frame in the file)
% 'framestride', value   Periodicity of frames to retrieve. E.g., every 4th
%                        frame. Useful for subcommutated telemetry data.
%                        (Default = 1, for every frame)
% 'dumpfile', value      File name to dump ASCII hex into. (Default = none)
%
% 'writemethod', value   A file permission setting supported by fopen(), i.e.,
%                        'w' for overwrite or 'a' for append. Appending is
%                        recommended when dumping large files in chunks.
%                        Note: when an append method is selected, the header row
%                        will not be dumped.  (Default = 'w')
%
% OUTPUT:
% A structure with the following fields:
%
% 'frame_num'           A column vector with the frame numbers that were read.
% 'time'                A column vector with the frame times of day, in seconds.
% 'quality'             An n x 2 vector where the columns are the upper byte and
%                       lower byte of the 16-bit frame quality structure values.
% 'value'               An n x m double precision array of the telemetry  word
%                       values, where `n` is the number of frames retrieved and
%                       `m` is the number of words.
%
% USAGE:
%
% ffName = 'generic_telemetry_rf_link_file.ff';
% frmSizWd = 900;
% wdSizBit = 16;
% getWds = [...
%     ... % Frame ID and some other words of supposed interest
%     800, ...
%     4, 64, 508, 509, 900, ...
% ];
% frmStart = 3901;
% frmStop = 100000;
% frmStride = 4;
% dumpFile = 'hexdump.txt';
%
% tlm_struct = ff_read(...
%     ... % Required inputs
%     ffName, frmSizWd, wdSizBit, ...
%     ... % Optional inputs
%     'getwords', getWds, ...
%     'firstframe', firstFrame, ...
%     'lastframe', lastFrame, ...
%     'framestride', frmStride, ...
%     'dumpfile', dumpFile, ...
%     'writemethod, 'w' ...
% );
%
%%%
function tlm_struct = ff_read(ffName, frmSizWd, wdSizBit, varargin)

    % Parse the optional key-value pair arguments, if received
    if nargin > 1
        if boolean(mod(length(varargin), 2))
            disp('Warning, odd number of optional key-value arguments.')

    % Retrieve the value following each supported key name, or set a default
    else
        valueId = find(strcmp('getwords', varargin)) + 1;
        if ~isempty(value_id)
            getWds = varargin{valueId};
        else
            getWds = 1;
        end
        valueId = find(strcmp('firstframe', varargin)) + 1;
        if ~isempty(value_id)
            frmStart = varargin{valueId};
        else
            frmStart = ',';
        end
        valueId = find(strcmp('lastframe', varargin)) + 1;
        if ~isempty(value_id)
            lastFrame = varargin{valueId};
        else
            lastFrame = false;
        end
        valueId = find(strcmp('writemethod', varargin)) + 1;
        if ~isempty(value_id)
            writeMethod = varargin{valueId};
        else
            writeMethod = 'w';
        end
    end

    % Open the file as read-only, big-endian
    [fid, message] = fopen(ffName, 'r', 'b');
    disp(message)

    % Alert with the file size
    fseek(fid, 0, 'eof');
    fBytes = ftell(fid);
    fprintf(1, 'Input file size is %0.1f MB.\n', fBytes/1024^2);

    % Each data frame is suffixed by a frame-tag packet with four 16-bit bytes.
    % Byte 1 contains the frame quality fields, 2-4 are frame time fields.
    % Reference Full Frame Technical Manual
    packetSizBit = 64;

    % Each telemetry word is packed into an integer number of 8-bit bytes, padded on
    % the left with zero-valued bits
    ff_wdSizByte = ceil(wdSizBit/8);
    ff_wdSizBit = 8 * ff_wdSizByte;

    % Calculate the number of bits in the data-word portion of one frame
    dataSizBit = frmSizWd * ff_wdSizBit;

    % Calculate the total number of 8-bit bytes per frame
    frmSizBit = dataSizBit + packetSizBit;

    % Calculate the number of 8-bit bytes per frame
    byteSizBit = 8;
    frmSizByte = frmSizBit/byteSizBit;

    % If 'lastframe' was not specified:
    if ~frmStop
        % Read to the end of the file
        frmStop = floor(fBytes/frmSizByte);
    end

    % Calculate the total number of frames & bytes to read
    nFrames = floor((frmStop - (frmStart-1)) / frmStride;
    nBytes = nFrames * frmSizByte;

    % Position file pointer at first frame
    frmOffset = (frmStart-1)*frmSizByte;
    fseek(fid, frmOffset, 'bof');

    % Read the requested frames
    precision = sprintf('%0.0f*uint8=>uint8', frmSizByte);
    skip = frmSizByte*(frmStride - 1);
    fprintf(1, 'Reading %0.1f MB...\n', nBytes/1024^2)
    tic
    data = fread(fid, nBytes, precision, skip);
    fprintf(1, 'Read completed in %0.3f sec\n', toc);
    fclose(fid);

    % Recalculate number of frames in case EOF was encountered
    nFrames = length(data)/frmSizByte;

    % Reshape `data` so that rows are frames, columns are bytes
    data = reshape(data, frmSizByte, nFrames)';

    % Force getWds into a column vector and get its length
    getWds = getWds(:);
    nWds = length(getWds);

    % Calculate offsets to the locations of the bytes containing the words of
    % interest within one frame
    byteOffsets = reshape(...
        (...
            ... % `n` duplicate columns for the `n` bytes per word
            repmat((getWds-1)*ff_wdSizByte, 1, ff_wdSizByte) + ...
            ... % Increment across cols so each row points to all bytes of that
			... % word
            repmat((1:ff_wdSizByte), nWds, 1) ...
        )', ...
        % Reshape the array back into a 1D list
        nWds*ff_wdSizByte, 1 ...
    );

    % Append offsets to the frame-tag packet bytes that follow every data-frame
    byteOffsets = [byteOffsets; frmSizWd*(wdSizBit/byteSizBit) + (1:8)'];

    % Slice-copy the frame-tag packet columns off the RH side of the `data`
	% array
    time = data(:, byteOffsets(end-5:end-0));
    quality = data(:, byteOffsets(end-7:end-6));

    % Slice `data` down to just the bytes containing the data-words of interest
    data = data(:, byteOffsets(1:end-8));

    % The frame time structure is 12, four-bit (unsigned) fields that represent
    % 10s of hrs, 1s of hrs, 10s of mins, 1s of mins, 10s of secs, 1s of secs,
    % .1s of secs, .01s of secs, ... and so on down to the .000001s of secs
    timeScales = [36e3,36e2, 6e2,6e1, 1e1,1e0, 1e-1,1e-2,1e-3,1e-4,1e-5,1e-6];

    % Instantiate a vector for time-of-day, in seconds
    tod = zeros(nFrames, 1);

    % Iterate over the six 8-bit bytes in the time structure
    for i = 1:6
        % Iterate over the two 4-bit fields in this byte
        for j = 1:2
            % Add this field's contribution to the time of day
            tod = tod + timeScales(2*(i-1) + j) * ...
                ... Scrub the bits around to isolate this field, in the 4 LSBs
                double(bitshift(bitshift(time(:,i), 4*(j-1)), -4) ...
            ;
        end
    end

    % Instantiate an array to contain all telemetry word values in all frames
    tlm = double(zeros(nFrames, nWds));

    % Iterate over the telemetry words
    for thisWd = 1:nWds

        % Construct an in-frame index to the 8-bit bytes spanned by this word
        thisBytes = (thisWd-1)*ff_wdSizByte + (1:2);

        % Instantiate array to contain this tlm. word's values in all frames
        wdVals = double(zeros(nFrames, 1));

        % Iterate over however-many 8-bit bytes one telemetry word spans
        for i = 1:ff_wdSizByte
            % Left-shift the upper bytes the correct amount
            shift = byteSizBit * (ff_wdSizByte - i);

            % Add this byte's contribution to the word value
            wdVals = wdVals + ...
                double(bitshift(double(data(:, thisBytes(i))), shift)) ...
            ;
        end

        % Store the time series of values for this word in the `tlm` array
        tlm(:, thisWd) = wdVals;
    end

    % Construct a frame number vector
    frmNum = frmStart + frmStride*((1:nFrames)'-1);

    % Done with `data`
    clear data

    % Compile a structure to return
    tlm_sruct = struct(...
        'frame_num', frmNum, ...
        'time', tod, ...
        'quality', quality, ...
        'value', tlm ...
    );


    %%% ASCII DUMP

    % Construct an ASCII hex character array of `tlm` using hexdump(). Each row
    % contains one frame of telemetry
    delim = ',';
    dump = (hexdump(tlm, 'elemsizebyte',ff_wdSizByte, 'delimiter',delim);

    % Convert it to a cell vector of strings (the rows)
    dump = cellstr(dump);

    % Construct an ASCII dump of the frame-tag information
    format = [...
        '%06.0f',delim, '%04.6f',delim, '%03.0f',delim, '%03.0f',delim, '\n' ...
    ];
    for i = 1:nFrames
        packet_dump = fprintf(...
            1, format, frmNum(i), tod(i), quality(i,1), quality(i,2) ...
        );
    end

    % Horizontally concatenate the frame-tag and data-word dumps
    dump = strcat(packet_dump, dump);

    % Construct a header row
    format = [...
        'Frame_Num', delim, 'Time(sec)', delim, ...
        'Qual_Wd_1', delim, 'Qual_Wd_2', delim, ...
        repmat(['04.0f', delim], 1, nWds), ...
        '\n' ...
    ];
    header = fprintf(1, format, getWds(:));

    % Pre-pend the header row to `dump`
    dump = [header; dump];

    % Dump to `stdout`, always
    fid(1) = 1;

    % If dump file output was requested:
    if dumpFile
        % Open the file with permission = `writeMethod`.
        [fid(2), message] = fopen(dumpFile, writeMethod);
        disp(message)
    end

    % Iterate over the dump destinations
    for i = 1:length(fid)
        % Get this destination's identification
        thisFid = fid(i);

        % If this destination is `stdout`:
        if thisFid == 1
            % Only dump the header + 30 frames
            nHead = 31;
        else
            % Dump all frames
            nHead = 1 + nFrames;
        end
        
        % Print the header and some frames
        fprintf(thisFid, '%s', dump{1:nHead})
    end
end
