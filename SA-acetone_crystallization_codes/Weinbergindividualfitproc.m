clear; clc; close all;
% This script loads the preprocessed crystallization data and fits the
% Weinberg crystallization model to each experimental curve by optimizing
% the parameter R/G .
% The parameter P1R is fixed. For each video, the fitted curve is plotted
% against the experimental data and saved as a .png file. All fit results
% are stored in a .mat file for further analysis.
%% -----------------------------
% BASE FOLDER
% -----------------------------
% Set baseFolder to the directory containing the preprocessed
% .mat file. The output figures and fit results are saved in a subfolder
% within baseFolder. 

baseFolder = 'C:\Users\aname\Documents\TFG\Análisis día 4 LAB';

% Set the .mat file name in the dataFile input call to match the
% output of the preprocessing script (use processed_crystallization_data_pp.mat
% for PP-coated slides experiments).
dataFile = fullfile(baseFolder, 'processed_crystallization_data.mat');

load(dataFile, 'processedData');

%% -----------------------------
% OUTPUT FOLDER
% -----------------------------
% The name can be changed to differentiate between bare glass slides and
% pp-coated slides. Eg:'Weinberg_fits_RoverG_only_pp'
outputFolder = fullfile(baseFolder, ...
    'Weinberg_fits_RoverG_only');

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

%% -----------------------------
% FIXED MODEL PARAMETERS
% -----------------------------
% Ny: number of points for numerical integration of the Weinberg curve
Ny = 160;
% P1R: fixed nucleation parameter (P1*R), set to 10/(2*pi) 
P1R_fixed = 10/(2*pi);

