
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
basePath = "D:/lastline/bioTweezers/folderForFits"
#				file idx, setpoint
usedFileIdx =  [2  , 	#	???,
				# 3 , 	#	???,
				# 4 , 	#	???,
				]
usedFiles = [plotFirstPassagePdf.getBaseFileNameFromIdx(basePath, i) for i in usedFileIdx]
foundResults = []

def FTP_PDF_nonNormalized(t, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):	
	inputList = [x0_m, stiffness_N_m, drag_Ns_m, T_K]
	maxLength = max(map(lambda l: len(l) if isinstance(l, (list, np.ndarray)) else 1, inputList))
	for i in range(len(inputList)):
		if isinstance(inputList[i], list):
			inputList[i] = np.array(inputList[i])
		elif not isinstance(inputList[i], np.ndarray):
			inputList[i] = np.repeat(inputList[i], maxLength)
	(x0_m, stiffness_N_m, drag_Ns_m, T_K) = tuple(inputList)
	
	kBoltzman = 1.3806504e-23
	A = drag_Ns_m/(2*kBoltzman*T_K)
	omega = stiffness_N_m/drag_Ns_m
	O = np.outer(omega, t)
	tau = (1 - np.exp(-2 * O)) / (2 * omega[:, None])
	P = np.sqrt(A[:, None]) * np.abs(x0_m[:, None]) * np.exp(-O) / np.sqrt(2 * np.pi * tau**3) * np.exp(-A[:, None] * x0_m[:, None]**2 * np.exp(-2 * O) / (2 * tau))
	P[:,t==0] = 0
	return P
def FTP_CDF(t, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):	
	P = FTP_PDF_nonNormalized(t, x0_m, stiffness_N_m, drag_Ns_m, T_K)
	dt = np.concatenate(([t[0]],np.diff(t)))
	C = np.cumsum(P * dt[None,:], axis = 1)
	C -= (C[:,0])[:,None]
	C /= (C[:,-1])[:,None]
	return C
def FTP_PDF(t, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):
	P = FTP_PDF_nonNormalized(t, x0_m, stiffness_N_m, drag_Ns_m, T_K)
	dt = np.concatenate(([t[0]],np.diff(t)))
	sum = np.sum(P * dt[None,:], axis = 1)
	P /= sum[:,None]
	return P

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
# dimensions:
# 	setpoint:	nm 		 = 1e-9 m
# 	stiffness:	pN/nm 	 = 1e-3 N/m
# 	drag:		pN*ms/nm = 1e-6 N*s/m
	stiffness, drag_Ns_m, meterScale = params[:3]
	x0_m_values = params[3:]
	total_s = 0
	for i in range(len(usedFiles)):
		x = x_arrays[i]
		t = np.linspace(0, max_times[i],len(x))
		theoretical_cdf = FTP_CDF(t, x0_m=x0_m_values[i] * meterScale, stiffness_N_m=stiffness / meterScale, drag_Ns_m=drag_Ns_m / meterScale)
		s = np.sum((theoretical_cdf - x) ** 2)
		total_s += s
	print(total_s)
	return total_s

initial_guess = [10e-6, 28e-9, 1] + [50e-9] * len(usedFiles)
bounds = [(1e-11, 1e-4), (20e-9, 30e-9), (1e-2, 1e2)] + [(1e-10, 1e-7)] * len(usedFiles)
result = differential_evolution(objective, bounds)

# result.x = [2.26415350e-06, 2.80607625e-08, 7.69547381e-08, 4.32306280e-08, \
#  2.36452550e-08, 8.03034386e-08, 6.24333857e-08]
print(f"Optimized parameters: {result.x}")
stiffness_N_m, drag_Ns_m, meterScale = result.x[:3]
x0_m_values = result.x[3:]
foundResults.append(result.x)

print(stiffness_N_m, drag_Ns_m, meterScale)

for i in range(len(x0_m_values)):
	t = np.linspace(0, max_times[i], len(x_arrays[i]))
	plt.plot(t, x_arrays[i], label=f"{i}")
	plt.plot(t, FTP_CDF(t, x0_m_values[i] * meterScale, stiffness_N_m / meterScale, drag_Ns_m / meterScale)[0], label=f"{i}: {x0_m_values[i]}")
plt.legend()
plt.show()
# for i in range(len(x0_m_values)):
# 	t = np.linspace(0, max_times[i], len(x_arrays[i]))
# 	pdf = FTP_PDF(t, x0_m=x0_m_values[i], stiffness_N_m=stiffness_N_m, drag_Ns_m=drag_Ns_m)
# 	theoreticalMean = (t[:,None].dot(pdf) / np.sum(pdf))[0]
# 	x_pdf = np.diff(x_arrays[i])
# 	experimentalMean = t[:,None].dot(x_pdf) / np.sum(x_pdf)
# 	ppdf = pdf#np.interp(x_arrays[i], np.linspace(0,1,len(pdf)), pdf)
# 	cdf = np.cumsum(ppdf)
# 	cdf -= cdf[0]
# 	cdf /= cdf[-1]
# 	# ksTest = acquisition.Kolmogorov_Smirnov_test(cdf, x_arrays[i])
# 	# print(f"#{i:03d}\tstiffness: {x0_m_values[i]:.3e}\ttheor. average: {theoreticalMean:.3e}\t exp. average: {experimentalMean:.3e}\t KS test: {ksTest:.3e}")

# #013 0.005 [6.10264604e-09 6.81908163e-05 6.16294955e-07]
# #014 0.005 [5.94840761e-09 6.87628186e-05 5.87929612e-07]
# #015 0.02  [1.36551225e-08 4.69721824e-05 7.57224292e-07]
