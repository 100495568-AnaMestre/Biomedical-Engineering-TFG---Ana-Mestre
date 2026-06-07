## Scripts

- `01_preprocessinggraylevels.m` — Processes all experimental videos, obtaining the evolution of gray intensity, and saves results to a .mat file.
- `02_graylevels_plot_curves.m` — Plots all the normalized gray intensity curves over time.
- `03_graylevels_plot_curves_normalized.m` — Plots normalized gray intensity against normalized time.
- `04_graylevels_velocity.m` — Computes and plots the crystallization rate (dI/dt).
- `05_weinberg_fit.m` — Fits the Weinberg model to each experimental curve.
- `06_weinberg_plot_all_fits.m` — Plots all experimental and fitted curves together and provides RMSE values.
- `ajusteElipse.m` — Auxiliary function for ellipse fitting using SVD.