%% -----------------------------
% LOOP OVER PREPROCESSED DATA
% -----------------------------
fitResults = struct([]);
fitCounter = 0;
for i = 1:length(processedData)

    videoName = processedData(i).videoName;

    fprintf('\nProcessing %s...\n', videoName);

    %% -----------------------------
    % LOAD PREPROCESSED DATA
    % -----------------------------
    t_all = processedData(i).t_all;
    Xexp_all = processedData(i).Xexp_all;

    nFrames = processedData(i).nFrames;

    %% -----------------------------
    % FIT WINDOW
    % -----------------------------
    % The curve is already cropped and normalized in preprocessing
    
    t_fit = t_all;
    Xexp_fit = Xexp_all;
    
    t05_exp = timeAtX(Xexp_fit, t_fit, 0.5);
    %% -----------------------------
    % FIT ONLY RoverG
    % -----------------------------
    RoverG0 = 1.0;

    q0 = log(RoverG0);

    lb = log(1e-3);
    ub = log(1e3);

    resFun = @(q) residualWeinberg( ...
        exp(q), ...
        P1R_fixed, ...
        t_fit, ...
        Xexp_fit, ...
        t05_exp, ...
        Ny);

    useLsqnonlin = exist('lsqnonlin','file') == 2;

    if useLsqnonlin

        opts = optimoptions('lsqnonlin', ...
            'Display','off', ...
            'MaxFunctionEvaluations',800, ...
            'FunctionTolerance',1e-8, ...
            'StepTolerance',1e-10);

        qhat = lsqnonlin(resFun, q0, lb, ub, opts);

    else

        opts = optimset('Display','off', ...
            'MaxFunEvals',1500, ...
            'TolX',1e-8, ...
            'TolFun',1e-8);

        qhat = fminsearch(@(q) sum(resFun(q).^2), q0, opts);

    end

    RoverG_hat = exp(qhat);

    P1R_hat = P1R_fixed;

    [Xmod_fit, t0_hat, ~] = modelWeinbergAligned( ...
        RoverG_hat, ...
        P1R_hat, ...
        t_fit, ...
        t05_exp, ...
        Ny);
    residuals = Xmod_fit - Xexp_fit;

    % the error associated with each fitting as well as the mean error
    % associated with each regime is computed
    RMSE = sqrt(mean(residuals.^2, 'omitnan'));
    MAE  = mean(abs(residuals), 'omitnan');
    nPoints = sum(~isnan(residuals));

    fprintf('R/g = %.6g s\n', RoverG_hat);

    %% -----------------------------
    % COMPLETE WEINBERG CURVE
    % -----------------------------
    t_ref = t_fit(1);

    t_fit_plot = t_fit - t_ref;

    t05_plot = t05_exp - t_ref;

    y_plot = linspace(0,1,500);

    X_plot = weinbergX(y_plot, P1R_hat);

    X_plot = X_plot / max(X_plot);

    t_model_plot = t0_hat + RoverG_hat*y_plot;

    t_model_plot0 = t_model_plot - t_ref;

    y05_plot = timeAtX(X_plot, y_plot, 0.5);

    t05_model_plot = t0_hat + RoverG_hat*y05_plot;

    t05_model_plot0 = t05_model_plot - t_ref;
    
    %% -----------------------------
    % STORE FIT RESULT
    % -----------------------------
    fitCounter = fitCounter + 1;
    
    fitResults(fitCounter).videoName = videoName;
    fitResults(fitCounter).regime = processedData(i).regime;
    fitResults(fitCounter).folder = processedData(i).folder;
    
    fitResults(fitCounter).RoverG_hat = RoverG_hat;
    fitResults(fitCounter).P1R_hat = P1R_hat;
    fitResults(fitCounter).t0_hat = t0_hat;
    
    fitResults(fitCounter).t_exp = t_fit_plot;
    fitResults(fitCounter).X_exp = Xexp_fit;
    
    fitResults(fitCounter).t_model = t_model_plot0;
    fitResults(fitCounter).X_model = X_plot;
    
    fitResults(fitCounter).t05_exp = t05_plot;
    fitResults(fitCounter).t05_model = t05_model_plot0;
    
    fitResults(fitCounter).residuals = residuals;
    fitResults(fitCounter).RMSE = RMSE;
    fitResults(fitCounter).MAE = MAE;
    fitResults(fitCounter).nPoints = nPoints;

    %% -----------------------------
    % FIGURE
    % -----------------------------
    fig = figure('Visible','off');

    ax = gca;

    set(fig, 'Position', [100 100 1200 800]);

    %curveColor = lines(1);
    expColor = [0 0.4470 0.7410];      % blue MATLAB
    modelColor = [0.8500 0.3250 0.0980]; % orange MATLAB

    plot(t_fit_plot, Xexp_fit, 'o', ...
    'Color', expColor, ...
    'MarkerEdgeColor', expColor, ...
    'MarkerFaceColor', 'none', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 5);

    hold on;
    
    plot(t_model_plot0, X_plot, '-', ...
        'Color', modelColor, ...
        'LineWidth', 2.2);

    plot(t05_model_plot0, 0.5, 'ko', ...
        'MarkerFaceColor', 'k', ...
        'MarkerSize', 6);

    xline(t05_plot, '--', ...
        'LineWidth', 1.2);

    yline(0.5, '--', ...
        'LineWidth', 1.2);

    %% -----------------------------
    % FORMAT
    % -----------------------------
    grid on;

    set(ax, ...
        'TickLabelInterpreter', 'latex', ...
        'FontSize', 28, ...
        'LineWidth', 1);

    xlabel('$t - t_{\mathrm{start}}$ (s)', ...
        'Interpreter', 'latex', ...
        'FontSize', 34);

    ylabel('$X$', ...
        'Interpreter', 'latex', ...
        'FontSize', 34);

    legend({ ...
        'Experimental curve', ...
        'Weinberg curve', ...
        'Alignment point $X=0.5$'}, ...
        'Interpreter', 'latex', ...
        'Location', 'best');

    ylim([0 1]);

    yticks(0:0.2:1);

    xmin_data = min([t_fit_plot(:); t_model_plot0(:)]);
    xmax_data = max([t_fit_plot(:); t_model_plot0(:)]);
    
    % Left limit
    % if no curve begins before 0, the axis starts at 0
    % if a theoretical curve begins before 0, shift to the immediately lower 0.5 multiple
    if xmin_data >= 0
        xmin_plot = 0;
    else
        xmin_plot = 0.5 * floor(xmin_data / 0.5);
    end
    
    % Right limit:
    % shift to the upper 0.5 multiple
    xmax_plot = 0.5 * ceil(xmax_data / 0.5);
    
    if xmax_plot <= xmin_plot
        xmax_plot = xmin_plot + 0.5;
    end
    
    xlim([xmin_plot xmax_plot]);
    xticks(xmin_plot:0.5:xmax_plot);

    ax.Position = [0.12 0.15 0.82 0.75];

    hold off;

    %% -----------------------------
    % SAVE FIGURE
    % -----------------------------
    regimeFolder = processedData(i).folder;

    outputSubfolder = fullfile(outputFolder, regimeFolder);

    if ~exist(outputSubfolder, 'dir')
        mkdir(outputSubfolder);
    end

    outputFile = fullfile(outputSubfolder, ...
        [videoName '_crop.png']);

    exportgraphics(fig, outputFile, ...
        'Resolution', 300);

    close(fig);

