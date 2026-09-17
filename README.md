This repository contains MATLAB code to analyze timelapse imaging data generated using the 
_sox10:myrEGFP-P2A-Lifeact-TagRFP_ genetic construct in Danio rerio. 

Input file type: .TRACES files generated from timelapse imaging tracing Lifeact signal in each 
time frame using the Simple Neurite Tracer package in FIJI (https://imagej.net/plugins/snt/)1.

Output: "ans" data structure containing distance from lifeact signal to lower edge of sheath 
across time in submitted data. To estimate variability in Lifeact signal, this data can then be
used to calculate the sum of absolute values across time points, averaged across the length of 
the sheath. Additionally, with input arguments (1,1) (_i.e._, makeplot = true), this code will 
output a graphical representation of variation in Lifeact signal for each timepoint. Example:
<img width="1246" height="1019" alt="image" src="https://github.com/user-attachments/assets/dff56935-9003-40a1-9f3f-11e5b10c92bf" />

This code was used in the analysis of Lifeact data in the following work:
Piller M, Doan RA, Call CL, Smith SM, Monk, KR. P/Q-Type voltage-gated calcium channels regulate 
  calcium signaling and developmental myelination in oligodendrocyte lineage cells. Preprint, 
  bioRxiv, Dec 13, 2025. doi: 10.64898/2025.12.12.694003.

References:
1. Arshadi, C., Günther, U., Eddison, M., Harrington, K. I. S. & Ferreira, T. A. SNT: a unifying 
      toolbox for quantification of neuronal anatomy. Nat. Methods 18, 374–377 (2021).
