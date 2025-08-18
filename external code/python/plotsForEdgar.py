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
from acquisition import acquisition


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
# filesToNotTrust = [
# 	"d:\\lastline\\bioTweezers\\20250709\\set_04_cell_bead_006",
# 	"d:\\lastline\\bioTweezers\\20250708\\set09_free_bead_011",
# 	"d:\\lastline\\bioTweezers\\20250708\\set03_free_bead_002",
# 	"d:\\lastline\\bioTweezers\\20250708\\set05_free_bead_001",
# 	"d:\\lastline\\bioTweezers\\20250708\\set04_cell_bead_001",
# 	"d:\\lastline\\bioTweezers\\20250708\\set05_cell_bead_002",
# 	"d:\\lastline\\bioTweezers\\20250716\\set01_cell_bead_001",
# 	"d:\\lastline\\bioTweezers\\20250708\\set01_cell_bead_001",

# ]
# allCellFiles = []
# allFreeFiles = []
# folders = [
# 	"d:/lastline/bioTweezers/20250708", 
# 	"d:/lastline/bioTweezers/20250709", 
# 	"d:/lastline/bioTweezers/20250715", 
# 	"d:/lastline/bioTweezers/20250716",
	
# ]
# for folder in folders:
# 	files = acquisition.getAllBaseFiles(folder)
# 	files = [file for file in files if "feedback" not in file]
# 	allCellFiles += [file for file in files if "cell" in file]
# 	allFreeFiles += [file for file in files if "free" in file]
# allCellFiles = [file for file in allCellFiles if file not in filesToNotTrust]
# allFreeFiles = [file for file in allFreeFiles if file not in filesToNotTrust]

# for fileList in [allCellFiles, allFreeFiles]:
# 	for i, file in enumerate(fileList):
# 		print(file)
# 		acq = acquisition(file)
# 		# laserIntensity = np.mean(acq.getNidaqAcquisition()["AI7"])
# 		# print(laserIntensity)
# 		t, x = acq.nidaq_t_x
# 		x = x * 1e-6 / 1e-9 #x * Sx, in nm

# 		windowSize = int(0.5 / 1e-3)
# 		x -= np.convolve(x, np.ones(windowSize)/windowSize, mode = "same")

# 		counts, vals = np.histogram(x,bins=500)
# 		counts = counts / len(x) / (vals[-1] - vals[0])
# 		plt.plot(vals[:-1], counts, label = file)
# 		plt.xlabel("Position (nm)")
# 		# if i%10==9:
# 		# 	plt.legend()
# 		# 	plt.show()
# 	plt.legend()
# 	plt.show()


files = ["d:/lastline/bioTweezers/20250709/set_02_free_bead_005", "d:/lastline/bioTweezers/20250709/set_02_cell_bead_002"]
#smaller files
# files = ["d:/lastline/bioTweezers/20250716/set02_cell_bead_feedback_003", "d:/lastline/bioTweezers/20250805/set04_free_bead_feedback_saturated_008"]

def plotForPositionDistribution(fileName):
	plt.legend(fontsize=12)
	plt.gcf().set_size_inches(12/2.54, 8/2.54)  # 12cm x 8cm in inches
	plt.xlabel("Position (nm)", fontsize=12, fontname="Arial")
	plt.ylabel("Probability Distribution Function", fontsize=12, fontname="Arial")
	plt.xticks(fontsize=12, fontname="Arial", )
	# Set y-ticks at desired positions (0, 2, 4, 6, 8, 10) * 1e-4
	plt.yticks(fontsize=12, fontname="Arial")
	# plt.gcf().subplots_adjust(left=0.18)  # Increase left margin to prevent y-label clipping
	# plt.gcf().subplots_adjust(bottom=0.18)  # Increase bottom margin to prevent x-label clipping
	plt.gca().set_yticklabels(["$"+"{:.1e}".format(tick._y).replace("e", "\\times 10^{")+"}$" for tick in plt.gca().yaxis.get_ticklabels()])
	plt.ylabel("Probability Distribution Function", fontsize=12, fontname="Arial")
	plt.xlim(left=-20,right=20)
	plt.tight_layout()
	plt.savefig(fileName, dpi=600)
	plt.yscale("log")
	plt.tight_layout()
	plt.savefig(fileName.replace(".png", "_log.png"), dpi=600)
	plt.show()

