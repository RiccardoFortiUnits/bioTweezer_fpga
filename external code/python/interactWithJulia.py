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
'''

stiffness: pN/um = 1e-6 N/m
drag: pN*ms/um = 1e-9 N*s/m

'''



def FTP_PDF(t, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):	
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
	O = np.outer(omega, t)
	tau = (1 - np.exp(-2 * O)) / (2 * omega[:, None])
	P = np.sqrt(A[:, None]) * np.abs(x0_m[:, None]) * np.exp(-O) / np.sqrt(2 * np.pi * tau**3) * np.exp(-A[:, None] * x0_m[:, None]**2 * np.exp(-2 * O) / (2 * tau))
	P[:,t==0] = 0
	return P
def FTP_CDF(t, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):	
	P = FTP_PDF(t, x0_m, stiffness_N_m, drag_Ns_m, T_K)
	dt = np.concatenate(([t[0]],np.diff(t)))
	C = np.cumsum(P * dt[None,:], axis = 1)
	C -= (C[:,0])[:,None]
	C /= (C[:,-1])[:,None]
	return C
def FTP_PDF_normalized(t, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):
	P = FTP_PDF(t, x0_m, stiffness_N_m, drag_Ns_m, T_K)
	dt = np.concatenate(([t[0]],np.diff(t)))
	sum = np.sum(P * dt[None,:], axis = 1)
	P /= sum[:,None]
	return P
# def FTP_PDF(t, A, x0, w0):
# 	O = np.outer(w0, t)
# 	tau = (1 - np.exp(-2 * O)) / (2 * w0[:, None])
# 	P = np.sqrt(A[:, None]) * np.abs(x0[:, None]) * np.exp(-O) / np.sqrt(2 * np.pi * tau**3) * np.exp(-A[:, None] * x0[:, None]**2 * np.exp(-2 * O) / (2 * tau))
# 	P[t[None, :]==0] = 0
# 	return P
# def FTP_waywayWayBetterThanJulia(maxTime, nOfPoints, A, x0, w0):
# 	if nOfPoints is not None:
# 		t = np.linspace(0, maxTime, nOfPoints)
				
# 		P = FTP_PDF(t, A, x0, w0)
		
# 		# P = np.concatenate((np.zeros_like(P[:, 0])[:,None],P), axis=1)
# 		# t = np.concatenate(([0], t))
# 		return t, P.T
	
# 	P = FTP_PDF(maxTime, A, x0, w0)
# 	return maxTime, P.T

def getFPTFromJuliaScript(maxTime_s, nOfPoints, x0_m, stiffness_N_m, drag_Ns_m, T_K = 300):
	inputList = [x0_m, stiffness_N_m, drag_Ns_m, T_K]
	maxLength = max(map(lambda l: len(l) if isinstance(l, (list, np.ndarray)) else 1, inputList))
	for i in range(len(inputList)):
		if isinstance(inputList[i], list):
			inputList[i] = np.array(inputList[i])
		elif not isinstance(inputList[i], np.ndarray):
			inputList[i] = np.repeat(inputList[i], maxLength)
	(x0_m, stiffness_N_m, drag_Ns_m, T_K) = tuple(inputList)

	#'''
	kBoltzman = 1.3806504e-23
	A = drag_Ns_m/(2*kBoltzman*T_K)
	omega = stiffness_N_m/drag_Ns_m
	#execute the julia script. It will create a csv file that we can read
	A_str = ",".join(map(str, A))
	x0_m_str = ",".join(map(str, x0_m))
	omega_str = ",".join(map(str, omega))
	# command = f'D:/lastline/Julia-1.11.3/bin/julia.exe "C:/Git/bioTweezer_fpga/external code/julia/Scripts_FPT/script_FPT_dir.jl" {maxTime_s} {nOfPoints} {A_str} {x0_m_str} Constant {omega_str}'
	'''
	maxTime_ms = maxTime_s*1e3
	kBoltzman = 1.3e-2
	drag_pNms_nM = drag_Ns_m*1e12*1e3/1e9
	stiffness_pN_nm = stiffness_N_m*1e12/1e9
	x0_nm = x0_m*1e9
	A = drag_pNms_nM / (2*kBoltzman*T_K)
	omega=stiffness_pN_nm/drag_pNms_nM
	#execute the julia script. It will create a csv file that we can read
	A_str = ",".join(map(str, A))
	x0_m_str = ",".join(map(str, x0_nm))
	omega_str = ",".join(map(str, omega))
	# command = f'D:/lastline/Julia-1.11.3/bin/julia.exe "C:/Git/bioTweezer_fpga/external code/julia/Scripts_FPT/script_FPT_dir.jl" {maxTime_ms} {nOfPoints} {A_str} {x0_m_str} Constant {omega_str}'
	#'''
	# print(command)
	# os.system(command)
	##read the csv file
	# df = pd.read_csv("C:/Git/bioTweezer_fpga/external code/python/result.csv", delimiter=',', header=0)
	# data = df.to_numpy()
	# times = data[:,0]
	# pdf = data[:,1:]
	# pdf[0,:] = 0
	# return times, pdf
	t,fpt= FTP_waywayWayBetterThanJulia(maxTime_s,nOfPoints,A,x0_m,omega)
	out_t, out_fpt = t,fpt
	#let's normalize the result. But we can't just divide for the sum of all fpt, because 
	# maxTime_s could be close to the peak, and thus sum(fpt(maxTime_s)) != sum(fpt(infinity))
	# while any(fpt[-1,:]>1e-3):
	# 	#let's increase the range until we are sure we're far from the peak
	# 	maxTime_s *= 2
	# 	nOfPoints *= 2
	# 	t,fpt = FTP_waywayWayBetterThanJulia(maxTime_s,nOfPoints,A,x0_m,omega)
	# out_fpt *= nOfPoints/np.sum(fpt, axis=0)
	return out_t, out_fpt

import plotFirstPassagePdf
if __name__ == "__main__":
	#2.76665116e-03 -1.63524817e-05  1.21543669e-02
	x0=10.**np.arange(-10,-7,1)
	stiffness = 10.**np.arange(-9,-3,1)#[10e-9,10e-8,10e-7,10e-6]#np.linspace(.1e-9, 10e-6, 3)
	viscosity = 2.80641696e-08#10**np.linspace(-5, -4,5)
	X0,S,V = np.meshgrid(x0, stiffness, viscosity)
	x0 = X0.flatten()
	stiffness = S.flatten()
	viscosity = V.flatten()
	maxT = .05
	t=np.linspace(0, maxT,50000)
	x = FTP_CDF(t, x0, stiffness, viscosity)
	# x=np.cumsum(x,axis=0)
	# x/=x[-1,:]
	
	for i in range(len(x)):
		plt.plot(t,x[i], label = f"{i}", alpha=0.5)
	# plt.legend()
	# folder_path = 'D:/elaborated data - Copia'
	# p=plotFirstPassagePdf.getAllx0x1(folder_path)
	# for (x,y) in p:
	# 	plt.plot(x,y, color = 'blue')
	plt.show()