
from tkinter import *
from tkinter import ttk
import numpy as np
import socket
import time as t
from dimensionLinker import dimensionLinker
import matplotlib.pyplot as plt
from scipy.optimize import  least_squares
from functools import partial
import pandas as pd
from threading import Thread

def setupReception(ip, port):
	#get a socket for UDP transmission
	sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	try:
		sock.bind((ip, port))
	except OSError as e:
		raise Exception(f"check if the selected IP {ip} is the IP of your computer (you might have to manually change the IP)") from e
		
	socket.setdefaulttimeout(1)
	return sock

def transmitCommand(sock, ip, port, command, waitForResponse = False, printTransmission = False):
	#transmit a string or bite stream to the selected ip/port. It can also wait for a response message
	if(isinstance(command, str)):
		command = command.encode()
	sock.sendto(command, (ip, port))
	if(printTransmission):
		print("sent to ", ip, ": ", command)
	if(waitForResponse):
		return receive(sock, port)

def receive(sock, port, printReception = False):
	#receive a string or byte string  from the selected port. For now, the sender is not returned
	received, address = sock.recvfrom(port)
	if(printReception):
		print("Received from", address, ":", received)
	return received
	
class fpgaRegister:
	#class that handles data conversion between physical values and the raw values used inside the FPGA controller.
		#it has a base dimension (the raw bit values inside the FPGA) and a preferred physical dimension (i.e. the
		#dimension that the FPGA value represents). It uses a dimensionLinker to convert between dimensions, so you
		#can also change/read the value of this object by feeding it a value in a different dimension, as long as
		#it is connected to the base dimension
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
		#convert from a physical dimension to the corresponding FPGA value
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
			val = int(minVal)
		if(len(self.command) > 1):
			return [val >> 16, val & 0xffff]
		return [val]
	
	def fixedPointToFloat(self, intValue, toDimension = None):
		#convert from a FPGA value to the corresponding value of the selected physical dimension
		if(len(self.command) > 1):
			intValue = (intValue[0] << 16) + intValue[1]
		if isinstance(intValue, list):
			intValue = intValue[0]
		intValue &= ((1<<self.bitSize) - 1)
		if intValue >= (1 << (self.bitSize - 1)):
			intValue -= (1 << self.bitSize)
		if(toDimension is None):
			toDimension = self.preferredConversionDimension
		return self.dimLinker.convert(intValue, self.dimension, toDimension)
		
