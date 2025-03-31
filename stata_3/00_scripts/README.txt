# Simulation Study: Fixed vs. Infinite Superpopulation

## **Overview**
We create a simple **data generating process (DGP)** in which:  
- `X` is drawn from a normal distribution: \( X \sim N(0,1) \)  
- `error` is drawn from a normal distribution.  
- The outcome variable is generated as:  
  \[
  Y = 2X + error
  \]
- This DGP is **identical** in both parts of the study.

## **Part 1: Sampling from a Fixed Population**
Here, **sampling noise** is introduced **only** due to random draws from a fixed dataset of 10,000 individuals.

<<dd_do:nocommands>>
clear 
use "01_data/sim_results.dta", replace 
gen fin = 1
append using "01_data/sim_inf_results.dta"
replace fin = 0 if fin == . 
drop if beta == . 
<</dd_do>>

### **Histogram of Beta Estimates (Finite Population)**
  
<<dd_do:nooutput>>
histogram beta if fin == 1, by(sample_size) name(beta_finite, replace)
<</dd_do>>
 
<<dd_graph: sav("fig_beta_finite.svg") alt("Beta Distribution - Finite Population") replace height(400)>>

### **Summary Statistics (Finite Population)**
<<dd_do:nocommands>>
tabstat beta sem pvalue if fin == 1, by(sample_size)
<</dd_do>>


## **Part 2: Sampling from an Infinite Superpopulation**
Here, each replication draws from an entirely **new dataset**, representing an **infinite** superpopulation.  

As expected, **standard errors (SE)** and **confidence intervals (CI widths)** **shrink as N increases**.

### **Histogram of Beta Estimates (Infinite Superpopulation)** 
<<dd_do:nooutput>>
histogram beta if fin == 0, by(sample_size) name(beta_infinite, replace)
<</dd_do>>
  
<<dd_graph: sav("fig_beta_infinite.svg") alt("Beta Distribution - Infinite Superpopulation") replace height(400)>>

### **Summary Statistics (Infinite Superpopulation)**
<<dd_do:nocommands>>
tabstat beta sem pvalue if fin == 0, by(sample_size) 
<</dd_do>>

---

## **Comparing Fixed vs. Infinite Sampling**
When sampling from a **fixed population** at `N = 10,000`, the **variation in estimates is limited** by the finite underlying variability of the dataset.  

In contrast, the **infinite superpopulation** case exhibits a smoother trend as `N` grows.

### **Density Plot: Finite vs. Infinite** 
<<dd_do:nooutput>>
twoway (kdensity beta if fin == 1, lcolor(blue)) ///
       (kdensity beta if fin == 0, lcolor(red)), ///
       legend(order(1 "Fixed Population" 2 "Superpopulation")) ///
       title("Distribution of Estimated Beta") xtitle("Beta") ytitle("Density") ///
       name(beta_density, replace)
<</dd_do>>

<<dd_graph: sav("fig_beta_density.svg") alt("Beta Density Comparison") replace height(400)>>


Below we can compare the mean overall values between the infinite and finite population
<<dd_do:nocommands>>
tabstat beta sem pvalue, by(fin) 
<</dd_do>>


## **Conclusion**
- The **infinite superpopulation** has **smaller standard errors and tighter confidence intervals** as `N` increases.
- The **finite population** has more erratic estimates at **small sample sizes** due to **sampling constraints**.
- Larger sample sizes **reduce confidence interval width**, improving precision.

---
