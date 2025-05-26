


def install_and_import(package):
	import subprocess
	import sys
	try:
		__import__(package)
	except ImportError:
		subprocess.check_call([sys.executable, "-m", "pip", "install", package])
		__import__(package)
install_and_import("networkx")
from scipy.optimize import  least_squares
import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import correlate
import os
import tkinter
from tkinter import filedialog
import numpy as np
from bioTweezerController import bioTweezerController
import bisect

class cellAcquisition(bioTweezerController):
	def reset(self):
		pass
	def sendCommand(self, *args):
		pass
	@staticmethod
	def _getDf(fileName):
		with open(fileName, 'r') as file:
			lines = file.readlines()
			num_columns = len(lines[1].strip().split('\t'))

		# Load the .cdv file into a DataFrame, specifying the number of columns
		df = pd.read_csv(fileName, delimiter='\t', header=0, usecols=range(num_columns))
		df.columns = df.columns.str.strip()
		return df

	@staticmethod
	def getBaseSettingsFromFile(fileName, returnType = dict):
		pf = pd.read_csv(fileName, sep=',', lineterminator="\n", header=1)
		l = [dict(row) for index, row in pf.iterrows()]
		if '\r' in list(l[0].keys())[-1]:
			lastKey_slashR = list(l[0].keys())[-1]
			lastKey = lastKey_slashR.replace('\r','')
			for i in range(len(l)):
				l[i][lastKey] = l[i][lastKey_slashR].replace('\r','')
				l[i].pop(lastKey_slashR)
		if returnType == list:
			return l
		elif returnType == dict:
			return {e["Parameter internal name"] : e for e in l}
	
	@staticmethod
	def find_delay(signal1, signal2, t1, t2):
		fs1, fs2 = 1 / t1, 1 / t2
		# Resample the signals to the same frequency
		max_fs = max(fs1, fs2)
		resampled_signal1 = np.interp(np.arange(0, len(signal1), fs1/max_fs), np.arange(len(signal1)), signal1)
		resampled_signal2 = np.interp(np.arange(0, len(signal2), fs2/max_fs), np.arange(len(signal2)), signal2)
		
		# Compute cross-correlation
		correlation = correlate(resampled_signal1, resampled_signal2)
		delay_index = np.argmax(correlation) - (len(resampled_signal2) - 1)
		
		# Convert delay index to time
		delay = delay_index / max_fs
		return delay
	
	def __init__(self, fileName:str):
		super(cellAcquisition, self).__init__()
		bioFileName = fileName.replace(".csv", "_bioControllerAcquisition.csv")
		confFileName = fileName.replace(".csv", "_conf.csv")
		self.baseDf = cellAcquisition._getDf(fileName)
		piezoX = np.array(self.baseDf["AI1"])
		piezoY = np.array(self.baseDf["AI5"])
		self.piezo = piezoX if np.var(piezoX) > np.var(piezoY) else piezoY
		self.sum = np.array(self.baseDf["AI2"])
		self.xdiff = np.array(self.baseDf["AI3"])
		self.response = np.array(self.baseDf["AI6"])
		self.x = self.xdiff/self.sum
		self.base_times = np.array(self.baseDf["Time (s)"])
		varianceSize = 50
		self.variance = pd.Series(self.x).rolling(window=varianceSize).var().to_numpy()
		self.variance[np.isnan(self.variance)] = 0

		# self.externalForce = self.getExternalForces()

		self.bioDf = cellAcquisition._getDf(bioFileName)
		self.bio_times = np.array(self.bioDf["times"])
		if any(self.bio_times[1:]-self.bio_times[:-1] != self.bio_times[1]-self.bio_times[0]):
			print("fixing times for bio controller acquisitions")
			period = 0x40000 / 50e6
			self.bio_times = np.linspace(self.bio_times[0], period * (len(self.bio_times) - 1), len(self.bio_times))

		self.conf = cellAcquisition.getBaseSettingsFromFile(confFileName)
		self.zOffset = self.conf["SUM_offsetFor_z"]['Parameter value']
		self.setPoint = np.array([self.conf["setpoint"]['Parameter value']] * 2)
		self.neg_setPoint = -self.setPoint
		self.bio_x = np.array(self.bioDf["x"])
		self.bio_response = np.array(self.bioDf["pid out"])
		# self.bio_variance = np.array(self.bioDf["x^2"] - np.array(self.bioDf["x"] ** 2
		self.bio_variance = pd.Series(np.array(self.bioDf["x^2"])).rolling(window=varianceSize).mean().to_numpy() - \
							pd.Series(self.bio_x).rolling(window=varianceSize).mean().to_numpy() ** 2
		self.bio_variance[np.isnan(self.bio_variance)] = 0
		
		self.bio_sum = - (np.array(self.bioDf["z"]) - self.zOffset)
		# self.bio_sum = self.dimLink.convert(np.array(self.bioDf["z"] - self.zOffset, "FPGA_SUMfloatValue", "QPD_output") / 10

		delay = cellAcquisition.find_delay(self.sum, self.bio_sum, self.base_times[1]-self.base_times[0], self.bio_times[1]-self.bio_times[0])
		self.bio_times += delay
		self.linesTimes = np.array([min(self.bio_times[0], self.base_times[0]), max(self.bio_times[len(self.bio_times)-1], self.base_times[len(self.base_times)-1])])

		self.allCurves = {
			"base_times" : ["piezo", "sum", "xdiff", "response", "x", "variance", ],
			# "base_times" : ["piezo", "sum", "xdiff", "response", "x", "variance", "externalForce"],
			"linesTimes" : ["setPoint", "neg_setPoint", ],
			"bio_times"  : ["bio_x", "bio_response", "bio_variance", "bio_sum"],
			}
		
		self.updateGeneratorBaseCurrent(self.conf["currentGenerator_baseCurrent"]["Parameter value"])
	@staticmethod
	def find_closest_indices(a, b, I):
		J = []
		for i in I:
			# Find the index of the closest value in b to a[i]
			closest_index = np.argmin(np.abs(b - a[i]))
			J.append(closest_index)
		return J
	@staticmethod
	def __find_first_larger_than(sorted_list, value):
		index = bisect.bisect_right(sorted_list, value)
		return index if index < len(sorted_list) else -1
	def truncateData(self, startTime = None, endTime = None):
		if startTime is None:
			startTime = min(self.base_times[0], self.bio_times[0])
		if endTime is None:
			endTime = max(self.base_times[-1], self.bio_times[-1])
		
		time = self.base_times
		minIdx = cellAcquisition.__find_first_larger_than(time, startTime)
		maxIdx = cellAcquisition.__find_first_larger_than(time, endTime) - 1
		if minIdx > 0:
			self.baseDf = self.baseDf.iloc[minIdx:]
			maxIdx -= minIdx
		if maxIdx > 0:
			self.baseDf = self.baseDf.iloc[:maxIdx]
		
		for key, val in self.allCurves.items():
			time = getattr(self, key)
			minIdx = cellAcquisition.__find_first_larger_than(time, startTime)
			maxIdx = cellAcquisition.__find_first_larger_than(time, endTime) - 1
			if minIdx > 0:
				maxIdx -= minIdx

			for s in val:
				l = getattr(self,s)
				if minIdx > 0:
					l = l[minIdx:]
				if maxIdx > 0:
					l = l[:maxIdx]
				setattr(self, s, l)
			
			if minIdx > 0:
				time = time[minIdx:]
			if maxIdx > 0:
				time = time[:maxIdx]
			setattr(self, key, time)
			
	def addOffsetToBaseX(self, nOfSamples = 50):
		border = len(self.base_times) // 5
		baseSamples = np.floor(np.linspace(border,len(self.base_times)-1 - border, nOfSamples)).astype(int)
		bioSamples = cellAcquisition.find_closest_indices(self.base_times, self.bio_times, baseSamples)
		xd = self.xdiff[baseSamples]
		sum = self.sum[baseSamples]
		x = self.bio_x[bioSamples]
		def f(o):
			return ((xd-o[0])/(sum-o[1])-o[2]) - x
		solution = least_squares(f, np.array([0,0,0]))
		o = solution.x
		print(solution)
		if np.any(np.abs(o) > .6):
			raise Exception(f"solution {o} too big, it's not valid")
		self.x = ((self.xdiff-o[0])/(self.sum-o[1])-o[2])

	def getConfig(self, parameterName):
		return self.conf[parameterName]["Parameter value"]
	def getConfigWithDimension(self, parameterName):
		return (self.conf[parameterName]["Parameter value"], self.conf[parameterName]["Parameter internal unit"])
	def convert(self, parameterName, newDimension):
		return self.dimLink.convert(self.conf[parameterName]["Parameter value"], self.conf[parameterName]["Parameter internal unit"], newDimension)
	def _getEdgesPosition(self, isFromInactiveToActive = True):
		
		lowLevel = self.convert("outWhenPiDisabled", "generator_input")
		highLevel = self.convert("binFeedback_valueWhenActive", "generator_input")
		threshold = (highLevel - lowLevel) * 0.9
		stepLength = 10# the response might not have an immediate switch due to the filtering of the system, 
			# instead of checking the difference between 2 adiacent samples, let's see the difference between 
			# 2 more distantiated samples
		if isFromInactiveToActive:
			edgePositions = np.array(range(len(self.response)))[np.append(self.response[stepLength:]-self.response[0:-stepLength] > threshold, [False] * stepLength)]
			#remove the repeated edge (elongating the step length, we might register the same step multiple times)
			if len(edgePositions) > 0:
				edgePositions = edgePositions[np.append(edgePositions[1:]-edgePositions[0:-1] > stepLength, [True])]
		else:
			edgePositions = np.array(range(len(self.response)))[np.append(self.response[stepLength:]-self.response[0:-stepLength] < -threshold, [False] * stepLength)]
			#remove the repeated edge (elongating the step length, we might register the same step multiple times)
			if len(edgePositions) > 0:
				edgePositions = edgePositions[np.append([True],edgePositions[1:]-edgePositions[0:-1] > stepLength)]
		return edgePositions
	
	def getActivations(self):
		# gets the times of activation of the control
		edgePositions = self._getEdgesPosition(True)
		edges = self.base_times[edgePositions]
		return edges
	
	def getIndexesWhenActive(self, nOfBorderIndexes = 0):
		starts = self._getEdgesPosition(True) + nOfBorderIndexes
		ends = self._getEdgesPosition(False) - nOfBorderIndexes
		indices = set()
		for start, end in zip(starts, ends):
			indices.update(range(start, end))
		return list(sorted(indices))
	
	def fromBaseTimesToBioTimes(self, indexes):
		times = self.base_times[indexes]
		times = [bisect.bisect_left(self.bio_times, value) for value in times]
		times = list(set(times))
		return times
		
	def getInitalCurrent(self):
		v = self.baseDf["AI7"][0]
		return self.dimLink.convert(v,"generator_debugVoltage", "generator_current")
	
	def getExternalForces(self, I_to_k = 1):
		#get the force pulling on the bead, which should be compensated by the optical tweezer.
		# I_to_k converts the laser current into a trap stiffness
		#we assume a slow movement, so in each moment the bead is in an equilibrium, thus speed = 0 => sum(Forces) = 0
		# => F_external = - F_trap = kx = I * I_to_k * x
		I = - self.baseDf["AI7"]
		x = self.dimLink.convert(self.x, "FPGA_floatValue", "bead_position")#np.interp(self.base_times, self.bio_x, self.bio_times, )
		return I * I_to_k * x
	
	def plotAll(self, remove = None, keep = None, normalizeAll = False):
		if keep is None:
			keep = [el for key, val in self.allCurves.items() for el in val]
		if remove is not None:
			keep = [el for el in keep if el not in remove]
		for key, val in self.allCurves.items():
			for s in val:
				if s in keep:
					signal = getattr(self,s)
					if normalizeAll:
						signal = signal / max(abs(signal))
					plt.plot(getattr(self,key), signal, label=s, alpha=0.7)
		plt.legend()
		plt.show()

	def printAll(self):
		for key, val in self.conf.items():
			print(f"{key}: {val['Parameter value']} ({val['Parameter internal unit']})")

	@staticmethod
	def allBaseFileNames(folder_path):
		file_names = []
		for root, dirs, files in os.walk(folder_path):
			for file in files:
				if	"_bioControllerAcquisition.csv"	not in file and \
					"_conf.csv" 					not in file and \
					".csv"							in file:
					file_names.append(os.path.join(root, file))
		return file_names
	
