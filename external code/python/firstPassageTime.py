
# import matplotlib.pyplot as plt
# import numpy as np
# from acquisition import acquisition

# '''
# dimensions:
# 	setpoint:	nm 		 = 1e-9 m
# 	stiffness:	pN/nm 	 = 1e-3 N/m
# 	drag:		pN*ms/nm = 1e-6 N*s/m

# '''

# def FTP_PDF(t_ms, x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K = 300):
# 	'''calculates the theoretical probability distribution function of the first passage time (FPT) for a harmonic potential.
# 	Formula obtained from Costantino's Julia script, for the case in which k(t) = constant (=stiffness_pN_nm).
	
# 	if x0_nm and/or stiffness_pN_nm and/or drag_pNms_nm are lists, the function will return a matrix with the PDF for each combination of values.
# 	'''

# 	#let's convert all the input parameters into lists (if they are not already)
# 	inputList = [x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K]
# 	maxLength = max(map(lambda l: len(l) if isinstance(l, (list, np.ndarray)) else 1, inputList))
# 	for i in range(len(inputList)):
# 		if isinstance(inputList[i], list):
# 			inputList[i] = np.array(inputList[i])
# 		elif not isinstance(inputList[i], np.ndarray):
# 			inputList[i] = np.repeat(inputList[i], maxLength)
# 	(x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K) = tuple(inputList)
	
# 	kBoltzman = 1.3806504e-23 * 1e12 * 1e9 # in pN*nm/K

# 	A = drag_pNms_nm/(2*kBoltzman*T_K)
# 	omega = stiffness_pN_nm/drag_pNms_nm

# 	'''if we had only one value for each parameter, the following code would be equivalent to:
	
# 	OMEGA = omega * t_ms
# 	tau = (1 - np.exp(-2 * OMEGA)) / (2 * omega)
# 	P = np.sqrt(A) * np.abs(x0_nm) * np.exp(-OMEGA) / np.sqrt(2 * np.pi * tau**3) * np.exp(-A * x0_nm**2 * np.exp(-2 * OMEGA) / (2 * tau))	
# 	'''
# 	OMEGA = np.outer(omega, t_ms)
# 	tau = (1 - np.exp(-2 * OMEGA)) / (2 * omega[:, None])
# 	P = np.sqrt(A[:, None]) * np.abs(x0_nm[:, None]) * np.exp(-OMEGA) / np.sqrt(2 * np.pi * tau**3) * np.exp(-A[:, None] * x0_nm[:, None]**2 * np.exp(-2 * OMEGA) / (2 * tau))

# 	#for t->0, PDF(t)->0, but when calculating it, we obtain NaN. Let's set it to 0
# 	P[:,t_ms==0] = 0
# 	return P.T

# def FTP_CDF(t_ms, x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K = 300, normalize = True):
# 	'''Cumulative distribution function of the FPT, it's simply the integral of the calculated PDF'''
# 	P = FTP_PDF(t_ms, x0_nm, stiffness_pN_nm, drag_pNms_nm, T_K).T
# 	dt = np.concatenate(([t_ms[0]],np.diff(t_ms)))
# 	C = np.cumsum(P * dt[None,:], axis = 1)
# 	if normalize:
# 		'''in case you are not considering the entire range, or if the time resolution is
# 		not high enough, we would have C[:,-1] < 1. In this case, 
# 		you might have problems with comparing this curve with an experimental 
# 		one (which would be normalized, no matter if the entire range is included or not).
		
# 		Let's normalize the data so that the first point is 0 and the last one is 1'''
# 		C -= (C[:,0])[:,None]
# 		C /= (C[:,-1])[:,None]

# 	return C.T





# # t=np.sort(np.random.random(100))
# # x = np.random.random(100)*np.linspace(.5,1,100)
# # x[-1]=2
# # q = signalForFPT(t,x)
# # plt.plot(t,x)
# # plt.scatter(t,x)
# # idx = q._getIdxList()
# # tt = q.timeAtIdx(idx)
# # plt.plot(tt,q(tt))
# # plt.show()
# # print(q._getIdxList())