class fpgaHandler:
	#handles transmission and data conversion from the FPGA controller
		#this is an abstract class, you're supposed to create a child class that overrides the dimLink parameter and
		#defines transmission and calibration functions
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
	
	#dimLink contains all the dimensions used in the system, and their relations between one another.
	dimLink = dimensionLinker()
	#This is a dummy dimensionLinker containing just a few dimensions and a few connections
	dimLink.addDimension("small_FPGA_register", "bit", bitSize = 16)
	dimLink.addDimension("large_FPGA_register", "bit", bitSize = 32)
	#the following connection states that to convert a value from small_FPGA_register to large_FPGA_register,
		#you need to multiply it by 2**16, and viceversa to go backwards you need to divide by 2*16
	dimLink.addConnection("small_FPGA_register", "large_FPGA_register", dimensionLinker.gainFunctions(2**16))
	
	#the FPGA handles 2 groups of values, data sent on a stream (periodically sent to the computer), and data
		#received (mostly configuration values, sent only once)
	
	#these values are sent periodically by the FPGA (es: every 5ms), and they usually are the outputs of the control
	dataValuesFromFPGA = {
		"data read from the fpga stream"    : fpgaRegister(dimLink, "small_FPGA_register", "small_FPGA_register"),
	}
	
	#these values are sent by the computer, and they are meant to be configuration values. If a value is stored
		#in more than 16 bits inside the FPGA (and less than 32), you should add it to the list in the first group
		#of elements. remember to follow the same order in which the values were inserted inside the FPGA firmware
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
				print(f"setting {parameters[i]} to {values[i][0]} ({values[i][1]}), fpga number: {[hex(pv) for pv in paramVals]}")
			else:
				paramVals = register.floatToFixedPoint(values[i])
				print(f"setting {parameters[i]} to {values[i]} ({register.preferredConversionDimension}), fpga number: {[hex(pv) for pv in paramVals]}")
			for j in range(len(register.command)-1,-1,-1):
				commandList.append(b"CPAR"+register.command[j].to_bytes(1,'big')+b"\0"+\
								   (paramVals[j]&0xffff).to_bytes(2,'big'))
		self.sendCommand(commandList)
			
	def readBackParameter(self, *parameters):
		values = [[]] * len(parameters)
		for i,param in enumerate(parameters):
			if isinstance(param, tuple):
				param, dim = param
			else:
				dim = None
			register = self.ParametersForFPGA[param]
			values[i] = [0] * len(register.command)
			for j in range(len(register.command)-1,-1,-1):
				readString = self.sendCommand(b"RPAR"+register.command[j].to_bytes(1,'big')+b"\0\0\0")
				values[i][j] = int.from_bytes(readString[0:2], byteorder='big')
			values[i] = register.fixedPointToFloat(values[i], dim)
		if len(values) == 1:
			values = values[0]
		return values
		
	def sendCommand(self, commands, waitForResponse = True):
		#send one or multiple commands to the FPGA
		with setupReception(self.self_ip, self.parameterPort) as sock:
			if isinstance(commands, list):
				responses = [None] * len(commands)
				for i, command in enumerate(commands):
					responses[i] = transmitCommand(sock, self.fpga_ip, self.parameterPort, command, waitForResponse)
				return responses
			return transmitCommand(sock, self.fpga_ip, self.parameterPort, commands, waitForResponse)
	
	
	def getDataStream(self, time = 1, **dimensions):
		#receive the data stream from the FPGA for the specified time (in seconds). The returned value is a dictionary
			#where the keys are the names of the different values sent by the FPGA (specified in dataValuesFromFPGA),
			#and the values are the lists of values received during the reception time.
			#you can specify the final dimension of the various signal (add to the declaration <signalName> = <desiredDimension>)
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
					
					if name in dimensions.keys():
						retData[name].append(register.fixedPointToFloat(val, dimensions[name]))
					else:
						retData[name].append(register.fixedPointToFloat(val))
					byteIdx += 2
			return retData
		
	def startDataStream(self, maxTime = 70, updateFunction = None, **dimensions):
		#start a thread dedicated to reading the datastream from the FPGA. It works
			#similarly to getDataStream, but it is not a blocking procedure, and you
			#don't have to specify the duration of the reading.Remember  that you're
			#supposed to close the thread (and so the data reception) with
			#stopDataStream, which also returns the read data.
			#you can execute a function at every reception of data (example, to update a
			#scatter plot in real time)
		sock = setupReception(self.self_ip, self.dataPort)
		try:
			self.dataStreamThread = Thread(target=self._dataStreamThreadRun, args=(sock,maxTime, updateFunction),kwargs= dimensions)
			self.dataStreamRunning = True
			self.dataStreamBuffer = {}
			self.dataStreamThread.start()
		except:
			try:
				sock.close()
			except:
				pass

	def _dataStreamThreadRun(self, sock, maxTime = 70, updateFunction = None, **dimensions):
		try:
			for name in self.dataValuesFromFPGA.keys():
				self.dataStreamBuffer[name] = []

			self.dataStreamBuffer["times"] = []
			startTime = t.time()
			maxendTime = startTime + maxTime
			while self.dataStreamRunning:
				received, address = sock.recvfrom(2048)
				self.dataStreamBuffer["times"].append(t.time() - startTime)
				byteIdx = 1
				for name, register in self.dataValuesFromFPGA.items():
					val = int(received[byteIdx] << 8) + int(received[byteIdx+1])
					if(val >= 0x8000):
						val = -0x10000 + val
						
					if name in dimensions.keys():
						self.dataStreamBuffer[name].append(register.fixedPointToFloat(val, dimensions[name]))
					else:
						self.dataStreamBuffer[name].append(register.fixedPointToFloat(val))
					byteIdx += 2
				if updateFunction is not None:
					updateFunction(self.dataStreamBuffer)
				if t.time() > maxendTime:
					raise Exception(f"dataStream was kept open for too long (more than {maxTime}s). Closing automatically")
		finally:
			sock.close()


	def stopDataStream(self):
		#stops the data stream thread and returns the read data
		if hasattr(self, "dataStreamThread") and self.dataStreamThread is not None:
			self.dataStreamRunning = False
			if not self.dataStreamThread.is_alive():
				print("WARNING: data stream read finished early because of a timeout.")
			self.dataStreamThread.join()
			self.dataStreamThread = None
			return self.dataStreamBuffer
		print("start the stream first!")
		return {}
	
	def getArraysFromDataStreamBuffer(self):
		t = np.array(self.dataStreamBuffer["times"])
		pts = t.shape[0]
		y = np.zeros((pts, 3), dtype=np.float64)
		y[:,0] = np.array(self.dataStreamBuffer["x"])
		y[:,1] = np.array(self.dataStreamBuffer["y"])
		y[:,2] = np.array(self.dataStreamBuffer["z"])
		
		return(t, y)

		
	def plotReceivedData(self, time = 3, elementsToShow = None, elementsToRemove = None, **dimensions):
		#receive a dataStream and print the values (or some of the values) received.
		data = self.getDataStream(time, **dimensions)
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
		plt.legend()
		plt.show()
		
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
			"pid out"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"x"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"y"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"z"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"x^2"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare"),
			"y^2"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare"),
			"z^2"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare"),
		}
		self.ParametersForFPGA = {#follow the FPGA order
			#large parameters
			"kp"					: fpgaRegister(self.dimLink, "FPGA_coeffRegister", "FPGA_floatValue"),
			"ki"					: fpgaRegister(self.dimLink, "FPGA_coeffRegister", "FPGA_floatValue"),
			"SUM_multiplierFor_div" : fpgaRegister(self.dimLink, "FPGA_largeCoeffRegister", "FPGA_floatValue"),
			"SUM_multiplierFor_z"	: fpgaRegister(self.dimLink, "FPGA_largeCoeffRegister", "FPGA_floatValue"),
			"toggleEnableTime"		: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			"binFeedback_activeFeedbackMaxCycles"	: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			"binFeedback_idleWaitCycles"			: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			"binFeedback_cyclesForActivation"		: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			
			#small parameters
			"outWhenPiDisabled"		: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"setpoint"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"limitLow"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"limitHigh"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"SUM_offsetFor_div"		: fpgaRegister(self.dimLink, "FPGA_SUMsignalRegister", "QPD_output"),
			"SUM_offsetFor_z"		: fpgaRegister(self.dimLink, "FPGA_SUMsignalRegister", "QPD_output"),
			"x_offset"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"y_offset"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"useToggleEnable"		: fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
			"binFeedback_actOnInGreaterThanThreshold"	: fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
			"binFeedback_threshold"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"binFeedback_valueWhenActive"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"disableY"				: fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
			"disableZ"				: fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
			"xDiff_offset"			: fpgaRegister(self.dimLink, "FPGA_signalRegister", "QPD_output"),
			"yDiff_offset"			: fpgaRegister(self.dimLink, "FPGA_signalRegister", "QPD_output"),
		}
		super(bioTweezerController, self).__init__(**kwargs)
		self.reset()
		self.updateDimensionLinker()
		#self.initiateTweezers()
		
	#gains of the ADC/DAC circuits
	ADC_xyAttenuation = -1 / 7.8																							#	V/V
	ADC_sumAttenuation = -1 / 11																							#	V/V
	DAC_gain = 10																											#	V/V
	DAC_offset = 2.5																										#	V
	ADC_voltageToFpgaInput = 1																								#	1/V
	DAC_fpgaOuputToVoltage = 2.5																							#	V
	
	#parameters of the current generator (how does the control input voltage get translated into a current)
	currentGenerator_inputVtoI = 1e-3 / 20e-3																				#	A/V
	currentGenerator_baseCurrent = 100e-3																					#	A
	currentGenerator_minCurrent = 0e-3																						#	A
	currentGenerator_maxCurrent = 250e-3																					#	A
		
	#parameters of the laser
	laser_currentToLaserPower = 340e-3 / 730e-3																				#	W/A
	
	#conversion from bead position to qpd voltage output
	sensitivity_x = sensitivity_y = 0.5e-3 / 1e-9																			#	[adimensional]/m
	sensitivity_z = 1e-3 / 1e-9																								#	V/m
	
	#distance ranges (i.e. the values of x and y when their respective DIFF signals are == SUM)
	range_x = range_y = 10 / sensitivity_x																					#	m
	#value of the SUM signal when the bead is at the center of the laser (z == 0)
	SUM_at_z0 = 0.1																											#	V
	SUM_multiplierForDIFF_SUM = range_x/range_x																				#	[adimensional]
	
	#values found during calibration. Hence, let's keep them as adimensional values,
		#since we don't care about the actual value in the correct dimension
	x_offset = 0																											#	[adimensional]
	y_offset = 0																											#	[adimensional]
	xDiff_offset = 0																										#	[adimensional]
	yDiff_offset = 0																										#	[adimensional]

	#FPGA controller clock
	fpga_controller_clock = 50e6																							#	Hz
		
	def initiateTweezers(self, singleCalibrationTime = 1, usedLaserPowers = [(n, "generator_current") for n in np.linspace(50e-3, 200e-3,6)], useXYDIFF_offset = True, useSUM_offset = True):
		#do some calibration measures
		self.getCalibrationValues(singleCalibrationTime = singleCalibrationTime, usedLaserPowers = usedLaserPowers,
							  useXYDIFF_offset = useXYDIFF_offset, useSUM_offset = useSUM_offset)
		
		#set a lot of parameters in the FPGA
		mz = 1 / (self.range_x * self.sensitivity_z * self.ADC_sumAttenuation)
		self.setParameters(
			SUM_multiplierFor_z = (mz, "FPGA_floatValue"),
			SUM_offsetFor_z = (-self.SUM_at_z0, "QPD_output"),
			
			SUM_multiplierFor_div = (self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
			
			SUM_offsetFor_div = (self.SUM_offsetFor_div, "FPGA_floatValue"),
			x_offset = (self.x_offset, "FPGA_floatValue"),
			xDiff_offset = (self.xDiff_offset, "FPGA_floatValue"),
			y_offset = (self.y_offset, "FPGA_floatValue"),
			yDiff_offset = (self.yDiff_offset, "FPGA_floatValue"),
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
		#calculate the stiffness of the trap based on the variation on the bead position
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
	
	def _get_zOffset(self, intensity = (0, "FPGA_floatValue"), time = 0.2):
		self.EnableConstantOutput(intensity)
		self.setParameters(
			SUM_multiplierFor_z = (- self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),#value to normalize SUM to respect to XDIFF and YDIFF (the amplification circuit has different gains for X/YDIFF and SUM)
			SUM_multiplierFor_div = (- self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
			SUM_offsetFor_z = (0, "FPGA_floatValue"),
			SUM_offsetFor_div = (0, "FPGA_floatValue"),
		)
		z = - np.mean(self.getDataStream(time)["z"])
		self.reset()
		z = self.dimLink.convert(z, self.dataValuesFromFPGA["z"].preferredConversionDimension, "FPGA_signalRegister")
		z = self.dimLink.convert(z, "FPGA_SUMsignalRegister", "QPD_output")
		return z
		
	def getCalibrationValues(self, singleCalibrationTime = 0.3, usedLaserPowers = [(n, "generator_current") for n in np.linspace(50e-3, 200e-3,6)], useXYDIFF_offset = True, useSUM_offset = True):
		self.set_zOffset(singleCalibrationTime)
		#calculate the offsets for x and y
		SUM = np.zeros(len(usedLaserPowers))
		XDIFF = np.zeros(len(usedLaserPowers))
		YDIFF = np.zeros(len(usedLaserPowers))
		#reset every offset value, even for z, since we'll be using it to read the SUM signal
		self.setParameters(
			x_offset = (0, "FPGA_floatValue"),
			y_offset = (0, "FPGA_floatValue"),
			xDiff_offset = (0, "FPGA_floatValue"),
			yDiff_offset = (0, "FPGA_floatValue"),
			SUM_multiplierFor_z = (- self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),#value to normalize SUM to respect to XDIFF and YDIFF (the amplification circuit has different gains for X/YDIFF and SUM)
			SUM_multiplierFor_div = (- self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
			SUM_offsetFor_z = (0, "FPGA_floatValue"),
			SUM_offsetFor_div = (0, "FPGA_floatValue"),
		)
		debug = False
		if debug:
			global xd, yd, sm
			SUM = sm
			XDIFF = xd
			YDIFF = yd
			print("using debug calibration")
		else:
			#let's get some values for SUM, XDIFF and YDIFF
			for i, intensity in enumerate(usedLaserPowers):
				self.EnableConstantOutput(intensity)
				
				t.sleep(0.01)#wait for the system to stabilize
				data = self.getDataStream(singleCalibrationTime)
				
				SUM[i] = - np.mean(data["z"])
				SUM[i] = self.dimLink.convert(SUM[i], self.dataValuesFromFPGA["z"].preferredConversionDimension, "FPGA_floatValue")#convert the bead position into an adimensional value
				XDIFF[i] = np.mean(data["x"])
				XDIFF[i] = self.dimLink.convert(XDIFF[i], self.dataValuesFromFPGA["x"].preferredConversionDimension, "FPGA_floatValue") * SUM[i]#x = XDIFF / SUM => XDIFF = x * SUM
				YDIFF[i] = np.mean(data["y"])
				YDIFF[i] = self.dimLink.convert(YDIFF[i], self.dataValuesFromFPGA["y"].preferredConversionDimension, "FPGA_floatValue") * SUM[i]

		#now, assuming that the formula for calculating x from SUM and XDIFF is
			#x = (XDIFF - o_xdiff) / (SUM - o_sum ) - o_x
			#and knowing that x ~ 0, let's estimate the 3 offsets by minimizing the error of the formula on the values we obtained
			#(same thing for y, with the condition that o_sum is the same for both x and y)
		#let's group together all the data for X and Y
		xydiff = np.append(XDIFF, YDIFF)
		sumsum = np.append(SUM, SUM)
		#we might disable some offsets in case we want a simpler offset calculation
		sumOffsetPosition = 1 if useXYDIFF_offset else 0
		xOffsetPosition = sumOffsetPosition + (1 if useSUM_offset else 0)
		def fxy(oo):
			o = np.array([[oo[0]]*len(XDIFF) + [oo[1]]*len(YDIFF),
						  [oo[2]]*len(xydiff),
						  [oo[3]]*len(XDIFF) + [oo[4]]*len(YDIFF)])
			return (xydiff - (o[0] if useXYDIFF_offset else 0)) - (sumsum - (o[1] if useSUM_offset else 0)) * o[2]
				#when all the offsets are enabled, this formula equals to (xydiff - o[0]) - (sumsum - o[1]) * o[2].
				#minimizing this formula is the same as minimizing		( (xydiff - o[0]) / (sumsum - o[1]) - o[2] ),
				#but it is more stable since it doesn't have any variable in the denominator
		
		solution = least_squares(fxy, np.array([0,0,0,0,0]))

		self.xDiff_offset = solution.x[0]
		self.yDiff_offset = solution.x[1]
		self.SUM_offsetFor_div = -solution.x[2]
		self.x_offset = solution.x[3]
		self.y_offset = solution.x[4]
		print(solution)
			
	
	def set_zOffset(self, time = 0.2):
		self.SUM_at_z0 = self._get_zOffset(time)
	
	def setReset(self, reset = 1):
		self.sendCommand([b"PICL0000"+reset.to_bytes(1, 'big')])
	def setPiEnable(self, enable = 1):
		self.sendCommand([b"PIEN0000"+enable.to_bytes(1, 'big')])
	def reset(self):
		self.sendCommand([b"PICL0001", b"PIEN0000"])
	def EnableConstantOutput(self, output = None):
		self.sendCommand([b"PICL0001"])
		if output is None:
			self.setParameters(useToggleEnable = False)
		else:
			self.setParameters(outWhenPiDisabled = output, useToggleEnable = False)
		self.sendCommand([b"PICL0000", b"PIEN0000"])
	def EnablePI(self, kp = 0.1, ki = 0.001, **kwargs):
		self.sendCommand([b"PICL0001"])
		self.setParameters(kp=kp, ki=ki, useToggleEnable = False, **kwargs)
		self.sendCommand([b"PICL0000", b"PIEN0001"])
		
	def EnableBinaryFeedback(self, threshold = 0.5, actOn_In_HigherThanThreshold = True, valueWhenActive = 0.1,
					activeFeedbackDuration = 0.01, idleDurationAfterFeedback = 0, timeBeforeActivation = 0, **kwargs):
		self.sendCommand([b"PICL0001"])
		self.setParameters(binFeedback_threshold = threshold, binFeedback_actOnInGreaterThanThreshold = actOn_In_HigherThanThreshold,
							binFeedback_valueWhenActive = valueWhenActive, binFeedback_activeFeedbackMaxCycles = activeFeedbackDuration,
							binFeedback_idleWaitCycles = idleDurationAfterFeedback, binFeedback_cyclesForActivation = timeBeforeActivation,
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
	
	def updateGeneratorBaseCurrent(self, newCurrent_Ampere):
		self.currentGenerator_baseCurrent = float(newCurrent_Ampere)
		self.updateDimensionLinker()
	

if __name__ == "__main__":
	q = bioTweezerController()
	print(q.readBackParameter(("SUM_multiplierFor_z", "FPGA_floatValue")))
	q.initiateTweezers()
	q.disable_yz_Dimensions(True, True)
	
	#q.EnableConstantOutput((0.0, "generator_input"))
	
	#q.EnablePI(kp = -0.01, ki = 0.0, setpoint = (-0.1, "FPGA_floatValue"), limitLow=(-.999,"FPGA_floatValue"), limitHigh=(.999,"FPGA_floatValue"))
	
	#q.EnableBinaryFeedback((100e-7, "bead_position"),True, (0.2, "generator_input"), 0.2)#, 0.1, 0.3)
	
	q.plotReceivedData(1,elementsToRemove=["pid out", "z"], x = "FPGA_floatValue", y = "FPGA_floatValue")