
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


def firstPassageTime(x, dt, pointResolution, maxConsideredTime, usedDataRatio = 1):
	'''returns the probability density functions of the first passage time of 
	signal x as function of starting point and passage point'''

	#dimensions: [starting point, passage point, fpi], value = pdf(fpi | starting point, passage point)
	maxIndex = int(np.ceil(maxConsideredTime/dt))
	fpt = np.zeros((pointResolution, pointResolution, maxIndex))
	# Calculate the number of values to exclude from each end
	exclude_count = int(len(x) * (1 - usedDataRatio) / 2)
	x_sorted = np.sort(x)
	xm = x_sorted[exclude_count]
	xM = x_sorted[-exclude_count-1]
	x = ((x - xm) / (xM - xm) * (pointResolution)).astype(int)
	x = np.clip(x, a_min=0, a_max= pointResolution-1)
	lastIndexes = np.repeat(-maxIndex, pointResolution)
	# for i in range(len(x)):
	# 	maxUsedIndex = min(len(x)-1, i+maxIndex)
	# 	np.add.at(fpt, (x[i], x[i+1:maxUsedIndex],np.arange(1, maxUsedIndex-i)), 1)
	prevX = x[0]
	lastIndexes[prevX] = 0
	for i in range(1, len(x)):
		usedIndexes = i - lastIndexes < maxIndex
		newPoints = np.arange(prevX+1,x[i]+1) if prevX<x[i] else (np.arange(prevX-1, x[i]-1,-1) if prevX>x[i] else [prevX])
		for j in newPoints:
			fpt[usedIndexes, j, i - lastIndexes[usedIndexes]] += 1
			lastIndexes[j] = i
		prevX = x[i]
	fpt = np.cumsum(fpt, axis=2)
	fullIndexes = fpt[:,:,-1] > 0
	fpt[fullIndexes, :] /= fpt[fullIndexes, -1][:,None]
	# Calculate the derivative of fpt along its third dimension (axis=2)
	dfpt = derivativeForCDF(fpt)#np.diff(fpt, axis=2, prepend=0)
	# dfpt[:,:,0] = 0
	def fptFun(t, startPoint, passagePoint):
		index = (t / dt).astype(int)
		startPoint = ((startPoint - xm) / (xM - xm) * pointResolution).astype(int)
		passagePoint = ((passagePoint - xm) / (xM - xm) * pointResolution).astype(int)
		index = np.clip(index, a_min=0, a_max=maxIndex-1)
		startPoint = np.clip(startPoint, a_min=0, a_max=pointResolution-1)
		passagePoint = np.clip(passagePoint, a_min=0, a_max=pointResolution-1)
		return dfpt[startPoint, passagePoint, index]
	return fptFun, (xm, xM)






# t=np.sort(np.random.random(100))
# x = np.random.random(100)*np.linspace(.5,1,100)
# x[-1]=2
# q = signalForFPT(t,x)
# plt.plot(t,x)
# plt.scatter(t,x)
# idx = q._getIdxList()
# tt = q.timeAtIdx(idx)
# plt.plot(tt,q(tt))
# plt.show()
# print(q._getIdxList())

def derivativeForCDF(cdf):
	paddingShape = list(np.shape(cdf))
	paddingShape[-1] = 1
	padding = np.zeros(paddingShape)
	difference = np.concatenate((cdf[...,1:],cdf[...,-1:]), axis=-1) - np.concatenate((padding, cdf[...,:-1]), axis=-1)
	firstValue = np.zeros_like(difference, dtype=bool)
	firstValue[...,0] = True
	nonNullIndexes = np.array( np.where(np.logical_or(firstValue,difference > 0)))
	# if nonNullIndexes[0] != 0:
	# 	nonNullIndexes = np.concatenate(([0], nonNullIndexes))
	distanceBetweenNonNullValues = nonNullIndexes[...,1:]-nonNullIndexes[...,:-1]

	for i in range(len(distanceBetweenNonNullValues)):
		if nonNullIndexes[0,i]<=10 and nonNullIndexes[1,i]>=49:
			i+=0
		if(np.all(nonNullIndexes[:-1,i]==nonNullIndexes[:-1,i+1])):
			current_nni = nonNullIndexes[-1,i]
			next_nni = nonNullIndexes[-1,i+1]
			difference[current_nni,current_nni+1:next_nni+1] = difference[current_nni, next_nni] / distanceBetweenNonNullValues[-1,i]
	return difference



	# pdf = np.interp(x, x[nonNullValues], difference[nonNullValues])

