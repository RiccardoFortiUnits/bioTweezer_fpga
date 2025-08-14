import numpy as np

def FPT_PDF_fromData(x, t, setpoint0, setpoint1 = 0, bins = 100, onlyLongTransitions = False):
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
	x0, x1 = setpoint0, setpoint1
	x0Crosses = (x[:-1] - x0) * (x[1:] - x0) <= 0
	x1Crosses = (x[:-1] - x1) * (x[1:] - x1) <= 0

	startIndexes = np.where(x0Crosses)[0]
	endIndexes = np.where(x1Crosses)[0]
	startIndexes = startIndexes[startIndexes < endIndexes[-1]]
	startIdxPositionInEndIndices = np.searchsorted(endIndexes, startIndexes, side = 'left')
	if onlyLongTransitions:
		startIndexes = startIndexes[np.concatenate(([0],1+np.where(startIdxPositionInEndIndices[:-1] != startIdxPositionInEndIndices[1:])[0]))]
		startIdxPositionInEndIndices = np.unique(startIdxPositionInEndIndices)

	transitionTimes = t[endIndexes[startIdxPositionInEndIndices]] - t[startIndexes]
	transitionTimes = np.sort(transitionTimes)
	count, fpt = np.histogram(transitionTimes, bins=bins)
	
	count = np.cumsum(count)
	count = count / count[-1]
	pdf = derivativeForCDF(count)
		
	return fpt, pdf


def FPT_PDF_fromData_multipleSetpoints(x, dt, pointResolution, maxConsideredTime, usedDataRatio = 1):
	'''
	returns the function PDF(fpt, setpoint0, setpoint1), which gives the probability density functions of the first passage time of 
	signal x as function of starting point and final point, alongside the maximum and minimum values for the setpoints.
	
	x: signal on which the first passage time is calculated

	dt: time distance between two consecutive points in x (so, only uniformly sampled signals are supported)

	pointResolution: number of values considered for the setpoints. Any intermediate value will be approximated to the nearest value in the setpoints

	maxConsideredTime: highest considered value for the first passage time. Higher values give best results, but require a lot of memory.

	usedDataRatio: value to remove from the setpoint list a percentage of extreme values, that would not have enough passages to be statistically significant.
	For example, if usedDataRatio = 0.99, the 1% of extreme values (both lower and upper extremes) will be removed from the setpoint list
	
	Returns:
		(PDF, minSetpoint, maxSetpoint):
			PDF(fpt, setpoint0, setpoint1): probability density function of the first passage time, given the starting point and the passage point. All the input arguments can be given as arrays
			
			minSetpoint: minimum value of the setpoints used for the PDF. It depends on the usedDataRatio
			
			maxSetpoint: maximum value of the setpoints used for the PDF.
	'''
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
	dfpt = derivativeForCDF(fpt)
	def fptFun(t, startPoint, passagePoint):
		index = (t / dt).astype(int)
		startPoint = ((startPoint - xm) / (xM - xm) * pointResolution).astype(int)
		passagePoint = ((passagePoint - xm) / (xM - xm) * pointResolution).astype(int)
		index = np.clip(index, a_min=0, a_max=maxIndex-1)
		startPoint = np.clip(startPoint, a_min=0, a_max=pointResolution-1)
		passagePoint = np.clip(passagePoint, a_min=0, a_max=pointResolution-1)
		return dfpt[startPoint, passagePoint, index]
	return fptFun, xm, xM

def derivativeForCDF(cdf, x = None):
	paddingShape = list(np.shape(cdf))
	paddingShape[-1] = 1
	padding = np.zeros(paddingShape)
	difference = np.concatenate((cdf, cdf[...,-1:]), axis=-1) - np.concatenate((padding, cdf), axis=-1)
	if x is not None:
		difference /= x
	firstValue = np.zeros_like(difference, dtype=bool)
	firstValue[...,0] = True
	nonNullIndexes = np.array( np.where(np.logical_or(firstValue,difference > 0)))
	
	distanceBetweenNonNullValues = nonNullIndexes[...,1:]-nonNullIndexes[...,:-1]

	if len(np.shape(cdf)) == 1:
		nonNullIndexes = nonNullIndexes[0]
		distanceBetweenNonNullValues = distanceBetweenNonNullValues[0]
		for i in range(len(distanceBetweenNonNullValues)):
			difference[nonNullIndexes[i]+1:nonNullIndexes[i+1]+1] = difference[nonNullIndexes[i+1]] / distanceBetweenNonNullValues[i]
	else:
		for i in range(len(distanceBetweenNonNullValues)):
			if(np.all(nonNullIndexes[:-1,i]==nonNullIndexes[:-1,i+1])):
				current_nni = nonNullIndexes[-1,i]
				next_nni = nonNullIndexes[-1,i+1]
				difference[current_nni,current_nni+1:next_nni+1] = difference[current_nni, next_nni] / distanceBetweenNonNullValues[-1,i]
	return difference

if __name__=="__main__":
	import matplotlib.pyplot as plt

	#create a sample signal
	x = np.random.normal(0, 1, 10000)
	x = np.convolve(x, np.ones(30)/30, mode='same')  # Smoothing the signal
	t = np.arange(len(x))

	# Calculate the first passage time PDF for a specific couple of setpoints
	setpoint0 = 0.2
	setpoint1 = 0
	fpt, pdf = FPT_PDF_fromData(x, t, setpoint0, setpoint1, bins=100)

	#plot the results
	plt.plot(fpt, pdf)
	plt.title(f"FPT PDF for setpoint0={setpoint0}, setpoint1={setpoint1}")
	plt.show()

	# Calculate the first passage time PDF for multiple setpoints
	dt = 0.1
	maxConsideredTime = 2
	pointResolution = 40
	fptFun, minSetpoint, maxSetpoint = FPT_PDF_fromData_multipleSetpoints(x, dt, pointResolution, maxConsideredTime, usedDataRatio=0.90)

	#create a 3D surface plot with the first passage time PDF as a function of start point and fpt (end point == 0)
	# Create a uniform grid for x and y
	startPoint = np.linspace(minSetpoint, maxSetpoint, pointResolution)
	t = np.linspace(0, maxConsideredTime, int(maxConsideredTime / dt))
	startPoint, t = np.meshgrid(startPoint, t)

	# Evaluate z over the grid
	z = fptFun(t, startPoint, 0)

	# Plot the surface
	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	ax.plot_surface(startPoint, t, z, cmap='viridis')

	# Label axes
	ax.set_xlabel('start point')
	ax.set_ylabel('fpt')
	ax.set_zlabel('PDF')

	plt.title('PDF = FPT(fpt, start point, 0)')
	plt.show()

