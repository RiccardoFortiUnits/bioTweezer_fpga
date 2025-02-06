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

def filter_asynchronous_signal(signal, timings, new_sampling_rate, window_size=20):
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

def getTimings_x0x1_and_x1x0(baseFile):
    timingsFile = baseFile.replace('.csv', '_bioControllerTimings.csv')
    q = pd.read_csv(timingsFile, delimiter='\t', header=0)
    
    # #remove absolute time
    # q["startTimes"]-=q["startTimes"][0]
    
    # raw data is given in clock cycles, not in seconds
    if min(q["timing"]) >= 1:
        q["timing"]/=50e6
    
    # timings are alternated between x0x1 and x1x0, sometimes the bit that indicates that gets lost (still don't know how), so to be sure if the timings x0x1 are in the even or odd rows, let's see the sum of all the even and odd bits
    evenLines = np.sum(q["reachedThreshold"][0::2])
    oddLines = np.sum(q["reachedThreshold"][1::2])
    if evenLines > oddLines:
        x0x1 = np.array(q["timing"][0::2])
        x1x0 = np.array(q["timing"][1::2])
    else:
        x0x1 = np.array(q["timing"][1::2])
        x1x0 = np.array(q["timing"][0::2])
    return x0x1, x1x0

def getPFD(values):
    values = np.sort(values)
    singleValues, valuesCounts = np.unique(values, return_counts=True)
    valuesCounts = valuesCounts.astype(float) / len(values)
    y = valuesCounts[:-1] / (singleValues[1:] - singleValues[:-1])
    
    return singleValues[:-1],y
    # new_timings, filtered_signal = filter_asynchronous_signal(y, singleValues[:-1], 1000)
    # return new_timings, filtered_signal

def plotTimingsProbabilities(baseFile):
    x0, x1 = getValuesOf_x0_and_x1(baseFile)
    x0x1, x1x0 = getTimings_x0x1_and_x1x0(baseFile)
    plt.figure()
    x,y=getPFD(x0x1)
    plt.plot(x,y, label=f"{x0} to {x1}")
    x,y=getPFD(x1x0)
    plt.plot(x,y, label=f"{x1} to {x0}")
    plt.legend()
    plt.xlabel('Time (seconds)')
    plt.ylabel('Density')
    plt.show()
    
baseFile = 'C:/Users/lastline/Documents/bioTweezers/28_1_25/longAcquisition_010.csv'
plotTimingsProbabilities(baseFile)