def getSignalfromNidaqAcquisition(fileName, filteringTime_s):
	'''
	returns all the sorted transition timings from x0 to x1 and (if bothTransitions is True) from x1 to x0

	bothTransitions: if True, returns both x0x1 and x1x0 transitions (the returned value will be a tuple)

	onlyLongTransitions: if True, only the longest timings of a transition will be returned
		example, if the data says that the particle passed for x0 2 times before passing for x1, 
		only the timing between the first x0 crossing and the x1 crossing will be returned
	'''
	self = acquisition(fileName)
	t, x = self.nidaq_t_x
	windowSize = int(filteringTime_s / (t[1]-t[0]))
	x -= np.convolve(x, np.ones(windowSize)/windowSize, mode='same')
	return x

if __name__=="__main__":
	# acquisition.createNewFigure=False
	# a=acquisition("d:/lastline/bioTweezers/18_4_25/FPT_150mA_setpoint.02_001_bioControllerAcquisition.csv")
	# a.plotNidaqAcquisition(False, True)
	# x0=[10,15,30]					# in nm
	# k0=10e-3						# in pN/nm
	# gamma=30e-3						# in pN*ms/nm
	# t = np.linspace(0, 20, 10000)	# in ms

	# P = FTP_PDF(t, x0, k0, gamma)
	# plt.plot(t, P, label=[f"x0={x} nm" for x in x0])
	# plt.xlabel("Time (ms)")
	# plt.ylabel("Probability distribution function")
	# plt.legend()
	# plt.show()

	# P = FTP_CDF(t, x0, k0, gamma)
	# plt.plot(t, P, label=[f"x0={x} nm" for x in x0])
	# plt.xlabel("Time (ms)")
	# plt.ylabel("Cumulative distribution function")
	# plt.legend()
	# plt.show()
	
	# dt = .2e-3
	nOfSamples = 10000
	# maxConsideredTime = dt*40
	# # x = np.sin(np.linspace(0,nOfSamples, nOfSamples)/2.01*np.pi/maxConsideredTime*0.0007)+np.random.random(nOfSamples)*0.3# 
	# # Apply a moving average (lowpass) filter of 10 samples to x

	# x=np.random.random(nOfSamples)
	# window_size = 2
	# window = np.ones(window_size)
	# window[::2] = -1
	# x = np.convolve(x-np.mean(x), window, mode='same')
	
	x = getSignalfromNidaqAcquisition("d:/lastline/bioTweezers/someOfTheDataFrom7_8_25/set05_cell_bead_002.csv", 0.5)
	maxConsideredTime = 8e-3
	dt = 1e-4
	fpt, (xm,xM) = firstPassageTime(x, dt, 100, maxConsideredTime, usedDataRatio = 0.99)
	from mpl_toolkits.mplot3d import Axes3D

	# Create a uniform grid for x and y
	startPoint = np.linspace(xm, xM, 100)
	t = np.linspace(0, maxConsideredTime, int(maxConsideredTime / dt))
	startPoint, t = np.meshgrid(startPoint, t)

	# Evaluate z over the grid
	z = fpt(t, startPoint, 0)

	# Plot the surface
	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	ax.plot_surface(startPoint, t, z, cmap='viridis')

	# Label axes
	ax.set_xlabel('start point')
	ax.set_ylabel('t')
	ax.set_zlabel('CDF')

	plt.title('3D Surface Plot of z = f(x, y)')
	plt.show()
	
	# Evaluate z over the grid
	z = fpt(t, startPoint, xM*0.5)

	# Plot the surface
	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	ax.plot_surface(startPoint, t, z, cmap='viridis')

	# Label axes
	ax.set_xlabel('start point')
	ax.set_ylabel('t')
	ax.set_zlabel('CDF')

	plt.title('3D Surface Plot of z = f(x, y)')
	plt.show()



	