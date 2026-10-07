*==============================================================================
* FINDEX BANGLADESH: MASTER ANALYSIS FILE
* Beyond Transfers: Mobile Money and Deeper Financial Inclusion in Bangladesh
* Alvee Ahmed, MSc Development Finance, University of Manchester, 2026
*
* Reproduces every result in Chapters 3 to 5 and Appendices B and C in one run.
* Each block names where its result appears and the value reported there.
* Replaces five earlier files: findex_master_verification, findex_corrections,
* findex_verify_all, findex_weighting_robustness and findex_fairlie_ro.
*
* INPUT     pooled_findex_bgd_keyed_v2.csv, 5,000 obs, 1,000 per wave. Not
*           published: World Bank terms bar redistribution (Appendix A.2).
* RUN       Set the cd path below, then Ctrl+D. Writes findex_bgd_master_log.txt.
* REQUIRES  Stata 17+; ssc install fairlie; ssc install oaxaca.
* NOTES     Models [pw=wgt], descriptives [aw=wgt]. i.account_mob gives the
*           0-to-1 discrete change. Robust SEs: no PSU identifier is released
*           (Sec 3.6.1). Percentage points = proportions x 100. Fixed seed.
*==============================================================================

clear all
set more off
set seed 20260914
set linesize 100

cd "C:\Users\AlveeAhmed\OneDrive - Episerver\UoM\Dissertation\Data and Scripts"

capture log close
log using "findex_bgd_master_log.txt", replace text

import delimited "pooled_findex_bgd_keyed_v2.csv", clear varnames(1) case(preserve)

*------------------------------------------------------------------------------
* PART 0  Data integrity (Sec 3.3, 3.4, App A.3). Halts if any check fails.
*------------------------------------------------------------------------------
display _n "#### PART 0  Data integrity ####"

