[![Launch App](https://img.shields.io/badge/Launch-app-blue?style=for-the-badge&logo=R)](https://rodmarsh.github.io/effect-size-benchmark-explorer/) *(Cmd/Ctrl + Click to open in a new tab)*

# Effect-Size Benchmark Explorer

Hydrological alteration and ecological change are both, at base, questions about magnitude relative to a reference regime. In hydrology, the reference regime is the natural envelope of flow variability. In ecology, it is the natural distribution of ecological states. In both cases the central question is not only whether a difference can be detected, but whether the shift is large relative to natural variability — large enough to be ecologically consequential.

This is an interactive Shiny app for comparing Cohen's generic effect-size benchmarks against ecohydrology-specific thresholds in the literature. Designed as an instructional tool to help users understand how different benchmark frameworks classify the same standardised effect size.

## Running the app

From the project root:

```r
shiny::runApp("R/shiny_effect_size_benchmarks")
```

## Features

### Controls

- **Effect size (d)** — slider (0–3) sets the separation between baseline and scenario distributions
- **Coefficient of variation (CV)** — slider (0.2–2.0) controls how Richter presumptive thresholds map to d (d = %Δ / CV)
- **Distribution family** — Normal, Log-normal, or Gamma; switches the density curves and recalculates empirical VDA/Cliff's δ for non-normal families
- **Cliff's δ thresholds** — toggle between Vargha & Delaney (2000): 0.11 / 0.28 / 0.43 and Romano et al. (2006): 0.147 / 0.33 / 0.474
- **Benchmark toggles** — show/hide individual benchmark rows

### Panels

1. **Distributional overlap** — baseline (blue) vs scenario (red) density curves at the selected d, with a subtitle showing d, VDA, δ, and Cohen classification
2. **Benchmark comparison ruler** — up to five rows showing how the current d maps onto each framework:
   - **Cohen's *d*** — negligible / small / medium / large
   - **Cliff's δ** — thresholds from the selected reference (V&D or Romano)
   - **Richter RVA** — ±1 SD natural envelope
   - **Richter presumptive** — 10% and 20% change thresholds scaled by CV
   - **Nathan stress score (Vic Gov)** — no concern / some concern / relatively greater concern / high concern

A red indicator line marks the current d value on the ruler.

### Sidebar metrics

Computed values update in real time: d, VDA, Cliff's δ, % change at the selected CV, non-overlapping area, and categorical classifications for Cohen, Cliff, and Nathan.

## Dependencies

- shiny
- bslib
- ggplot2

## References

### Effect-size frameworks
- Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences*. 2nd ed. Lawrence Erlbaum.
- Cliff, N., 1993. Dominance statistics: Ordinal analyses to answer ordinal questions. Psychological bulletin 114, 494.
- Vargha, A. & Delaney, H.D. (2000). A critique and improvement of the CL common language effect size statistics of McGraw and Wong. *Journal of Educational and Behavioral Statistics*, 25(2), 101–132.
- Romano, J., Kromrey, J.D., Coraggio, J. & Skowronek, J. (2006). Exploring methods for evaluating group differences on the NSSE and other surveys: Are the t-test and Cohen's d indices the most appropriate choices? *Annual Meeting of the Southern Association for Institutional Research*.

### Ecohydrology benchmarks
- Richter, B.D., Baumgartner, J.V., Powell, J. & Braun, D.P. (1996). A method for assessing hydrologic alteration within ecosystems. *Conservation Biology*, 10(4), 1163–1174.
- Richter, B.D., Baumgartner, J.V., Wigington, R. & Braun, D.P. (1997). How much water does a river need? *Freshwater Biology*, 37(1), 231–249.
- Richter, B.D., Davis, M.M., Apse, C. & Konrad, C. (2012). A presumptive standard for environmental flow protection. *River Research and Applications*, 28(8), 1312–1321.
- Fowler, K., Horne, A., John, A., Nathan, R., Morden, R., Bond, N., Campion, N., 2025. Hydrological analysis to support decision making in Victoria’s unregulated rivers, Unregulated rivers management framework development. University of Melbourne, Melbourne.
- Swirepik, J.L., Burns, I.C., Dyer, F.J., Neave, I.A., O’Brien, M.G., Pryde, G.M., Thompson, R.M., 2016. Establishing Environmental Water Requirements for the Murray–Darling Basin, Australia’s Largest Developed River System. River Res. Applic. 32, 1153–1165.
- Murray‐Darling Basin Authority, 2011. The proposed ‘environmentally sustainable level of take’ for surface water of the Murray–Darling Basin:Method and outcomes, MDBA publication. Murray‐Darling Basin Authority, Canberra.


### Guide to effect sizes in biology

- Nakagawa, S., Cuthill, I.C., 2007. Effect size, confidence interval and statistical significance: a practical guide for biologists. Biological Reviews 82, 591–605. https://doi.org/10.1111/j.1469-185X.2007.00027.x


### Cliff's delta in hydrology

- Köplin, N., Rößler, O., Schädler, B., Weingartner, R., 2014. Robust estimates of climate-induced hydrological change in a temperate mountainous region. Climatic Change 122, 171–184.
- Abbott, K.M., Zaidel, P.A., Roy, A.H., Houle, K.M., Nislow, K.H., 2022. Investigating impacts of small dams and dam removal on dissolved oxygen in streams. PLOS ONE 17, e0277647.




