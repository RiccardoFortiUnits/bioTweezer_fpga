
import matplotlib.pyplot as plt
import numpy as np
from acquisition import acquisition

'''
dimensions:
	setpoint:	nm 		 = 1e-9 m
	stiffness:	pN/nm 	 = 1e-3 N/m
	drag:		pN*ms/nm = 1e-6 N*s/m

'''

def FTP_PDF(t_ms, x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K = 300):
	'''calculates the theoretical probability distribution function of the first passage time (FPT) for a harmonic potential.
	Formula obtained from Costantino's Julia script, for the case in which k(t) = constant (=stiffness_pN_nm).
	
	if x0_nm and/or stiffness_pN_nm and/or drag_pNms_nm are lists, the function will return a matrix with the PDF for each combination of values.
	'''

	#let's convert all the input parameters into lists (if they are not already)
	inputList = [x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K]
	maxLength = max(map(lambda l: len(l) if isinstance(l, (list, np.ndarray)) else 1, inputList))
	for i in range(len(inputList)):
		if isinstance(inputList[i], list):
			inputList[i] = np.array(inputList[i])
		elif not isinstance(inputList[i], np.ndarray):
			inputList[i] = np.repeat(inputList[i], maxLength)
	(x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K) = tuple(inputList)
	
	kBoltzman = 1.3806504e-23 * 1e12 * 1e9 # in pN*nm/K

	A = drag_pNms_nm/(2*kBoltzman*T_K)
	omega = stiffness_pN_nm/drag_pNms_nm

	'''if we had only one value for each parameter, the following code would be equivalent to:
	
	OMEGA = omega * t_ms
	tau = (1 - np.exp(-2 * OMEGA)) / (2 * omega)
	P = np.sqrt(A) * np.abs(x0_nm) * np.exp(-OMEGA) / np.sqrt(2 * np.pi * tau**3) * np.exp(-A * x0_nm**2 * np.exp(-2 * OMEGA) / (2 * tau))	
	'''
	OMEGA = np.outer(omega, t_ms)
	tau = (1 - np.exp(-2 * OMEGA)) / (2 * omega[:, None])
	P = np.sqrt(A[:, None]) * np.abs(x0_nm[:, None]) * np.exp(-OMEGA) / np.sqrt(2 * np.pi * tau**3) * np.exp(-A[:, None] * x0_nm[:, None]**2 * np.exp(-2 * OMEGA) / (2 * tau))

	#for t->0, PDF(t)->0, but when calculating it, we obtain NaN. Let's set it to 0
	P[:,t_ms==0] = 0
	return P.T

def FTP_CDF(t_ms, x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K = 300, normalize = True):
	'''Cumulative distribution function of the FPT, it's simply the integral of the calculated PDF'''
	P = FTP_PDF(t_ms, x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K).T
	dt = np.concatenate(([t_ms[0]],np.diff(t_ms)))
	C = np.cumsum(P * dt[None,:], axis = 1)
	if normalize:
		'''in case you are not considering the entire range, or if the time resolution is
		not high enough, we would have C[:,-1] < 1. In this case, 
		you might have problems with comparing this curve with an experimental 
		one (which would be normalized, no matter if the entire range is included or not).
		
		Let's normalize the data so that the first point is 0 and the last one is 1'''
		C -= (C[:,0])[:,None]
		C /= (C[:,-1])[:,None]

	return C.T

if __name__=="__main__":
	acquisition.createNewFigure=False
	a=acquisition("d:/lastline/bioTweezers/18_4_25/FPT_150mA_setpoint.02_001_bioControllerAcquisition.csv")
	a.plotNidaqAcquisition(False, True)
	x0=[10,15,30]					# in nm
	k0=10e-3						# in pN/nm
	gamma=30e-3						# in pN*ms/nm
	t = np.linspace(0, 20, 10000)	# in ms

	P = FTP_PDF(t, x0, k0, gamma)
	plt.plot(t, P, label=[f"x0={x} nm" for x in x0])
	plt.xlabel("Time (ms)")
	plt.ylabel("Probability distribution function")
	plt.legend()
	plt.show()

	P = FTP_CDF(t, x0, k0, gamma)
	plt.plot(t, P, label=[f"x0={x} nm" for x in x0])
	plt.xlabel("Time (ms)")
	plt.ylabel("Cumulative distribution function")
	plt.legend()
	plt.show()