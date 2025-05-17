# Analysis of Model Covariates' Ability to Recover the True Effect (2.1) of the Confounder 

The true data generating process is:

$$
Y = \beta_1 \text{Confounder} + \beta_2 \text{Treatment} + \beta_3 (\text{Treatment} * \text{Treatment Effect}) + \text{Strata Fixed Effects}
$$

We first run a density plot of the estimated betas across three sample sizes 

The model we pull from m1 is denoted as such:

$$
\hat{Y} = \text{Confounder} + \text{Treatment} + \text{Strata Fixed Effects}
$$

![Density Plot](density.png)

### Overview  
- **Lines in different colors** represent different sample sizes:
  - **Blue (samp_size = 60):** We see a noticeably wider distribution, more spread around 2.1.  
  - **Black (samp_size = 360):** The distribution becomes tighter compared to 60, suggesting increased precision as the sample size grows irrespective of changing any controls.  
  - **Green (samp_size = 660):** This trend continues as we add another 300 obs to the sample.
    
---

This process is further driven home by the vilon plot which averages the effect of the confounder across all models and sample sizes which increminates from 60 to 1410 total obs. 

![Violin Plot](vioplot_beta.png)

### Key Takeaways
1. **Narrowing of the Violin**  
   - We see an almost funnel for the estimates as sample size increases and models get closer to the DGP, each violin becomes slimmer, illustrating a more precise estimate with less spread.
2. **Centering on 2.1**  
   - The center of the violin approaches **2.1** as the sample size increases, suggesting the estimator is consistent.
---

## 3. Conclusion

From the density and violin plots, we observe that:

- **Smaller sample sizes** yield more dispersed estimates that still seem to cluster near 2.1 but with higher variability.
- **Larger sample sizes** progressively tighten the distribution around the true effect, confirming that the model is consistent and likely unbiased.
- **Inclusion of appropriate covariates** (the confounder, treatment indicator, and strata fixed effects) appears to help to unbias the estimate to be closer to the known true value.

In summary, these plots underscore the importance of both **adequate sample size** and **well-specified models with relevant covariates** to produce accurate and precise estimates of the true effect (2.1).

## Summary Table of Estimates


| samp_size | e(m1)                   | e(m2)                     | e(m3)                   | e(m4)                   | e(m5)           |
|-----------|-------------------------|---------------------------|-------------------------|-------------------------|-----------------|
| **60**    | 2.133824 (1.163578)     | -0.1291751 (0.2559239)     | 2.097697 (0.1223905)     | 2.121245 (1.18304)      | 2.1 (5.42e-07)  |
| **210**   | 2.100325 (0.5932618)    | -0.1027658 (0.1281104)    | 2.099971 (0.0596471)    | 2.097786 (0.5819492)     | 2.1 (2.68e-07)  |
| **360**   | 2.097824 (0.4630004)    | -0.0978927 (0.0956793)    | 2.099815 (0.0445387)    | 2.099447 (0.4596301)     | 2.1 (2.00e-07)  |
| **510**   | 2.094536 (0.3605391)    | -0.1073168 (0.0812202)    | 2.098961 (0.0383528)    | 2.099552 (0.3575697)     | 2.1 (1.78e-07)  |
| **660**   | 2.105276 (0.3285618)    | -0.1028221 (0.0703639)    | 2.099083 (0.0350703)    | 2.106031 (0.3281519)     | 2.1 (1.52e-07)  |
| **810**   | 2.109628 (0.3066839)    | -0.0946783 (0.0650661)    | 2.100699 (0.0315957)    | 2.111002 (0.3012487)     | 2.1 (1.44e-07)  |
| **960**   | 2.103456 (0.2879982)    | -0.0996886 (0.061125)     | 2.100453 (0.0286398)    | 2.100202 (0.2843689)     | 2.1 (1.42e-07)  |
| **1110**  | 2.102988 (0.2493)       | -0.0971465 (0.0511383)    | 2.101331 (0.0249286)    | 2.101603 (0.2471081)     | 2.1 (1.35e-07)  |
| **1260**  | 2.103135 (0.2336352)    | -0.0965063 (0.0515591)    | 2.099656 (0.0245935)    | 2.102565 (0.2310541)     | 2.1 (1.22e-07)  |
| **1410**  | 2.104264 (0.226412)     | -0.0937086 (0.0512921)    | 2.100712 (0.0230817)    | 2.102772 (0.225998)      | 2.1 (1.20e-07)  |
| **Total** | 2.105526 (0.4999716)    | -0.1021701 (0.1091965)    | 2.099838 (0.0517312)    | 2.104221 (0.5018068)     | 2.1 (2.35e-07)  |




