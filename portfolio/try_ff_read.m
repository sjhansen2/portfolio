% Clear the workspace
clear

% Close all plots, clear the command line
close all
clc


% Some test cases
try
    % Define a test case
    ffName = 'generic_telemetry_rf_link_file.ff';
    wdSizBit = 16;
    frmSizWd = 900;
    getWds = [...
        ... % Frame ID and some other telemetry words of interest
        800, ...
        4, 64, 508, 509, 900, ...
    ];
    frmStart = 3901;
    frmStop = 100000;
    frmStride = 4;
    dumpFile = 'hexdump.txt';

    tlm_struct = ff_read(...
        ... % Required inputs
        ffName, frmSizWd, wdSizBit, ...
        ... % Optional inputs
        'getwords', getWds, ...
        'firstframe', firstFrame, ...
        'lastframe', lastFrame, ...
        'framestride', frmStride, ...
        'dumpfile', dumpFile, ...
        'writemethod, 'w' ...
    );

catch me
    disp('An error was caught.')
    disp(me)
end