for removeDrift in ["", "_drift removed"]:
	for file, cellFree in zip(files, ["free", "cell"]):
		acq = acquisition(file)
		t, x = acq.nidaq_t_x

		windowSize = int(0.5 / 1e-3)
		if removeDrift == "":
			x -= np.mean(x)
		else:
			x -= np.convolve(x, np.ones(windowSize)/windowSize, mode = "same")
		x = x * 1e-6 / 1e-9 #x * Sx, in nm

		counts, vals = np.histogram(x,bins=500)
		counts = counts / len(x) / (vals[-1] - vals[0])
		if cellFree=="cell":
			stupidOrangeColor = "#ff7f0e"
			plt.plot(vals[:-1], counts, color=stupidOrangeColor, label=cellFree)
		else:
			plt.plot(vals[:-1], counts, label = cellFree)
		plotForPositionDistribution(f"d:\\lastline\\bioTweezers\\20250709\\position distribution_{cellFree}{removeDrift}.png")
for removeDrift in ["", "_drift removed"]:
	for file, cellFree in zip(files, ["free", "cell"]):
		acq = acquisition(file)
		t, x = acq.nidaq_t_x

		windowSize = int(0.5 / 1e-3)
		if removeDrift == "":
			x -= np.mean(x)
		else:
			x -= np.convolve(x, np.ones(windowSize)/windowSize, mode = "same")
		x = x * 1e-6 / 1e-9 #x * Sx, in nm

		counts, vals = np.histogram(x,bins=500)
		counts = counts / len(x) / (vals[-1] - vals[0])
		if cellFree=="cell":
			stupidOrangeColor = "#ff7f0e"
			plt.plot(vals[:-1], counts, color=stupidOrangeColor, label=cellFree)
		else:
			plt.plot(vals[:-1], counts, label = cellFree)
	plotForPositionDistribution(f"d:\\lastline\\bioTweezers\\20250709\\position distribution{removeDrift}.png")

setpoints = [10, 15]
for setpoint in setpoints:
	for file, cellFree in zip(files, ["free", "cell"]):
		acq = acquisition(file)
		t, x = acq.nidaq_t_x
		x = x * 1e-6 / 1e-9 #x * Sx, in nm
		t = t * 1e3#in ms

		
		windowSize = int(0.5 / 1e-3)
		x -= np.convolve(x, np.ones(windowSize)/windowSize, mode = "same")

		fpt, cdf = FPT_CDF_fromData(x, t, setpoint, 0, 1000)
		pdf = np.gradient(cdf, fpt)
		# pdf = np.array([np.gradient(cdf[:,i], fpt[:,i]) for i in range(len(cdf[0]))]).T
		plt.semilogx(fpt, pdf, label = cellFree)#[f"{i}nm" for i in setpoints])
	plt.legend(fontsize=12)
	plt.gcf().set_size_inches(12/2.54, 8/2.54)  # 12cm x 8cm in inches
	plt.xlabel(f"First Passage Time (ms)", fontsize=12, fontname="Arial")
	plt.xticks(fontsize=12, fontname="Arial")
	# plt.gca().set_yticks([])
	plt.ylabel("Probability Distribution Function", fontsize=12, fontname="Arial")
	plt.gcf().subplots_adjust(left=0.18)  # Increase left margin to prevent y-label clipping
	plt.gcf().subplots_adjust(bottom=0.18)  # Increase bottom margin to prevent x-label clipping
	plt.tight_layout()
	plt.savefig("histogram_plot.png", dpi=600)
	plt.tight_layout()
	plt.xlim(.1,20)
	plt.ylim(-0.007, .32)
	plt.savefig(f"d:\\lastline\\bioTweezers\\20250709\\fpt_setpoint{setpoint}.png", dpi=600)
	plt.show()





