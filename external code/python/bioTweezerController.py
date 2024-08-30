# -*- coding: utf-8 -*-
"""
Created on Thu Aug  1 11:12:16 2024

@author: lastline
"""

# -*- coding: utf-8 -*-
"""
Created on Fri Jul 26 11:09:04 2024

@author: lastline
"""
import numpy as np
import socket
import time as t
from dimensionLinker import dimensionLinker
import matplotlib.pyplot as plt

def setupReception(ip, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((ip, port))
    socket.setdefaulttimeout(1)
    return sock

def transmitCommand(sock, ip, port, command, waitForResponse = False, printTransmission = False):
    if(isinstance(command, str)):
        command = command.encode()
    sock.sendto(command, (ip, port))    
    if(printTransmission):
        print("sent to ", ip, ": ", command)
    if(waitForResponse):
        return receive(sock, port)        

def receive(sock, port, printReception = False):
    received, address = sock.recvfrom(port)
    if(printReception):
        print("Received from", address, ":", received)
    return received
    
class fpgaRegister:
    def __init__(self, dimLinker, dimension, preferredConversionDimension, command = None):
        self.dimLinker = dimLinker
        self.dimension = dimension
        self.preferredConversionDimension = preferredConversionDimension
        self.bitSize = dimLinker.nodes[dimension]["bitSize"]
        try:
            self.isSigned = dimLinker.nodes[dimension]["isSigned"]
        except:
            self.isSigned = True
                
        if command is None:
            self.command = [-1] * ((self.bitSize + 15) // 16)
        else: 
            self.command = command
    
    def convertValue(self, value, startDimension = None):
        if(startDimension is None):
            startDimension = self.preferredConversionDimension
        value = self.dimLinker.convert(value, startDimension, self.dimension)
        return int(value), startDimension
    
    def floatToFixedPoint(self, value, startDimension = None):
        val, startDimension = self.convertValue(value, startDimension)
        maxVal = (1 << (self.bitSize-1)) - 1 if self.isSigned else (1 << self.bitSize) - 1
        minVal = -(1 << (self.bitSize-1)) if self.isSigned else 0
        if(val > maxVal):
            maxVal_unConverted = self.dimLinker.convert(maxVal, self.dimension, startDimension)
            print(f"warning: value too high! using Max value = {maxVal_unConverted}" )
            val = int(maxVal)
        elif(val < minVal):
            minVal_unConverted = self.dimLinker.convert(minVal, self.dimension, startDimension)
            print(f"warning: value too low! using Min value = {minVal_unConverted}" )
            val = int(minVal_unConverted)
            
        if(len(self.command) > 1):
            return [val >> 16, val & 0xffff]
        return [val]
    
    def fixedPointToFloat(self, intValue, toDimension = None):
        if(len(self.command) > 1):
            intValue = intValue[0] << 16 + intValue[1]
        if(toDimension is None):
            toDimension = self.preferredConversionDimension
        return self.dimLinker.convert(intValue, self.dimension, toDimension)

class segmented_function:
    def __init__(self, x,y):
        self.x = x
        self.y = y
    def valueAt(self, t):
        if t <= self.x[0]:
            return self.y[0]
        elif t >= self.x[-1]:
            return self.y[-1]
        
        for i in range(len(self.x) - 1):
            if self.x[i] <= t <= self.x[i + 1]:
                #Linear interpolation
                slope = (self.y[i + 1] - self.y[i]) / (self.x[i + 1] - self.x[i])
                return self.y[i] + slope * (t - self.x[i])
        
class fpgaHandler:
    
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)
        #test the connection
        version = self.sendCommand("VER?")
        print("fpga version: ", version)
        
        #setup the command idx of each fpga register
        self.setupFpgaCommandIndexes()        
    
    #UDP connection
    self_ip = "192.168.1.100"#"127.0.0.1"#
    fpga_ip = "192.168.1.12"
    parameterPort = 2047
    dataPort = 2048
    
    dimLink = dimensionLinker()
    dimLink.addDimension("small_FPGA_register", "bit", bitSize = 16)
    dimLink.addDimension("large_FPGA_register", "bit", bitSize = 16)
    
    dataValuesFromFPGA = {
        "data read from the fpga stream"    : fpgaRegister(dimLink, "small_FPGA_register", "small_FPGA_register"),
    }
    
    ParametersForFPGA = {
        #large parameters
        "parameter larger than 16 bits"     : fpgaRegister(dimLink, "large_FPGA_register", "large_FPGA_register"),
        
        #small parameters
        "parameter with max 16 bits"        : fpgaRegister(dimLink, "small_FPGA_register", "small_FPGA_register"),
    }
    
    
    def setupFpgaCommandIndexes(self):
        offset = 1
        for (key,value) in self.ParametersForFPGA.items():
            for j in range(len(value.command)):
                value.command[j] = offset
                offset += 1
                
    def setParameters(self, **kwargs):
        (parameters, values) = list(kwargs.keys()), list(kwargs.values())
        commandList = []
        for i in range(len(parameters)):
            register = self.ParametersForFPGA[parameters[i]]
            if(isinstance(values[i], tuple)):
                paramVals = register.floatToFixedPoint(*values[i])
                print(f"setting {parameters[i]} to {values[i][0]} ({values[i][1]}), fpga number: {paramVals}")
            else:
                paramVals = register.floatToFixedPoint(values[i])
                print(f"setting {parameters[i]} to {values[i]} ({register.preferredConversionDimension}), fpga number: {paramVals}")
            for j in range(len(register.command)-1,-1,-1):    
                commandList.append(b"CPAR"+register.command[j].to_bytes(1,'big')+b"\0"+\
                                   (paramVals[j]&0xffff).to_bytes(2,'big'))
        self.sendCommand(commandList)
            
        
    def sendCommand(self, commands, waitForResponse = True):
        with setupReception(self.self_ip, self.parameterPort) as sock:
            if isinstance(commands, list):
                responses = [None] * len(commands)
                for i, command in enumerate(commands):
                    responses[i] = transmitCommand(sock, self.fpga_ip, self.parameterPort, command, waitForResponse)
                return responses
            return transmitCommand(sock, self.fpga_ip, self.parameterPort, commands, waitForResponse)
    
    
    def getDataStream(self, time = 1):
        with setupReception(self.self_ip, self.dataPort) as sock:
            retData = {}
            for name in self.dataValuesFromFPGA.keys():
                retData[name] = []
            retData["times"] = []
            endTime = t.time() + time
            startTime = t.time()
            while t.time() < endTime:
                received, address = sock.recvfrom(2048)
                retData["times"].append(t.time() - startTime)
                byteIdx = 1
                for name, register in self.dataValuesFromFPGA.items():
                    val = int(received[byteIdx] << 8) + int(received[byteIdx+1])
                    if(val >= 0x8000):
                        val = -0x10000 + val
                    
                    retData[name].append(register.fixedPointToFloat(val))
                    byteIdx += 2
            return retData
        
    def plotReceivedData(self, time = 3, elementsToShow = None, elementsToRemove = None):
        data = self.getDataStream(time)
        plt.figure()
        x=data["times"]
        if(elementsToShow is None):
            elementsToShow = list(data.keys())
            elementsToShow.remove("times")
        if(elementsToRemove is not None):
            for e in elementsToRemove:
                elementsToShow.remove(e)
        
        for key in elementsToShow:
            plt.plot(x, data[key], label=key, alpha=0.7)
        
        # Add legend
        plt.legend()
        
class bioTweezerController(fpgaHandler):
    
    def initializeDimensionLinker(self):
        dimLink = dimensionLinker()
        dimLink.addDimension("bead_position", "m")
        dimLink.addDimension("bead_positionSquare", "m^2")
        dimLink.addDimension("QPD_output", "V")
        dimLink.addDimension("xy_voltage", "V")
        dimLink.addDimension("sum_voltage", "V")
        dimLink.addDimension("FPGA_floatValue", "[adimensional]")
        dimLink.addDimension("FPGA_SUMfloatValue", "[adimensional]")
        dimLink.addDimension("FPGA_signalRegister", "bit", bitSize = 16)
        dimLink.addDimension("FPGA_SUMsignalRegister", "bit", bitSize = 16)
        dimLink.addDimension("FPGA_coeffRegister", "bit", bitSize = 26)
        dimLink.addDimension("FPGA_largeCoeffRegister", "bit", bitSize = 26)
        dimLink.addDimension("FPGA_bitRegister", "bit", bitSize = 1, isSigned = False)
        dimLink.addDimension("FPGA_timeRegister", "bit", bitSize = 28, isSigned = False)
        dimLink.addDimension("control_voltage", "V")
        dimLink.addDimension("generator_input", "V")
        dimLink.addDimension("generator_current", "I")
        dimLink.addDimension("laserPower", "W")
        dimLink.addDimension("time", "s")
        self.dimLink = dimLink
        
    def updateDimensionLinker(self):
        self.dimLink.clearEdges()
        self.dimLink.addConnection("QPD_output", "xy_voltage", dimensionLinker.gainFunctions(self.ADC_xyAttenuation))
        self.dimLink.addConnection("QPD_output", "sum_voltage", dimensionLinker.gainFunctions(self.ADC_sumAttenuation))
        self.dimLink.addConnection("xy_voltage", "FPGA_floatValue", dimensionLinker.gainFunctions(self.ADC_voltageToFpgaInput))
        self.dimLink.addConnection("sum_voltage", "FPGA_SUMfloatValue", dimensionLinker.gainFunctions(self.ADC_voltageToFpgaInput))
        self.dimLink.addConnection("FPGA_floatValue", "FPGA_signalRegister", dimensionLinker.gainFunctions(2**15))
        self.dimLink.addConnection("FPGA_SUMfloatValue", "FPGA_SUMsignalRegister", dimensionLinker.gainFunctions(2**15))
        self.dimLink.addConnection("FPGA_floatValue", "FPGA_coeffRegister", dimensionLinker.gainFunctions(2**24))
        self.dimLink.addConnection("FPGA_floatValue", "FPGA_largeCoeffRegister", dimensionLinker.gainFunctions(2**22))
        self.dimLink.addConnection("FPGA_floatValue", "control_voltage", dimensionLinker.gain_n_shiftFunctions(self.DAC_fpgaOuputToVoltage, self.DAC_offset))
        self.dimLink.addConnection("control_voltage", "generator_input", dimensionLinker.shift_n_gainFunctions(-self.DAC_offset, self.DAC_gain))
        self.dimLink.addConnection("generator_input", "generator_current", dimensionLinker.gain_n_shiftFunctions(self.currentGenerator_inputVtoI, self.currentGenerator_baseCurrent))
        self.dimLink.addConnection("generator_current", "laserPower", dimensionLinker.gainFunctions(self.laser_currentToLaserPower))
        
        self.dimLink.addConnection("FPGA_floatValue", "bead_position", dimensionLinker.gainFunctions(self.range_x))
        self.dimLink.addConnection("bead_position", "bead_positionSquare", dimensionLinker.squareFunctions())
        self.dimLink.addConnection("time", "FPGA_timeRegister", dimensionLinker.gainFunctions(self.fpga_controller_clock))
        self.dimLink.checkForLoops()
    
    def __init__(self, **kwargs):
        
        self.initializeDimensionLinker()
        self.dataValuesFromFPGA = {
            "pid out"               : fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
            "x"                     : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
            "y"                     : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
            "z"                     : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
            "x^2"                   : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare"),
            "y^2"                   : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare"),
            "z^2"                   : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare"),
        }
        self.ParametersForFPGA = {#follow the FPGA order
            #large parameters
            "kp"                    : fpgaRegister(self.dimLink, "FPGA_coeffRegister", "FPGA_floatValue"),
            "ki"                    : fpgaRegister(self.dimLink, "FPGA_coeffRegister", "FPGA_floatValue"),
            "SUM_multiplierFor_div" : fpgaRegister(self.dimLink, "FPGA_largeCoeffRegister", "FPGA_floatValue"),
            "SUM_multiplierFor_z"   : fpgaRegister(self.dimLink, "FPGA_largeCoeffRegister", "FPGA_floatValue"),
            "toggleEnableTime"      : fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
            "binFeedback_activeFeedbackMaxCycles"      : fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
            
            #small parameters
            "outWhenPiDisabled"     : fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
            "setpoint"              : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
            "limitLow"              : fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
            "limitHigh"             : fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
            "SUM_offsetFor_div"     : fpgaRegister(self.dimLink, "FPGA_SUMsignalRegister", "QPD_output"),
            "SUM_offsetFor_z"       : fpgaRegister(self.dimLink, "FPGA_SUMsignalRegister", "QPD_output"),
            "x_offset"              : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
            "y_offset"              : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
            "useToggleEnable"       : fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
            "binFeedback_actOnInGreaterThanThreshold"  : fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
            "binFeedback_threshold"                    : fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
            "binFeedback_valueWhenActive"              : fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
            "disableY"              : fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
            "disableZ"              : fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
        }
        super(bioTweezerController, self).__init__(**kwargs)
        self.reset()
        self.updateDimensionLinker()
        self.initiateTweezers()
        
    #gains of the ADC/DAC circuits
    ADC_xyAttenuation = -1 / 7.8                                                                             # V/V
    ADC_sumAttenuation = -1 / 11                                                                             # V/V
    DAC_gain = 10                                                                                          # V/V
    DAC_offset = 2.5                                                                                        # V
    ADC_voltageToFpgaInput = 1                                                                              # 1/V
    DAC_fpgaOuputToVoltage = 2.5                                                                            # V
    
    #parameters of the current generator (how does the control input voltage get translated into a current)
    #parameters of the laser
    laser_currentToLaserPower = 340e-3 / 730e-3                                                             # W/A
    #= segmented_function([0,730e-3], [0,340e-3])  
    
    #conversion from bead position to qpd voltage output
    sensitivity_x = sensitivity_y = 0.5e-3 / 1e-9                                                           # V/m
    sensitivity_z = 1e-3 / 1e-9                                                                             # V/m
    
    #distance ranges (i.e. the values of x and y when their respective DIFF signals are == SUM)
    range_x = range_y = 10 / sensitivity_x                                                                  # m
    #value of the SUM signal when the bead is at the center of the laser (z == 0)
    SUM_at_z0 = 0.1                                                                                           # V
    
    x_offset = 0
    y_offset = 0
    
    SUM_backgroundVoltage = 0                                                                               # V
    SUM_multiplierForDIFF_SUM = range_x/range_x                                                             # [adimensional] (maybe?)
    
    
    #calibration parameters
    calibration_laserPower = 90e-3                                                                          # W
    calibration_time = 3                                                                                    # s
    
    fpga_controller_clock = 50e6
    
    def _fpgaOutputToLaserPower(self, value):
        return ((value * self.DAC_fpgaOuputToVoltage * self.DAC_gain * self.currentGenerator_inputVtoI) + \
                self.currentGenerator_baseCurrent) * self.laser_currentToLaserPower
    
    
    def initiateTweezers(self):
        self.set_zOffset()
        self.remove_xy_offset()
        mz = 1 / (self.range_x * self.sensitivity_z * self.ADC_sumAttenuation)
        self.setParameters(
            SUM_multiplierFor_z = (mz, "FPGA_floatValue"),
            SUM_offsetFor_z = (-self.SUM_at_z0, "QPD_output"),
            
            SUM_multiplierFor_div = (self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
            SUM_offsetFor_div = (self.SUM_backgroundVoltage * self.ADC_sumAttenuation * self.SUM_multiplierForDIFF_SUM, "QPD_output"),
           
            x_offset = self.x_offset,
            y_offset = self.y_offset, 
           
            outWhenPiDisabled = (0, "generator_input"),
        )
        if(self.DAC_gain > 0):
            self.setParameters(
                limitLow = (self.currentGenerator_minCurrent, "generator_current"),
                limitHigh = (self.currentGenerator_maxCurrent, "generator_current"),
            )
        else:
            self.setParameters(
                #high and low limits are switched, because the DAC amplifier has a negative gain
                limitLow = (self.currentGenerator_maxCurrent, "generator_current"),
                limitHigh = (self.currentGenerator_minCurrent, "generator_current"),
            )
        
    
    def calcStiffness(self, time = 3, temperature = 300, directions = ["x", "y"]):
        self.initiateFpga()
        dataFromFPGA = self.getDataStream(time)
        kBoltzman = 1.3806504e-23
        stiffnesses = [0] * len(directions)
        for i,direction in enumerate(directions):
            l = dataFromFPGA[direction]
            l_squared = dataFromFPGA[direction+"^2"]
            variance = np.mean(l_squared) - np.mean(l)**2
            stiffnesses[i] = kBoltzman * self.temperature / variance
        return stiffnesses
    
    def calibrateTweezers(self):
        #set a constant output (=> constant laser power)        
        self.setConstantOutput(self.calibration_laserPower)
        [kx, ky, kz] = self.calcStiffness(time=self.calibration_time, directions=["x","y","z"])
        self.laser_powerToStiffness_xy = (kx+ky)/2 / self.calibration_laserPower
        self.laser_powerToStiffness_z = kz / self.calibration_laserPower
    
    def remove_xy_offset(self, time = 0.2):
        self.EnablePI(
            kp = 0,
            ki = 0,
            x_offset = (0, "FPGA_floatValue"),
            y_offset = (0, "FPGA_floatValue"),
        )
        data = self.getDataStream(time)
        self.x_offset = - np.mean(data["x"])
        self.y_offset = - np.mean(data["y"])
        
    def _get_zOffset(self, time = 0.2):
        self.EnablePI(
            kp = 0,
            ki = 0,
            SUM_multiplierFor_z = (-1, "FPGA_floatValue"),
            SUM_offsetFor_z = (0, "QPD_output"),
        )
        z = - np.mean(self.getDataStream(time)["z"])
        self.reset()
        z = self.dimLink.convert(z, self.dataValuesFromFPGA["z"].preferredConversionDimension, "FPGA_signalRegister")
        z = self.dimLink.convert(z, "FPGA_SUMsignalRegister", "QPD_output")
        return z
        
    def set_SumBackgroundVoltage(self, time = 0.2):
        self.SUM_backgroundVoltage = self._get_zOffset(time)
        
    def set_zOffset(self, time = 0.2):
        self.SUM_at_z0 = self._get_zOffset(time)
    
    def setReset(self, reset = 1):
        self.sendCommand([b"PICL000000"+reset.to_bytes(1, 'big')])
    def setPiEnable(self, enable = 1):
        self.sendCommand([b"PIEN000000"+enable.to_bytes(1, 'big')])
    def reset(self):
        self.sendCommand([b"PICL0001", b"PIEN0000"])
    def EnableConstantOutput(self, output):
        self.sendCommand([b"PICL0001"])
        self.setParameters(outWhenPiDisabled = output, useToggleEnable = False)
        self.sendCommand([b"PICL0000", b"PIEN0000"])
    def EnablePI(self, kp = 0.1, ki = 0.001, **kwargs):
        self.sendCommand([b"PICL0001"])
        self.setParameters(kp=kp, ki=ki, useToggleEnable = False, **kwargs)
        self.sendCommand([b"PICL0000", b"PIEN0001"])
    def EnableBinaryFeedback(self, threshold = 0.5, actOn_In_HigherThanThreshold = True, valueWhenActive = 0.1, activeFeedbackDuration = 0.01, **kwargs):
        self.sendCommand([b"PICL0001"])
        self.setParameters(binFeedback_threshold = threshold, binFeedback_actOnInGreaterThanThreshold = actOn_In_HigherThanThreshold, 
                           binFeedback_valueWhenActive = valueWhenActive, binFeedback_activeFeedbackMaxCycles = activeFeedbackDuration, 
                           useToggleEnable = False, **kwargs)
        self.sendCommand([b"PICL0000", b"PIEN0002"])
    def setToggleOnEnable(self, enable = True, toggleTime = 0.1):
        self.setParameters(useToggleEnable = int(enable), toggleEnableTime = toggleTime)
    def toggleEnableDisable(self, toggleTime, totalDuration):
        start = t.time()
        nextTime = start
        warnForTooSlow = True
        currentToggle = True
        
        with setupReception(self.self_ip, self.parameterPort) as sock:
            while nextTime - start < totalDuration:
                nextTime += toggleTime
                if currentToggle:
                    transmitCommand(sock, self.fpga_ip, self.parameterPort, b"PICL0000", True)
                    transmitCommand(sock, self.fpga_ip, self.parameterPort, b"PIEN0001", True)
                else:
                    transmitCommand(sock, self.fpga_ip, self.parameterPort, b"PICL0001", True)
                    transmitCommand(sock, self.fpga_ip, self.parameterPort, b"PIEN0000", True)
                currentToggle = not currentToggle
                currentTime = t.time()
                if currentTime < nextTime:
                    t.sleep(nextTime - currentTime)
                else:
                    if(warnForTooSlow):
                        warnForTooSlow = False
                        print(f"transmission is too slow for the toggling time! (taken {currentTime - (nextTime - toggleTime)} instead of {toggleTime})")
                    nextTime = currentTime
            
    def disable_yz_Dimensions(self, disableY, disableZ):
        self.setParameters(disableY = disableY, disableZ = disableZ)
    
    currentGenerator_inputVtoI = 1e-3 / 20e-3                                                               # A/V
    currentGenerator_baseCurrent = 100e-3                                                                   # A
    currentGenerator_minCurrent = 0e-3                                                                   # A
    currentGenerator_maxCurrent = 50e-3                                                                   # A
        

q = bioTweezerController()
q.disable_yz_Dimensions(True, True)
q.EnableConstantOutput((-0.0, "generator_input"))
q.EnablePI(kp = -0.1, ki = 0.0, setpoint = (-0.1, "FPGA_floatValue"), limitLow=(-.999,"FPGA_floatValue"), limitHigh=(.999,"FPGA_floatValue"))
# for i in np.linspace(0,1,10):
#     print(i)
#     q.EnableBinaryFeedback(i,True, (0.5, "FPGA_floatValue"), 0.1)
    # t.sleep(0.5)
q.EnableBinaryFeedback((0xc00, "FPGA_signalRegister"),True, (0.2, "generator_input"), 0.003)
# # q.setToggleOnEnable(True,0.2)
# # q.reset()

# # q.toggleEnableDisable(0.001, 5)

q.plotReceivedData(3,elementsToRemove=["pid out"])
q.plotReceivedData(3,elementsToShow=["pid out"])

# Example dictionary of vectors
