# Beyond Transfers: Mobile Money and Deeper Financial Inclusion in Bangladesh

Replication code for an MSc dissertation using five waves of the World Bank Global
Findex for Bangladesh, 2011 to 2024.

Alvee Ahmed, MSc Development Finance, Global Development Institute, School of
Environment, Education and Development, The University of Manchester, 2026.

## What is here, and what is not

This repository contains one do-file and the log it produces. **It does not contain the
survey data.**

The Global Findex microdata are distributed through the World Bank Microdata Library
under terms of use which state that data obtained from the Library

> shall not be redistributed or sold to other individuals, institutions, or
> organizations without the prior written agreement of the Microdata Library or the
> originating repository.

That applies to the five Bangladesh release files and equally to the pooled file built
from them, which is a reorganised copy of the same 5,000 unit records. The terms do
permit reporting aggregated results, which is what the published log contains, and
they permit the data to be used as a foundation for further work, which is what the
code here describes. So the code and the output are public; the records are not.

## Getting the data

Register (free) at <https://microdata.worldbank.org> and download the Bangladesh files
for all five waves:

| Wave | Catalogue entry |
|---|---|
| 2011 | Global Financial Inclusion (Global Findex) Database 2011 |
| 2014 | Global Financial Inclusion (Global Findex) Database 2014 |
| 2017 | Global Financial Inclusion (Global Findex) Database 2017 |
| 2021 | Global Findex Database 2021 |
| 2024 | The Global Findex Database 2025 (2024 fieldwork) |

## Rebuilding the pooled file

The analysis runs on one file, `pooled_findex_bgd_keyed_v2.csv`: 5,000 observations,
1,000 per wave. To rebuild it:

1. Take 1,000 respondents from each wave's Bangladesh file.
2. Construct the analytic variables per Table 3.1 of the dissertation.
3. Carry `wpid_random` from 2014 onward. The 2011 release has no identifier of any
   kind; align that wave positionally and use it for descriptive trends only.
4. For 2017, take `account_fin` from the released constructed variable (418 positives)
   and `saved_fin` from `fin17a` (109 positives). An earlier build read the 2017 text
   values incorrectly and returned zero for both across the whole wave.
5. Keep the within-country survey weight as `wgt`.

**The pooling step in the original work was done outside Stata and is not itself a
script.** This is a real gap in the replication chain and is stated as such in
Appendix A.3 of the dissertation. What stands in for it is verification: Part 0 of the
do-file asserts the sample size, the per-wave counts, the respondent keys and both 2017
repair counts, and halts if any of them fails. A rebuilt file that passes Part 0 will
reproduce the published results.

Row alignment of the original pooled file was checked against all five source releases
on three independent fields: the weight sequence, age, and the gender label.

## Running the analysis

One do-file, one log.

```
do findex_bgd_master.do
```

Edit the `cd` line at the top first. The file reproduces every number and every table
in Chapters 4 and 5, every methodological figure quoted in Chapter 3 and every
robustness check, in one pass, and writes `findex_bgd_master_log.txt`. Each block is
labelled with the place in the dissertation where its result appears, so the log can be
read against the chapters directly, and Part 10 prints a one-line-per-figure checklist.

Requires Stata 17 or later and the user-written commands `fairlie` and `oaxaca`
(`ssc install fairlie`, `ssc install oaxaca`). The published results were produced with
`fairlie` version 1.0.7 (16 June 2008) and `oaxaca` version 4.1.1 (24 April 2023), both
by Ben Jann; Part 6.9 of the log records this. A later SSC release may differ.

| File | What it is |
|---|---|
| `findex_bgd_master.do` | The analysis. Everything is here. |
| `findex_bgd_master_log.txt` | The unedited log that file produces |
| `LICENSE` | MIT licence for the code |
| `.gitignore` | Blocks the microdata from being committed by accident |

### Map of the do-file

