import pandas as pd
import numpy as np
from bioTweezerController import bioTweezerController
import matplotlib.pyplot as plt
from types import FunctionType, MethodType
from functools import partial
from scipy.optimize import differential_evolution
import interactWithJulia
import os
import glob
from scipy.optimize import curve_fit
import matplotlib.animation as animation



class acquisition():
	createNewFigure = True
	@staticmethod
	def newFigure(*vals):
		if acquisition.createNewFigure:
			plt.figure(*vals)
	@staticmethod
	def show():
		if acquisition.createNewFigure:
			plt.legend()
			plt.show()
	def genericPlot(self, x,y,label=None, plotFunction = plt.plot,*args,**kwargs):
		if label is None:
				plotFunction(x,y,*args,**kwargs)
		else:
			if not acquisition.createNewFigure:
				name = str.replace(os.path.basename(self.__baseFile),"_"," ")
				label = f"{name}: {label}"			
			plotFunction(x,y, label=label,*args,**kwargs)
	def plot(self, x,y,label=None, *args, **kwargs):
		self.genericPlot(x,y,label, plt.plot, *args, **kwargs)
	def step(self, x,y,label=None, *args, **kwargs):
		self.genericPlot(x,y,label, plt.step, *args, **kwargs)
	def loglog(self, x,y,label=None, *args, **kwargs):
		self.genericPlot(x,y,label, plt.loglog, *args, **kwargs)
	@staticmethod
	def getAllFilesProperties(folderPath, properties = ["binFeedback_x0", "binFeedback_valueWhenIn_x0"]):
		files = acquisition.getAllBaseFiles(folderPath)
		allProperties = []
		for file in files:
			acq = acquisition(file)
			filtered_properties = {key: acq.configurations[key]["Parameter value"] for key in properties if key in acq.configurations}
			filtered_properties["file"] = os.path.basename(file)
			allProperties.append(filtered_properties)
		return allProperties

	@staticmethod
	def getBaseSettingsFromFile(fileName='bio_controller.csv', device = "Bio Controller", returnType = list):
		pf = pd.read_csv(fileName, sep=',', lineterminator="\n", header=1)
		l = [dict(row) for index, row in pf.iterrows()]
		if '\r' in list(l[0].keys())[-1]:
			lastKey_slashR = list(l[0].keys())[-1]
			lastKey = lastKey_slashR.replace('\r','')
			for i in range(len(l)):
				l[i][lastKey] = l[i][lastKey_slashR].replace('\r','')
				l[i].pop(lastKey_slashR)
		if returnType == list:
			if device is not None:
				return [e for e in l if e["Device"] == device]
			else:
				return l		
		elif returnType == dict:
			if device is not None:
				return {e["Parameter internal name"] : e for e in l if e["Device"] == device}
			else:
				return {e["Parameter internal name"] : e for e in l}
		
	@staticmethod
	def getBaseFile(fileName):
		return fileName	.replace('.csv', '')\
						.replace('_bioControllerAcquisition', '')\
						.replace('_bioControllerTimings', '')\
						.replace('_conf', '')\
						.replace('_x0x1_timings', '')\
						.replace('_x1x0_timings', '')\
						.replace('_trajectory', '')
	
	@staticmethod
	def getAllBaseFiles(folderPath):
		allFiles = [os.path.abspath(file) for file in glob.glob(os.path.join(folderPath, "*.csv"))]
		allFiles = [acquisition.getBaseFile(file) for file in allFiles]
		allFiles = list(set(allFiles))
		return allFiles
	def getFile(self, fileType):
		return self.__baseFile + fileType
	def __init__(self, *args, **kwargs):
		'''
		input arguments: either the path of the files or the raw data
		the raw data must be given inside **kwargs with the following keys:
			- ai_buffer
			- bio_buffer
			- bio_configurations
			- crossTimings
		'''
		if len(args) == 1 and isinstance(args[0], str):
			baseFileName = args[0]
			self.__baseFile = acquisition.getBaseFile(baseFileName)
			self.file_nidaqAcquisition = self.getFile('.csv')
			self.file_bioControllerAcquisition = self.getFile('_bioControllerAcquisition.csv')
			self.file_bioControllerTimings = self.getFile('_bioControllerTimings.csv')
			self.file_conf = self.getFile('_conf.csv')
		else:
			for key in kwargs:
				setattr(self, f'_{key}', kwargs[key])

	def _genericPropertyFromFileOrFunctionOrValue(self, propertyName, getFromFileFunction):
		_propertyName = f'_{propertyName}'		
		if not hasattr(self, _propertyName):
			setattr(self, _propertyName, getFromFileFunction())
		val = getattr(self, _propertyName)
		if isinstance(val, (MethodType, FunctionType)):
			val = val()
		return val
	@property
	def ai_buffer(self):
		return self._genericPropertyFromFileOrFunctionOrValue("ai_buffer", self.getNidaqAcquisition)
	@property
	def bio_buffer(self):
		return self._genericPropertyFromFileOrFunctionOrValue("bio_buffer", self.getBioControllerAcquisition)
	@property
	def crossTimings(self):
		return self._genericPropertyFromFileOrFunctionOrValue("crossTimings", self.getBioControllerCrossings)
	@property
	def configurations(self):
		return self._genericPropertyFromFileOrFunctionOrValue("configurations", partial(acquisition.getBaseSettingsFromFile, self.file_conf, None, dict))
	
	@property
	def longTransitions(self):
		if not hasattr(self, '_longTransitions'):
			setattr(self, '_longTransitions', self.getBioControllerRawFPT(onlyLongTransitions=True))
		return self._longTransitions
	@property
	def allTransitions(self):
		if not hasattr(self, '_allTransitions'):
			setattr(self, '_allTransitions', self.getBioControllerRawFPT(onlyLongTransitions=False))
		return self._allTransitions
	
	@property
	def nidaq_t_x(self):
		def get_t_x():
			d=self.ai_buffer			
			t = np.array(d["Time (s)"])
			sum = np.array(d["AI2"])
			xdiff = np.array(d["AI3"])
			return t, xdiff/sum
		return self._genericPropertyFromFileOrFunctionOrValue("nidaq_t_x", get_t_x)
	@property
	def bio_t_x(self):
		def get_t_x():
			d=self.bio_buffer			
			t = np.array(d["times"])
			x = np.array(d["x"])
			return t, x
		return self._genericPropertyFromFileOrFunctionOrValue("bio_t_x", get_t_x)

	@staticmethod
	def _getAcquisitions(fileName, returnType = dict):
		pf = pd.read_csv(fileName, sep='\t', lineterminator='\n')
		if '\r' in pf.columns[-1]:
			column_noSlashR = pf.columns[-1].replace('\r','')
			pf[column_noSlashR] = pf[pf.columns[-1]]
			pf.drop(pf.columns[-2], axis=1, inplace=True)
		
		timeIndex = [i for i in range(len(pf.columns)) if 'time' in str.lower(pf.columns[i])][0]
		if returnType == dict:
			# t = pf[pf.columns[timeIndex]].to_numpy(dtype=np.float64)
			# pf.drop(pf.columns[timeIndex], axis=1, inplace=True)
			buf = {pf.columns[i] : pf[pf.columns[i]].to_numpy(dtype=np.float64) for i in range(len(pf.columns))}
			return buf
		elif returnType == np.ndarray:
			buf = pf.to_numpy(dtype=np.float64).T
			t = buf[timeIndex]
			buf = np.delete(buf, timeIndex, 0)
			return t,buf
		
	def getNidaqAcquisition(self, returnType = dict):
		return acquisition._getAcquisitions(self.file_nidaqAcquisition, returnType)
	def getBioControllerAcquisition(self, returnType = dict):
		return acquisition._getAcquisitions(self.file_bioControllerAcquisition, returnType)
	def getBioControllerCrossings(self, returnType = dict):
		pf = pd.read_csv(self.file_bioControllerTimings, sep='\t', lineterminator='\n')
		if '\r' in pf.columns[-1]:
			column_noSlashR = pf.columns[-1].replace('\r','')
			pf[column_noSlashR] = pf[pf.columns[-1]]
			pf.drop(pf.columns[-2], axis=1, inplace=True)

		t = pf["timing"]
		if min(t) >= 1:#old file with time in clock cycles?
			t/=bioTweezerController.fpga_controller_clock
		
		if returnType == dict:
			return {pf.columns[i] : pf[pf.columns[i]].to_numpy(dtype=np.float64) for i in range(len(pf.columns))}
		elif returnType == np.ndarray:
			return np.column_stack((t.to_numpy(dtype=np.float64), pf["reachedThreshold"].to_numpy(dtype = np.int8)))
		
	def getBioControllerRawFPT(self, bothTransitions = True, onlyLongTransitions = False):
		'''
		returns all the sorted transition timings from x0 to x1 and (if bothTransitions is True) from x1 to x0

		bothTransitions: if True, returns both x0x1 and x1x0 transitions (the returned value will be a tuple)

		onlyLongTransitions: if True, only the longest timings of a transition will be returned
			example, if the data says that the particle passed for x0 2 times before passing for x1, 
			only the timing between the first x0 crossing and the x1 crossing will be returned
		'''
		crossings = self.crossTimings
		t = np.array(crossings["timing"])
		reachedThresholds = np.array(crossings["reachedThreshold"])

		transitionIndexes = 1+np.where(reachedThresholds[1:]!=reachedThresholds[:-1])[0]#where we have a transition
		#elements after the last transition are not usable, because we don't have info on when the next cross would have been
		lastUsableIndex = transitionIndexes[-1]
		reachedThresholds = reachedThresholds[:lastUsableIndex+1]
		t = t[:lastUsableIndex+1]
		longestTimes=t[transitionIndexes]
		xx = [None] * (2 if bothTransitions else 1)
		for i in range(len(xx)):
			if not onlyLongTransitions:
				t[transitionIndexes]=0
				allTimes = longestTimes[np.searchsorted(transitionIndexes, np.arange(len(t)-1), side='right')] - t[1:]
				xx[i] = np.sort(allTimes[reachedThresholds[:-1] == i])
			else:
				xx[i] = np.sort(longestTimes[reachedThresholds[transitionIndexes] == 1-i])
		# x0x1 = np.sort(allTimes[reachedThresholds[:-1] == 1])
		if bothTransitions:
			x0x1,x1x0 = xx[0], xx[1]
			return x0x1, x1x0
		x0x1 = xx[0]
		return x0x1
	def getBioControllerFPT_CDF(self, bothTransitions = True, onlyLongTransitions = False):
		'''
		returns the Cumulative Distribution Function of the First Passage Time (FPT). The returned value is a tuple containing  
		'''
		q = self.getBioControllerRawFPT(bothTransitions, onlyLongTransitions)
		if not isinstance(q,tuple):
			q = (q,)
		cdf = []
		for x in q:
			x = np.append((0,x))#let's add probability 0 at the start
			t = np.linspace(0,1,len(x))
			cdf.append([x,t])

	
	def plotNidaqAcquisition(self):
		d = self.ai_buffer
		t, data = d["Time (s)"], d.copy()
		data.pop("Time (s)")
		acquisition.newFigure()
		self.plot(t, np.column_stack(list(data.values())), label = list(data.keys()), alpha = 0.5)
		acquisition.show()
	def plotBioControllerAcquisition(self):
		d = self.bio_buffer
		t, data = d["times"], d.copy()
		data.pop("times")
		acquisition.newFigure()
		self.plot(t, np.column_stack(list(data.values())), label = list(data.keys()), alpha = 0.5)
		acquisition.show()
	def plotBioControllerFPT_CDF(self, bothTransitions = True, onlyLongTransitions = False):
		l = [True] if onlyLongTransitions else [False, True]
		for b in l:
			q = self.getBioControllerRawFPT(bothTransitions, b)
			if isinstance(q,tuple):
				x0x1, x1x0 = q
			else:
				x0x1 = q
			s="only long transitions" if b else "all transitions"
			self.plot(x0x1, np.linspace(0,1,len(x0x1)), label = f"x0 to x1 {s}")
			if bothTransitions:
				self.plot(x1x0, np.linspace(0,1,len(x1x0)), label = f"x1 to x0 {s}")
		acquisition.show()
	def plotBioControllerFPT_CDF_fitted_onlyLongTransitions(self):
		return self.plotBioControllerFPT_CDF_fitted(True)
	def plotBioControllerFPT_CDF_fitted_allTransitions(self):
		return self.plotBioControllerFPT_CDF_fitted(False)
	def get_xy_forFPT_CDF(self, onlyLongTransitions=True):
		q = self.getBioControllerRawFPT(bothTransitions=False, onlyLongTransitions=onlyLongTransitions)
		x0x1 = q
		x=np.concatenate(([0],x0x1))
		y=np.linspace(0,1,len(x))
		unique = np.concatenate(([True], np.abs(x[1:]-x[:-1]) >= (1/50e6)))
		x=x[unique]
		y=y[unique]
		return x,y
	def get_xy_forFPT_PDF(self, onlyLongTransitions=True):
		x,y = self.get_xy_forFPT_CDF(onlyLongTransitions)
		dy_dx = np.gradient(y, x)
		return x, dy_dx
	def __fitForCDF(self, onlyLongTransitions = True, bounds = [(1e-11,1e-4), (1e-10, 1e-7), (10e-10,50e-8)]):
		x,y=self.get_xy_forFPT_CDF(onlyLongTransitions)	
		theoreticalFunction = lambda t, stiff, x0, drag: interactWithJulia.FTP_CDF(t, x0, stiff, drag)
		p, theor_y = getFittingFunction(x,y, theoreticalFunction, bounds, alsoReturnF_x=True)
		print(f"theoretical curve: stiffness: {p[0]}, x0: {p[1]}, drag: {p[2]}")
		return x,y, p,theor_y
	
	def plotBioControllerFPT_CDF_fitted(self, onlyLongTransitions = True):
		s = "long transitions" if onlyLongTransitions else "all transitions"
		acquisition.newFigure(f"{self.__baseFile} FPT CDF ({s})")
		bondss = [
			[(1e-11,1e-4), (1e-10, 30e-6), (25e-9,30e-9)]
		]
		for bonds in bondss:
			x,y,p, theor_y = self.__fitForCDF(onlyLongTransitions, bounds = bonds)
			self.plot(x, theor_y[0], label=f"theoretical curve: stiffness: {p[0]:.3e}, x0: {p[1]:.3e}, drag: {p[2]:.3e}")
		self.step(x, y, label = f"x0 to x1", color=plt.gca().lines[-1].get_color())
		acquisition.show()
	def plotBioControllerFPT_PDF_fitted(self, onlyLongTransitions = True):
		_,__,p, theor_y = self.__fitForCDF(onlyLongTransitions)	
		x,y=self.get_xy_forFPT_PDF(onlyLongTransitions)
		s = "long transitions" if onlyLongTransitions else "all transitions"
		acquisition.newFigure(f"{self.__baseFile} FPT CDF ({s})")
		self.step(x, y, label = f"x0 to x1")
		theor_y = interactWithJulia.FTP_PDF_normalized(x, p[1], p[0], p[2])
		self.plot(x, theor_y[0], label=f"theoretical curve: stiffness: {p[0]:.3e}, x0: {p[1]:.3e}, drag: {p[2]:.3e}", color=plt.gca().lines[-1].get_color())
		acquisition.show()

	def plotBioControllerFPT_PDF_fitted_onlyLongTransitions(self):
		return self.plotBioControllerFPT_PDF_fitted(True)
	def plotBioControllerFPT_PDF_fitted_allTransitions(self):
		return self.plotBioControllerFPT_PDF_fitted(False)

	@staticmethod
	def plotBioControllerFPT_CDF_multipleFitted_allTransitions(acquisitions):
		acquisition.plotBioControllerFPT_CDF_multipleFitted(acquisitions, onlyLongTransitions=True)
	@staticmethod
	def plotBioControllerFPT_CDF_multipleFitted_onlyLongTransitions(acquisitions):
		acquisition.plotBioControllerFPT_CDF_multipleFitted(acquisitions, onlyLongTransitions=False)
	@staticmethod
	def plotBioControllerFPT_CDF_multipleFitted(acquisitions, onlyLongTransitions = True):
		xs = []
		ys = []
		acquisitions = [acquisition(s) if isinstance(s, str) else s for s in acquisitions]
		for acq in acquisitions:
			x,y=acq.get_xy_forFPT_CDF(onlyLongTransitions)
			xs.append(x)
			ys.append(y)
		# xs = np.array(xs)
		# ys = np.array(ys)
		theoreticalFunction = lambda t, stiff, drag, x0 : interactWithJulia.FTP_CDF(t, x0, stiff, drag)
		commonBounds = [(1e-10, 1e-7), (10e-9,50e-9)]
		singleBounds = [(1e-9,1e-7)]
		p, theor_y = getFittingFunctions_commonParameters(xs,ys, theoreticalFunction, commonBounds, singleBounds, alsoReturnF_x=True)
		print(f"theoretical curves: stiffness: {p[0]}, drag: {p[1]}, x0s: {p[2:]}")
		acquisition.newFigure(f"theoretical curves: stiffness: {p[0]}, drag: {p[1]}")		
		for i,acq in enumerate(acquisitions):
			acq.step(xs[i], ys[i], label = f"x0 to x1")
			acq.plot(xs[i], theor_y[i][0], label=f"theoretical curve: x0: {p[2+i]:.3e}", color=plt.gca().lines[-1].get_color())
		acquisition.show()
	@staticmethod
	def lorentzian(x, a,  fc):
		return a  * fc**2/ ((x)**2 + fc**2)
	@staticmethod
	def bead_PSD(omega,  stiffness, gamma, mass, temperature = 300):
		return 2 * 1.3806504e-23 * temperature * gamma / ( \
			(stiffness - mass*omega**2)**2 + (gamma*omega)**2 )
	
	@staticmethod
	def logDecimate(t, x, logSampleRate):
		logt = np.log10(t)
		new_logt = np.linspace(logt[0],logt[-1],int(np.ceil((logt[-1]-logt[0]) / logSampleRate)))
		new_x = np.zeros_like(new_logt)
		for i in range(len(new_logt)):
			minRange = np.searchsorted(logt, new_logt[i] - logSampleRate/2)
			maxRange = np.searchsorted(logt, new_logt[i] + logSampleRate/2)
			maxRange = np.minimum(len(logt) - 2, maxRange)
			if maxRange == minRange:
				new_x[i] = np.interp(new_logt[i], logt, x)
			else:
				dt = np.diff(logt[minRange:maxRange+1],)
				new_x[i] = np.sum(dt * x[minRange:maxRange]) / (logt[maxRange] - logt[minRange])

		return np.power(10, new_logt), new_x
		


	def showVarianceAndStiffness(self, startTime_s = 2, duration_s = 10):
		d = self.getNidaqAcquisition()
		t = np.array(d["Time (s)"])
		sum = np.array(d["AI2"])
		xdiff = np.array(d["AI3"])
		validTimes = np.logical_and(t > startTime_s, t - startTime_s < duration_s)
		t = t[validTimes]
		sum = sum[validTimes]
		xdiff = xdiff[validTimes]
		x = xdiff / sum / bioTweezerController.sensitivity_x
		var = np.var(x)
		stiffness = bioTweezerController.laserStiffnessFromVariance(var)
		print(f"Variance: {var:.3e}\nStiffness: {stiffness:.3e}")
		
		# b = self.getBioControllerAcquisition()
		# bt=np.array(b["times"])
		# bx=np.array(b["x"])[None,:]
		# bx = bioTweezerController.dimLink.convert(bx, "FPGA_floatValue", "bead_position")
		# bx2=np.array(b["x^2"])[None,:]
		# squareShift = 8#self.configurations["squaresShift"]
		# bx2 = bioTweezerController.dimLink.convert([bx2, -squareShift], ["FPGA_floatValue", "FPGA_bitShift"], "bead_positionSquare")
		# bioTweezerController.laserStiffnessFromPositionSignal(bx,bx2)


		time_step = t[1]-t[0]
		freqs = np.fft.fftfreq(x.size, time_step)
		ps = np.abs(np.fft.fft(x))**2
		ps = ps[freqs >= 0]
		freqs = freqs[freqs >= 0]

		idx = np.argsort(freqs)

		freqs = freqs[idx]
		ps = ps[idx]

		self.newFigure('Power Spectrum Density (PSD)')

		#plt.plot(freqs[idx], ps[idx])
		self.loglog(freqs, ps, label = "PSD")
		plt.xlabel('Frequency [Hz]')
		plt.ylabel('PSD [V**2/Hz]')
		plt.grid(True)

		freqs = freqs[1:]
		ps = ps[1:]
		freqs, ps = acquisition.logDecimate(freqs, ps, np.log10(freqs[1] / freqs[0])*.5)

		'''
		expectedDrag = 2.8e-9
		expectedMass = 2.82e-14
		initial_guess = [stiffness, expectedDrag, expectedMass]
		# params, covariance = curve_fit(acquisition.bead_PSD, freqs, ps, p0=initial_guess, bounds=([stiffness*.01, expectedDrag*.5, expectedMass*.1], [stiffness*100, expectedDrag*1.5, expectedMass*10]), method = 'trf')
		plt.plot(freqs, acquisition.bead_PSD(freqs, *params), label='Fitted PSD', color='red')
		'''
		initial_guess = [ps[0], np.sqrt(freqs[-1]*freqs[0])]
		params, covariance = curve_fit(acquisition.lorentzian, freqs, ps, p0=initial_guess, method = 'trf')
		self.plot(freqs, acquisition.lorentzian(freqs, *params), label='Fitted PSD', color=plt.gca().lines[-1].get_color())
		#'''
		print(f"Fitted parameters: {params}")
		self.show()
	
	def getNidaqRawFPT(self, bothTransitions = True, onlyLongTransitions = False):
		'''
		returns all the sorted transition timings from x0 to x1 and (if bothTransitions is True) from x1 to x0

		bothTransitions: if True, returns both x0x1 and x1x0 transitions (the returned value will be a tuple)

		onlyLongTransitions: if True, only the longest timings of a transition will be returned
			example, if the data says that the particle passed for x0 2 times before passing for x1, 
			only the timing between the first x0 crossing and the x1 crossing will be returned
		'''
		t, x = self.nidaq_t_x
		x -= np.mean(x)
		x0 = self.configurations["binFeedback_x0"]["Parameter value"]
		x1 = self.configurations["binFeedback_x1"]["Parameter value"]
		x0Crosses = (x[:-1] - x0) * (x[1:] - x0) <= 0
		x1Crosses = (x[:-1] - x1) * (x[1:] - x1) <= 0
		crosses = [x0Crosses, x1Crosses]
		if bothTransitions:
			crosses += [x0Crosses]

		for i in range(len(crosses) - 1):
			startCross = crosses[i]
			endCross = crosses[i + 1]

			startIndexes = np.where(startCross)[0]
			endIndexes = np.where(endCross)[0]
			startIdxPositionInEndIndices = np.searchsorted(endIndexes, startIndexes)
			startIndexes = startIndexes[startIdxPositionInEndIndices < len(endIndexes)]
			startIdxPositionInEndIndices = startIdxPositionInEndIndices[startIdxPositionInEndIndices < len(endIndexes)]
			if onlyLongTransitions:
				startIndexes = startIndexes[np.concatenate(([0],1+np.where(startIdxPositionInEndIndices[:-1] != startIdxPositionInEndIndices[1:])[0]))]
				startIdxPositionInEndIndices = np.unique(startIdxPositionInEndIndices)

			transitionTimes = t[endIndexes[startIdxPositionInEndIndices]] - t[startIndexes]
			transitionTimes = np.sort(transitionTimes)
			if i == 1:
				return (x0x1, transitionTimes)
			x0x1 = transitionTimes
			
		return x0x1



		transitionIndexes = 1+np.where(reachedThresholds[1:]!=reachedThresholds[:-1])[0]#where we have a transition
		#elements after the last transition are not usable, because we don't have info on when the next cross would have been
		lastUsableIndex = transitionIndexes[-1]
		reachedThresholds = reachedThresholds[:lastUsableIndex+1]
		t = t[:lastUsableIndex+1]
		longestTimes=t[transitionIndexes]
		xx = [None] * (2 if bothTransitions else 1)
		for i in range(len(xx)):
			if not onlyLongTransitions:
				t[transitionIndexes]=0
				allTimes = longestTimes[np.searchsorted(transitionIndexes, np.arange(len(t)-1), side='right')] - t[1:]
				xx[i] = np.sort(allTimes[reachedThresholds[:-1] == i])
			else:
				xx[i] = np.sort(longestTimes[reachedThresholds[transitionIndexes] == 1-i])
		# x0x1 = np.sort(allTimes[reachedThresholds[:-1] == 1])
		if bothTransitions:
			x0x1,x1x0 = xx[0], xx[1]
			return x0x1, x1x0
		x0x1 = xx[0]
		return x0x1
	def animatePotentialWell(self, tStart=0, tEnd=None, ):
		t, x = self.nidaq_t_x
		# bioTweezerController.updateGeneratorBaseCurrent(bioTweezerController, self.configurations["currentGenerator_baseCurrent"]["Parameter value"])
		stiffness = bioTweezerController.dimLink.convert(self.ai_buffer["AI7"], "generator_debugVoltage", "laserPower")
		if tEnd is None:
			tEnd = t[-1]
		x = x[np.logical_and(t >= tStart, t <= tEnd)]
		stiffness = stiffness[np.logical_and(t >= tStart, t <= tEnd)]
		t = t[np.logical_and(t >= tStart, t <= tEnd)]
		minX, maxX = np.min(x), np.max(x)
		linspace = np.linspace(minX, maxX)
		fig, ax = plt.gcf(), plt.gca()
		line, = ax.plot([], [], 'b-', alpha=0.2)
		dot, = ax.plot([], [], 'ro', markersize=8)
		# ax.plot(linspace, linspace**2)
		ax.set_xlim(minX, maxX)
		ax.set_ylim(min(linspace**2), max(np.max(stiffness) * linspace**2))
		ax.set_xlabel("x")
		ax.set_ylabel("Potential")

		def init():
			line.set_data([], [])
			dot.set_data([], [])
			return (line, dot,)

		def animate(i):
			idx = min(i, len(x)-1)
			line.set_data([linspace], [stiffness[idx] * linspace**2])
			dot.set_data([x[idx]], [stiffness[idx] * x[idx]**2])
			return (line, dot,)

		frames = len(x) if tEnd is None else np.searchsorted(t, tEnd)
		ani = animation.FuncAnimation(fig, animate, init_func=init, frames=frames, interval=30, blit=True)
		plt.show()
		ani=0


