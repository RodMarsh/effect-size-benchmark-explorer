[![Launch App](https://img.shields.io/badge/Launch-app-blue?style=for-the-badge&logo=R)](https://rodmarsh.github.io/effect-size-benchmark-explorer/) *(Cmd/Ctrl + Click to open in a new tab)*

This is an interactive Shiny app for comparing Cohen's generic effect-size benchmarks against ecohydrology-specific thresholds from the literature and benchmarks used in Australian jurisdictions. Designed as tool to help users compare how different benchmark frameworks classify the same standardised effect size.

# Effect-Size benchmark explorer - rationale

Hydrological alteration and ecological change are both, at base, questions about magnitude relative to a reference regime. In hydrology, the reference regime is usually the natural envelope of flow variability. In ecology, it is the natural distribution of ecological states. In both cases the central question is not only whether a difference can be detected, but whether the shift is large enough to matter.

Effect sizes address help address these two related questions: if an effect is real, how large is it? And is it large enough to matter practically? They quantify the magnitude of separation between two distributions or conditions, helping distinguish meaningful differences from merely detectable ones. Effect sizes are increasingly recommended as best practice for reporting change in ecology, biology, and hydrology because they speak directly to biological or ecological relevance in a way that *p*-values cannot. As Nakagawa and Cuthill (2007) put it, "all biologists should ultimately be interested in biological importance, which can be assessed from the magnitude of an effect but not from its statistical significance."

The conventional Cohen's *d* benchmarks are widely used as interpretive reference points: values of 0.2, 0.5, and 0.8 correspond roughly to small (one-fifth of a standard deviation), medium (one-half), and large (four-fifths) shifts between conditions. Analogous benchmarks exist for other effect-size measures — Cliff's δ, MAD-scaled effect size, and log response ratio. Cohen himself noted that these benchmarks were somewhat arbitrary and recommended them only in the absence of a better domain-specific basis for interpretation; nonetheless they remain widely used.

An effect size cannot be interpreted in isolation. It requires scientific judgement informed by the study question, the precision of the estimate, the responses being measured, the consequences of those changes, and the condition of the system being studied. Interpreting effect sizes means placing results in context — often asking whether the observed effect is smaller than, larger than, or broadly comparable to effects reported in similar work.

When expressed on a common effect-size scale, a range of different frameworks used to assess hydrological alteration in Australia reveal markedly different implicit tolerances for hydrological change. Cohen’s benchmarks treat relatively small distribution shifts as meaningful, with “large” effects beginning around $d \approx 0.8$. Non-parametric thresholds based on Cliff’s δ align closely with this interpretation. By contrast, ecohydrological frameworks are calibrated to much greater natural variability. The default Richter RVA target allows indicator values to vary within roughly one natural standard deviation ($|d| \le 1$), while the Nathan stress-score framework as used in recent advice to support Victorian Government decision making does not indicate ecological concern until distribution overlap has already declined substantially (approximately $d \gtrsim 0.6$), with higher stress categories corresponding to very large separations. Viewed together, these benchmarks illustrate that hydrological assessment frameworks implicitly tolerate much larger statistical shifts than are typically considered meaningful in many other empirical disciplines, reflecting the inherently high variability of river systems and the expectation that ecological communities are adapted to that variability.

## Running the app

From the project root:

```r
shiny::runApp("R/shiny_effect_size_benchmarks")
```

## Features

### Controls

- **Effect size (d)** — slider (0–3) sets the separation between baseline and scenario distributions
- **Distribution family** — Normal, Log-normal, or Gamma; switches the density curves and recalculates empirical VDA/Cliff's δ for non-normal families
- **Cliff's δ thresholds** — toggle between Vargha & Delaney (2000): 0.11 / 0.28 / 0.43 and Romano et al. (2006): 0.147 / 0.33 / 0.474
- **Benchmark toggles** — show/hide individual benchmark rows

### Panels

1. **Distributional overlap** — baseline (blue) vs scenario (red) density curves at the selected d, with a subtitle showing d, VDA, δ, and Cohen classification
2. **Benchmark comparison ruler** — up to five rows showing how the current d maps onto each framework:
   - **Cohen's *d*** — negligible / small / medium / large
   - **Cliff's δ** — thresholds from the selected reference (V&D or Romano)
   - **Richter RVA (default)** — ±1 SD natural envelope
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
- Nathan, R.J., McMahon, T.A., Peel, M.C., Horne, A., 2019. Assessing the degree of hydrologic stress due to climate change. Climatic Change 156, 87–104.
- Fowler, K., Horne, A., John, A., Nathan, R., Morden, R., Bond, N., Campion, N., 2025. Hydrological analysis to support decision making in Victoria’s unregulated rivers, Unregulated rivers management framework development. University of Melbourne, Melbourne.
- Swirepik, J.L., Burns, I.C., Dyer, F.J., Neave, I.A., O’Brien, M.G., Pryde, G.M., Thompson, R.M., 2016. Establishing Environmental Water Requirements for the Murray–Darling Basin, Australia’s Largest Developed River System. River Res. Applic. 32, 1153–1165.
- Murray‐Darling Basin Authority, 2011. The proposed ‘environmentally sustainable level of take’ for surface water of the Murray–Darling Basin:Method and outcomes, MDBA publication. Murray‐Darling Basin Authority, Canberra.
- MDBA, 2010. *Guide to the proposed Basin Plan: technical background.* Murray-Darling Basin Authority.
- Guarino F and Sengupta A. 2023. Basin-scale evaluation of 2021–22 Commonwealth environmental water: Hydrology. Flow-MER
Program. Commonwealth Environmental Water Holder, Department of Climate Change, Energy, the Environment and Water.
- NSW DPIE. 2023. River condition index: method report. NSW Department of Planning and Environment.

### Guide to effect sizes in biology and ecology

- Nakagawa, S., Cuthill, I.C., 2007. Effect size, confidence interval and statistical significance: a practical guide for biologists. Biological Reviews 82, 591–605. 
- Popovic, G., Mason, T.J., Drobniak, S.M., Marques, T.A., Potts, J., Joo, R., Altwegg, R., Burns, C.C.I., McCarthy, M.A., Johnston, A., Nakagawa, S., McMillan, L., Devarajan, K., Taggart, P.L., Wunderlich, A., Mair, M.M., Martínez-Lanfranco, J.A., Lagisz, M., Pottier, P., 2024. Four principles for improved statistical ecology. Methods in Ecology and Evolution 15, 266–281. https://doi.org/10.1111/2041-210X.14270
- Popovic, G., Mason, T.J., Drobniak, S.M., Marques, T.A., Potts, J., Joo, R., Altwegg, R., Burns, C.C.I., McCarthy, M.A., Johnston, A., Nakagawa, S., McMillan, L., Devarajan, K., Taggart, P.L., Wunderlich, A., Mair, M.M., Martínez-Lanfranco, J.A., Lagisz, M., Pottier, P., 2024. Four principles for improved statistical ecology. Methods in Ecology and Evolution 15, 266–281. https://doi.org/10.1111/2041-210X.14270
- Methratta, E.T., 2025. Effect size as a measure of biological relevance for offshore wind impact studies. ICES Journal of Marine Science 82, fsaf022. https://doi.org/10.1093/icesjms/fsaf022

### Cliff's delta in hydrology

- Köplin, N., Rößler, O., Schädler, B., Weingartner, R., 2014. Robust estimates of climate-induced hydrological change in a temperate mountainous region. Climatic Change 122, 171–184.
- Abbott, K.M., Zaidel, P.A., Roy, A.H., Houle, K.M., Nislow, K.H., 2022. Investigating impacts of small dams and dam removal on dissolved oxygen in streams. PLOS ONE 17, e0277647.




