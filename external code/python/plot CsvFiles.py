
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
sx=.5e-3/1e-9
sz= 1e-3/1e-9
folder_path = None# ["C:/Users/lastline/Documents/bioTweezers/8_8_24/biglia3um_vs_10um_015.csv"]#None# ['C:/Users/lastline/Downloads/canale_blue_risposta_su_e_x_div_sum_001.csv']
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
        try:
            df.drop(['AO1', 'AO2'], axis=1, inplace=True)
        except:
            df.drop(['AI5'], axis=1, inplace=True)
        df.columns = ["time", "piezo displacement", "SUM", "XDIFF", "YDIFF", "feedback signal", "current signal"]
        df["piezo displacement"] = df["piezo displacement"] - np.mean(df["piezo displacement"])
        
        
        df["x"] = 1e9*(df["XDIFF"]) / df["SUM"] / sx
        df["y"] = 1e9*(df["YDIFF"]) / df["SUM"] / sx
        df["z"] = 1e9*(df["SUM"] - np.mean(df["SUM"][:100])) / sz
        df["ray xz"] = np.sqrt(df["x"]**2 + df["z"]**2)
        df["feedback signal"] *= 1e9*2e-6*75/25
        # Set the first column as the index (times)
        # df.drop(["piezo displacement", "SUM", "XDIFF", "YDIFF", "current signal"], axis=1, inplace=True)
        
        
        df.set_index(df.columns[0], inplace=True)
        plt.figure()
        # Plot all the curves with custom labels
        plt.plot(df, label = df.columns)
        # for column, label in zip(df.columns, ["piezo displacement", "SUM", "XDIFF", "YDIFF", "feedback signal"]):
        #     plt.plot(df.index, df[column], label=label)
        
        # Add labels and title
        plt.xlabel('Time (s)')
        plt.ylabel('Values (nm)')
        plt.title(name)
        plt.legend()
        
        # Show the plot
        plt.show()

        # Create a 3D plot
        do3D_plot = False
        if do3D_plot:
            fig = plt.figure()
            ax = fig.add_subplot(111, projection='3d')
            lim = len(df["x"])# 25000
            average = 101
            xmult = 0
            x,y,z = list(df["x"]), list(df["y"]), list(df["SUM"])
            x = average_filter(x[:lim],average)
            y = average_filter(y[:lim],average)
            z = average_filter(z[:lim],average)
            xm,ym,zm = x[0],y[0],z[0]
            o = average_filter(list(df["feedback signal"])[:lim],average)
            ax.plot(x, y, z, label='3D Curve')
            point, = ax.plot([], [], [], 'ro')  # Point to animate
            # vector = ax.quiver([], [], [], [], [], [], color='g')
            
            frames = 50
            time = 8.7
            multiplier = len(z) // frames
            def update(num):
                num *= multiplier
                point.set_data(x[num], y[num])
                point.set_3d_properties(z[num])
                # X,Y,Z = x[num]-xm, y[num]-ym, z[num]-zm
                # [xn,yn,zn] = np.array([X,Y,Z]) / np.sqrt(X**2+Y**2+Z**2) * o[num]
                # global vector
                # vector.remove()
                # vector = ax.quiver(xm,ym,zm, xn,yn,zn, color='g')
                return point,
    
            ani = FuncAnimation(fig, update, frames=frames, interval=(time*1e3)//frames, blit=True, repeat = True, repeat_delay = 2e3)
            
            ax.set_xlabel('X')
            ax.set_ylabel('Y')
            ax.set_zlabel('SUM')
            ax.legend()

# Show the plot
plt.show()

        