def __plotAllFirings():
	folder = "C:/Users/lastline/Documents/bioTweezers/25_9_24/"
	allFiles = cellAcquisition.allBaseFileNames(folder)
	allFiles = [file for file in allFiles if "wall_trap" in file]
	elements = []
	for file in allFiles:
		acq = cellAcquisition(file)
		timesOfFiring = acq.getActivations()
		if len(timesOfFiring) >= 1:
			periodOfFiring = acq.base_times[-1] - timesOfFiring[0]
			firingRate = len(timesOfFiring) / periodOfFiring
		else:
			firingRate = 0
		cur = acq.getInitalCurrent()
		if abs(cur - 150e-3) > abs(cur - 100e-3):
			cur = 100e-3
		else:
			cur = 150e-3
		if "x3" in file:
			fedCur = cur * 3
		else:
			fedCur = cur * 2
		elements.append({"name" : file, "acquisition" : acq, "firingRate" : firingRate, "baseCurrent" : cur, "activeCurrent" : fedCur, "setpoint" : acq.getConfig("binFeedback_threshold")})
	print(elements)
# 	elements = [{'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/new_wall_trap_150mA_x2_setpoint0_01abilitato_a_meta,_009.csv', 'acquisition': 0x0000022713B7A390, 'firingRate': 48.05405352930326, 'baseCurrent': 0.15, 'activeCurrent': 0.3, 'setpoint': \
# 0.009979248046875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/new_wall_trap_150mA_x2_setpoint0_02abilitato_a_meta,_009.csv', \
# 'acquisition': 0x00000227151E6D50, 'firingRate': 66.59603450885425, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.019989013671875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/new_wall_trap_150mA_x2_setpoint0_05abilitato_a_meta,_009.csv', 'acquisition': 0x00000227188CAD50, 'firingRate': 0.5863070650001333, 'baseCurrent': 0.15, 'activeCurrent': 0.3, 'setpoint': 0.04998779296875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/new_wall_trap_150mA_x2_setpoint0_1abilitato_a_meta,_009.csv', 'acquisition': 0x000002271881DF90, 'firingRate': 0, 'baseCurrent': 0.15, 'activeCurrent': 0.3, 'setpoint': 0.0999755859375}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_150mA_x2_setpoint0_02abilitato_a_meta,_009.csv', 'acquisition': 0x0000022718831550, 'firingRate': 55.56213484920259, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.019989013671875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_150mA_x2_setpoint0_05abilitato_a_meta,_010.csv', 'acquisition': 0x0000022718844110, 'firingRate': 35.27199384201655, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.04998779296875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_150mA_x2_setpoint0_1abilitato_a_meta,_011.csv', 'acquisition': 0x0000022718852990, 'firingRate': 5.9571651458559876, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.0999755859375}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_150mA_x2_setpoint0_2abilitato_a_meta,_012.csv', 'acquisition': 0x0000022718862A10, 'firingRate': 0, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.199981689453125}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_setpoint0_1_abilitato_a_meta,_002.csv', 'acquisition': 0x000002271FD56CD0, 'firingRate': 2.579918849825269, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.0999755859375}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_setpoint0_1_disabilitato_a_meta,_001.csv', 'acquisition': 0x0000022718845090, 'firingRate': 1.3437833675937563, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.0999755859375}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_x2_setpoint0_02_abilitato_a_meta,_008.csv', 'acquisition': 0x00000227188991D0, 'firingRate': 54.60174500422178, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.019989013671875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_x2_setpoint0_05_abilitato_a_meta,_005.csv', 'acquisition': 0x00000227188AEBD0, 'firingRate': 31.78043367267195, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.04998779296875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_x2_setpoint0_1_abilitato_a_meta,_004.csv', 'acquisition': \
# 0x00000227188BF710, 'firingRate': 8.759347222875418, 'baseCurrent': 0.1, 'activeCurrent': 0.2, 'setpoint': 0.0999755859375}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_x3_setpoint0_02_abilitato_a_meta,_007.csv', 'acquisition': 0x00000227188D9A10, 'firingRate': 54.11906193625977, 'baseCurrent': 0.1, 'activeCurrent': 0.30000000000000004, 'setpoint': 0.019989013671875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_x3_setpoint0_05_abilitato_a_meta,_006.csv', 'acquisition': 0x000002271FD29DD0, 'firingRate': 30.83039227617541, 'baseCurrent': 0.1, 'activeCurrent': 0.30000000000000004, 'setpoint': 0.04998779296875}, {'name': 'C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_x3_setpoint0_1_abilitato_a_meta,_003.csv', 'acquisition': 0x000002271FD2BF50, 'firingRate': 2.245336716307319, 'baseCurrent': 0.1, 'activeCurrent': 0.30000000000000004, 'setpoint': 0.0999755859375}]
	currents = set()
	for el in elements:
		currents.add((el["baseCurrent"], el["activeCurrent"]))
	groups = {}
	currents = list(currents)[::-1]
	print(currents)
	for (bc,ac) in currents:
		groups[f"{bc}, {ac}"] = ([a["setpoint"]for a in elements if a["baseCurrent"] == bc and a["activeCurrent"] == ac],
								[a["firingRate"]for a in elements if a["baseCurrent"] == bc and a["activeCurrent"] == ac])
	for key, val in groups.items():
		plt.scatter(val[0],val[1],label = key, alpha=0.7)
	plt.legend()
	plt.xscale('log')
	plt.yscale('log')
	plt.show()


