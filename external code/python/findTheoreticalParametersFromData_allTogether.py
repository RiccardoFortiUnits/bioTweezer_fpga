
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
import acquisition
basePath = "D:/lastline/bioTweezers/20_2_5"
#				file idx, setpoint
usedFileIdx =  [9  , 	#	0.015,
				12 , 	#	0.010,
				14 , 	#	0.005,
				15 , 	#	0.020,
				16 , 	#	-0.015
				]
usedFiles = [plotFirstPassagePdf.getBaseFileNameFromIdx(basePath, i) for i in usedFileIdx]
foundResults = []
def getTheoreticalCdf(maxTime_s, nOfPoints, x0_m=0, stiffness_N_m=13e-6, drag_Ns_m=0, T_K=300):
	t, pdf = interactWithJulia.getFPTFromJuliaScript(maxTime_s, nOfPoints, x0_m, stiffness_N_m, drag_Ns_m, T_K)
	cdf = np.cumsum(pdf)
	cdf -= cdf[0]
	if cdf[-1] != 0:
		cdf /= cdf[-1]
	else:
		cdf -= 5
	return cdf

# Precompute x arrays and maxTime_s values
x_arrays = []
max_times = []
for baseFile in usedFiles:
	q = plotFirstPassagePdf.getTimings_x0x1_and_x1x0(baseFile, [])
	x0, x1 = plotFirstPassagePdf.getValuesOf_x0_and_x1(baseFile)
	if isinstance(q, tuple):
		x0x1, _ = q
	else:
		x0x1 = q
	x = np.sort(x0x1)
	x -= x[0]
	maxTime_s = x[-1]
	x = np.interp(np.linspace(0, 1, len(x)), x / x[-1], np.linspace(0, 1, len(x)))
	x_arrays.append(x)
	max_times.append(maxTime_s)

def objective(params):
	stiffness, drag_Ns_m = params[:2]
	x0_m_values = params[2:]
	total_s = 0
	for i in range(len(usedFiles)):
		x = x_arrays[i]
		maxTime_s = max_times[i]
		theoretical_cdf = getTheoreticalCdf(maxTime_s=maxTime_s, nOfPoints=len(x), x0_m=x0_m_values[i], stiffness_N_m=stiffness, drag_Ns_m=drag_Ns_m)
		s = np.sum((theoretical_cdf - x) ** 2)
		total_s += s
	print(total_s)
	return total_s

initial_guess = [10e-6, 28e-9] + [50e-9] * len(usedFiles)
bounds = [(1e-11, 1e-4), (20e-9, 30e-9)] + [(1e-10, 1e-7)] * len(usedFiles)
result = differential_evolution(objective, bounds)

# result.x = [2.26415350e-06, 2.80607625e-08, 7.69547381e-08, 4.32306280e-08, \
#  2.36452550e-08, 8.03034386e-08, 6.24333857e-08]
print(f"Optimized parameters: {result.x}")
stiffness_N_m, drag_Ns_m = result.x[:2]
x0_m_values = result.x[2:]
foundResults.append(result.x)
for i in range(len(x0_m_values)):
	tt_, pdf = interactWithJulia.getFPTFromJuliaScript(maxTime_s=max_times[i], nOfPoints=len(x_arrays[i]), x0_m=x0_m_values[i], stiffness_N_m=stiffness_N_m, drag_Ns_m=drag_Ns_m)
	theoreticalMean = (np.linspace(0, max_times[i], len(pdf)).dot(pdf) / np.sum(pdf))[0]
	x_pdf = np.diff(x_arrays[i])
	experimentalMean = np.linspace(0, max_times[i], len(x_pdf)).dot(x_pdf) / np.sum(x_pdf)
	ppdf = pdf#np.interp(x_arrays[i], np.linspace(0,1,len(pdf)), pdf)
	cdf = np.cumsum(ppdf)
	cdf -= cdf[0]
	cdf /= cdf[-1]
	ksTest = acquisition.Kolmogorov_Smirnov_test(cdf, x_arrays[i])
	print(f"#{i:03d}\tstiffness: {x0_m_values[i]:.3e}\ttheor. average: {theoreticalMean:.3e}\t exp. average: {experimentalMean:.3e}\t KS test: {ksTest:.3e}")

#013 0.005 [6.10264604e-09 6.81908163e-05 6.16294955e-07]
#014 0.005 [5.94840761e-09 6.87628186e-05 5.87929612e-07]
#015 0.02  [1.36551225e-08 4.69721824e-05 7.57224292e-07]