# def FPT_PDF_fromData(x, t, setpoint0, setpoint1 = 0, bins = 100, onlyLongTransitions = False):
# 	'''
# 	returns the probability distribution function (PDF) of the first passage time (FPT) of a signal x, with the corresponding times.
	
# 	x: signal on which the first passage time is calculated

# 	t: corresponding timings of the signal

# 	setpoint0: inital setpoint. The first passage times will start when x crosses this value

# 	setpoint1: final setpoint. The first passage times will end when x crosses this value
	
# 	bins: number of points of the obtained PDF

# 	onlyLongTransitions: if True, only the longest timings of a transition will be returned
# 	example, if the data says that the particle passed for setpoint0 2 times before passing for setpoint1, 
# 	only the timing between the first setpoint0 crossing and the setpoint1 crossing will be returned

# 	Returns:
# 		(fpt, pdf): the first passage time and the corresponding probability density function (PDF) (Probability(first passage time == fpt[i]) = pdf[i])
# 	'''
# 	x0, x1 = setpoint0, setpoint1
# 	x0Crosses = (x[:-1] - x0) * (x[1:] - x0) <= 0
# 	x1Crosses = (x[:-1] - x1) * (x[1:] - x1) <= 0

# 	startIndexes = np.where(x0Crosses)[0]
# 	endIndexes = np.where(x1Crosses)[0]
# 	startIndexes = startIndexes[startIndexes < endIndexes[-1]]
# 	startIdxPositionInEndIndices = np.searchsorted(endIndexes, startIndexes, side = 'left')
# 	if onlyLongTransitions:
# 		startIndexes = startIndexes[np.concatenate(([0],1+np.where(startIdxPositionInEndIndices[:-1] != startIdxPositionInEndIndices[1:])[0]))]
# 		startIdxPositionInEndIndices = np.unique(startIdxPositionInEndIndices)

# 	transitionTimes = t[endIndexes[startIdxPositionInEndIndices]] - t[startIndexes]
# 	transitionTimes = np.sort(transitionTimes)
# 	count, fpt = np.histogram(transitionTimes, bins=bins)
	
# 	count = np.cumsum(count)
# 	count = count / count[-1] * len(fpt) / fpt[-1]
# 	pdf = derivativeForCDF(count)
		
# 	return fpt, pdf


# def FPT_PDF_fromData_multipleSetpoints(x, dt, pointResolution, maxConsideredTime, usedDataRatio = 1):
# 	'''
# 	returns the function PDF(fpt, setpoint0, setpoint1), which gives the probability density functions of the first passage time of 
# 	signal x as function of starting point and final point, alongside the maximum and minimum values for the setpoints.
	
# 	x: signal on which the first passage time is calculated

# 	dt: time distance between two consecutive points in x (so, only uniformly sampled signals are supported)

# 	pointResolution: number of values considered for the setpoints. Any intermediate value will be approximated to the nearest value in the setpoints

# 	maxConsideredTime: highest considered value for the first passage time. Higher values give best results, but require a lot of memory.

# 	usedDataRatio: value to remove from the setpoint list a percentage of extreme values, that would not have enough passages to be statistically significant.
# 	For example, if usedDataRatio = 0.99, the 1% of extreme values (both lower and upper extremes) will be removed from the setpoint list
	
# 	Returns:
# 		(PDF, minSetpoint, maxSetpoint):
# 			PDF(fpt, setpoint0, setpoint1): probability density function of the first passage time, given the starting point and the passage point. All the input arguments can be given as arrays
			
# 			minSetpoint: minimum value of the setpoints used for the PDF. It depends on the usedDataRatio
			
