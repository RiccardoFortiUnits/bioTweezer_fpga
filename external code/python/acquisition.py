import pandas as pd
import numpy as np
from bioTweezerController import bioTweezerController
import matplotlib.pyplot as plt
from types import FunctionType, MethodType
from functools import partial
class acquisition():


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
		if not onlyLongTransitions:
			transitionIndexes = np.concatenate(([0],transitionIndexes))#the first element is also treated as a transition
			t[transitionIndexes]=0
			allTimes=np.array([longestTimes[transitionIndexes>i][0]-t[i] for i in range(len(t)-1)])
			x0x1 = np.sort(allTimes[reachedThresholds[:-1] == 1])
		else:
			x0x1 = longestTimes
		x0x1 = np.sort(allTimes[reachedThresholds[:-1] == 1])
		if bothTransitions:
			x1x0 = np.sort(allTimes[reachedThresholds[:-1] == 0])
			return x0x1, x1x0
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
		plt.figure()
		plt.plot(t, np.column_stack(list(data.values())), label = list(data.keys()))
		plt.legend()
		plt.show()
	def plotBioControllerAcquisition(self):
		d = self.bio_buffer
		t, data = d["times"], d.copy()
		data.pop("times")
		plt.figure()
		plt.plot(t, np.column_stack(list(data.values())), label = list(data.keys()))
		plt.legend()
		plt.show()
	def plotBioControllerFPT_CDF(self, bothTransitions = True, onlyLongTransitions = True):
		q = self.getBioControllerRawFPT(bothTransitions, onlyLongTransitions)
		if isinstance(q,tuple):
			x0x1, x1x0 = q
		else:
			x0x1 = q
		plt.plot(x0x1, np.linspace(0,1,len(x0x1)), label = "x0 to x1")
		if bothTransitions:
			plt.plot(x1x0, np.linspace(0,1,len(x1x0)), label = "x1 to x0")
		plt.legend()
		plt.show()
		