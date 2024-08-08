
import pandas as pd
import matplotlib.pyplot as plt
import os
import tkinter
from tkinter import filedialog
import numpy as np
from matplotlib.animation import FuncAnimation

def average_filter(signal, window_size):
    # Ensure the window size is odd
    if window_size % 2 == 0:
        raise ValueError("Window size must be odd")
    
    # Apply the average filter without padding
    filtered_signal = np.convolve(signal, np.ones(window_size)/window_size, mode='valid')
    
    return filtered_signal

X = list()
Y = list()
folder_path = None# ['C:/Users/lastline/Downloads/canale_blue_risposta_su_e_x_div_sum_001.csv']
if folder_path is None:
    root = tkinter.Tk()
    root.withdraw() # prevents an empty tkinter window from appearing
    root.grab_set()  # Make the root window modal
    folder_path = filedialog.askopenfilenames(filetypes=[("csv files", "*.*")])
    # Release the grab to allow interaction with other windows
    root.grab_release()
if len(folder_path) < 1:
    print("procedure stopped")
else:    
    for path in folder_path:
        extension = os.path.splitext(path)[-1]
        name = os.path.basename(path)
        # Read the .cdv file to get the number of columns from the second line
        with open(path, 'r') as file:
            lines = file.readlines()
            num_columns = len(lines[1].strip().split('\t'))
    
        # Load the .cdv file into a DataFrame, specifying the number of columns
        df = pd.read_csv(path, delimiter='\t', header=0, usecols=range(num_columns))
        df.columns = df.columns.str.strip()
        df.drop(['AO1', 'AO2'], axis=1, inplace=True)
        df.columns = ["time", "piezo displacement", "SUM", "XDIFF", "YDIFF", "control signal"]
        df["x"] = df["XDIFF"] / df["SUM"]
        df["y"] = df["YDIFF"] / df["SUM"]
        df["piezo displacement"] = df["piezo displacement"] - np.mean(df["piezo displacement"])
        # Set the first column as the index (times)
        df.set_index(df.columns[0], inplace=True)
        plt.figure()
        # Plot all the curves with custom labels
        plt.plot(df, label = df.columns)
        # for column, label in zip(df.columns, ["piezo displacement", "SUM", "XDIFF", "YDIFF", "control signal"]):
        #     plt.plot(df.index, df[column], label=label)
        
        # Add labels and title
        plt.xlabel('Time (s)')
        plt.ylabel('Values (V)')
        plt.title(name)
        plt.legend()
        
        # Show the plot
        plt.show()

        # Create a 3D plot
        do3D_plot = True
        if do3D_plot:
            fig = plt.figure()
            ax = fig.add_subplot(111, projection='3d')
            lim = len(df["x"])# 25000
            average = 101
            xmult = 0
            x,y,z = list(df["x"]+xmult*df["piezo displacement"]), list(df["y"]), list(df["SUM"])
            x = average_filter(x[:lim],average)
            y = average_filter(y[:lim],average)
            z = average_filter(z[:lim],average)
            ax.plot(x, y, z, label='3D Curve')
            point, = ax.plot([], [], [], 'ro')  # Point to animate
            
            frames = 500
            multiplier = len(z) // frames
            def update(num):
                num *= multiplier
                point.set_data(x[num], y[num])
                point.set_3d_properties(z[num])
                return point,
    
            ani = FuncAnimation(fig, update, frames=frames, interval=20, blit=True, repeat = True)
            
            ax.set_xlabel('X')
            ax.set_ylabel('Y')
            ax.set_zlabel('SUM')
            ax.legend()

# Show the plot
plt.show()

        