# 			maxSetpoint: maximum value of the setpoints used for the PDF.
# 	'''
# 	maxIndex = int(np.ceil(maxConsideredTime/dt))
# 	fpt = np.zeros((pointResolution, pointResolution, maxIndex))
# 	# Calculate the number of values to exclude from each end
# 	exclude_count = int(len(x) * (1 - usedDataRatio) / 2)
# 	x_sorted = np.sort(x)
# 	xm = x_sorted[exclude_count]
# 	xM = x_sorted[-exclude_count-1]
# 	x = ((x - xm) / (xM - xm) * (pointResolution)).astype(int)
# 	x = np.clip(x, a_min=0, a_max= pointResolution-1)
# 	lastIndexes = np.repeat(-maxIndex, pointResolution)
# 	allIndexes = np.arange(0,pointResolution)
# 	prevX = x[0]
# 	lastIndexes[prevX] = 0
# 	for i in range(1, len(x)):
# 		usedIndexes = i - lastIndexes < maxIndex
# 		# if prevX<x[i]:
# 		# 	newPoints = np.arange(prevX+1,x[i]+1)
# 		# 	nonUpdatedPoints = np.logical_and(usedIndexes, np.logical_or(allIndexes <= prevX, allIndexes > x[i]))
# 		# 	fpt[nonUpdatedPoints, prevX+1:x[i]+1, i - lastIndexes[nonUpdatedPoints]] += 1
# 		# 	couples = np.triu_indices(len(newPoints), k=1)
# 		# 	fpt[newPoints[couples[1]], newPoints[couples[0]], 0] += 1
# 		# 	couples = (couples[0][usedIndexes[newPoints[couples[0]]]], couples[1][usedIndexes[newPoints[couples[0]]]])
# 		# 	fpt[newPoints[couples[0]], newPoints[couples[1]], i - lastIndexes[newPoints[couples[0]]]] += 1
# 		# elif prevX>x[i]:
# 		# 	newPoints = np.arange(prevX-1, x[i]-1,-1)
# 		# 	nonUpdatedPoints = np.logical_and(usedIndexes, np.logical_or(allIndexes < x[i], allIndexes >= prevX))
# 		# 	fpt[nonUpdatedPoints, x[i]+1:prevX+1, i - lastIndexes[nonUpdatedPoints]] += 1
# 		# 	couples = np.triu_indices(len(newPoints), k=1)
# 		# 	fpt[newPoints[couples[1]], newPoints[couples[0]], 0] += 1
# 		# 	couples = (couples[0][usedIndexes[newPoints[couples[0]]]], couples[1][usedIndexes[newPoints[couples[0]]]])
# 		# 	fpt[newPoints[couples[0]], newPoints[couples[1]], i - lastIndexes[newPoints[couples[0]]]] += 1
# 		# else:
# 		# 	fpt[prevX, prevX, 0] += 1

# 		# lastIndexes[newPoints] = i
# 		newPoints = np.arange(prevX+1,x[i]+1) if prevX<x[i] else (np.arange(prevX-1, x[i]-1,-1) if prevX>x[i] else [prevX])
# 		for j in newPoints:
# 			fpt[usedIndexes, j, i - lastIndexes[usedIndexes]] += 1
# 			lastIndexes[j] = i
# 		prevX = x[i]
# 	fpt = np.cumsum(fpt, axis=2)
# 	fullIndexes = fpt[:,:,-1] > 0
# 	fpt[fullIndexes, :] /= fpt[fullIndexes, -1][:,None]
# 	# Calculate the derivative of fpt along its third dimension (axis=2)
# 	dfpt = derivativeForCDF(fpt)
# 	def fptFun(t, startPoint, passagePoint):
# 		index = (t / dt).astype(int)
# 		startPoint = ((startPoint - xm) / (xM - xm) * pointResolution).astype(int)
# 		passagePoint = ((passagePoint - xm) / (xM - xm) * pointResolution).astype(int)
# 		index = np.clip(index, a_min=0, a_max=maxIndex-1)
# 		startPoint = np.clip(startPoint, a_min=0, a_max=pointResolution-1)
# 		passagePoint = np.clip(passagePoint, a_min=0, a_max=pointResolution-1)
# 		return dfpt[startPoint, passagePoint, index]
# 	return fptFun, xm, xM

