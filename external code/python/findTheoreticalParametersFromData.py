
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import csv
from scipy import signal
from scipy.interpolate import interp1d
from scipy.signal import butter, filtfilt
import os
from scipy.optimize import minimize
import interactWithJulia
import plotFirstPassagePdf
from scipy.optimize import differential_evolution

basePath = "D:/lastline/bioTweezers/20_2_5"
#				file idx, setpoint
usedFileIdx =  [9  , 	#	0.015,
				12 , 	#	0.010,
				14 , 	#	0.005,
				15 , 	#	0.020,
				16 , 	#	-0.015
				]
usedFiles = [plotFirstPassagePdf.getBaseFileNameFromIdx(basePath, i) for i in usedFileIdx]

fileConversion = {
	'constantIntensity_004.csv' 									:	'004_bead 1_setpoint 0.015_constant stiffness 0.15_',
	'constantIntensity_005.csv' 									:	'005_bead 1_setpoint 0.01_constant stiffness 0.15_ offset around -0.01_005',
	'constantIntensity_disruptedByGerm_003.csv' 					:	'003_bead 1_setpoint 0.025_constant stiffness 0.15_ disruption at 63s_higherSampling_003',
	'constantStiffness_bothTransitions_007.csv' 					:	'007_bead 1_setpoint 0.015_constant stiffness 0.15_',
	'constantStiffness_bothTransitions_008.csv' 					:	'008_bead 1_setpoint -0.015_constant stiffness 0.15_',
	'newBead_constantStiffness_009.csv' 							:	'009_bead 2_setpoint 0.015_constant stiffness 0.15_',
	'newBead_constantStiffness_012.csv' 							:	'012_bead 2_setpoint 0.01_constant stiffness 0.15_',
	'newBead_constantStiffness_013.csv' 							:	'013_bead 2_setpoint 0.005_constant stiffness 0.15_',
	'newBead_constantStiffness_014.csv' 							:	'014_bead 2_setpoint 0.005_constant stiffness 0.15_',
	'newBead_constantStiffness_015.csv' 							:	'015_bead 2_setpoint 0.02_constant stiffness 0.15_',
	'newBead_constantStiffness_interruptedByBead_011.csv' 			:	'011_bead 2_setpoint 0.01_constant stiffness 0.15_ disruption at 40s_011',
	'newBead_constantStiffness_offsetStillShiftingALot_017.csv'		:	'017_bead 2_setpoint -0.015_constant stiffness 0.15_ lots of drifts_017',
	'newBead_constantStiffness_offsetStillShiftingALot_018.csv'		:	'018_bead 2_setpoint -0.015_constant stiffness 0.15_ offset drifts to 0.01_018',
	'newBead_constantStiffness_setpointShifted_010.csv' 			:	'010_bead 2_setpoint 0.01_constant stiffness 0.15_ offset drifts to 0.02_010',
	'newBead_constantStiffness_setpointShiftsTooMuch_016.csv' 		:	'016_bead 2_setpoint -0.015_constant stiffness 0.15_',
	'test_001.csv' 													:	'001_bead 1_setpoint 0.025_constant stiffness 0.15_',
	'test_002.csv' 													:	'002_bead 1_setpoint 0.025_constant stiffness 0.15_',
	'constantStiffness_006.csv' 									:	'006_bead 1_setpoint 0.015_feedback stiffness 0.15_ 0.2_offset around 0.07_006',
	'newBead_feedbackStiffness_019.csv' 							:	'019_bead 2_setpoint 0.02_feedback stiffness 0.15_ 0.3_offset around 0.01_019',
}

foundResults = []

for baseFile in usedFiles:
	fileName = baseFile.split("/")[-1]
	newFileName = fileConversion[fileName]
	q = plotFirstPassagePdf.getTimings_x0x1_and_x1x0(baseFile, [])
	x0,x1=plotFirstPassagePdf.getValuesOf_x0_and_x1(baseFile)
	if isinstance(q, tuple):
		x0x1, _= q
	else:
		x0x1 = q
	x=np.sort(x0x1)
	# x = x[x<0.01]
	# x = signal.decimate(x, 10)
	x -= x[0]
	maxTime_s = x[-1]
	# x /= x[-1]
	t = np.linspace(0,x[-1],len(x))
	x = np.interp(np.linspace(0,1,len(x)),x/x[-1],np.linspace(0,1,len(x)))
	

	def getTheoreticalCdf(maxTime_s=maxTime_s, nOfPoints = len(x), x0_m = 0, stiffness_N_m = 13e-6, drag_Ns_m = 0, T_K = 300):
		t,pdf = interactWithJulia.getFPTFromJuliaScript(maxTime_s, nOfPoints, x0_m, stiffness_N_m, drag_Ns_m, T_K)
		cdf = np.cumsum(pdf)
		cdf -= cdf[0]
		if cdf[-1]!=0:
			cdf /= cdf[-1]
		else:
			cdf -= 5
		return cdf

	def objective(params):
		x0_m, stiffness, drag_Ns_m = params
		theoretical_cdf = getTheoreticalCdf(x0_m=x0_m, stiffness_N_m=stiffness, drag_Ns_m=drag_Ns_m)
		s = np.sum((theoretical_cdf - x) ** 2)
		print(s)
		return s
	initial_guess = [50e-9, 10e-6, 28e-9]
	bounds = [(1e-10, 1e-7), (1e-11,1e-4), (20e-6,30e-6)]
	result = differential_evolution(objective, bounds)

	print(f"Optimized parameters: {result.x}")
	x0_m, stiffness_N_m, drag_Ns_m = result.x
	foundResults.append(result.x)
	theoretical_cdf_opt = getTheoreticalCdf(x0_m=x0_m, stiffness_N_m=stiffness_N_m, drag_Ns_m=drag_Ns_m)
	drag_pNms_nM = drag_Ns_m*1e12*1e3/1e9
	stiffness_pN_nm = stiffness_N_m*1e12/1e9
	x0_nm = x0_m*1e9
	plt.figure(f"CDF setpoint {x0}")
	plt.plot(t*1e3,x, label=f'Empirical CDF ({newFileName})')
	plt.plot(t*1e3, theoretical_cdf_opt, label=f'Theoretical CDF, setpoint {x0_nm}nm, stiffness {stiffness_pN_nm}pN/nm, drag {drag_pNms_nM}pN ms/nm')
	plt.legend()
	plt.xlabel("ms")
	plt.ylabel("CFD")

	plt.show()
	plt.figure(f"PDF setpoint {x0}")
	t,pdf = interactWithJulia.getFPTFromJuliaScript(maxTime_s, len(x), x0_m, stiffness_N_m, drag_Ns_m)
	plt.plot(t*1e3,pdf*1e-3, label=f'Empirical PDF ({newFileName})')
	t,x=plotFirstPassagePdf.getTimingProbabilitiesFox_x0x1(baseFile)
	plt.plot(t*1e3,x*1e-3, label=f'Theoretical PDF, setpoint {x0_nm}nm, stiffness {stiffness_pN_nm}pN/nm, drag {drag_pNms_nM}pN ms/nm')
	plt.show()

print(foundResults)
a=1
#013 0.005 [6.10264604e-09 6.81908163e-05 6.16294955e-07]
#014 0.005 [5.94840761e-09 6.87628186e-05 5.87929612e-07]
#015 0.02  [1.36551225e-08 4.69721824e-05 7.57224292e-07]