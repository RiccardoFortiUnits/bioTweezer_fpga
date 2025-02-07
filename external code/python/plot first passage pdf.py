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
        p/=50.e6
    
    # timings are alternated between x0x1 and x1x0, sometimes the bit that indicates that gets lost (still don't know how), so to be sure if the timings x0x1 are in the even or odd rows, let's see the sum of all the even and odd bits
    evenLines = np.sum(q["reachedThreshold"][0::2])
    oddLines = np.sum(q["reachedThreshold"][1::2])
    if evenLines > oddLines:
        x0x1 = np.array(p[0::2])
        x1x0 = np.array(p[1::2])
    else:
        x0x1 = np.array(p[1::2])
        x1x0 = np.array(p[0::2])
    return x0x1, x1x0

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

def plotTimingsProbabilities(baseFile, showPlot = True, saveImage = False, removeRanges = []):
    x0, x1 = getValuesOf_x0_and_x1(baseFile)
    x0x1, x1x0 = getTimings_x0x1_and_x1x0(baseFile, removeRanges)
    outputAfter_x0, outputAfter_x1 = getValuesOf_outputs(baseFile)
    plt.figure()
    x,y=getPFD(x0x1)
    plt.plot(x,y, label=f"{x0} to {x1}, intensity from {outputAfter_x0}A to {outputAfter_x1}A")
    x,y=getPFD(x1x0)
    plt.plot(x,y, label=f"{x1} to {x0}, intensity from {outputAfter_x1}A to {outputAfter_x0}A")
    plt.legend()
    plt.xlabel('Time (seconds)')
    plt.ylabel('Density')
    if showPlot:
        plt.show()
    if saveImage:
        output_file = baseFile.replace('.csv', '_FPT_probabilityDensity.png')
        plt.savefig(output_file)
    plt.close()
    
def get_csv_files(folderPath):
    csv_files = [f for f in os.listdir(folderPath) if f.endswith('.csv')]
    return csv_files

def getBaseFiles(folderPath):
    csv_files = get_csv_files(folderPath)
    csv_files = [(folderPath+"/"+f) for f in csv_files if (
        'bioControllerAcquisition' not in f and
        'bioControllerTimings' not in f and
        'conf.csv' not in f)]
    return csv_files

def saveAllProbabilities(folderPath):
    csv_files = getBaseFiles(folderPath)
    for file in csv_files:
        plotTimingsProbabilities(file, saveImage=True)
# folder_path = 'C:/Users/lastline/Documents/bioTweezers/6_2_25'
# saveAllProbabilities(folder_path)
baseFile = 'C:/Users/lastline/Documents/bioTweezers/6_2_25/biglia2um_activeFeedback_higherSampling_interruptedByGerm_009.csv'
plotTimingsProbabilities(baseFile, removeRanges=[])