# def derivativeForCDF(cdf, x = None):
# 	paddingShape = list(np.shape(cdf))
# 	paddingShape[-1] = 1
# 	padding = np.zeros(paddingShape)
# 	difference = np.concatenate((cdf, cdf[...,-1:]), axis=-1) - np.concatenate((padding, cdf), axis=-1)
# 	if x is not None:
# 		difference /= x
# 	firstValue = np.zeros_like(difference, dtype=bool)
# 	firstValue[...,0] = True
# 	nonNullIndexes = np.array( np.where(np.logical_or(firstValue,difference > 0)))
	
# 	distanceBetweenNonNullValues = nonNullIndexes[...,1:]-nonNullIndexes[...,:-1]

# 	if len(np.shape(cdf)) == 1:
# 		nonNullIndexes = nonNullIndexes[0]
# 		distanceBetweenNonNullValues = distanceBetweenNonNullValues[0]
# 		for i in range(len(distanceBetweenNonNullValues)):
# 			difference[nonNullIndexes[i]+1:nonNullIndexes[i+1]+1] = difference[nonNullIndexes[i+1]] / distanceBetweenNonNullValues[i]
# 	else:
# 		for i in range(len(distanceBetweenNonNullValues)):
# 			if(np.all(nonNullIndexes[:-1,i]==nonNullIndexes[:-1,i+1])):
# 				current_nni = nonNullIndexes[-1,i]
# 				next_nni = nonNullIndexes[-1,i+1]
# 				difference[current_nni,current_nni+1:next_nni+1] = difference[current_nni, next_nni] / distanceBetweenNonNullValues[-1,i]
# 	return difference

# def getSignalfromNidaqAcquisition(fileName, filteringTime_s):
# 	'''
# 	returns all the sorted transition timings from x0 to x1 and (if bothTransitions is True) from x1 to x0

# 	bothTransitions: if True, returns both x0x1 and x1x0 transitions (the returned value will be a tuple)

# 	onlyLongTransitions: if True, only the longest timings of a transition will be returned
# 		example, if the data says that the particle passed for x0 2 times before passing for x1, 
# 		only the timing between the first x0 crossing and the x1 crossing will be returned
# 	'''
# 	self = acquisition(fileName)
# 	t, x = self.nidaq_t_x
# 	windowSize = int(filteringTime_s / (t[1]-t[0]))
# 	x -= np.convolve(x, np.ones(windowSize)/windowSize, mode='same')
# 	return x

# if __name__=="__main__":
# 	# acquisition.createNewFigure=False
# 	# a=acquisition("d:/lastline/bioTweezers/18_4_25/FPT_150mA_setpoint.02_001_bioControllerAcquisition.csv")
# 	# a.plotNidaqAcquisition(False, True)
# 	# x0=[10,15,30]					# in nm
# 	# k0=10e-3						# in pN/nm
# 	# gamma=30e-3						# in pN*ms/nm
# 	# t = np.linspace(0, 20, 10000)	# in ms

# 	# P = FTP_PDF(t, x0, k0, gamma)
# 	# plt.plot(t, P, label=[f"x0={x} nm" for x in x0])
# 	# plt.xlabel("Time (ms)")
# 	# plt.ylabel("Probability distribution function")
# 	# plt.legend()
# 	# plt.show()

# 	# P = FTP_CDF(t, x0, k0, gamma)
# 	# plt.plot(t, P, label=[f"x0={x} nm" for x in x0])
# 	# plt.xlabel("Time (ms)")
# 	# plt.ylabel("Cumulative distribution function")
# 	# plt.legend()
# 	# plt.show()
	
# 	# dt = .2e-3
# 	# nOfSamples = 10000
# 	# # maxConsideredTime = dt*40
# 	# # # x = np.sin(np.linspace(0,nOfSamples, nOfSamples)/2.01*np.pi/maxConsideredTime*0.0007)+np.random.random(nOfSamples)*0.3# 
# 	# # # Apply a moving average (lowpass) filter of 10 samples to x