end
fitResultsFile = fullfile(outputFolder, 'weinberg_fit_results.mat');

save(fitResultsFile, 'fitResults', '-v7.3');

fprintf('\nFit results saved in:\n%s\n', fitResultsFile);
fprintf('\nAll fits completed.\n');

%% FUNCTIONS
% Computes the residual vector between the Weinberg model and experimental data
function r = residualWeinberg(RoverG, P1R, t_fit, Xexp_fit, t05_exp, Ny)

    [Xmod_fit, ~, ~] = modelWeinbergAligned(RoverG, P1R, ...
                                            t_fit, t05_exp, Ny);

    r = Xmod_fit - Xexp_fit;
    r = r(:);

    bad = ~isfinite(r);

    if any(bad)
        r(bad) = 10;
    end
end

% Aligns the Weinberg model curve to the experimental data using the X=0.5 point
function [Xmod_fit, t0, t05_mod] = modelWeinbergAligned(RoverG, P1R, ...
                                                        t_fit, t05_exp, Ny)

    yv = linspace(0, 1, Ny);
    Xy = weinbergX(yv, P1R);

    Xy = Xy / max(Xy);

    y05 = timeAtX(Xy, yv, 0.5);

    t05_mod = RoverG * y05;

    t0 = t05_exp - t05_mod;

    t_rel = t_fit - t0;
    y = t_rel ./ RoverG;

    Xmod_fit = NaN(size(y));

    ok = (y >= 0) & (y <= 1);

    Xmod_fit(ok) = interp1(yv, Xy, y(ok), 'pchip');

end

% Computes the Weinberg crystallization curve X(y) by numerical integration
function X = weinbergX(yv, P1R)

    X1 = zeros(size(yv));

    for k = 1:numel(yv)

        y = yv(k);

        if y <= 0
            X1(k) = 0;
            continue;
        end

        integrand = @(V) V .* exp(-2*P1R .* ...
            acos(clamp01((1 + V.^2 - y.^2) ./ (2.*V))));

        Int = integral(integrand, 1-y, 1, ...
            'RelTol',1e-7, ...
            'AbsTol',1e-11);

        denom = 0.5 * (1 - (1 - y)^2);

        X1(k) = 1 - Int / max(denom, eps);
    end

    f1 = 1 - (1 - yv).^2;

    X = f1 .* X1;

    X = min(max(X, 0), 1);

end

% Clamps values to the range [-1, 1] to avoid domain errors in acos
function x = clamp01(x)

    x = max(min(x, 1), -1);

end

% Finds the time at which the curve X(t) reaches a target value Xtarget by linear interpolation
function tX = timeAtX(X, t, Xtarget)

    X = X(:);
    t = t(:);

    idx = find(X(1:end-1) <= Xtarget & X(2:end) >= Xtarget, ...
               1, 'first');

    if isempty(idx)
        [~, j] = min(abs(X - Xtarget));
        tX = t(j);
        return;
    end

    x1 = X(idx);
    x2 = X(idx+1);

    t1 = t(idx);
    t2 = t(idx+1);

    if abs(x2 - x1) < 1e-12
        tX = t1;
    else
        alpha = (Xtarget - x1) / (x2 - x1);
        tX = t1 + alpha * (t2 - t1);
    end

end