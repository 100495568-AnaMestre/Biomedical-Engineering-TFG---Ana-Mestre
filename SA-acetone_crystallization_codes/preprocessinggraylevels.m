clc; clear; close all;
% This script processes all experimental videos, previously classified 
% by crystallization regime, extracts the gray intensity evolution within 
% an elliptical mask fitted to the droplet, and saves the results to a 
% .mat file for further analysis.

% Before running, set the baseFolder variable to the path  
% of the folder containing the experimental videos, and the outputFile 
% variable to the desired output .mat file name.
%% =========================
% BASE FOLDER
% =========================

% Set baseFolder to the directory containing the experimental videos.
% Set outputFile to the desired path and name for the output .mat file.
% For PP-coated slides, rename the output file accordingly, for example:
% outputFile = fullfile(baseFolder, 'processed_crystallization_data_pp.mat');

baseFolder = 'C:\Users\aname\Documents\TFG\Análisis día 4 LAB';
outputFile = fullfile(baseFolder, 'processed_crystallization_data.mat');

%% =========================
% DATASETS
% =========================
% Firstly, the experiments in each folder are saved with a specific
% structure which is relevant for the analysis: 'videoname', threshold,
% framestart, frameend; (framestart and frameend refer to the frames of the
% video in which crystallization starts and ends)

% If pp-coated slides experiments were to be analyzed, the folder would
% change as well as the specific parameters. From then on, the processing
% will be the same 

% These are the specific values for my bare glass slides videos:
datasets(1).folder = 'edges';
datasets(1).name   = 'Edge-dominated';
datasets(1).params = {
    'glass2_1.1', 20, 21, 116
    'glass2_15',  26, 12, 111
    'glass2_30',  21, 16, 90
    'glass2_32',  28, 11, 98
    'glass2_34',  28, 8, 109
    'glass2_36',  27, 10, 74
    'glass2_38',  24, 14, 108
    'glass2_40',  27, 10, 208
    %'glass2_41',  27, 41, 169
    'glass2_46',  24, 4, 69
    'glass2_48',  27, 9, 82
};

datasets(2).folder = 'none';
datasets(2).name   = 'Spreading-dominated';
datasets(2).params = {
    'glass2_1.2', 27, 11, 61
    'glass2_3',   27, 29, 59
    'glass2_5',   27, 21, 56
    'glass2_6',   27, 20, 53
    'glass2_7',   26, 10, 45
    'glass2_8',   27, 10, 59
    'glass2_12',  22, 12, 52
    'glass2_16',  28, 7, 37
    'glass2_19',  25, 21, 93
    'glass2_35',  26, 7, 64
};

%% =========================
% PREPROCESS VIDEOS
% =========================
% From here on, the videos are processed. To start with, the frames are
% limited according to the parameters.

processedData = struct([]);
counter = 0;

for d = 1:length(datasets)

    folderName = datasets(d).folder;
    regimeName = datasets(d).name;
    params = datasets(d).params;

    for i = 1:size(params,1)

        videoName = params{i,1};
        glthr = params{i,2};
        frame_start_default = params{i,3};
        frame_end_default = params{i,4};

        videoFile = fullfile(baseFolder, folderName, [videoName '_crop.avi']);

        fprintf('\nProcessing %s...\n', videoName);

        if ~exist(videoFile, 'file')
            warning('Video not found: %s', videoFile);
            continue;
        end

        video = VideoReader(videoFile);
        nFrames = floor(video.Duration * video.FrameRate);

        if isinf(frame_end_default)
            frame_end_mask = nFrames;
        else
            frame_end_mask = min(frame_end_default, nFrames);
        end

        %% -----------------------------
        % Elliptical mask from final frame
        % ----------------------------
        % In this section the elliptical mask is built. Firstly, the code
        % iterates along the columns of the last frame of the video to find
        % those pixels over the set threshold.

        I_last = read(video, frame_end_mask);
        Igray_last = im2gray(I_last);

        im = Igray_last;
        [rows, columns] = size(im);
        yc = zeros(2, columns);
        kc = 0;

        for cl = 1:columns
            gl = im(:, cl);
            if any(gl > glthr)
                kc = kc + 1;
                yc(1, kc) = find(gl > glthr, 1, 'first');
                yc(2, kc) = find(gl > glthr, 1, 'last');
            end
        end

        if kc < 5
            warning('Not enough points for ellipse fitting in %s', videoName);
            continue;
        end

        x = 1:kc;
        y_top = yc(1, 1:kc);
        y_bot = yc(2, 1:kc);

        x_all = [x x];
        y_all = [y_top y_bot];

        % vector are built according to the those points in the last frame
        % that are over the threshold, and the ellipse is built.
        % ajusteElipse is an auxiliary function that fits an ellipse to the set of
        % points using Singular Value Decomposition (SVD).

        paramsEllipse = ajusteElipse(x_all', y_all');

        A = paramsEllipse(1);
        B = paramsEllipse(2);
        C = paramsEllipse(3);
        D = paramsEllipse(4);
        E = paramsEllipse(5);
        F = paramsEllipse(6);

        [cols, fils] = meshgrid(1:columns, 1:rows);
        % mask is built according to the parameters obtained from the
        % function ajusteElipse

        mask = (A*cols.^2 + B*cols.*fils + C*fils.^2 + ...
                D*cols + E*fils + F) < 0;

        %% -----------------------------
        % Grey intensity extraction
        % -----------------------------
        nFrames_used = frame_end_default - frame_start_default + 1;

        gris_vec = zeros(1, nFrames_used);
        
        video.CurrentTime = ...
            (frame_start_default - 1) / video.FrameRate;
        % The mask goes over limited the frames of the video and stores the
        % values of the gray levels in gris_vec
        
        for kk = 1:nFrames_used
        
            I = readFrame(video);
        
            Igray = im2gray(I);
        
            gris_vec(kk) = sum(Igray(mask));
        
        end
        GI_0 = gris_vec(1);
        GI_max = max(gris_vec);
        % the value of gray is normalized between 0 and 1.
        
        Xexp_all = (gris_vec - GI_0) / (GI_max - GI_0);
        
        Xexp_all = max(0, Xexp_all);
        Xexp_all = min(Xexp_all, 1);
        
        % and the time axis is set
        t_all = (frame_start_default:frame_end_default);
        
        t_all = (t_all - frame_start_default)/ video.FrameRate;

        %% -----------------------------
        % All the data is stored
        % -----------------------------
        counter = counter + 1;

        processedData(counter).videoName = videoName;
        processedData(counter).regime = regimeName;
        processedData(counter).folder = folderName;
        processedData(counter).videoFile = videoFile;

        processedData(counter).glthr = glthr;
        processedData(counter).frame_start_default = frame_start_default;
        processedData(counter).frame_end_default = frame_end_default;

        processedData(counter).FrameRate = video.FrameRate;
        processedData(counter).nFrames = nFrames;

        processedData(counter).t_all = t_all;
        processedData(counter).Xexp_all = Xexp_all;
        processedData(counter).gris_vec = gris_vec;

        processedData(counter).ellipseParams = paramsEllipse;
        processedData(counter).mask = mask;

    end
end

save(outputFile, 'processedData', '-v7.3');

fprintf('\nPreprocessing completed.\n');
fprintf('Data saved in:\n%s\n', outputFile);