# 	# # x=np.random.random(nOfSamples)
# 	# # window_size = 2
# 	# # window = np.ones(window_size)
# 	# # window[::2] = -1
# 	# # x = np.convolve(x-np.mean(x), window, mode='same')
	
# 	x = getSignalfromNidaqAcquisition("d:/lastline/bioTweezers/20250709/set_01_cell_bead_001.csv", 0.5)
	
# 	# import pandas as pd
# 	# file_path = "c:/Users/lastline/Downloads/test_001.xlsx"
# 	# data = pd.read_excel(file_path)
# 	# data.head()
# 	# data['sum_mv']  = data['Sum'] * 1000
# 	# data['x_diff_mv']  = data['X-diff'] * 1000
# 	# data['y_diff_mv']  = data['y-diff'] * 1000
# 	# data['X'] = data['x_diff_mv'] / data['sum_mv'] #in um
# 	# #on the sensor, 1[adimensional] equals 1um
# 	# data['X'] *= 1000 #in nm

# 	# windowSize = int(0.5 / (0.001))
# 	# data['X'] -= np.convolve(data['X'], np.ones(windowSize)/windowSize, mode='same')
# 	# x = data['X'].to_numpy()

# 	# maxConsideredTime = 20e-3
# 	dt = 1e-3
# 	# fpt, xm,xM = FPT_PDF_fromData_multipleSetpoints(x, dt, 100, maxConsideredTime, usedDataRatio = 0.99)
# 	# from mpl_toolkits.mplot3d import Axes3D

# 	# # Create a uniform grid for x and y
# 	# startPoint = np.linspace(xm, xM, 100)
# 	# t = np.linspace(0, maxConsideredTime, int(maxConsideredTime / dt))
# 	# startPoint, t = np.meshgrid(startPoint, t)

# 	# # Evaluate z over the grid
# 	# z = fpt(t, startPoint, 0)

# 	# # Plot the surface
# 	fig = plt.figure()
# 	ax = fig.add_subplot(111, projection='3d')
# 	ax.plot_surface(startPoint, fpt, z, cmap='viridis')

# 	# Label axes
# 	ax.set_xlabel('start point')
# 	ax.set_ylabel('fpt')
# 	ax.set_zlabel('PDF')

# 	plt.title('PDF = FPT(fpt, start point, 0)')
	
	
# 	fpt, pdf = FPT_PDF_fromData(x, np.arange(len(x))*dt, 0.010, bins = 100)
# 	plt.plot(fpt, pdf)
# 	plt.show()


	

import matplotlib.pyplot as plt
import numpy as np