if __name__ == "__main__":
	# __plotAllFirings()
	pass


# p = cellAcquisition("c:/Users/lastline/Documents/bioTweezers/26_9_24/bigliaInTether_PI_004.csv")
# # p = cellAcquisition("C:/Users/lastline/Documents/bioTweezers/25_9_24/wall_trap_x2_setpoint0_1_abilitato_a_meta,_004.csv")

# p.printAll()
# # p.plotAll(keep=["x", "bio_x", "response"], normalizeAll=True)

# plt.scatter(p.baseDf["AI1"], p.getExternalForces(), s=0.1)
# plt.show()
# p.plotAll()
# p = cellAcquisition("c:/Users/lastline/Documents/bioTweezers/26_9_24/biglia_leggermenteAbbassata_conVideo_oscillanteInY_PI_IntegralePiuBasso_020.csv")
# # p = cellAcquisition("C:/Users/lastline/Documents/bioTweezers/25_9_24/new_wall_trap_150mA_x2_setpoint0_05abilitato_a_meta,_009_bioControllerAcquisition.csv")

# p.printAll()
# plt.scatter(p.baseDf["AI5"], p.getExternalForces())
# plt.show()

def __lookAtFFT():
	import numpy as np
	from scipy.fft import fft, fftfreq
	from scipy.signal import resample
	import matplotlib.pyplot as plt
	p = cellAcquisition("C:/Users/lastline/Documents/bioTweezers/26_9_24/bigliaInTether_PI_004.csv")
	p.addOffsetToBaseX(200)
	p.truncateData(startTime=4)
	X = np.abs(fft(p.x))
	bX = np.abs(fft(p.bio_x))

	plt.loglog(np.abs(fftfreq(len(p.x), p.base_times[1] - p.base_times[0])), X)
	plt.loglog(np.abs(fftfreq(len(p.bio_x), p.bio_times[1] - p.bio_times[0])), bX)

	p = cellAcquisition("C:/Users/lastline/Documents/bioTweezers/26_9_24/bigliaInTether_PI_004.csv")
	# p.truncateData(endTime=3)
	p.addOffsetToBaseX(200)
	X1 = np.abs(fft(p.x))
	bX1 = np.abs(fft(p.bio_x))

	plt.loglog(np.abs(fftfreq(len(p.x), p.base_times[1] - p.base_times[0])), X1)
	plt.loglog(np.abs(fftfreq(len(p.bio_x), p.bio_times[1] - p.bio_times[0])), bX1)

	plt.show()

	p.printAll()
	# p = cellAcquisition("C:/Users/lastline/Documents/bioTweezers/25_9_24/baseline_001.csv")
	# X = np.abs(fft(p.x))
	# bX = np.abs(fft(p.bio_x))

	# plt.loglog(np.abs(fftfreq(len(p.x), p.base_times[1] - p.base_times[0])), X)
	# plt.loglog(np.abs(fftfreq(len(p.bio_x), p.bio_times[1] - p.bio_times[0])), bX)

	# plt.show()

