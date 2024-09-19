
# import numpy as np
# from dimensionLinker import dimensionLinker


# dimLink = dimensionLinker()
# #basic electrical dimensions
# dimLink.addDimension("voltage", "V")
# dimLink.addDimension("current", "A")
# dimLink.addDimension("resistance", "Ω")
# dimLink.addMultiConnection(["voltage", "current", "resistance"], dimensionLinker.monomialFunctions(["voltage"], ["current", "resistance"]))

# dimLink.addDimension("power", "W")
# dimLink.addMultiConnection(["voltage", "current", "power"], dimensionLinker.monomialFunctions(["voltage","current"], ["power"]))
# dimLink.addDimension("time", "s")
# dimLink.addDimension("frequency", "Hz")
# dimLink.addConnection("time", "frequency", lambda x : 1/x, lambda x : 1/x)

# dimLink.addDimension("voltage_rms", "Vrms")
# dimLink.addDimension("output_resistance", "R", defaultValue=50)
# dimLink.addDimension("input_resistance", "R", defaultValue=50)
# dimLink.addDimension("output_impedance", "R")
# dimLink.addDimension("input_impedance", "R")

# #partition
# dimLink.addDimension("voltage_partitioned", "V")
# dimLink.addMultiConnection(["voltage_partitioned", "voltage", "output_resistance", "input_resistance"], [
#                            lambda **x : x["voltage"]             * x["input_resistance"]    / (x["output_resistance"] + x["input_resistance"]), #V_out = V_in * R2/(R1+R2)
#                            lambda **x : x["voltage_partitioned"] / x["input_resistance"]    * (x["output_resistance"] + x["input_resistance"]), #V_out = V_in * (R1+R2) / R2
#                            lambda **x : x["input_resistance"]    / x["voltage_partitioned"] * (x["voltage"]           - x["voltage_partitioned"]), #R1 = ...
#                            lambda **x : x["output_resistance"]   * x["voltage_partitioned"] / (x["voltage"]           - x["voltage_partitioned"])  #R2 = ...
#                          ])
# print(dimLink.convert([np.array([3,2,1,0,-1,-2,-3]), 50], ["voltage", "resistance"], "power"))

# dimLink.addDimension("voltage_signal", "V")
# dimLink.addDimension("sampling_time", "s")
# dimLink.addConnection("voltage_signal","voltage",lambda x:np.mean(x))


import numpy as np
import matplotlib.pyplot as plt

# Sample rate and signal duration
fs = 1000  # Sampling frequency in Hz
T = 1.0    # Duration in seconds
N = int(T * fs)  # Number of samples

# Generate a sample signal: a 50 Hz sine wave plus noise
t = np.linspace(0, T, N, endpoint=False)
x = 2*np.sin(2 * np.pi * 50 * t) + 0.5 * np.random.randn(N)

# Compute the FFT
X = np.fft.fft(x)
frequencies = np.fft.fftfreq(N, 1/fs)

# Compute the PSD
psd = (1/(fs*N)) * np.abs(X * 2)**2
psd = psd[:N//2]  # Keep only the positive frequencies
frequencies = frequencies[:N//2]

# Compute the ASD
asd = (1/N) * np.abs(X * 2)
asd = asd[:N//2]  # Keep only the positive frequencies


# Plot the ASD
plt.plot(frequencies, asd)
plt.plot(frequencies, np.sqrt(psd))
plt.xlabel('Frequency (Hz)')
plt.ylabel('ASD (V/√Hz)')
plt.title('Amplitude Spectral Density')
plt.grid(True)
plt.show()