def FPT_CDF_fromData(x, t, setpoint0, setpoint1 = 0, bins = 100):
		'''
		returns the probability distribution function (PDF) of the first passage time (FPT) of a signal x, with the corresponding times.
		
		x: signal on which the first passage time is calculated

		t: corresponding timings of the signal

		setpoint0: inital setpoint. The first passage times will start when x crosses this value

		setpoint1: final setpoint. The first passage times will end when x crosses this value
		
		bins: number of points of the obtained PDF

		onlyLongTransitions: if True, only the longest timings of a transition will be returned
		example, if the data says that the particle passed for setpoint0 2 times before passing for setpoint1, 
		only the timing between the first setpoint0 crossing and the setpoint1 crossing will be returned

		Returns:
			(fpt, pdf): the first passage time and the corresponding probability density function (PDF) (Probability(first passage time == fpt[i]) = pdf[i])
		'''
		#stupid floats, differences that should be the same are not the same, let's just work with integers first and then rescale them at the end
		dt = t[1]-t[0]
		t = np.round(t/dt).astype(int)

		x0, x1 = setpoint0, setpoint1
		if not isinstance(x0, (list, np.ndarray)):
			x0 = np.array([x0])
			returnList = False
		else:
			if isinstance(x0, list):
				x0 = np.array(x0)
			returnList = True
		nOfSetpoints = x0.size
		x0 = np.array(x0)[None,:]
		x0Crosses = (x[:-1, None] - x0) * (x[1:, None] - x0) <= 0
		x1Crosses = (x[:-1] - x1) * (x[1:] - x1) <= 0

		startIndexes, startSetpointIndexes = np.where(x0Crosses)
		endIndexes = np.where(x1Crosses)[0]
		if len(endIndexes) < 1:
			raise Exception(f"the signal never crosses value {x1}")
		startSetpointIndexes = startSetpointIndexes[startIndexes < endIndexes[-1]]
		startIndexes = startIndexes[startIndexes < endIndexes[-1]]
		startIdxPositionInEndIndices = np.searchsorted(endIndexes, startIndexes, side = 'right')
		if len(startIndexes) < 1:
			raise Exception(f"the signal never crosses values {x0}")
		transitionTimes = t[endIndexes[startIdxPositionInEndIndices]] - t[startIndexes]
		transitionTimes = transitionTimes.astype(float) * dt#rescale back to float
		cdf = np.zeros((nOfSetpoints, bins))
		fpt = np.zeros((nOfSetpoints, bins))
		baseCdf = np.linspace(0, 1, bins)
		for i in range(nOfSetpoints):
			currentTransitionTimes = transitionTimes[startSetpointIndexes == i]
			currentTransitionTimes = np.concatenate(([0], np.sort(currentTransitionTimes)))
			fpt[i] = currentTransitionTimes[np.linspace(0, len(currentTransitionTimes)-1, bins, dtype=int)]
			
			unique, count = np.unique(fpt[i], return_counts=True)			
			uniqueIndexes = np.concatenate(([0],np.cumsum(count)[:-1]))
			cdf[i][:len(unique)] = baseCdf[uniqueIndexes]
			fpt[i][:len(unique)] = unique
			cdf[i][len(unique):] = 1
			fpt[i][len(unique)-1:] = np.linspace(unique[-1], unique[-1]*1.01,len(fpt[i]) - len(unique) + 1)
			
		if returnList:
			return fpt.T, cdf.T
		return fpt[0,:len(unique)], cdf[0,:len(unique)]
if __name__ =="__main__":

	#example signal
	dt = 0.1
	totalTime = 10000
	t = np.linspace(0,totalTime,int(totalTime / dt))
	x = np.random.randn(t.size)
	x = np.convolve(x, np.ones(100) / 100, mode="same")

	#first passage time for one setpoint
	timings, cdf = FPT_CDF_fromData(x, t, [.05, 0.1], 0, 100)
	pdf = np.array([np.gradient(cdf[:,i], timings[:,i]) for i in range(len(cdf[0]))])
	plt.plot(timings, pdf, label="PDF")
	plt.plot(timings, cdf, label="CDF")
	plt.legend()
	plt.show()

	#first passage time for multiple setpoints (3D plot)
	setpoints = np.linspace(-.2,.2,20)
	timings, cdf = FPT_CDF_fromData(x, t, setpoints, 0, 100)
	pdf = np.array([np.gradient(cdf[i], timings[i]) for i in range(len(cdf))])
	setpointGrid = np.repeat(setpoints[:,None], np.shape(timings)[1], axis=1)

	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	ax.plot_surface(setpointGrid, timings, cdf, cmap='viridis')
	ax.set_xlabel('start point')
	ax.set_ylabel('fpt')
	ax.set_zlabel('CDF')
	plt.title('CDF = FPT(fpt, start point, 0)')
	plt.show()

	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	ax.plot_surface(setpointGrid, timings, pdf, cmap='viridis')
	ax.set_xlabel('start point')
	ax.set_ylabel('fpt')
	ax.set_zlabel('PDF')
	plt.title('PDF = FPT(fpt, start point, 0)')
	plt.show()