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
from types import SimpleNamespace

import pickle
import re
from collections import defaultdict
from scipy.optimize import curve_fit


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
		if len(t) > 0 and min(t) >= 1:#old file with time in clock cycles?
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
		if transitionIndexes.size == 0:
			return np.array([]) if not bothTransitions else (np.array([]), np.array([]))
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
		return self.plotFPT_CDF_fitted("bio", True)
	def plotBioControllerFPT_CDF_fitted_allTransitions(self):
		return self.plotFPT_CDF_fitted("bio", False)
	def plotNidaqFPT_CDF_fitted_onlyLongTransitions(self):
		return self.plotFPT_CDF_fitted("nidaq", True)
	def plotNidaqFPT_CDF_fitted_allTransitions(self):
		return self.plotFPT_CDF_fitted("nidaq", False)
	def get_xy_forFPT_CDF(self, source="bio", onlyLongTransitions=True):
		if source not in ("bio", "nidaq"):
			raise ValueError("source must be either 'bio' or 'nidaq'")
		if source == "bio":
			q = self.getBioControllerRawFPT(bothTransitions=False, onlyLongTransitions=onlyLongTransitions)
		else:
			q = self.getNidaqRawFPT(bothTransitions=False, onlyLongTransitions=onlyLongTransitions)
		x0x1 = q
		x = np.concatenate(([0], x0x1))
		y = np.linspace(0, 1, len(x))
		unique = np.concatenate(([True], np.abs(x[1:] - x[:-1]) >= (1 / 50e6)))
		x = x[unique]
		y = y[unique]
		return x, y
	def get_xy_forFPT_PDF(self, source="bio", onlyLongTransitions=True):
		x,y = self.get_xy_forFPT_CDF(source, onlyLongTransitions)
		dy_dx = np.gradient(y, x)
		return x, dy_dx
	def __fitForCDF(self, source="bio", onlyLongTransitions = True, bounds = [(1e-11,1e-4), (1e-10, 1e-7), (10e-10,50e-8)]):
		x,y=self.get_xy_forFPT_CDF(source, onlyLongTransitions)	
		theoreticalFunction = lambda t, stiff, x0, drag: interactWithJulia.FTP_CDF(t, x0, stiff, drag)
		p, theor_y = getFittingFunction(x,y, theoreticalFunction, bounds, alsoReturnF_x=True)
		print(f"theoretical curve: stiffness: {p[0]}, x0: {p[1]}, drag: {p[2]}")
		return x,y, p,theor_y
	
	def plotBioControllerFPT_CDF_fitted(self, onlyLongTransitions = True):
		return self.plotFPT_CDF_fitted("bio", onlyLongTransitions)
	def plotNidaqFPT_CDF_fitted(self, onlyLongTransitions = True):
		return self.plotFPT_CDF_fitted("nidaq", onlyLongTransitions)
	def plotBioControllerFPT_PDF_fitted(self, onlyLongTransitions = True):
		return self.plotFPT_PDF_fitted("bio", onlyLongTransitions)
	def plotNidaqFPT_PDF_fitted(self, onlyLongTransitions = True):
		return self.plotFPT_PDF_fitted("nidaq", onlyLongTransitions)

	def plotFPT_CDF_fitted(self, source="bio", onlyLongTransitions = True):
		s = "long transitions" if onlyLongTransitions else "all transitions"
		acquisition.newFigure(f"{self.__baseFile} FPT CDF ({s})")
		bondss = [
			[(1e-11,1e-4), (1e-10, 30e-6), (25e-9,30e-9)]
		]
		for bonds in bondss:
			x,y,p, theor_y = self.__fitForCDF(source, onlyLongTransitions, bounds = bonds)
			self.plot(x, theor_y[0], label=f"theoretical curve: stiffness: {p[0]:.3e}, x0: {p[1]:.3e}, drag: {p[2]:.3e}")
		self.step(x, y, label = f"x0 to x1", color=plt.gca().lines[-1].get_color())
		acquisition.show()
	def plotFPT_PDF_fitted(self, source="bio", onlyLongTransitions = True):
		_,__,p, theor_y = self.__fitForCDF(source, onlyLongTransitions)	
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
		if "xDriftTiming" in self.configurations.keys():
			averagingTime = float(self.configurations["xDriftTiming"]["Parameter value"])
			windowSize = int(averagingTime / (t[1]-t[0]))
			x -= np.convolve(x, np.ones(windowSize)/windowSize, mode="same")
		else:
			x -= np.mean(x)
		x0 = float(self.configurations["binFeedback_x0"]["Parameter value"])
		x1 = float(self.configurations["binFeedback_x1"]["Parameter value"])
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

	# def getFiringTimings
	
	@staticmethod
	def FPT_CDF_fromData(x, t, setpoint0, setpoint1 = 0, bins = 100, removeHighPercentage = 0.0001, onlyLongTransitions = False):
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
		nOfSetpoints = x0.size
		x0 = np.array(x0)[None,:]
		x0Crosses = (x[:-1, None] - x0) * (x[1:, None] - x0) <= 0
		x1Crosses = (x[:-1] - x1) * (x[1:] - x1) <= 0

		startIndexes, startSetpointIndexes = np.where(x0Crosses)
		endIndexes = np.where(x1Crosses)[0]
		startSetpointIndexes = startSetpointIndexes[startIndexes < endIndexes[-1]]
		startIndexes = startIndexes[startIndexes < endIndexes[-1]]
		startIdxPositionInEndIndices = np.searchsorted(endIndexes, startIndexes, side = 'right')
		if onlyLongTransitions:
			raise ValueError("onlyLongTransitions is not supported for multiple setpoints")
			valuesToKeep = np.concatenate(([0],1+np.where(startIdxPositionInEndIndices[:-1] != startIdxPositionInEndIndices[1:])[0]))
			startIndexes = startIndexes[valuesToKeep]
			startSetpointIndexes = startSetpointIndexes[valuesToKeep]
			startIdxPositionInEndIndices = np.unique(startIdxPositionInEndIndices)

		transitionTimes = t[endIndexes[startIdxPositionInEndIndices]] - t[startIndexes]
		transitionTimes = transitionTimes.astype(float) * dt#rescale back to float
		pdf = np.zeros((nOfSetpoints, bins))
		fpt = np.zeros((nOfSetpoints, bins))
		cdf = np.linspace(0, 1, bins)
		for i in range(nOfSetpoints):
			currentTransitionTimes = transitionTimes[startSetpointIndexes == i]
			currentTransitionTimes = np.concatenate(([0], np.sort(currentTransitionTimes)))
			fpt[i] = currentTransitionTimes[np.linspace(0, len(currentTransitionTimes)-1, bins, dtype=int)]
			''' # Spread identical adjacent values in fpt[i]
			for j in range(1, len(fpt[i])):
				if fpt[i][j] == fpt[i][j-1]:
					# Find the next different value
					k = j
					while k < len(fpt[i]) and fpt[i][k] == fpt[i][j]:
						k += 1
					# Spread values between previous and next different value
					prev_val = fpt[i][j-1]
					next_val = fpt[i][k] if k < len(fpt[i]) else prev_val
					num_to_spread = k - j + 1
					spread_vals = np.linspace(prev_val, next_val, num_to_spread + 1)[1:-1]
					fpt[i][j:k] = spread_vals'''
			'''
			cdf = np.linspace(0, 1, bins)
			unique, count = np.unique(fpt[i], return_counts=True)
			uniqueIndexes = np.concatenate(([0],np.cumsum(count)[:-1]))
			nonSingleValues = np.where(count > 1)[0]
			for j in range(len(nonSingleValues)):
				start = uniqueIndexes[nonSingleValues[j]]
				prevVal = unique[nonSingleValues[j]-1]
				currentVal = unique[nonSingleValues[j]]
				followingVal = unique[nonSingleValues[j]+1]
				fpt[i][start:count[nonSingleValues[j]]+start] = np.linspace((prevVal + currentVal) / 2, (currentVal + followingVal) / 2, count[nonSingleValues[j]],endpoint=False, )
			'''
			
			unique, count = np.unique(fpt[i], return_counts=True)			
			uniqueIndexes = np.concatenate(([0],np.cumsum(count)[:-1]))
			pdf[i][:len(unique)] = cdf[uniqueIndexes]
			fpt[i][:len(unique)] = unique
			pdf[i][len(unique):] = 1
			fpt[i][len(unique):] = unique[-1]
			

			# # currentTransitionTimes = currentTransitionTimes[:int(len(currentTransitionTimes) * (1-removeHighPercentage))]
			# count, fpt[i] = np.histogram(currentTransitionTimes, bins=bins-1)
			
			# count = np.cumsum(count)
			# count = count / count[-1] * len(fpt[i]) / fpt[i][-1]
			# pdf[i] = acquisition.derivativeForCDF(np.concatenate((count, [count[-1], count[-1]])))
		startPoints = np.repeat(x0[0,:,None], bins, axis=1)
		return fpt, startPoints, pdf


	@staticmethod
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
		dfpt = acquisition.derivativeForCDF(fpt)
		def fptFun(t, startPoint, passagePoint):
			index = (t / dt).astype(int)
			startPoint = ((startPoint - xm) / (xM - xm) * pointResolution).astype(int)
			passagePoint = ((passagePoint - xm) / (xM - xm) * pointResolution).astype(int)
			index = np.clip(index, a_min=0, a_max=maxIndex-1)
			startPoint = np.clip(startPoint, a_min=0, a_max=pointResolution-1)
			passagePoint = np.clip(passagePoint, a_min=0, a_max=pointResolution-1)
			return dfpt[startPoint, passagePoint, index]
		return fptFun, xm, xM

	@staticmethod
	def derivativeForCDF(cdf, x = None):
		paddingShape = list(np.shape(cdf))
		paddingShape[-1] = 1
		padding = np.zeros(paddingShape)
		difference = cdf[1:] - cdf[:-1]#cdf - np.concatenate((padding, cdf[:-1]), axis=-1)#np.concatenate((cdf, cdf[...,-1:]), axis=-1) - np.concatenate((padding, cdf), axis=-1)
		if x is not None:
			dx = x[1:] - x[:-1]
			difference /= dx
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

	
	def getUsefulDataForCellExperimentsJuly2025(self):
		'''
		returns the following data arrays:
			from nidaq:
				timing
				sum
				xdiff
			from bioController:
				timing
				x
				x^2
				FPT 
				
		and the following metadata:
			from nidaq:
				movement of the piezos (direction, speed and stopping time)
			from bioController:
				FPT setpoints
				drift compensation time
				
			
				
		'''
		# tx = self.nidaq_t_x
		# bio_tx = self.bio_t_x
		# return {
		# 	'nidaqTimings' : tx[0],
		# 	'nidaqX' : tx[1],
		# 	'nidaqSum' :self.ai_buffer["AI2"],
		# 	'nidaqXdiff' :self.ai_buffer["AI3"],
		# 	'bioTimings' : bio_tx[0],
		# 	'bioX' : bio_tx[1],
		# 	'bioX2' :self.bio_buffer["x^2"],
		# 	'bioFPT' :self.getBioControllerRawFPT(onlyLongTransitions=False, bothTransitions=True),
		# 	'FPT_setpoint0' : float(self.configurations["binFeedback_x0"]["Parameter value"]),
		# 	'FPT_setpoint1' : float(self.configurations["binFeedback_x1"]["Parameter value"]),
		# 	'driftCompensationTime' :float(self.configurations["xDriftTiming"]["Parameter value"]),
		# }


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
	
