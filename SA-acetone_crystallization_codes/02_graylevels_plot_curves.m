clc
clear
close all

% This script loads the preprocessed crystallization data (from pand plots the
% normalized gray intensity curves over time for each video, color-coded
% by crystallization regime (edge-dominated vs spreading-dominated).
%
% Set the .mat file name in the load() call to match the
% output of the preprocessing script (use processed_crystallization_data_pp.mat
% for PP-coated slides experiments).
% =========================
% LOAD PROCESSED DATA
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

all_t = {};
all_I = {};
all_color = {};

% =========================
% LOOP THROUGH PROCESSED DATA
% =========================

for i = 1:length(processedData)

    videoName = processedData(i).videoName;
    regime    = processedData(i).regime;

    t_plot = processedData(i).t_all;
    I_norm = processedData(i).Xexp_all;

    % Ensure row vectors
    t_plot = t_plot(:)';
    I_norm = I_norm(:)';

    % Remove invalid values
    valid = ~isnan(t_plot) & ~isnan(I_norm);
    t_plot = t_plot(valid);
    I_norm = I_norm(valid);

    if length(t_plot) < 2
        warning('%s skipped: not enough valid points.', videoName);
        continue
    end

    % Force each curve to start at t = 0
    t_plot = t_plot - t_plot(1);

    % Color by regime
    if contains(lower(regime), 'edge')
        curveColor = edgeColor;
    elseif contains(lower(regime), 'spread')
        curveColor = spreadColor;
    else
        curveColor = [0.3 0.3 0.3];
    end

    all_t{end+1} = t_plot;
    all_I{end+1} = I_norm;
    all_color{end+1} = curveColor;

    plot(ax_main, t_plot, I_norm, '-o', ...
        'Color', curveColor, ...
        'LineWidth', 1.2, ...
        'MarkerSize', 3, ...
        'HandleVisibility', 'off');

    % text(t_plot(end), I_norm(end), videoName, ...
    % 'Interpreter','none', ...
    % 'FontSize',8);

end

% =========================
% LEGEND
% =========================

% change with PP if that is being analyzed
plot(ax_main, NaN, NaN, '-', ...
    'Color', edgeColor, ...
    'LineWidth', 2, ...
    'DisplayName', 'Edge-dominated');

plot(ax_main, NaN, NaN, '-', ...
    'Color', spreadColor, ...
    'LineWidth', 2, ...
    'DisplayName', 'Spreading-dominated');

% =========================
% MAIN PLOT FORMAT
% =========================

set(ax_main, ...
    'TickLabelInterpreter', 'latex', ...
    'FontSize', 17, ...
    'TickLength', [0.005 0.01], ...
    'LineWidth', 1);

xlabel(ax_main, 'Time (s)', ...
    'Interpreter', 'latex', ...
    'FontSize', 23);

ylabel(ax_main, 'Normalized gray intensity', ...
    'Interpreter', 'latex', ...
    'FontSize', 23);

ylim(ax_main, [0 1]);
yticks(ax_main, 0:0.2:1);

grid(ax_main, 'on');
box(ax_main, 'on');

legend(ax_main, ...
    'Interpreter', 'latex', ...
    'Location', 'best', ...
    'FontSize', 23);

set(fig, 'Color', 'w');
set(fig, 'Position', [100 100 1000 650]);