def __plotPiezoAndBeadDisplacemets(file, applyFilter = False):
	p = cellAcquisition(file)
	p.addOffsetToBaseX(200)
	# p.plotAll()
	x = p.base_times
	y2 = p.dimLink.convert(p.x,"FPGA_floatValue", "bead_position") / 1e-9
	if np.mean(y2) < 0:
		y2 = -y2
	y1 = p.dimLink.convert(p.piezo - np.mean(p.piezo),"piezo_voltage", "bead_position") / 1e-6

	if applyFilter:
		from scipy.signal import butter, filtfilt
		b, a = butter(4, 0.15, btype='low', analog=False)

		# Apply the filter
		y2 = filtfilt(b, a, y2)

	fig, ax1 = plt.subplots()
	# Plotting the first y-axis
	ax1.plot(x, y1, 'orange')
	ax1.set_xlabel('time (s)')
	ax1.set_ylabel('piezo displacement (um)', color = "orange")

	ax2 = ax1.twinx()
	ax2.plot(x, y2, 'b-')
	ax2.set_ylabel('bead x displacement (nm)', color='b')
	# Set the font size for axis tick labels and axis labels
	ax1.tick_params(axis='both', labelsize=14)  # Change 14 to your desired font size
	ax1.xaxis.label.set_size(16)  # X-axis label font size
	ax1.yaxis.label.set_size(16)  # Y-axis label font size

	ax2.tick_params(axis='both', labelsize=14)
	ax2.yaxis.label.set_size(16)
	ax2.set_ybound(0,np.max(y2)+10)
	fig.set_size_inches(8, 6)
	plt.savefig("piezo_bead_displacements.tiff", format="tiff", dpi=600)
	plt.show()

	# Plotting the first y-axis
	plt.plot(x, y1, label="piezo displacement")
	plt.xlabel('time (s)')
	plt.ylabel('displacement (nm)')

	plt.plot(x, y2, label="bead displacement")
	plt.legend()
	plt.show()