class experimentJuly2025:
	def __init__(self, acquisition : acquisition, filteringTime_s = None):
		self.acquisition = acquisition
		self.nidaqTimings, self.nidaqX = acquisition.nidaq_t_x
		if filteringTime_s is not None:
			windowSize = int(filteringTime_s / (self.nidaqTimings[1]-self.nidaqTimings[0]))
			self.nidaqX -= np.convolve(self.nidaqX, np.ones(windowSize)/windowSize, mode='same')
		self.nidaqSum = acquisition.ai_buffer["AI2"]
		self.nidaqXdiff = acquisition.ai_buffer["AI3"]
		# piezoX = - acquisition.ai_buffer["AI1"]
		# piezoY = acquisition.ai_buffer["AI5"]
		try:
			self.bioTimings, self.bioX = acquisition.bio_t_x
			self.bioX2 = acquisition.bio_buffer["x^2"]
			self.bioFPT = acquisition.getBioControllerRawFPT(onlyLongTransitions=False, bothTransitions=True)
			self.FPT_setpoint0, self.FPT_setpoint1 = float(acquisition.configurations["binFeedback_x0"]["Parameter value"]), float(acquisition.configurations["binFeedback_x1"]["Parameter value"])
			self.driftCompensationTime = float(acquisition.configurations["xDriftTiming"]["Parameter value"])
		except:
			print(f"BioController data not available in acquisition {acquisition.__baseFile}")

