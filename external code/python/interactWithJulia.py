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
    inputList = [x0_m, stiffness_N_m, drag_Ns_m, T_K]
    maxLength = max(map(lambda l: len(l) if isinstance(l, (list, np.ndarray)) else 1, inputList))
    for i in range(len(inputList)):
        if isinstance(inputList[i], list):
            inputList[i] = np.array(inputList[i])
        elif not isinstance(inputList[i], np.ndarray):
            inputList[i] = np.repeat(inputList[i], maxLength)
    (x0_m, stiffness_N_m, drag_Ns_m, T_K) = tuple(inputList)

    kBoltzman = 1.3806504e-23
    A = drag_Ns_m/(2*kBoltzman*T_K)
    omega = stiffness_N_m/drag_Ns_m
    #execute the julia script. It will create a csv file that we can read
    A_str = ",".join(map(str, A))
    x0_m_str = ",".join(map(str, x0_m))
    omega_str = ",".join(map(str, omega))
    command = f'D:/lastline/Julia-1.11.3/bin/julia.exe "C:/Git/bioTweezer_fpga/external code/julia/Scripts_FPT/script_FPT_dir.jl" {maxTime_s} {nOfPoints} {A_str} {x0_m_str} Constant {omega_str}'
    print(command)
    os.system(command)
    #read the csv file
    df = pd.read_csv("C:/Git/bioTweezer_fpga/external code/python/result.csv", delimiter=',', header=0)
    data = df.to_numpy()
    times = data[:,0]
    pdf = data[:,1:]
    pdf[0,:] = 0
    return times, pdf

if __name__ == "__main__":
    x0=np.linspace(0.5e-9,2e-9,4)
    viscosity = np.linspace(28.3e-9, 1.3e-7, 4)
    X0,S = np.meshgrid(x0, viscosity)
    x0 = X0.flatten()
    viscosity = S.flatten()
    t,x = getFPTFromJuliaScript(0.2, 5000, x0,13e-6, viscosity)
    plt.plot(t,x, label = [i for i in range(len(x[0]))], alpha = 0.5)
    plt.legend()
    plt.show()