display _n "--- 0.1  5,000 observations, 1,000 per wave ---"
tab wave
assert _N==5000
foreach w in 2011 2014 2017 2021 2024 {
    quietly count if wave==`w'
    assert r(N)==1000
}

display _n "--- 0.2  Keys: 1,000 unique per wave from 2014, none in 2011 ---"
egen byte _tag = tag(wave wpid_random)
table wave, statistic(sum _tag) nformat(%6.0f)
drop _tag
duplicates report wave wpid_random if !missing(wpid_random)
assert !missing(wpid_random) if wave>=2014
quietly duplicates report wave wpid_random if wave>=2014
assert r(unique_value)==r(N)

display _n "--- 0.3  2017 repair [Sec 3.4: 418 and 109] ---"
count if wave==2017 & account_fin==1
assert r(N)==418
count if wave==2017 & saved_fin==1
assert r(N)==109
display "    PASS: account_fin=418 and saved_fin=109 for 2017."

display _n "--- 0.4  Gender coding check: men above women on accounts in every wave ---"
table wave female [pw=wgt], statistic(mean account) nformat(%7.4f)

*------------------------------------------------------------------------------
* PART 1  Table 4.1, weighted, per cent
*   use 2.7/2.7/21.2/29.0/20.8   gap 0.3/1.1/22.2/18.1/12.7
*   saved 26.8/23.9/27.5/23.4/20.4   borrowed 23.3/48.3/36.8/46.1/70.3
*------------------------------------------------------------------------------
display _n "#### PART 1  Table 4.1 ####"

display _n "--- 1.1  Use, saving and borrowing by wave ---"
table wave [pw=wgt], statistic(mean account_mob) statistic(mean saved) statistic(mean borrowed) nformat(%7.4f)

display _n "--- 1.2  Use by wave and gender (gap = difference of columns) ---"
table wave female [pw=wgt], statistic(mean account_mob) nformat(%7.4f)

display _n "--- 1.3  2024 use, unweighted then weighted [Sec 3.3: 16.9 vs 20.8] ---"
summarize account_mob if wave==2024
summarize account_mob if wave==2024 [aw=wgt]

display _n "--- 1.4  2011 proxy users [Sec 3.4: a very small base] ---"
count if wave==2011 & account_mob==1

*------------------------------------------------------------------------------
* PART 2  Table 4.2, H1 (AME, pp)
*   saved pooled 15.6 (SE 2.3, N 3,998); borrowed 14.9/15.6/21.3/9.4 by wave;
*   merchant 5.8 pooled, 2.8 (2021), 9.3 (2024). Borrowing is estimated wave
*   by wave because the question is not comparable across waves.
*------------------------------------------------------------------------------
display _n "#### PART 2  Table 4.2 (H1) ####"

display _n "--- 2.1  Saving, pooled 2014-2024 [0.1555] ---"
probit saved i.account_mob female age i.educ i.inc_q i.wave if wave>=2014 [pw=wgt]
margins, dydx(account_mob)

display _n "--- 2.2  Borrowing, wave by wave ---"
foreach w in 2014 2017 2021 2024 {
    display _n "    ---- borrowing, wave `w' ----"
    capture noisily probit borrowed i.account_mob female age i.educ i.inc_q if wave==`w' [pw=wgt]
    capture noisily margins, dydx(account_mob)
}

display _n "--- 2.3  Merchant payment, pooled 2021-2024 [0.0579] ---"
probit merchant i.account_mob female age i.educ i.inc_q i.wave if wave>=2021 [pw=wgt]
margins, dydx(account_mob)

display _n "--- 2.4  Merchant payment, wave by wave [2.8 and 9.3] ---"
foreach w in 2021 2024 {
    display _n "    ---- merchant payment, wave `w' ----"
    capture noisily probit merchant i.account_mob female age i.educ i.inc_q if wave==`w' [pw=wgt]
    capture noisily margins, dydx(account_mob)
}

display _n "--- 2.5  Merchant prevalence [Sec 4.3: 2.8 per cent each wave] ---"
table wave [pw=wgt], statistic(mean merchant) nformat(%7.4f)

display _n "--- 2.6  Users with no merchant payment [Sec 4.3: 265 in 2021, 152 in 2024] ---"
display _n "    ---- 2021: account_mob==1, merchant==0 cell ----"
tab account_mob merchant if wave==2021, missing
display _n "    ---- 2024: account_mob==1, merchant==0 cell ----"
tab account_mob merchant if wave==2024, missing

*------------------------------------------------------------------------------
* PART 2A  Sec 4.3.1, did the saving association change across waves?
*   AMEs 24.4/11.4/17.1/15.4; joint chi2(3) = 2.00, p = .572; index p = .465.
*------------------------------------------------------------------------------
display _n "#### PART 2A  Sec 4.3.1 ####"

display _n "--- 2A.1  Use interacted with wave ---"
probit saved i.account_mob##i.wave female age i.educ i.inc_q if wave>=2014 [pw=wgt]

display _n "--- 2A.2  AME by wave ---"
margins wave, dydx(account_mob)

display _n "--- 2A.3  Joint test, probability scale ---"
capture noisily margins r.wave, dydx(account_mob)

display _n "--- 2A.4  Joint test, latent index ---"
testparm i.account_mob#i.wave

display _n "--- 2A.5  Pooled benchmark [0.1555] ---"
probit saved i.account_mob female age i.educ i.inc_q i.wave if wave>=2014 [pw=wgt]
margins, dydx(account_mob)

*------------------------------------------------------------------------------
* PART 3  Sec 4.3.2, why any digital payment is not reported
*   279 of 279 (2021), 169 of 169 (2024), 4 positives in 2017; 360 completely
*   determined; AME 52.6 (SE 0.9), pseudo R2 0.58: quasi-complete separation.
*------------------------------------------------------------------------------
display _n "#### PART 3  Sec 4.3.2 ####"

display _n "--- 3.1  2017 is a proxy with four positives ---"
table wave, statistic(mean digpay) statistic(sum digpay) statistic(mean digpay_proxy) nformat(%7.4f)

display _n "--- 3.2  Use against digital payment: the empty cells ---"
bysort wave: tab account_mob digpay if wave>=2017, missing

display _n "--- 3.3  The separated model, for the record ---"
probit digpay i.account_mob female age i.educ i.inc_q i.wave if wave>=2017 [pw=wgt]
margins, dydx(account_mob)

*------------------------------------------------------------------------------
* PART 4  Sec 4.3.3, is the saving association a banking association?
*   12.3 (SE 2.2) with account_fin 22.8 (SE 1.7); overlap 49.85 per cent;
*   unbanked 9.9 (SE 2.8), N 2,566.
*------------------------------------------------------------------------------
display _n "#### PART 4  Sec 4.3.3 ####"

display _n "--- 4.1  Saving with a financial-institution control ---"
probit saved i.account_mob i.account_fin female age i.educ i.inc_q i.wave if wave>=2014 [pw=wgt]
margins, dydx(account_mob account_fin)

display _n "--- 4.2  Overlap of the two account types [49.85, unweighted] ---"
tab account_mob account_fin if wave>=2014, missing row

display _n "--- 4.3  Adults with no financial-institution account [N 2,566] ---"
probit saved i.account_mob female age i.educ i.inc_q i.wave if wave>=2014 & account_fin==0 [pw=wgt]
margins, dydx(account_mob)

*------------------------------------------------------------------------------
* PART 5  Table 4.3, H2 (AME by income quintile, pp)
*   11.4/9.7/17.0/17.6/20.5; joint chi2(4) = 3.37, p = .498; Q5-Q1 9.2
*   (CI -5.3 to 23.7); index-scale p = .774.
*------------------------------------------------------------------------------
display _n "#### PART 5  Table 4.3 (H2) ####"

probit saved i.inc_q##i.account_mob female age i.educ i.wave if wave>=2014 [pw=wgt]

display _n "--- 5.1  Index-scale test [p .774] ---"
testparm i.inc_q#i.account_mob

display _n "--- 5.2  AME by quintile ---"
margins inc_q, dydx(account_mob)

display _n "--- 5.3  Joint probability-scale contrast [chi2(4) 3.37, p .498] ---"
capture noisily margins r.inc_q, dydx(account_mob)

display _n "--- 5.4  Within-quintile averaging (check, not reported) ---"
capture noisily margins, dydx(account_mob) over(inc_q)

*------------------------------------------------------------------------------
* PART 6  Table 4.4, H3, and the gender-depth test (Sec 4.5)
*   Gap 17.6, N 2,998. Fairlie: explained 8.2 (47%), phone 2.4, workforce 5.4,
*   unexplained 9.4 (53%). Oaxaca: explained 4.2 (24%), phone 1.9, workforce
*   2.3, unexplained 13.4 (76%). Depth: 15.4 vs 15.8, p .930; borrowing p .842;
*   minimum detectable difference 12.6 at 80 per cent power.
*------------------------------------------------------------------------------
display _n "#### PART 6  Table 4.4 (H3) ####"

display _n "--- 6.1  Does the saving association differ by gender? ---"
probit saved i.account_mob##i.female age i.educ i.inc_q i.wave if wave>=2014 [pw=wgt]
margins female, dydx(account_mob)
capture noisily margins r.female, dydx(account_mob)
testparm i.account_mob#i.female

display _n "--- 6.2  Same test on borrowing ---"
probit borrowed i.account_mob##i.female age i.educ i.inc_q i.wave if wave>=2014 [pw=wgt]
capture noisily margins r.female, dydx(account_mob)

display _n "--- 6.3  Minimum detectable difference [12.6 at 80 per cent power] ---"
scalar se_d = 0.0450958
display "    SE of the difference      : " %5.2f 100*se_d " pp"
display "    Detectable at 50% power   : " %5.2f 100*1.96*se_d " pp"
display "    Detectable at 80% power   : " %5.2f 100*2.80*se_d " pp"

display _n "--- 6.4  Decomposition sample [N 2,998] ---"
preserve
keep if wave>=2017
drop if missing(account_mob, has_phone, emp_in, age, educ, inc_q, female)
count
assert r(N)==2998
tabulate educ,  generate(educ_)
tabulate inc_q, generate(incq_)
tabulate wave,  generate(wave_)

display _n "--- 6.5  Raw weighted gap [0.1760] ---"
mean account_mob [pw=wgt], over(female)

display _n "--- 6.6  Oaxaca, weighted linear, pooled reference ---"
oaxaca account_mob has_phone emp_in age educ_2 educ_3 incq_2 incq_3 incq_4 incq_5 wave_2 wave_3 [pw=wgt], by(female) pooled
capture noisily nlcom (share_explained: _b[overall:explained]/_b[overall:difference]) (share_unexplained: _b[overall:unexplained]/_b[overall:difference])

display _n "--- 6.7  Fairlie, weighted probit, 1,000 reps, random ordering (reported) ---"
set seed 20260914
capture noisily fairlie account_mob has_phone emp_in age (education: educ_2 educ_3) (income: incq_2 incq_3 incq_4 incq_5) (survey: wave_2 wave_3) [pw=wgt], by(female) pooled probit reps(1000) ro

display _n "--- 6.8  Same without random ordering [shares within 2 points] ---"
set seed 20260914
capture noisily fairlie account_mob has_phone emp_in age educ_2 educ_3 incq_2 incq_3 incq_4 incq_5 wave_2 wave_3 [pw=wgt], by(female) pooled probit reps(1000)

display _n "--- 6.9  Command versions, and does fairlie honour pweights? (totals should differ) ---"
capture noisily which fairlie
capture noisily which oaxaca
set seed 20260914
capture noisily fairlie account_mob has_phone emp_in age educ_2 educ_3 incq_2 incq_3 incq_4 incq_5 wave_2 wave_3 [pw=wgt], by(female) pooled probit reps(100)
set seed 20260914
capture noisily fairlie account_mob has_phone emp_in age educ_2 educ_3 incq_2 incq_3 incq_4 incq_5 wave_2 wave_3, by(female) pooled probit reps(100)

restore

*------------------------------------------------------------------------------
* PART 7  Table 4.5, H4, 2024
*   Predicted use 8.6/15.8/28.7 (unweighted 6.0/14.2/24.8); basic vs none 7.2,
*   p .034; smartphone vs basic 12.9, p .029; device block p .001; internet
*   8.2, p .114 (unweighted 11.9, p .013); counts 208/499/293; 265 of 293
*   smartphone owners use the internet; shares 82.4/38.2/43.6 per cent.
*   Device states are mutually exclusive: the overlapping has_phone/smartphone
*   indicators of an earlier file evaluated combinations that cannot occur.
*------------------------------------------------------------------------------
display _n "#### PART 7  Table 4.5 (H4) ####"

display _n "--- 7.1  Smartphone nested in handset ownership ---"
tab has_phone smartphone if wave==2024, missing

display _n "--- 7.2  Smartphone by internet [265 of 293] ---"
tab smartphone internet if wave==2024, missing

display _n "--- 7.3  Connectivity: counts, then weighted shares ---"
foreach v in has_phone smartphone internet {
    count if wave==2024 & `v'==1
}
summarize has_phone smartphone internet if wave==2024 [aw=wgt]