def __plotCellStiffness(file, startTime = 0,endTime = None):
	p = cellAcquisition(file)
	p.addOffsetToBaseX(200)
	# p.plotAll()
	if endTime is None:
		p.truncateData(startTime=startTime)
	else:
		p.truncateData(startTime=startTime, endTime=endTime)
	y2 = p.getExternalForces(1.3e-5 / 100e-3) / 1e-12
	if np.mean(y2) < 0:
		y2 = -y2
	y1 = p.dimLink.convert(p.piezo - np.mean(p.piezo),"piezo_voltage", "bead_position") / 1e-9

	# Plotting the first y-axis
	fig, ax1 = plt.subplots()
	plt.scatter(y1, y2,s=0.1)
	plt.xlabel('Piezo displacement (nm)')
	plt.ylabel('Membrane pulling force (pN)')
	ax1.yaxis.label.set_size(16)
	ax1.xaxis.label.set_size(16)
	fig.set_size_inches(8, 6)
	ax1.tick_params(axis='both', labelsize=14)  # Change 14 to your desired font size
	plt.savefig("CellStiffness.tiff", format="tiff", dpi=600)

	plt.show()

def __plotfirings():
	p = cellAcquisition("C:/Users/lastline/Documents/bioTweezers/25_9_24/new_wall_trap_150mA_x2_setpoint0_05abilitato_a_meta,_009.csv")
	p.addOffsetToBaseX(200)
	p.truncateData(startTime=18.8,endTime=19.2)
	p.printAll()
	p.plotAll()

