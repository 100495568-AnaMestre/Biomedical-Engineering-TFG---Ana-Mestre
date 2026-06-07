clc
clear
close all

% This script loads the preprocessed crystallization data and plots the
% crystallization rate (dI/dt) over time for each video, computed as the
% derivative of the normalized gray intensity curve, color-coded by crystallization regime.
%
% Set the .mat file name in the load() call to match the
% output of the preprocessing script (use processed_crystallization_data_pp.mat
% for PP-coated slides experiments).

% =============================
% LOAD DATA
% =============================

load('processed_crystallization_data.mat', 'processedData');

% =============================
% PARAMETERS
% =============================

% Colors assigned to each crystallization regime for visualization.
% These can be modified freely using RGB triplets in the range [0, 1].
edgeColor   = [0.85 0.10 0.10];
spreadColor = [0.10 0.25 0.85];

% smooth_window: number of frames used for moving average smoothing before derivation
% m: half-window size for the central difference derivative
% These values allow to soften the experimental noise from the videos. As
% all the data from the project is obtained experimentally this derivation
% procedure is quite noisy and needs to be smoothed.
smooth_window = 5;
m = 5;

% =============================
% FIGURE
% =============================

figure;
hold on;

% =============================
% LOOP THROUGH DATA
% =============================

for i = 1:length(processedData)

    videoName = processedData(i).videoName;
    regime    = processedData(i).regime;

    FrameRate = processedData(i).FrameRate;

    
    Inorm = processedData(i).Xexp_all;
    t     = processedData(i).t_all;

    Inorm = Inorm(:)';
    t     = t(:)';

    % =============================
    % DERIVATIVE
    % =============================
    % The intensity curve is first smoothed using a moving average to reduce
    % noise. The derivative is then computed using a central finite difference
    % scheme with half-window m:
    %       dI/dt ≈ (I(k+m) - I(k-m)) / (2*m*dt)

    A = movmean(Inorm, smooth_window);

    dt = 1 / FrameRate;
    n = length(A);

    if n <= 2*m

        warning('%s skipped: not enough points.', ...
                videoName);

        continue

    end

    k_vals = (1+m):(n-m);

    t_der = t(k_vals);
    %Time is shifted to start at zero. 
    % Note that the first m points are lost due to the central difference scheme.
    t_der = t_der - t_der(1);

    dAdt = (A(k_vals+m) - A(k_vals-m)) ...
          /(2*m*dt);

    % =============================
    % COLOR
    % =============================

    if contains(lower(regime),'edge')

        curveColor = edgeColor;

    elseif contains(lower(regime),'spread')

        curveColor = spreadColor;

    else

        curveColor = [0.3 0.3 0.3];

    end

    % =============================
    % PLOT
    % =============================

    plot(t_der, dAdt, '-o', ...
        'Color', curveColor, ...
        'LineWidth', 1.2, ...
        'MarkerSize', 3, ...
        'HandleVisibility', 'off');
    % text(t_der(end), dAdt(end), videoName, ...
    % 'Interpreter','none', ...
    % 'FontSize',8);

end

% =============================
% LEGEND
% =============================

plot(NaN,NaN,'-', ...
    'Color',edgeColor, ...
    'LineWidth',2, ...
    'DisplayName','Edge-dominated');

plot(NaN,NaN,'-', ...
    'Color',spreadColor, ...
    'LineWidth',2, ...
    'DisplayName','Spreading-dominated');

% =============================
% FORMAT
% =============================

set(gca, ...
    'TickLabelInterpreter','latex', ...
    'FontSize',17, ...
    'LineWidth',1);

xlabel('Time (s)', ...
    'Interpreter','latex', ...
    'FontSize',23);

ylabel('$dI/dt\;(s^{-1})$', ...
    'Interpreter','latex', ...
    'FontSize',23);

grid on;
box on;

legend('Interpreter','latex', ...
       'Location','best', ...
       'FontSize',23);

set(gcf,'Color','w');
set(gcf,'Position',[100 100 1000 650]);
