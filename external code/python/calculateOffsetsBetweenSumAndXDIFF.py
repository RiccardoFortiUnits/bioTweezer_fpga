# -*- coding: utf-8 -*-
"""
Created on Mon Sep  2 11:49:51 2024

@author: lastline
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import bisect
from scipy.optimize import fsolve, least_squares

val = []
def getPointFromShownGraph(x,y, nOfPoints = 1):
    global val
    # Plot the signal
    fig, ax = plt.subplots()
    ax.plot(x, y, label='Signal')
    ax.set_title('Click on the plot to select a point')
    ax.legend()
    val = []
    # Function to be called when a point is clicked
    def on_click(event):
        global val
        if event.inaxes:
            val.append(event.xdata)
            print(f'Selected point: x={event.xdata}, y={event.ydata}, val={np.interp(event.xdata, x, y)}')
            if(len(val) >= nOfPoints):
                # Disconnect the event handler after the first click
                fig.canvas.mpl_disconnect(cid)
                plt.close(fig)
    # Connect the click event to the on_click function
    cid = fig.canvas.mpl_connect('button_press_event', on_click)
    plt.show()
    
    while len(val) < nOfPoints:
        plt.pause(0.1)
    return val
    
nOfSteps = 6

offsets = []
for i in [1,2,3,4,5]:
    path = f"C:/Users/lastline/Documents/bioTweezers/2_9_24/power_ramp_bead_trapped_00{i}.csv"
    with open(path, 'r') as file:
        lines = file.readlines()
        num_columns = len(lines[1].strip().split('\t'))
    df = pd.read_csv(path, delimiter='\t', header=0, usecols=range(num_columns))
    
    x = np.array(df["AI3"])#XDIFF, YDIFF would be AI4
    SUM = np.array(df["AI2"])
    t = np.array(df["Time (s)"])#np.linspace(0,tTot,len(x))
    
    rampEdges = getPointFromShownGraph(t, list(df["AI7"]), nOfPoints=nOfSteps*2)
    rampStarts = rampEdges[0::2]
    rampEnds = rampEdges[1::2]
    
    averages = [0] * nOfSteps
    sums = [0] * nOfSteps
    nAverages = [0] * nOfSteps
    for i in range(nOfSteps):    
        rampStart = bisect.bisect_left(t, rampStarts[i])
        rampEnd = bisect.bisect_left(t, rampEnds[i])
        averages[i] = np.mean(x[rampStart:rampEnd])
        sums[i] = np.mean(SUM[rampStart:rampEnd])
        nAverages[i] = np.mean(x[rampStart:rampEnd] / SUM[rampStart:rampEnd])
    
    # plt.figure()
    # plt.plot(averages)
    # plt.plot(sums)
    # plt.plot(nAverages)
    # plt.plot(np.array(averages) / np.array(sums))
    
    
    def f(o):
        err = (np.array(averages) - o[0]) - (np.array(sums) - o[1]) * o[2]
        return err
        # return [np.sum(err**2), 0,0]
    solution = least_squares(f, np.array([0,0,0]))
    offsets.append(solution.x)
    
print(offsets)











