# AEM
## AEM-Automated Electromagnetic MKID Simulations. 


AEM is an app developed for the automation of construction and simulation of MKID pixels using MatLab, the EM simulation software: Sonnet and SonnetLab. This work was done in collaboration between Maynooth University, Dublin Institute for Advanced Studies and Dublin City University, Ireland.

The installer package will install AEM as an app in the MatLab GUI.  
AEM is easy to use but it is important to follow the steps and recommendations below for AEM to work correctly.
AEM is still early Alpha and will construct MKID pixels in most general cases.
It should also be noted that AEM will only work correctly on single resonant frequency pixels containing a single dip in the |S21| parameter. 

## How To Use AEM
Step 1:
AEM requires a starting geometry from the user in order to automate geometries. This geometry must contain: 
1) Feedline with ports
2) GND plane surrounding MKID (see below for specific details on GND plane)
3) General boxed area for interdigitated capacitor.

All other aspects of the MKID is up to the user (i.e. Lumped inductor, distributed inductor, antenna, etc), as automation only concerns the GND plane and interdigitated capacitor.

Step 2)
Within the starting geometry settings in Sonnet, have the following settings on:
1) Export .csv file to same project folder as geometry file in format mag and phase or 

2) Select "Auto Run" 

3) (Optional but preferred) Select...

4) 

![Screenshot (1)](https://github.com/scathalmca/AEM/assets/92909628/929909c7-3720-4ab4-a083-a9f8aabc4fc3)
