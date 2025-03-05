
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

baseFile = 'C:/Users/lastline/Documents/bioTweezers/20_2_5/newBead_constantStiffness_015.csv'
# plotTimingsProbabilities(baseFile, removeRanges=[])
q = plotFirstPassagePdf.getTimings_x0x1_and_x1x0(baseFile, [])
if isinstance(q, tuple):
	x0x1, _= q
else:
	x0x1 = q
x=np.sort(x0x1)
x = x[x<0.02]
# x = signal.decimate(x, 10)
x -= x[0]
x /= x[-1]
t = np.linspace(0,1,len(x))

def getTheoreticalCdf(maxTime_s=np.max(x), nOfPoints = len(x), x0_m = 0, stiffness_N_m = 13e-6, drag_Ns_m = 0, T_K = 300):
	t,pdf = interactWithJulia.getFPTFromJuliaScript(maxTime_s, nOfPoints, x0_m, stiffness_N_m, drag_Ns_m, T_K)
	cdf = np.cumsum(pdf)
	cdf -= cdf[0]
	cdf /= cdf[-1]
	return cdf

def objective(params):
	x0_m, drag_Ns_m = params
	theoretical_cdf = getTheoreticalCdf(x0_m=x0_m, drag_Ns_m=drag_Ns_m)
	s = np.sum((theoretical_cdf - x) ** 2)
	print(s)
	return s

initial_guess = [1e-9, 28e-6]
result = minimize(objective, initial_guess, method='Nelder-Mead')
x0_m_opt, stiffness_N_m_opt, drag_Ns_m_opt = result.x

print(f"Optimized parameters: x0_m = {x0_m_opt}, stiffness_N_m = {stiffness_N_m_opt}, drag_Ns_m = {drag_Ns_m_opt}")

theoretical_cdf_opt = getTheoreticalCdf(x0_m=x0_m_opt, stiffness_N_m=stiffness_N_m_opt, drag_Ns_m=drag_Ns_m_opt)
plt.plot(t, x, label='Empirical CDF')
plt.plot(t, theoretical_cdf_opt, label='Theoretical CDF')
plt.legend()

plt.show()