def getFittingFunction(x,y,fittingFunction, parametersRanges, alsoReturnF_x=False, printErrors = True):
	'''finds the best parameters *p that fit the experimental data (x,y) into the fitting function, so that
	y ~= fittingFunction(x,*p)
	'''	
	def difference(*p):
		e = np.sum((y - fittingFunction(x,*(p[0]))) ** 2)
		if printErrors:
			print(e)
		return e
	result = differential_evolution(difference, parametersRanges)
	p = result.x
	if alsoReturnF_x:
		return p, fittingFunction(x,*p)
	return p
def getFittingFunctions_commonParameters(x,y,fittingFunction, commonParametersRanges, separatedParametersRanges, alsoReturnF_x=False, printErrors = True):
	'''
	finds the best parameters *p,*q[i] that fit the experimental data (x[i],y[i]) into the fitting function, so that
	y[i] ~= fittingFunction(x[i],*p,*q[i]) for each i
	x and y are lists of arrays, and some of the parameters are common between different (x[i],y[i])
	'''	
	q_index=len(commonParametersRanges)
	def difference(*p):
		e = np.zeros(len(x))
		for i in range(len(x)):
			e[i] = np.sum((y[i] - fittingFunction(x[i],*(p[0][:q_index]),*(p[0][q_index+i::len(x)]))) ** 2)
		if printErrors:
			print(e)
		return np.sum(e)
		
	result = differential_evolution(difference, commonParametersRanges + separatedParametersRanges * len(x))
	p = result.x
	if alsoReturnF_x:
		return p, [fittingFunction(x[i],*(p[:q_index]),*(p[q_index+i::len(x)])) for i in range(len(x))]
	return p