| Part | What it produces |
|---|---|
| 0 | Data integrity, with assertions that halt on failure |
| 1 | Table 4.1, weighted indicators by wave |
| 2 | Table 4.2, H1 saving, borrowing and merchant payment |
| 2A | Section 4.3.1, whether the saving association changed across waves |
| 3 | Section 4.3.2, why digital payment is not reported |
| 4 | Section 4.3.3, the bank-account control and the unbanked subsample |
| 5 | Table 4.3, H2 income heterogeneity |
| 6 | Table 4.4, H3 gender decomposition, Oaxaca and Fairlie |
| 7 | Table 4.5, H4 device category and connectivity |
| 7.6 | Whether the two adjacent device steps differ |
| 8 | Table 4.6, adjusted wave differences |
| 9 | Appendix C, Table C.2: weighting and 2011 robustness checks |
| 10 | Cross-check list, one line per reported figure |

This file replaces the five do-files used while the analysis was being built
(`findex_master_verification.do`, `findex_corrections.do`, `findex_verify_all.do`,
`findex_weighting_robustness.do`, `findex_fairlie_ro.do`). Nothing was dropped except
two specifications those files themselves replaced: unweighted probits estimated with
the default OIM variance estimator, which confounded weighting with the variance
estimator and are re-run with `vce(robust)` in Part 9, and an H4 specification using
overlapping `has_phone`, `smartphone` and `internet` indicators, which Section 4.6
rejects because it lets the model evaluate device combinations that do not exist. Both
exclusions are explained in the file at the point where the replacement runs.

## Conventions

- Every model uses `[pw=wgt]`, normalised to mean one within each wave.
- Adoption always enters as `i.account_mob`, so `margins` returns the discrete change
  from zero to one rather than a derivative.
- Standard errors are robust. The released microdata carries no primary sampling unit
  identifier, so they cannot be clustered as the multistage design would require; the
  net direction of that omission is unknown. See Section 3.6.1 of the dissertation.
- `set seed 20260914`, so the 1,000 replications behind the non-linear decomposition
  reproduce exactly.
- Part 6.9 of the do-file records the installed `fairlie` and `oaxaca` versions with
  `which`, and checks that `fairlie` honours `[pw=wgt]` rather than discarding the
  weights. Implementations differ, so the log is the authority for which one produced
  the published decomposition.

## Citing the data

Demirgüç-Kunt, A. and Klapper, L. (2012) *Measuring Financial Inclusion: The Global
Findex Database*. Policy Research Working Paper 6025. Washington, DC: World Bank.

Klapper, L., Singer, D., Starita, L. and Norris, A. (2025) *The Global Findex Database
2025: Connectivity and Financial Inclusion in the Digital Economy*. Washington, DC:
World Bank.

The five Bangladesh releases, as cited in the dissertation:

World Bank (2012) *Global Financial Inclusion (Global Findex) Database 2011: Bangladesh*.
Ref. BGD_2011_FINDEX_v02_M. Washington, DC: World Bank. doi: 10.48529/s0z6-ps24.

World Bank (2015) *Global Financial Inclusion (Global Findex) Database 2014: Bangladesh*.
Ref. BGD_2014_FINDEX_v01_M. Washington, DC: World Bank. doi: 10.48529/9a52-dt47.

World Bank (2018) *Global Financial Inclusion (Global Findex) Database 2017: Bangladesh*.
Ref. BGD_2017_FINDEX_v02_M. Washington, DC: World Bank. doi: 10.48529/rv7t-ng66.

World Bank (2022) *Global Financial Inclusion (Global Findex) Database 2021: Bangladesh,
2022*. Ref. BGD_2021_FINDEX_v02_M. Washington, DC: World Bank. doi: 10.48529/qda7-6z97.

World Bank (2025) *The Global Findex Database 2025: Connectivity and Financial Inclusion in
the Digital Economy, Bangladesh 2024*. Ref. BGD_2024_FINDEX_v02_M. Washington, DC: World
Bank. doi: 10.48529/n6gt-g858.

## Licence

Code in this repository is released under the MIT licence; see `LICENSE`. The Global
Findex data are not covered by that licence and are not distributed here.
