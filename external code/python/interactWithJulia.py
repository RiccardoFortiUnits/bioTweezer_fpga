import ctypes
import sys
import os

# def is_admin():
#     try:
#         return ctypes.windll.shell32.IsUserAnAdmin()
#     except:
#         return False

# if is_admin():
#     # Your code that requires admin privileges goes here
#     print("we can make it!")
#     import julia
#     julia.install()
#     j = julia.Julia()
#     x = j.include("test.jl")
#     print("result", x)
#     input("Press Enter to continue...")
# else:
#     # Re-run the script with admin privileges
#     print("restarting")
#     ctypes.windll.shell32.ShellExecuteW(
#         None, "runas", sys.executable, " ".join(sys.argv), None, 1
#     )



import os
# os.environ["JULIA_BINDIR"] = "D:/lastline/Julia-1.11.3/bin"


# import julia
# # julia.install()
# j = julia.Julia()
# x = j.include("test.jl")
# print("result", x)

import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
# p=os.system('D:/lastline/Julia-1.11.3/bin/julia.exe "C:/Git/bioTweezer_fpga/external code/python/test.jl" a b c')
def getFPTFromJuliaScript(maxTime_s, nOfPoints, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):
    kBoltzman = 1.3806504e-23
    A = drag_Ns_m/(2*kBoltzman*T_K)
    omega = stiffness_N_m/drag_Ns_m
    #execute the julia script. It will create a csv file that we can read
    os.system(f'D:/lastline/Julia-1.11.3/bin/julia.exe "C:/Git/bioTweezer_fpga/external code/julia/Scripts_FPT/script_FPT_dir.jl" {maxTime_s} {nOfPoints} {A} {x0_m} Constant {omega}')
    #read the csv file
    df = pd.read_csv("C:/Git/bioTweezer_fpga/external code/python/result.csv", delimiter=',', header=0)
    data = df.to_numpy()
    times = data[:,0]
    fpts = data[:,1]
    return times, fpts

if __name__ == "__main__":
    for x0 in np.linspace(0.5e-9,2e-9,10):
        t,x = getFPTFromJuliaScript(0.02, 5000, x0, 13e-6, 28.3e-6)
        plt.plot(t,x)
    plt.show()