gen byte device = .
replace device = 0 if has_phone==0
replace device = 1 if has_phone==1 & smartphone==0
replace device = 2 if smartphone==1
label define devlbl 0 "No handset" 1 "Basic handset" 2 "Smartphone"
label values device devlbl
tab device if wave==2024, missing

display _n "--- 7.4  Weighted model ---"
probit account_mob i.device i.internet female age i.educ i.inc_q if wave==2024 [pw=wgt]
margins device
capture noisily margins ar.device
testparm i.device
margins, dydx(internet)
testparm i.internet

display _n "--- 7.5  Unweighted model ---"
probit account_mob i.device i.internet female age i.educ i.inc_q if wave==2024, vce(robust)
margins device
capture noisily margins ar.device
capture noisily margins r.device
margins, dydx(internet)

*------------------------------------------------------------------------------
* PART 7.6  Sec 4.6, do the two device steps differ? (supervisor's question)
*   Reported: difference 5.737 pp, SE 7.743, p .459 weighted; 2.305, p .727
*   unweighted. nlcom and the quadratic contrast test the same quantity and
*   must agree on p; Stata rescales the quadratic, so read its p only.
*------------------------------------------------------------------------------
display _n "#### PART 7.6  Sec 4.6 ####"

display _n "--- 7.6a  Weighted, nlcom ---"
probit account_mob i.device i.internet female age i.educ i.inc_q if wave==2024 [pw=wgt]
capture estimates drop h4_w
estimates store h4_w
capture noisily margins, at(device=(0 1 2)) post
capture noisily nlcom (step1: _b[2._at] - _b[1._at]) (step2: _b[3._at] - _b[2._at]) (diff: (_b[3._at] - _b[2._at]) - (_b[2._at] - _b[1._at]))
capture noisily lincom (_b[3._at] - _b[2._at]) - (_b[2._at] - _b[1._at])

display _n "--- 7.6b  Weighted, quadratic contrast ---"
capture noisily estimates restore h4_w
capture noisily margins p.device

display _n "--- 7.6c  Unweighted, nlcom ---"
probit account_mob i.device i.internet female age i.educ i.inc_q if wave==2024, vce(robust)
capture estimates drop h4_u
estimates store h4_u
capture noisily margins, at(device=(0 1 2)) post
capture noisily nlcom (step1: _b[2._at] - _b[1._at]) (step2: _b[3._at] - _b[2._at]) (diff: (_b[3._at] - _b[2._at]) - (_b[2._at] - _b[1._at]))

display _n "--- 7.6d  Unweighted, quadratic contrast ---"
capture noisily estimates restore h4_u
capture noisily margins p.device

*------------------------------------------------------------------------------
* PART 8  Table 4.6, wave contrasts in saving, common N 2,998
*   Wave effects only: 2021 -4.11 (p .063), 2024 -7.12 (p .001).
*   Full model: 2021 -5.11 (p .019), 2024 -7.45 (p .001). They widen.
*------------------------------------------------------------------------------
display _n "#### PART 8  Table 4.6 ####"

display _n "--- 8.1  Common sample from the full model ---"
probit saved i.wave i.account_mob female age i.educ i.inc_q if wave>=2017 [pw=wgt]
gen byte common = e(sample)
count if common==1

display _n "--- 8.2  Wave effects only ---"
probit saved i.wave if common==1 [pw=wgt]
margins wave
capture noisily margins r.wave

display _n "--- 8.3  Full model ---"
probit saved i.wave i.account_mob female age i.educ i.inc_q if common==1 [pw=wgt]
margins wave
capture noisily margins r.wave

*------------------------------------------------------------------------------
* PART 9  Appendix C, Table C.2: weighting and 2011 robustness
*   Saving 15.6 vs 16.9 unweighted; borrowing 15.2 vs 13.9; saving 15.6 vs
*   15.8 with 2011. Unweighted runs use vce(robust), replacing the default OIM
*   estimator of an earlier file, which confounded weighting with the VCE.
*------------------------------------------------------------------------------
display _n "#### PART 9  Appendix C, Table C.2 ####"

display _n "--- 9.1  Saving, unweighted [16.9] ---"
probit saved i.account_mob female age i.educ i.inc_q i.wave if wave>=2014, vce(robust)
margins, dydx(account_mob)

display _n "--- 9.2  Borrowing pooled, weighted then unweighted [15.2 vs 13.9] ---"
probit borrowed i.account_mob female age i.educ i.inc_q i.wave if wave>=2014 [pw=wgt]
margins, dydx(account_mob)
probit borrowed i.account_mob female age i.educ i.inc_q i.wave if wave>=2014, vce(robust)
margins, dydx(account_mob)

display _n "--- 9.3  H2 joint test, unweighted (check, not reported) ---"
probit saved i.inc_q##i.account_mob female age i.educ i.wave if wave>=2014, vce(robust)
testparm i.inc_q#i.account_mob
capture noisily margins r.inc_q, dydx(account_mob)

display _n "--- 9.4  Gender difference, unweighted (check, not reported) ---"
probit saved i.account_mob##i.female age i.educ i.inc_q i.wave if wave>=2014, vce(robust)
capture noisily margins r.female, dydx(account_mob)

display _n "--- 9.5  Adding the 2011 wave [15.6 vs 15.8] ---"
probit saved i.account_mob female age i.educ i.inc_q i.wave if wave>=2014 [pw=wgt]
margins, dydx(account_mob)
probit saved i.account_mob female age i.educ i.inc_q i.wave if wave>=2011 [pw=wgt]
margins, dydx(account_mob)

*------------------------------------------------------------------------------
* PART 10  Cross-check list
*------------------------------------------------------------------------------
display _n "#### PART 10  Cross-check list ####"
display "  Table 4.1  use 2.7/2.7/21.2/29.0/20.8 ............ Part 1.1"
display "  Table 4.1  gap 0.3/1.1/22.2/18.1/12.7 ............ Part 1.2"
display "  Table 4.1  saved 26.8/23.9/27.5/23.4/20.4 ........ Part 1.1"
display "  Table 4.1  borrowed 23.3/48.3/36.8/46.1/70.3 ..... Part 1.1"
display "  Table 4.2  saving 15.6, SE 2.3, N 3,998 .......... Part 2.1"
display "  Table 4.2  borrowing 14.9/15.6/21.3/9.4 .......... Part 2.2"
display "  Table 4.2  merchant 5.8 / 2.8 / 9.3 .............. Parts 2.3, 2.4"
display "  Sec 4.3    2.8 per cent; 265 and 152 users ....... Parts 2.5, 2.6"
display "  Sec 4.3.1  chi2(3) 2.00, p .572 .................. Part 2A"
display "  Sec 4.3.2  279/279, 169/169, 52.6 ................ Part 3"
display "  Sec 4.3.3  12.3, 22.8, 49.85, 9.9, N 2,566 ....... Part 4"
display "  Table 4.3  11.4/9.7/17.0/17.6/20.5, p .498 ....... Part 5"
display "  Table 4.4  Fairlie 8.2 (47%), 2.4, 5.4 ........... Part 6.7"
display "  Table 4.4  Oaxaca 4.2 (24%), 13.4 (76%) .......... Part 6.6"
display "  Sec 4.5    15.4 / 15.8, p .930; MDD 12.6 ......... Parts 6.1, 6.3"
display "  Table 4.5  8.6/15.8/28.7; 7.2, 12.9; 8.2 ......... Parts 7.4, 7.5"
display "  Table 4.5  208/499/293; 265 of 293 ............... Parts 7.1 to 7.3"
display "  Sec 4.6    step difference 5.737, p .459 ........ Part 7.6"
display "  Table 4.6  -4.11/-5.11/-7.12/-7.45, N 2,998 ...... Part 8"
display "  Sec 3.3    16.9 vs 20.8 ......................... Part 1.3"
display "  Sec 3.4    2017 repair 418 and 109 .............. Part 0.3"
display "  Table C.2  16.9; 15.2 vs 13.9; 15.8 .............. Part 9"

log close
display "=== DONE. Output saved to findex_bgd_master_log.txt ==="