# # __plotfirings()
# file = "C:/Users/lastline/Documents/bioTweezers/26_9_24/biglia_mossaDaLiberaAContatto_daSopra_poiAScattiMuovendosiSullaX_PI_009.csv"
# file = "C:/Users/lastline/Documents/bioTweezers/26_9_24/biglia_oscillazionePiezo_PI_IntegralePiuBasso_014.csv"

# # __plotPiezoAndBeadDisplacemets(file)
# # __plotCellStiffness(file)
# # file = "C:/Users/lastline/Documents/bioTweezers/26_9_24/biglia_leggermenteAlzata_oscillazionePiezo_PI_IntegralePiuBasso_015.csv"

# __plotPiezoAndBeadDisplacemets(file)
# __plotCellStiffness(file)

def __getVarianceInDifferentPlaces(file):
	acq = cellAcquisition(file)
	acq.printAll()
	print(acq.dimLink.convert(acq.getConfig("binFeedback_threshold"), "FPGA_floatValue", "bead_position"))
	indexesOfFiring = acq._getEdgesPosition(True)
	indexesOfDeFiring = acq._getEdgesPosition(False)
	# if len(indexesOfFiring) >= 1:
	x=acq.dimLink.convert(acq.x, "FPGA_floatValue", "bead_position")
	noControl = np.var(x[0:indexesOfFiring[0]-5])
	
	indices = set()
	for start, end in zip(indexesOfFiring+5, indexesOfDeFiring-5):
		indices.update(range(start, end))
	indeces = list(sorted(indices))
	duringControl = np.var(x[indeces])
	
	indices = set()
	for start, end in zip(indexesOfDeFiring[:-1]+10, indexesOfFiring[1:]-5):
		indices.update(range(start, end))
	indeces = list(sorted(indices))
	afterControl = np.var(x[indeces])

	indices = set()
	for start in indexesOfDeFiring[:-1]+10:
		indices.update(range(start, start+10))
	indeces = list(sorted(indices))
	rightAfterControl = np.var(x[indeces])
	print(noControl, duringControl,afterControl, rightAfterControl)

	controlTime = acq.base_times[-1]-acq.base_times[indexesOfFiring[0]]
	activeFrequency = len(indexesOfFiring) * acq.getConfig("binFeedback_activeFeedbackMaxCycles") / controlTime
	stiffnessRatio = acq.getConfig("binFeedback_valueWhenActive") / acq.getConfig("outWhenPiDisabled")
	averageStiffness = 1 * (1-activeFrequency) + stiffnessRatio * activeFrequency
	print(stiffnessRatio, activeFrequency,  averageStiffness, averageStiffness * rightAfterControl / noControl)
	# plt.plot(acq.response / np.max(np.abs(acq.response)))
	# plt.plot(x / np.max(np.abs(x)))
	# plt.show()
