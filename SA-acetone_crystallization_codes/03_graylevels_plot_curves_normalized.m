clc
clear
close all
% This script loads the preprocessed crystallization data and plots the
% normalized gray intensity curves against normalized time for each video,
% color-coded by crystallization regime (edge-dominated vs spreading-dominated).
% Both axes are normalized to [0, 1], allowing direct comparison across
% experiments with different durations.
%
% Set the .mat file name in the load() call to match the
% output of the preprocessing script (use processed_crystallization_data_pp.mat
% for PP-coated slides experiments).
% =========================
% LOAD DATA
% =========================

load('processed_crystallization_data.mat', 'processedData');

% =========================
% COLORS
% =========================

% Colors assigned to each crystallization regime for visualization.
% These can be modified freely using RGB triplets in the range [0, 1].
edgeColor   = [0.85 0.10 0.10];
spreadColor = [0.10 0.25 0.85];

% =========================
% FIGURE
% =========================

fig = figure;
ax_main = axes(fig);
hold(ax_main, 'on');

% =========================
% LOOP THROUGH PROCESSED DATA TO OBTAIN THE VARIABLES
% =========================

for i = 1:length(processedData)

    videoName = processedData(i).videoName;
    regime    = processedData(i).regime;

    t = processedData(i).t_all;
    X = processedData(i).Xexp_all;

    % Ensure row vectors
    t = t(:)';
    X = X(:)';

    % Remove invalid points
    valid = ~isnan(t) & ~isnan(X);
    t = t(valid);
    X = X(valid);

    if length(t) < 2
        warning('%s skipped: not enough valid points.', videoName);
        continue
    end

    % =========================
    % TIME NORMALIZATION
    % Start = 0, End = 1
    % =========================

    t = t - t(1);

    if t(end) == 0
        warning('%s skipped: zero duration.', videoName);
        continue
    end

    t_norm = t / t(end);

    % =========================
    % COLOR BY REGIME
    % =========================

    if contains(lower(regime), 'edge')
        curveColor = edgeColor;
    elseif contains(lower(regime), 'spread')
        curveColor = spreadColor;
    else
        curveColor = [0.3 0.3 0.3];
    end

    % =========================
    % PLOT
    % =========================

    plot(ax_main, t_norm, X, '-o', ...
        'Color', curveColor, ...
        'LineWidth', 1.2, ...
        'MarkerSize', 3, ...
        'HandleVisibility', 'off');

end

% =========================
% LEGEND
% =========================

plot(ax_main, NaN, NaN, '-', ...
    'Color', edgeColor, ...
    'LineWidth', 2, ...
    'DisplayName', 'Edge-dominated');

plot(ax_main, NaN, NaN, '-', ...
    'Color', spreadColor, ...
    'LineWidth', 2, ...
    'DisplayName', 'Spreading-dominated');

% =========================
% FORMAT
% =========================

set(ax_main, ...
    'TickLabelInterpreter', 'latex', ...
    'FontSize', 17, ...
    'TickLength', [0.005 0.01], ...
    'LineWidth', 1);

xlabel(ax_main, 'Normalized time', ...
    'Interpreter', 'latex', ...
    'FontSize', 23);

ylabel(ax_main, 'Normalized gray intensity', ...
    'Interpreter', 'latex', ...
    'FontSize', 23);

xlim(ax_main, [0 1]);
ylim(ax_main, [0 1]);

xticks(ax_main, 0:0.2:1);
yticks(ax_main, 0:0.2:1);

grid(ax_main, 'on');
box(ax_main, 'on');

legend(ax_main, ...
    'Interpreter', 'latex', ...
    'Location', 'best', ...
    'FontSize', 23);
