# AEM
## AEM-Automated Electromagnetic MKID Simulations. 

# **This is the old version of AEM and may contain many bugs, errors and crashes. Please see AEM v2 for an updated version of the code. Thanks :)**



AEM is an app developed for the automation of construction and simulation of MKID pixels using MatLab, the EM simulation software: Sonnet and SonnetLab. This work was done in collaboration between Maynooth University, Dublin Institute for Advanced Studies and Dublin City University, Ireland.  


The installer package will install AEM as an app in the MatLab GUI.  

AEM is easy to use but it is important to follow the steps and recommendations below for AEM to work correctly.  

AEM is still early Alpha and will construct MKID pixels in most general cases for accurate resonant frequencies and coupling Quality Factor.  

It should also be noted that AEM will only work correctly on single resonant frequency pixels containing a single dip in the |S21| parameter.  


## How To Use AEM
**Step 1:**
AEM requires a starting geometry from the user in order to automate geometries. This geometry must contain:  

1) Feedline with ports
2) GND plane surrounding MKID (see below for specific details on GND plane)
3) General boxed area for interdigitated capacitor.

**IMPORTANT GEOMETRY REQUIREMENTS:**
Make sure the GND ports (-1) are attached to the GND bridge polygon between the Feedline and MKID. The side GND plane polygons must not overlap the GND Bridge polygon for parameterization.
It is important that the side polygons for the interdigitated capacitor area are exactly equal in the Y co-ordinate.  

**For example:**. 

AEM will not work correctly if the left side capacitor polygon is Y=100 and the right polygon is Y=100.0001.  


All other aspects of the MKID is up to the user (i.e. Lumped inductor, distributed inductor, antenna, etc), as automation only concerns the GND plane and interdigitated capacitor.  


**Step 2:**
Within the starting geometry settings in Sonnet, have the following settings on:  


1) Export .csv file to same project folder as geometry file in format Magnitude or dB.  

2) Select "Auto Run" in the em Engine window where simulations run.

3) (Optional but preferred) Select "Enhanced Resonance Detection" and "Q-Factor Accuracy" under the "Advanced Settings" dialog box.

4) Remove any existing parameter sweep options in the geometry file.

Any existing frequency sweeps or file export settings will be removed and reset within AEM.  


**Step 3:**
Open the GUI, and import the starting geometry file.

**Step 4:**
Select the X1, Y1, X2 and Y2 coordinates of the box in the GND plane which the MKID sits in and type them into the corresponding dialog boxes. It does not matter which X coordinate is X1 or X2 and vice versa for the Y coordinates.  

If the above steps and recommendations were correct, the GUI and starting geometry should look similar to below:  


![Screenshot (1)](https://github.com/scathalmca/AEM/assets/92909628/929909c7-3720-4ab4-a083-a9f8aabc4fc3)

