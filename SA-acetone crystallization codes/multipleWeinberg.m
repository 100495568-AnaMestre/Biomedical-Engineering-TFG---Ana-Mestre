clear; clc; %close all;
% This script loads the Weinberg fit results and plots all experimental
% and fitted curves together in a single figure, color-coded by video.
% It also computes and prints the mean RMSE per crystallization regime.
%
% Update the load() path to match the location of the
% weinberg_fit_results.mat file on your system (adjust to the location of
% weinberg_fit_resultspp.mat in the case of pp experiments)

load('C:\Users\aname\Documents\TFG\Análisis día 4 LAB\Weinberg_fits_RoverG_only\weinberg_fit_results.mat')

% The code line below is commented because it was used to improve some
% plotting in the document, however, it is still used.

% fitResults(strcmp({fitResults.videoName}, 'glass2_40')) = [];
%% -----------------------------
% RMSE BY REGIME
% -----------------------------
regimes = unique({fitResults.regime});

for r = 1:length(regimes)

    idx = strcmp({fitResults.regime}, regimes{r});

    RMSE_values = [fitResults(idx).RMSE];

    fprintf('\n%s\n', regimes{r});
    fprintf('Mean RMSE = %.4f ± %.4f\n', ...
        mean(RMSE_values), ...
        std(RMSE_values));

end

n = length(fitResults);

% Each video is assigned a distinct color using the turbo colormap
colors = turbo(n);

figure;
hold on;

for i = 1:n

    c = colors(i,:);
    ls = '-';

    % Experimental
    plot(fitResults(i).t_exp, fitResults(i).X_exp, 'o', ...
        'Color', c, ...
        'MarkerEdgeColor', c, ...
        'MarkerFaceColor', 'none', ...
        'LineWidth', 1.2, ...
        'MarkerSize', 4, ...
        'HandleVisibility', 'off');

    % Weinberg
    plot(fitResults(i).t_model, fitResults(i).X_model, ls, ...
        'Color', c, ...
        'LineWidth', 2, ...
        'DisplayName', fitResults(i).videoName);

end

grid on;
box on;

set(gca, ...
    'TickLabelInterpreter', 'latex', ...
    'FontSize', 17, ...
    'LineWidth', 1);

xlabel('$t - t_{\mathrm{start}}$ (s)', ...
    'Interpreter', 'latex', ...
    'FontSize', 23);

ylabel('$X$', ...
    'Interpreter', 'latex', ...
    'FontSize', 23);

ylim([0 1]);
yticks(0:0.2:1);
legend('Interpreter','latex', ...
       'Location','best', ...
       'FontSize',23);

set(gcf, 'Color', 'w');
set(gcf, 'Position', [100 100 1100 700]);