def  Kolmogorov_Smirnov_test(theoreticalCDF, extractedData):
	'''
	Computes the Kolmogorov-Smirnov test between the theoretical CDF and the extracted data.
	
	theoreticalCDF: function
	extractedData: list of samples from the distribution
	
	'''
	extractedData = np.sort(extractedData)
	# t = np.linspace(0,1,len(extractedData))
	if isinstance(theoreticalCDF, MethodType):
		theoreticalValues = theoreticalCDF(extractedData)
	else:
		theoreticalValues = theoreticalCDF
	return np.max(np.abs(theoreticalValues-extractedData))
		

if __name__ == "__main__":
	# a=acquisition("C:/Users/lastline/Downloads/FPT_current225_x0.01_006.csv")
	# q=a.getBioControllerRawFPT(True, True)
	# for i in q:
	# 	plt.plot(i,np.linspace(0,1,len(i)))
	# q=a.getBioControllerRawFPT(True, False)
	# for i in q:
	# 	plt.plot(i,np.linspace(0,1,len(i)))
	# # self.plot(q[0])
	# # self.plot(q[1])
	# acquisition.show()
	# a.plotBioControllerAcquisition()

	# acquisition.plotBioControllerFPT_CDF_multipleFitted([
	# 	"d:/lastline/bioTweezers/28_3_25/bead8_FPT_150mA_x0-.015_015_conf.csv",
	# 	"d:/lastline/bioTweezers/28_3_25/bead8_FPT_150mA_x0-.01_014_bioControllerAcquisition.csv",
	# 	"d:/lastline/bioTweezers/28_3_25/bead7_FPT_150mA_x0.005_013_conf.csv",
	# 	"d:/lastline/bioTweezers/28_3_25/bead7_FPT_150mA_x0.02_drift_012_conf.csv",
	# 	"d:/lastline/bioTweezers/28_3_25/bead6_FPT_150mA_x0.01_drift_009_bioControllerTimings.csv",
	# ], True)
	# acquisition.plotBioControllerFPT_CDF_multipleFitted([
	# 	"d:/lastline/bioTweezers/28_3_25/bead8_FPT_150mA_x0-.015_015_conf.csv",
	# 	"d:/lastline/bioTweezers/28_3_25/bead8_FPT_150mA_x0-.01_014_bioControllerAcquisition.csv",
	# 	# "d:/lastline/bioTweezers/28_3_25/bead7_FPT_150mA_x0.005_013_conf.csv",
	# 	# "d:/lastline/bioTweezers/28_3_25/bead7_FPT_150mA_x0.02_drift_012_conf.csv",
	# 	# "d:/lastline/bioTweezers/28_3_25/bead6_FPT_150mA_x0.01_drift_009_bioControllerTimings.csv",
	# ], False)

	# a=acquisition('d:/lastline/bioTweezers/28_3_25/bead8_FPT_150mA_x0-.015_015_conf.csv')
	# a.plotBioControllerFPT_CDF_fitted_onlyLongTransitions()
	# a.plotBioControllerFPT_CDF_fitted_allTransitions()

	# allAcquisitions = acquisition.getAllBaseFiles("d:/lastline/bioTweezers/18_4_25")
	# for file in allAcquisitions:
	# 	acq = acquisition(file)
	# 	x,y=acq.get_xy_forFPT_CDF(onlyLongTransitions=True)
	# 	output_file = f"{file}_FPT_CDF.csv"
	# 	data_to_save = pd.DataFrame({"time (ms)": x*1e3, "CDF": y})
	# 	data_to_save.to_csv(output_file, index=False)
	# pass
	
	# for file in ["d:/lastline/bioTweezers/18_4_25/bead2_FPT_100mA_setpoint.03_005.csv", 
	# 		  "d:/lastline/bioTweezers/18_4_25/bead2_FPT_150mA_setpoint.03_004.csv"]:
	# 	a = acquisition(file)
	# 	d = a.getNidaqAcquisition()
	# 	t = np.array(d["Time (s)"])
	# 	sum = np.array(d["AI1"])
	# 	xdiff = np.array(d["AI2"])
	# 	x = sum/xdiff * 1e-6
	# 	x=x[t<10]
	# 	t=t[t<10]
	# 	plt.plot(t,x)
	# 	plt.show()
	# 	output_file = file.replace(".csv", "_only_x.csv")
	# 	data_to_save = pd.DataFrame({"Time (s)": t, "x": x})
	# 	data_to_save.to_csv(output_file, index=False)
	
	# t=np.linspace(.1,30,1000)
	# x=np.sin(t)
	# plt.plot(np.log10(t), x)
	# nt,nx = acquisition.logDecimate(t,x,.1)
	# plt.plot(np.log10(nt), nx)
	# plt.show()
	# a=acquisition("d:/lastline/bioTweezers/18_4_25/FPT_150mA_setpoint.02_001_bioControllerAcquisition.csv")
	# acquisition.createNewFigure = False
	# a.plotBioControllerFPT_CDF_fitted_allTransitions()
	# a.plotBioControllerFPT_CDF_fitted_onlyLongTransitions()
	# # a.getBioControllerRawFPT = a.getNidaqRawFPT
	# # # q = a.getBioControllerRawFPT(True, False)
	# # a.plotBioControllerFPT_CDF_fitted_allTransitions()
	# acquisition.createNewFigure = True
	# a.show()

	acq = acquisition("d:/lastline/bioTweezers/18_4_25/bead3_FPT_stiffnessChange_100_150mA_setpoint-.04_007_bioControllerAcquisition.csv")
	acq.animatePotentialWell(1, 5)