def plotHorizontalLine(x, height, text = None, edgeBarsHeight = None, lineStyle = 'r-', ax = plt, textPosition = "upperLeft"):	
	ax.plot([x[0], x[-1]], [height, height], lineStyle)

	if edgeBarsHeight is not None:
		ax.plot([x[0], x[0]], [height - edgeBarsHeight/2, height + edgeBarsHeight/2], lineStyle)
		ax.plot([x[-1], x[-1]], [height - edgeBarsHeight/2, height + edgeBarsHeight/2], lineStyle)
	else:
		edgeBarsHeight=0
	color = lineStyle.replace('-', '')
	if text is not None:
		if textPosition == "upperLeft":
			ax.text(x[0], height + edgeBarsHeight/2, 'threshold', color=color, va='bottom', ha='left', fontsize=12)
			return
		if textPosition == "lowerCenter":
			ax.text((x[0] + x[-1]) / 2, height - edgeBarsHeight/2, text, color=color, va='top', ha='center', fontsize=12)
			return


def __plotActivationSequence():
	fig, ax1 = plt.subplots()
	p = cellAcquisition("D:/lastline/bioTweezers/9_10_24/onoff001.csv")
	p.addOffsetToBaseX(200)
	# p.plotAll(keep=["response","x"],normalizeAll=False)
	p.truncateData(startTime=2.29, endTime=2.314)

	setpoint = p.dimLink.convert(p.getConfig("binFeedback_threshold"),"FPGA_floatValue", "bead_position") / 1e-9

	x = p.base_times - 2.29
	y2 = p.dimLink.convert(p.x,"FPGA_floatValue", "bead_position") / 1e-9
	y1 = p.response / 2

	# Plotting the first y-axis
	ax1.plot(x, y1, 'g-')
	ax1.set_xlabel('time (s)')
	ax1.set_ylabel('on-off control response', color = "g")

	ax2 = ax1.twinx()
	ax2.plot(x, y2, 'b-')
	ax2.set_ylabel('bead x displacement (nm)', color='b')
	ax2.set_xlabel('bead x displacement (nm)', color='b')
	ax1.tick_params(axis='both', labelsize=14)  # Change 14 to your desired font size
	ax1.xaxis.label.set_size(16)  # X-axis label font size
	ax1.yaxis.label.set_size(16)  # Y-axis label font size
	# ax1.axhline(y=0.35, color='red', linestyle='--')
	# Draw the horizontal threshold line

	params = {'mathtext.default': 'regular' }          
	plt.rcParams.update(params)
	plotHorizontalLine(x, setpoint, text="threshold")
	plotHorizontalLine([.00762, .01], .3, text="$τ_w$", edgeBarsHeight=.025, ax=ax1, textPosition="lowerCenter", lineStyle='k-')
	plotHorizontalLine([.01002, .01508], .2, text="$τ_a$", edgeBarsHeight=.025, ax=ax1, textPosition="lowerCenter", lineStyle='k-')
	plotHorizontalLine([.01507, .01867], .3, text="$τ_d$", edgeBarsHeight=.025, ax=ax1, textPosition="lowerCenter", lineStyle='k-')
	
	ax1.text(.00605,.431, "(1)", color="k", fontsize=14, va='bottom', ha='center')
	ax1.text(.01614,.435, "(2)", color="k", fontsize=14, va='bottom', ha='center')

	ax2.tick_params(axis='both', labelsize=14)
	ax2.yaxis.label.set_size(16)
	fig.set_size_inches(8, 6)
	plt.savefig("activation sequence.tiff", format="tiff", dpi=600)
	plt.show()
# __getVarianceInDifferentPlaces("C:/Users/lastline/Documents/bioTweezers/9_10_24/onoff001.csv")

# # __plotCellStiffness("C:/Users/lastline/Documents/bioTweezers/26_9_24/bigliaInTether_PI_004.csv", endTime=3)
# file = "C:/Users/lastline/Documents/bioTweezers/26_9_24/bigliaInTether_PI_004.csv"
# __plotPiezoAndBeadDisplacemets(file, True)
# # __plotCellStiffness(file)
file = "D:/lastline/bioTweezers/26_9_24/bigliaInTether_PI_004.csv"
# __plotPiezoAndBeadDisplacemets(file, applyFilter=True)
__plotActivationSequence()
# __plotCellStiffness(file)

# # plt.show()

# #3.209177155018705e-16 2.9566260253901517e-16 2.9812442584987604e-16 3.077272678630967e-16


# __plotActivationSequence()