class fpt_multiSetpoint:
	@staticmethod
	def getRangeFromUsedDataRatio(x,usedDataRatio):
			#let's remove the extreme values from the setpoints, since they would not have enough passages to be statistically significant
			exclude_count = int(len(x) * (1 - usedDataRatio) / 2)
			x_sorted = np.sort(x)
			xm = x_sorted[exclude_count]
			xM = x_sorted[-exclude_count-1]
			return xm, xM

	def __init__(self, x, t, setpoint1 = 0, pointResolution = 100, bins = 300, usedDataRatio = 0.99, setpointRange = None):
		'''
		either use usedDataRatio or setpointRange
		'''		
		if setpointRange is None:
			xm, xM = fpt_multiSetpoint.getRangeFromUsedDataRatio(x, usedDataRatio)
		else:
			xm, xM = setpointRange
		setpoints = np.linspace(xm, xM, pointResolution)
		self.fpt, self.startPoint, self.pdf = acquisition.FPT_CDF_fromData(x, t, setpoints, setpoint1, bins) 

		self.usedDataRatio = usedDataRatio
	def plot(self, fig_ax = None, title = "", label = None):
		if fig_ax is None:
			fig = plt.figure()
			ax = fig.add_subplot(111, projection='3d', title=title)
		else:
			fig, ax = fig_ax
		ax.plot_surface(self.startPoint, self.fpt, self.pdf, cmap='viridis', label = label)

		# Label axes
		ax.set_xlabel('start point')
		ax.set_ylabel('fpt')
		ax.set_zlabel('CDF')
		return fig, ax
	@staticmethod
	def getAllSetFiles(folderPath):
		files = acquisition.getAllBaseFiles(folderPath)		
		set_files = defaultdict(list)
		pattern = re.compile(r"set(\d+)_")
		for file in files:
			match = pattern.search(os.path.basename(file))
			if match:
				set_number = match.group(1)
				set_files[set_number].append(file)
		set_files = {k : v for k, v in set_files.items() if len(v) == 2}
		
		for set_number in set_files.keys():
			file_list = set_files[set_number]
			isCellBeadTheFirst = "cell" in file_list[0]
			cell, free = file_list if isCellBeadTheFirst else file_list[::-1]
			set_files[set_number] = {
				"cell": cell,
				"free": free,
			}
		return set_files
	@staticmethod
	def createAllCellAndFreeFPT(folderPath, setpoint1 = 0, pointResolution = 100, bins = 300, usedDataRatio = 0.99, setpointRange = None):
		set_files = fpt_multiSetpoint.getAllSetFiles(folderPath)
		returnedFPTs = {}
		for set_number, file_list in set_files.items():
			cell, free = file_list["cell"], file_list["free"]
			cell = pickle.load(open(f"{cell}_usefulData.pkl", "rb"))
			free = pickle.load(open(f"{free}_usefulData.pkl", "rb"))
			if setpointRange is None:
				xmc,xMc = fpt_multiSetpoint.getRangeFromUsedDataRatio(cell.nidaqX, usedDataRatio)
				xmf,xMf = fpt_multiSetpoint.getRangeFromUsedDataRatio(free.nidaqX, usedDataRatio)
				xm = min(xmc, xmf)
				xM = min(xMc, xMf)
			else:
				xm, xM = setpointRange
			returnedFPTs[set_number] = {
				"cell": fpt_multiSetpoint(cell.nidaqX, cell.nidaqTimings, setpoint1, pointResolution, bins, usedDataRatio=None, setpointRange = (xm, xM)),
				"free": fpt_multiSetpoint(free.nidaqX, free.nidaqTimings, setpoint1, pointResolution, bins, usedDataRatio=None, setpointRange = (xm, xM)),
			}
		return returnedFPTs
	@staticmethod
	def getDifferenceBetweenCellAndFreeFPT(c, f):
		diff = fpt_multiSetpoint.__new__(fpt_multiSetpoint)
		cSmallerThanF = c.fpt[:,-1] < f.fpt[:,-1]
		diff.fpt = np.zeros_like(c.fpt)
		diff.fpt[cSmallerThanF] = c.fpt[cSmallerThanF]
		diff.fpt[~cSmallerThanF] = f.fpt[~cSmallerThanF]
		diff.startPoint = c.startPoint
		diff.pdf = c.pdf - f.pdf

		return diff
