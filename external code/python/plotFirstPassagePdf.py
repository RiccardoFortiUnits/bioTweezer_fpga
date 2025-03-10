# -*- coding: utf-8 -*-
"""
Created on Mon Feb  3 16:01:29 2025

@author: lastline
"""

# -*- coding: utf-8 -*-
"""
Created on Tue Jan 28 14:50:00 2025

@author: lastline
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import csv
from scipy import signal
from scipy.interpolate import interp1d
from scipy.signal import butter, filtfilt
import os

def filter_asynchronous_signal(signal, timings, new_sampling_rate, window_size=1):
	# Create a new time array with regular intervals
	new_timings = np.arange(timings[0], timings[-1], 1/new_sampling_rate)
	
	# Interpolate the signal to the new time array
	interpolator = interp1d(timings, signal, kind='linear', fill_value='extrapolate')
	interpolated_signal = interpolator(new_timings)
		
	# # Apply the averager window filter
	# filtered_signal = np.convolve(interpolated_signal, np.ones(window_size)/window_size, mode='valid')
	
	filtered_signal = np.zeros_like(interpolated_signal)
	for i in range(len(interpolated_signal)):
		if i < window_size:
			filtered_signal[i] = np.mean(interpolated_signal[:i+1])
		else:
			filtered_signal[i] = np.mean(interpolated_signal[i-window_size+1:i+1])
	
	return new_timings, filtered_signal

def find_value_in_csv(file_path, search_column, search_value, return_column, expectedType = None):
	with open(file_path, mode='r') as file:
		csv_reader = csv.reader(file)
		next(csv_reader)  # Skip the first row
		headers = next(csv_reader)  # Use the second row as column names
		csv_dict_reader = csv.DictReader(file, fieldnames=headers)
		next(csv_dict_reader)  # Skip the header row in DictReader
		for row in csv_dict_reader:
			if row[search_column] == search_value:
				if expectedType is not None:
					return expectedType(row[return_column])
				return row[return_column]
	return None

def getAllTimingProbabilities(baseFile):
	timingsFile = baseFile.replace('.csv', '_bioControllerTimings.csv')
	q = pd.read_csv(timingsFile, delimiter='\t', header=0)
	
	t = q["timing"].to_numpy().astype(float)
	# raw data is given in clock cycles, not in seconds
	if min(t) >= 1:
		t/=50.e6
	
	reachedThresholds = q["reachedThreshold"].to_numpy()
	transitionIndexes = 1+np.where(reachedThresholds[1:]!=reachedThresholds[:-1])[0]
	lastUsableIndex = transitionIndexes[-1]
	reachedThresholds = reachedThresholds[:lastUsableIndex+1]
	t = t[:lastUsableIndex+1]
	longestTimes=t[transitionIndexes]
	t[transitionIndexes]=0
	allTimes=np.array([longestTimes[transitionIndexes>i][0]-t[i] for i in range(len(t)-1)])
	x0x1 = allTimes[reachedThresholds[:-1] == 0]
	x1x0 = allTimes[reachedThresholds[:-1] == 1]
	return x0x1, x1x0
	
	


def getValues(baseFile, valueName, type=float):
	configFile = baseFile.replace('.csv', '_conf.csv')
	if isinstance(valueName, list) or isinstance(valueName, tuple):
		return [find_value_in_csv(configFile, 'Parameter name', name, 'Parameter value', type) for name in valueName]
	return find_value_in_csv(configFile, 'Parameter name', valueName, 'Parameter value', type)
def getValuesOf_x0_and_x1(baseFile):
	configFile = baseFile.replace('.csv', '_conf.csv')
	x0 = find_value_in_csv(configFile, 'Parameter name', 'x0', 'Parameter value', float)
	x1 = find_value_in_csv(configFile, 'Parameter name', 'x1', 'Parameter value', float)
	return x0, x1
def getValuesOf_outputs(baseFile):
	configFile = baseFile.replace('.csv', '_conf.csv')
	outputAfter_x0 = find_value_in_csv(configFile, 'Parameter internal name', 'binFeedback_valueWhenIn_x0', 'Parameter value', float)
	outputAfter_x1 = find_value_in_csv(configFile, 'Parameter internal name', 'binFeedback_valueWhenIn_x0', 'Parameter value', float)
	return outputAfter_x0, outputAfter_x1
def getTimings_x0x1_and_x1x0(baseFile, removeRanges = []):
	timingsFile = baseFile.replace('.csv', '_bioControllerTimings.csv')
	q = pd.read_csv(timingsFile, delimiter='\t', header=0)
	
	p = q["timing"].to_numpy().astype(float)
	if len(removeRanges) > 0:
		# #remove absolute time
		t = q["startTimes"].to_numpy()
		t -= t[0]
		#sort with decreasing start, so that when we remove the ranges we do not change the indexes of the previous elements of p
		#(if you removed the first range at the start, every subsequent range would be shifted to lower ranges, and it would be a hassle to keep track of that)
		removeRanges.sort(key=lambda x: x[0], reverse=True)
		for start,end in removeRanges:
			start_idx = np.searchsorted(t, start, side='left')
			end_idx = np.searchsorted(t, end, side='right')
			if (end_idx-start_idx) & 1:#odd difference?
				#to keep the sequence 0,1,0,1, intact, let's remove an extra element
				end_idx += 1
			p = np.concatenate((p[:start_idx], p[end_idx:]))
	
	
	# raw data is given in clock cycles, not in seconds
	if min(p) >= 1:
		# remove bug in acquisition
		p[p%10==1] //= 2
		p[p%10==3] //= 4
		p[p%10==6] //= 8
		p/=50.e6
	
	# timings are alternated between x0x1 and x1x0, sometimes the bit that indicates that gets lost (still don't know how), so to be sure if the timings x0x1 are in the even or odd rows, let's see the sum of all the even and odd bits
	if max(q["configuration"]) == 2:
		evenLines = np.sum(q["reachedThreshold"][0::2])
		oddLines = np.sum(q["reachedThreshold"][1::2])
		if evenLines > oddLines:
			x0x1 = np.array(p[0::2])
			x1x0 = np.array(p[1::2])
		else:
			x0x1 = np.array(p[1::2])
			x1x0 = np.array(p[0::2])
		return x0x1, x1x0
	else:
		return np.array(p)
def saveSeparateTimings(baseFile):
	timingsFile = baseFile.replace('.csv', '_bioControllerTimings.csv')
	q = pd.read_csv(timingsFile, delimiter='\t', header=0)
	
	p = q["timing"].to_numpy().astype(float)
	t = q["startTimes"].to_numpy()
	t -= t[0]
	# raw data is given in clock cycles, not in seconds
	if min(p) >= 1:
		# remove bug in acquisition
		p[p%10==1] //= 2
		p[p%10==3] //= 4
		p[p%10==6] //= 8
		
		p/=50.e6
	
	transmissionConfig = getValues(baseFile, 'transmission config')
	if transmissionConfig == 2:
		# timings are alternated between x0x1 and x1x0, sometimes the bit that indicates that gets lost (still don't know how), so to be sure if the timings x0x1 are in the even or odd rows, let's see the sum of all the even and odd bits
		evenLines = np.sum(q["reachedThreshold"][0::2])
		oddLines = np.sum(q["reachedThreshold"][1::2])
		if evenLines > oddLines:
			x0x1 = np.array(p[0::2])
			x1x0 = np.array(p[1::2])
			t_x0x1 = np.array(t[0::2])
			t_x1x0 = np.array(t[1::2])
		else:
			x0x1 = np.array(p[1::2])
			x1x0 = np.array(p[0::2])
			t_x0x1 = np.array(t[1::2])
			t_x1x0 = np.array(t[0::2])
	elif transmissionConfig == 0:
		x0x1 = p
		t_x0x1 = t
		x1x0 = None
		t_x1x0 = None
	# Save the timings to a new CSV file
	output_file_x0x1 = baseFile.replace('.csv', '_x0x1_timings.csv')
	df_x0x1 = pd.DataFrame({'t': t_x0x1, 'first passage time': x0x1})
	df_x0x1.to_csv(output_file_x0x1, index=False)
	if x1x0 is not None:
		output_file_x1x0 = baseFile.replace('.csv', '_x1x0_timings.csv')
		df_x1x0 = pd.DataFrame({'t': t_x1x0, 'first passage time': x1x0})
		df_x1x0.to_csv(output_file_x1x0, index=False)
def saveAllSeparateTimings(folderPath):
	csv_files = getBaseFiles(folderPath)
	for file in csv_files:
		saveSeparateTimings(file)
def saveAllTrajectories(folderPath):
	csv_files = getBaseFiles(folderPath)
	for file in csv_files:
		bioAcqFile = file.replace('.csv', '_bioControllerAcquisition.csv')
		q = pd.read_csv(bioAcqFile, delimiter='\t', header=0)
		new_df = pd.DataFrame()
		new_df['t'] = q['times']
		new_df['x'] = q['x']
		output_file = bioAcqFile.replace('_bioControllerAcquisition.csv', '_trajectory.csv')
		new_df.to_csv(output_file, index=False)
		
def getCFD(values):
	values = np.sort(values)
	return values, np.linspace(0,1,len(values))
def getPFD(values, bins = 100, max = .075):
	values = np.sort(values)
	if bins is not None:
		if max is None:
			max = values[-1]
		max = max / bins
		values = (values // max) * max
	singleValues, valuesCounts = np.unique(values, return_counts=True)
	
	valuesCounts = valuesCounts.astype(float) / len(values)
	# plt.plot(np.cumsum(valuesCounts), singleValues)
	# plt.show()
	y = valuesCounts[:-1] / (singleValues[1:] - singleValues[:-1])
	
	return singleValues,np.concatenate((np.zeros(1),y))
	# new_timings, filtered_signal = filter_asynchronous_signal(y, singleValues[:-1], len(values))
	# return new_timings, filtered_signal
def getTimingProbabilitiesFox_x0x1(baseFile, removeRanges = []):
	q = getTimings_x0x1_and_x1x0(baseFile, removeRanges)
	if isinstance(q, tuple):
		x0x1, x1x0 = q
	else:
		x0x1 = q
		x1x0 = None
	x,y=getPFD(x0x1)
	return x,y
def plotTimingsProbabilities(baseFile, showPlot = True, saveImage = False, removeRanges = []):
	x0, x1 = getValuesOf_x0_and_x1(baseFile)
	q = getTimings_x0x1_and_x1x0(baseFile, removeRanges)
	if isinstance(q, tuple):
		x0x1, x1x0 = q
	else:
		x0x1 = q
		x1x0 = None
	outputAfter_x0, outputAfter_x1 = getValuesOf_outputs(baseFile)
	plt.figure()
	x,y=getPFD(x0x1)
	plt.plot(x,y, label=f"{x0} to {x1}, intensity from {outputAfter_x0}A to {outputAfter_x1}A")
	if x1x0 is not None:
		x,y=getPFD(x1x0)
		plt.plot(x,y, label=f"{x1} to {x0}, intensity from {outputAfter_x1}A to {outputAfter_x0}A")
	plt.legend()
	plt.xlabel('Time (seconds)')
	plt.ylabel('Density')
	output_file = baseFile.replace('.csv', '_FPT_probabilityDensity.png')
	if showPlot:
		def on_close(event):
			plt.savefig(output_file)
			# input("Press Enter after resizing the plot window to save the image...")
		plt.gcf().canvas.mpl_connect('close_event', on_close)
		plt.show()
	elif saveImage:
		plt.savefig(output_file)
		plt.close()
	return x,y

def getAllx0x1(folderPath):  
	csv_files = getBaseFiles(folderPath)
	output = []
	for baseFile in csv_files:
		x0, x1 = getValuesOf_x0_and_x1(baseFile)
		q = getTimings_x0x1_and_x1x0(baseFile, [])
		if isinstance(q, tuple):
			x0x1, _ = q
		else:
			x0x1 = q
		outputAfter_x0, outputAfter_x1 = getValuesOf_outputs(baseFile)
		x,y=getPFD(x0x1)
		output.append((x,y))
	return output
def getAll_cdf_x0x1(folderPath):  
	csv_files = getBaseFiles(folderPath)
	output = []
	for baseFile in csv_files:
		x0, x1 = getValuesOf_x0_and_x1(baseFile)
		q = getTimings_x0x1_and_x1x0(baseFile, [])
		if isinstance(q, tuple):
			x0x1, _ = q
		else:
			x0x1 = q
		
		x,y=getCFD(x0x1)
		output.append((x,y))
	return output
	
def plotAllx0x1(folderPath):    
	csv_files = getBaseFiles(folderPath)
	plt.figure()
	for baseFile in csv_files:
		x0, x1 = getValuesOf_x0_and_x1(baseFile)
		q = getTimings_x0x1_and_x1x0(baseFile, [])
		if isinstance(q, tuple):
			x0x1, _ = q
		else:
			x0x1 = q
		outputAfter_x0, outputAfter_x1 = getValuesOf_outputs(baseFile)
		x,y=getPFD(x0x1)
		plt.plot(x*1e3,y, label=f"{x0} to {x1}, intensity from {outputAfter_x0}A to {outputAfter_x1}A")
	plt.legend()
	plt.xlabel("ms")
	plt.ylabel("PDF")
	plt.show()
	for baseFile in csv_files:
		x0, x1 = getValuesOf_x0_and_x1(baseFile)
		q = getTimings_x0x1_and_x1x0(baseFile, [])
		if isinstance(q, tuple):
			_, x1x0 = q
			outputAfter_x0, outputAfter_x1 = getValuesOf_outputs(baseFile)
			x,y=getPFD(x1x0)
			plt.plot(x*1e3,y, label=f"{x1} to {x0}, intensity from {outputAfter_x1}A to {outputAfter_x0}A")
	plt.legend()
	plt.xlabel("ms")
	plt.ylabel("PDF")
	plt.show()
	
def get_csv_files(folderPath):
	csv_files = [f for f in os.listdir(folderPath) if f.endswith('.csv')]
	return csv_files

def getBaseFiles(folderPath):
	csv_files = get_csv_files(folderPath)
	csv_files = [(folderPath+"/"+f) for f in csv_files if (
		'bioControllerAcquisition' not in f and
		'bioControllerTimings' not in f and
		'conf.csv' not in f and
		'x0x1_timings.csv' not in f and
		'x1x0_timings.csv' not in f and
		'trajectory.csv' not in f)]
	return csv_files

def saveAllProbabilities(folderPath, showPlot = False):
	csv_files = getBaseFiles(folderPath)
	for file in csv_files:
		plotTimingsProbabilities(file, saveImage=True, showPlot = showPlot)

def getAllInfos(folderPath):
	csv_files = getBaseFiles(folderPath)
	for file in csv_files:
		print(file+str(getValues(file, ['x0', 'transmission config', 'output after x1', 'pre-average time'])))

def changeFileNames(folderPath, nameReplacements):
	#nameReplacements of type [[oldName, newName], ...]
	csv_files = get_csv_files(folderPath)
	for file in csv_files:
		for oldName, newName in nameReplacements:
			if oldName in file:
				os.rename(folderPath+'/'+file, folderPath+'/'+file.replace(oldName, newName))
from bioTweezerController import bioTweezerController
from scipy.signal import decimate
def getAllStiffnesses(folderPath):
	csv_files = getBaseFiles(folderPath)
	for file in csv_files:
		#'''
		positionFile = file.replace('.csv', '_bioControllerAcquisition.csv')
		q = pd.read_csv(positionFile, delimiter='\t', header=0)
		x = q['x'].to_numpy()
		x_2 = q['x^2'].to_numpy()
		x = bioTweezerController.dimLink.convert(x, "FPGA_floatValue", "bead_position")
		x_2 = bioTweezerController.dimLink.convert(x_2, "FPGA_floatValue", "bead_positionSquare")
		'''
		positionFile = file
		q = pd.read_csv(positionFile, delimiter='\t', header=0)
		x = q['AI3'].to_numpy() / q['AI2'].to_numpy()
		x_2 = None
		x = bioTweezerController.dimLink.convert(x, "FPGA_floatValue", "bead_position")
		#'''
		stiffness = bioTweezerController.laserStiffnessFromPositionSignal(x, x_2, 300)
		print(f"{file}: {stiffness}")
def getBaseFileNameFromIdx(folderPath, idx):
	csv_files = getBaseFiles(folderPath)
	for file in csv_files:
		if f"{idx:03}" in file:
			return file
	raise Exception(f"idx {idx} not found")


if __name__ == "__main__":
	# folder_path = 'D:/lastline/bioTweezers/20_2_5'
	# # saveAllProbabilities(folder_path, showPlot = True)
	# # getAllInfos(folder_path)
	# saveAllSeparateTimings(folder_path)
	# saveAllTrajectories(folder_path)
	

	# getAllStiffnesses(folder_path)

	# folder_path = 'D:/elaborated data'
	# changeFileNames(folder_path,[
	# ['constantIntensity_004', 									'004_bead 1_setpoint 0.015_constant stiffness 0.15_'],
	# ['constantIntensity_005', 									'005_bead 1_setpoint 0.01_constant stiffness 0.15_ offset around -0.01_005'],
	# ['constantIntensity_disruptedByGerm_003', 					'003_bead 1_setpoint 0.025_constant stiffness 0.15_ disruption at 63s_higherSampling_003'],
	# ['constantStiffness_bothTransitions_007', 					'007_bead 1_setpoint 0.015_constant stiffness 0.15_'],
	# ['constantStiffness_bothTransitions_008', 					'008_bead 1_setpoint -0.015_constant stiffness 0.15_'],
	# ['newBead_constantStiffness_009', 							'009_bead 2_setpoint 0.015_constant stiffness 0.15_'],
	# ['newBead_constantStiffness_012', 							'012_bead 2_setpoint 0.01_constant stiffness 0.15_'],
	# ['newBead_constantStiffness_013', 							'013_bead 2_setpoint 0.005_constant stiffness 0.15_'],
	# ['newBead_constantStiffness_014', 							'014_bead 2_setpoint 0.005_constant stiffness 0.15_'],
	# ['newBead_constantStiffness_015', 							'015_bead 2_setpoint 0.02_constant stiffness 0.15_'],
	# ['newBead_constantStiffness_interruptedByBead_011', 			'011_bead 2_setpoint 0.01_constant stiffness 0.15_ disruption at 40s_011'],
	# ['newBead_constantStiffness_offsetStillShiftingALot_017', 	'017_bead 2_setpoint -0.015_constant stiffness 0.15_ lots of drifts_017'],
	# ['newBead_constantStiffness_offsetStillShiftingALot_018', 	'018_bead 2_setpoint -0.015_constant stiffness 0.15_ offset drifts to 0.01_018'],
	# ['newBead_constantStiffness_setpointShifted_010', 			'010_bead 2_setpoint 0.01_constant stiffness 0.15_ offset drifts to 0.02_010'],
	# ['newBead_constantStiffness_setpointShiftsTooMuch_016', 		'016_bead 2_setpoint -0.015_constant stiffness 0.15_'],
	# ['test_001', 													'001_bead 1_setpoint 0.025_constant stiffness 0.15_'],
	# ['test_002', 													'002_bead 1_setpoint 0.025_constant stiffness 0.15_'],
	# ['constantStiffness_006', 									'006_bead 1_setpoint 0.015_feedback stiffness 0.15_ 0.2_offset around 0.07_006'],
	# ['newBead_feedbackStiffness_019', 							'019_bead 2_setpoint 0.02_feedback stiffness 0.15_ 0.3_offset around 0.01_019'],

	# 			])

	folder_path = 'D:/elaborated data - Copia'
	plotAllx0x1(folder_path)
	pass