import pandas as pd
import numpy as np

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
	def __init__(self, baseFileName):
		self.__baseFile = acquisition.getBaseFile(baseFileName)
		self.file_nidaqAcquisition = self.getFile('.csv')
		self.file_bioControllerAcquisition = self.getFile('_bioControllerAcquisition.csv')
		self.file_bioControllerTimings = self.getFile('_bioControllerTimings.csv')
		self.file_conf = self.getFile('_conf.csv')
		self.configurations = acquisition.getBaseSettingsFromFile(self.file_conf, None, dict)
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

		