class plottable:
	def __init__(self, x, y, xName, yName, plotFunction = plt.plot):
		self.x = x
		self.y = y
		self.xName = xName 
		self.yName = yName
		self.plotFunction = plotFunction

	def plot(self, fig_ax = None, title = "", label = None, **kwargs):
		if fig_ax is None:
			fig = plt.figure()
			ax = fig.add_subplot(111, title=title)
		else:
			fig, ax = fig_ax
			
		if self.plotFunction in [plt.plot, plt.loglog, plt.semilogx, plt.semilogy, plt.step, plt.scatter]:
			# Use the corresponding method from ax if available
			plot_func = getattr(ax, self.plotFunction.__name__, None)
			if plot_func is not None:
				plot_func(self.x, self.y, label=label, **kwargs)
			else:
				self.plotFunction(self.x, self.y, label=label, **kwargs)
		else:
			self.plotFunction(self.x, self.y, label=label, **kwargs)
		plt.xlabel(self.xName)
		plt.ylabel(self.yName)
		# plt.xlim(np.min(self.x), np.max(self.x))
		# plt.ylim(np.min(self.y), np.max(self.y))
		# print((np.min(self.y), np.max(self.y)))
		return fig, ax

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

	# acq = acquisition("d:/lastline/bioTweezers/18_4_25/bead3_FPT_stiffnessChange_100_150mA_setpoint-.04_007_bioControllerAcquisition.csv")
	# acq.animatePotentialWell(1, 5)

	# x=np.random.normal(size=1000000)
	# x = np.convolve(x, np.ones(100)/100, mode='valid')
	# t=np.arange(len(x)) * 0.01
	# startPoints = np.linspace(-.3,.3,100)
	# fpt, startPoints, pdf = acquisition.FPT_CDF_fromData(x, t, startPoints, 0, bins = 100)
	
	# fig = plt.figure()
	# ax = fig.add_subplot(111, projection='3d')
	# # fpt, startPoints = np.meshgrid(fpt, startPoints)
	# ax.plot_surface(startPoints, fpt, pdf, cmap='viridis')

	# # Label axes
	# ax.set_xlabel('start point')
	# ax.set_ylabel('fpt')
	# ax.set_zlabel('PDF')
	# plt.show()

	'''create usefulData and multiSetpoint files for all the acquisitions in a folder'''
	
	folder = "d:/lastline/bioTweezers/20250715/"
	files = acquisition.getAllBaseFiles(folder)

	# for file in files:
	# 	mainFile = f"{file}_usefulData.pkl"
	# 	if os.path.exists(mainFile):
	# 		continue
	# 	acq = acquisition(file)
	# 	q = experimentJuly2025(acq, 0.5)
	# 	pickle.dump(q, open(mainFile, "wb"))
	
	# for file in files:
	# 	multiSetpointFile = f"{file}_fpt_multiSetpoint.pkl"
	# 	if os.path.exists(multiSetpointFile):
	# 		continue
	# 	q = pickle.load(open(f"{file}_usefulData.pkl", "rb"))
	# 	w = fpt_multiSetpoint(q.nidaqX, q.nidaqTimings, 0, pointResolution=100, bins=300, usedDataRatio=0.99)
	# 	pickle.dump(w, open(multiSetpointFile, "wb"))

	'''plot all the multisetpoint files'''
	# for file in files:
	# 	w = pickle.load(open(f"{file}_fpt_multiSetpoint.pkl", "rb"))
	# 	fig = plt.figure(os.path.basename(file))
	# 	# plt.title(os.path.basename(file))
	# 	ax = fig.add_subplot(111, projection='3d', title=os.path.basename(file))
	# 	ax.plot_surface(w.startPoint, w.fpt, w.pdf, cmap='viridis')

	# 	# Label axes
	# 	ax.set_xlabel('start point')
	# 	ax.set_ylabel('fpt')
	# 	ax.set_zlabel('PDF')
	# 	plt.show()

	'''compare the created multisetpoint files between the same set (the multisetpoint files are created singularly, not with the use of fpt_multiSetpoint.createAllCellAndFreeFPT)'''
	# set_files = defaultdict(list)
	# pattern = re.compile(r"set(\d+)_")

	# for file in files:
	# 	match = pattern.search(os.path.basename(file))
	# 	if match:
	# 		set_number = match.group(1)
	# 		set_files[set_number].append(file)
	# set_files = {k : v for k, v in set_files.items() if len(v) == 2}
	# for set_number, file_list in set_files.items():
	# 	isCellBeadTheFirst = "cell" in file_list[0]
	# 	cell, free = file_list if isCellBeadTheFirst else file_list[::-1]
	# 	c = pickle.load(open(f"{cell}_fpt_multiSetpoint.pkl", "rb"))
	# 	f = pickle.load(open(f"{free}_fpt_multiSetpoint.pkl", "rb"))
	# 	import scipy.interpolate

	# 	# Flatten the 2D arrays to 1D for interpolation
	# 	c_points = np.column_stack((c.startPoint.ravel(), c.fpt.ravel()))
	# 	f_points = np.column_stack((f.startPoint.ravel(), f.fpt.ravel()))

	# 	# Interpolators for c and f
	# 	c_interp = scipy.interpolate.NearestNDInterpolator(c_points, c.pdf.ravel())#scipy.interpolate.LinearNDInterpolator(c_points, c.pdf.ravel(), fill_value=0)
	# 	f_interp = scipy.interpolate.NearestNDInterpolator(f_points, f.pdf.ravel())#scipy.interpolate.LinearNDInterpolator(f_points, f.pdf.ravel(), fill_value=0)

	# 	# Choose a common grid (for example, use c's grid)
	# 	common_start = np.linspace(np.maximum(c.startPoint.min(), f.startPoint.min()), np.minimum(c.startPoint.max(), f.startPoint.max()), c.startPoint.shape[0])[:, None].repeat(c.fpt.shape[1], axis=1)
	# 	common_fpt = np.zeros_like(c.fpt)
	# 	indexesOf_c_inCommonStart = np.searchsorted(c.startPoint[:,0], common_start[:,0])
	# 	indexesOf_f_inCommonStart = np.searchsorted(f.startPoint[:,0], common_start[:,0])
	# 	cSmallerThanF = c.fpt[indexesOf_c_inCommonStart,-1] < f.fpt[indexesOf_f_inCommonStart,-1]
	# 	common_fpt[cSmallerThanF] = c.fpt[indexesOf_c_inCommonStart][cSmallerThanF]
	# 	common_fpt[~cSmallerThanF] = f.fpt[indexesOf_f_inCommonStart][~cSmallerThanF]
	# 	# common_start = c.startPoint
	# 	# common_fpt = c.fpt

	# 	# Evaluate both interpolators on the common grid
	# 	c_vals = c_interp(common_start, common_fpt)
	# 	f_vals = f_interp(common_start, common_fpt)

	# 	# Compute the difference
	# 	diff = c_vals - f_vals

	# 	# Example: plot the difference surface
	# 	fig = plt.figure(f"Difference set {set_number}")
	# 	ax = fig.add_subplot(111, projection='3d')
	# 	ax.plot_surface(c.startPoint, c.fpt, np.zeros_like(c.startPoint), color='yellow', alpha=0.2, label='Cell')
	# 	ax.plot_surface(f.startPoint, f.fpt, np.zeros_like(c.startPoint), color='green', alpha=0.2, label='Free')
	# 	ax.plot_surface(common_start, common_fpt, diff, cmap='coolwarm')
	# 	ax.set_xlabel('start point')
	# 	ax.set_ylabel('fpt')
	# 	ax.set_zlabel('Difference (cell - free)')
	# 	ax.legend()
	# 	plt.show()

	'''create the set files'''
	# allCellAndFree = fpt_multiSetpoint.createAllCellAndFreeFPT(folder, 0, pointResolution=100, bins=300, usedDataRatio=0.99)
	# for set_number, fpt_set in allCellAndFree.items():
	# 	cell = fpt_set["cell"]
	# 	free = fpt_set["free"]
	# 	cell_file = f"{folder}set{set_number}_cell_fpt_sameSet.pkl"
	# 	free_file = f"{folder}set{set_number}_free_fpt_sameSet.pkl"
	# 	pickle.dump(cell, open(cell_file, "wb"))
	# 	pickle.dump(free, open(free_file, "wb"))

	'''plot the difference between set files'''
	# set_files = fpt_multiSetpoint.getAllSetFiles(folder)
	# for set_number, files in set_files.items():
	# 	cell = pickle.load(open(f"{folder}set{set_number}_cell_fpt_sameSet.pkl", "rb"))
	# 	free = pickle.load(open(f"{folder}set{set_number}_free_fpt_sameSet.pkl", "rb"))
	# 	diff = fpt_multiSetpoint.getDifferenceBetweenCellAndFreeFPT(cell, free)
	# 	# diff.plot()
	# 	fig = plt.figure(f"Set {set_number}")
	# 	ax = fig.add_subplot(111, projection='3d', title=f"Set {set_number}")
	# 	# ax.plot_surface(cell.startPoint, cell.fpt, cell.pdf, cmap='viridis', alpha=0.5, label='Cell')
	# 	# ax.plot_surface(free.startPoint, free.fpt, free.pdf, cmap='plasma', alpha=0.5, label='Free')
	# 	ax.plot_surface(diff.startPoint, diff.fpt, diff.pdf, cmap='coolwarm', label='Difference (Cell - Free)')
		
	# 	# Label axes
	# 	ax.set_xlabel('start point')
	# 	ax.set_ylabel('fpt')
	# 	ax.set_zlabel('cell-free CDF')
	# 	plt.show()

	'''create the PSD files'''
	
	# for file in files:
	# 	PSDFile = f"{file}_PSD.pkl"
	# 	if os.path.exists(PSDFile):
	# 		continue
	# 	q = pickle.load(open(f"{file}_usefulData.pkl", "rb"))
	# 	# Compute the Power Spectral Density (PSD) of q.nidaqX
	# 	x = q.nidaqX
	# 	dt = q.nidaqTimings[1] - q.nidaqTimings[0]
	# 	fs = 1.0 / dt  # Sampling frequency
	# 	n = len(x)
	# 	# Remove mean to avoid DC component
	# 	x = x - np.mean(x)
	# 	# Compute FFT and corresponding frequencies
	# 	fft_vals = np.fft.fft(x)
	# 	freqs = np.fft.fftfreq(n, dt)
	# 	psd = (np.abs(fft_vals) ** 2) / (fs * n)
	# 	# Only keep the positive frequencies
	# 	pos_mask = freqs > 0
	# 	psd = psd[pos_mask]
	# 	freqs = freqs[pos_mask]
	# 	# Save PSD and frequencies to file
	# 	psd_data = plottable(freqs,psd, "f", "PSD", plotFunction=plt.loglog)
	# 	pickle.dump(psd_data, open(PSDFile, "wb"))

	'''difference between nidaq and bio fpt'''
	# for file in files:
	# 	q = pickle.load(open(f"{file}_usefulData.pkl", "rb"))
	# 	if q.driftCompensationTime > .5 and q.bioFPT[0].size > 0:
	# 		bins = 200
	# 		setpoints = q.FPT_setpoint0 * np.array([.5,1,1.5, -0.5, -1, -1.5])
	# 		fpt, startPoint, pdf = acquisition.FPT_CDF_fromData(q.nidaqX, q.nidaqTimings, setpoints, q.FPT_setpoint1, bins)
	# 		plt.plot(fpt.T, pdf.T, label=setpoints)
	# 		plt.plot(q.bioFPT[0][np.linspace(0, len(q.bioFPT[0])-1, bins, dtype=int)], np.linspace(0, 1, bins), label="fpga")
	# 		plt.title(file)
	# 		plt.legend()
	# 		plt.show()

	'''gaussian distribution'''
	# file = "d:/lastline/bioTweezers/20250709/set_03_cell_bead_003"
	# acq = acquisition(file)
	# t, x = acq.nidaq_t_x

	# windowSize = int(.5 / 1e-3)
	# # x -= np.convolve(x, np.ones(windowSize)/windowSize, mode = "same")

	# counts, vals = np.histogram(x,bins=200)
	# plt.plot(vals[:-1], counts)

	# # Fit a Gaussian to the histogram

	# def gaussian(x, a, mu, sigma):
	# 	return a * np.exp(-(x - mu) ** 2 / (2 * sigma ** 2))

	# # Use the bin centers for fitting
	# bin_centers = (vals[:-1] + vals[1:]) / 2
	# p0 = [counts.max(), bin_centers[np.argmax(counts)], np.std(x)]
	# params, _ = curve_fit(gaussian, bin_centers, counts, p0=p0)

	# # Plot the fitted Gaussian
	# plt.plot(bin_centers, gaussian(bin_centers, *params), label='Gaussian fit')
	# plt.legend()
	# plt.figure()
	
	# x -= np.convolve(x, np.ones(windowSize)/windowSize, mode = "same")

	# counts, vals = np.histogram(x,bins=200)
	# plt.plot(vals[:-1], counts)
	# bin_centers = (vals[:-1] + vals[1:]) / 2
	# p0 = [counts.max(), bin_centers[np.argmax(counts)], np.std(x)]
	# params, _ = curve_fit(gaussian, bin_centers, counts, p0=p0)

	# # Plot the fitted Gaussian
	# plt.plot(bin_centers, gaussian(bin_centers, *params), label='Gaussian fit')
	# plt.legend()

	# plt.show()

	# acq = acquisition("d:/lastline/bioTweezers/bigliaInTether_PI_tiratoFinoAllaSaturazione_005.csv")
	# t, x = acq.nidaq_t_x
	# displacement = acq.getNidaqAcquisition()["AI1"]
	# stiffness = -acq.getNidaqAcquisition()["AI7"]
	# plt.scatter(displacement, stiffness * x,alpha=0.03)
	# plt.show()
	# t, x = acq.bio_t_x
	# displacement = acq.getBioControllerAcquisition()["AI1"]
	# stiffness = -acq.getNidaqAcquisition()["AI7"]
	# plt.scatter(displacement, stiffness * x,alpha=0.03)
	# plt.show()

	acq = acquisition("d:/lastline/bioTweezers/20250708/set02_cell_bead_001.csv")
	t, x = acq.nidaq_t_x
	# Instead of using fixed bin_edges, use the bin edges returned by np.histogram for each section.
	num_sections = 400

	section_edges = np.linspace(t.min(), t.max(), num_sections + 1)
	hist_matrix = []
	bin_centers_list = []

	for i in range(num_sections):
		mask = (t >= section_edges[i]) & (t < section_edges[i+1])
		x_section = x[mask]
		if len(x_section) > 0:
			counts, bin_edges = np.histogram(x_section, bins='auto')
			bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
			normalized_counts = counts / np.sum(counts) if np.sum(counts) > 0 else counts
			hist_matrix.append(normalized_counts)
			bin_centers_list.append(bin_centers)
		else:
			hist_matrix.append([])
			bin_centers_list.append([])

	# Plot each section as a line in 3D (since bins are not aligned)
	fig = plt.figure("Distribution of x over time (variable bins)")
	ax = fig.add_subplot(111, projection='3d')
	for i, (counts, bins) in enumerate(zip(hist_matrix, bin_centers_list)):
		if len(counts) > 0:
			section_time = (section_edges[i] + section_edges[i+1]) / 2
			ax.plot(bins, [section_time]*len(bins), counts, color='b', alpha=0.5)

	ax.set_xlabel('x')
	ax.set_ylabel('Time (s)')
	ax.set_zlabel('Normalized Distribution')
	plt.show()


	
