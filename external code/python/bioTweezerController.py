
from tkinter import *
from tkinter import ttk
import numpy as np
import socket
import select
import time as t
from dimensionLinker import dimensionLinker
import matplotlib.pyplot as plt
from scipy.optimize import  least_squares
from functools import partial
import pandas as pd
from threading import Thread
from typing import Dict

def setupReception(ip, port):
	#get a socket for UDP transmission
	sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	#sock.setblocking(0)
	try:
		sock.bind((ip, port))
	except OSError as e:
		raise Exception(f"check if the selected IP {ip} is the IP of your computer (you might have to manually change the IP)") from e
		
	socket.setdefaulttimeout(1)
	return sock

def transmitCommand(sock, ip, port, command, waitForResponse = False, printTransmission = False):
	'''transmit a string or bite stream to the selected ip/port. It can also wait for a response message'''
	if(isinstance(command, str)):
		command = command.encode()
	sock.sendto(command, (ip, port))
	if(printTransmission):
		print("sent to ", ip, ": ", command)
	if(waitForResponse):
		return receive(sock, port)

def receive(sock, port, printReception = False):
	'''receive a string or byte string from the selected port.'''
	# ready = select.select([sock], [], [], timeout=1)
	try:
		received, address = sock.recvfrom(port)
	except socket.timeout:
		ready = select.select([sock], [], [], timeout=1)
		if ready[0]:
			received, address = sock.recvfrom(port)
		else:
			raise TimeoutError("No data received within the timeout period.")
	if(printReception):
		print("Received from", address, ":", received)
	return received
	
class fpgaRegister:
	'''
	class that handles data conversion between physical values and the raw values used inside the FPGA controller.
	it has a base dimension (the raw bit values inside the FPGA) and a preferred physical dimension (i.e. the
	dimension that the FPGA value represents). It uses a dimensionLinker to convert between dimensions, so you
	can also change/read the value of this object by feeding it a value in a different dimension, as long as
	it is connected to the base dimension
	'''
	def __init__(self, dimLinker : dimensionLinker, dimension, preferredConversionDimension = None, command = None):
		self.dimLinker : dimensionLinker = dimLinker
		self.dimension = dimension
		if preferredConversionDimension is None:
			preferredConversionDimension = dimension
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
		if isinstance(value, np.ndarray):
			return value.astype(int), startDimension	
		return int(value), startDimension
	@staticmethod
	def _clipValue(val : int, bitSize : int, isSigned : bool, recalculateValueFunction):
		bitsOutOfBound = val >> bitSize
		if (bitsOutOfBound != 0 and bitsOutOfBound != -1):
			maxVal = (1 << (bitSize-1)) - 1 if isSigned else (1 << bitSize) - 1
			minVal = -(1 << (bitSize-1)) if isSigned else 0
			if(val > maxVal):
				maxVal_unConverted = recalculateValueFunction(maxVal)
				print(f"warning: value too high! using Max value = {maxVal_unConverted}" )
				val = int(maxVal)
			elif(val < minVal):
				minVal_unConverted = recalculateValueFunction(minVal)
				print(f"warning: value too low! using Min value = {minVal_unConverted}" )
				val = int(minVal)
		return val
	def floatToFixedPoint(self, value, startDimension = None):
		#convert from a physical dimension to the corresponding FPGA value
		val, startDimension = self.convertValue(value, startDimension)
		if isinstance(val, int):
			val = fpgaRegister._clipValue(val, self.bitSize, self.isSigned, partial(self.dimLinker.convert, fromDimensions= self.dimension, toDimension= startDimension))
			if(len(self.command) > 1):
				return [val >> 16, val & 0xffff]
			return [val]
		for i in range(len(val)):
			val[i] = fpgaRegister._clipValue(val[i], 16, self.isSigned, partial(self.dimLinker.convert, fromDimensions= self.dimension, toDimension= startDimension))
		#in the FPGA, the 32bit registers are a bit messy, so we have to invert the 16bit registers
		val[::2], val[1::2] = val[1::2].copy(), val[::2].copy()
		return val

	
	def fixedPointToFloat(self, intValue, toDimension = None):
		#convert from a FPGA value to the corresponding value of the selected physical dimension
		if(len(self.command) > 2):
			intValue = np.array(intValue)
			#in the FPGA, the 32bit registers are a bit messy, so we have to invert the 16bit registers
			intValue[::2], intValue[1::2] = intValue[1::2].copy(), intValue[::2].copy()
			bitSize = self.bitSize // len(intValue)
			for i in range(len(intValue)):
				intValue[i] &= ((1<<bitSize) - 1)
				if (self.isSigned) and (intValue[i] >= (1 << (bitSize - 1))):
					intValue[i] -= (1 << bitSize)
		else:
			if(len(self.command) > 1):
				intValue = (intValue[0] << 16) + intValue[1]
			if isinstance(intValue, list):
				intValue = intValue[0]
			intValue &= ((1<<self.bitSize) - 1)
			if (self.isSigned) and (intValue >= (1 << (self.bitSize - 1))):
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
		self.dataStreamRunning = False
	
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
	sporadicDataValuesFromFPGA = {
		"sporadic data from the fpga"       : fpgaRegister(dimLink, "small_FPGA_register", "small_FPGA_register"),
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
		#this function determines the command indexes of each parameter, in the same way as the FPGA compiler
			#determines them. So, you don't have to keep track of the index of each parameter, as long as the
			#order in which they are inserted in ParametersForFPGA is consistent with the FPGA code
		offset = 1
		for (key,value) in self.ParametersForFPGA.items():
			for j in range(len(value.command)):
				value.command[j] = offset
				offset += 1
				
	def setParameters(self, **kwargs):
		#sets the specified parameters inside the FPGA. The input argument names must be contained inside
			#ParametersForFPGA. The values can be either a number (which will be interpreted as a value in
			#the default dimension for that parameter) or a tuple (number, dimension). In that case, the
			#function will convert the value in the appropriate dimension before sending it to the FPGA
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
								   (int(paramVals[j])&0xffff).to_bytes(2,'big'))
		self.sendCommand(commandList)
			
	def readBackParameter(self, *parameters):
		#reads back the requested parameters. *parameters is a list of strings, where each of them identifies a register of ParametersForFPGA.
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
	def readAllParameters(self):
		#reads all the parameters from the FPGA, and returns a dictionary with the parameter names as keys
		values = {}
		for param in self.ParametersForFPGA.keys():
			values[param] = self.readBackParameter(param)
		return values
	def sendCommand(self, commands, waitForResponse = True):
		#send one or multiple commands to the FPGA
		with setupReception(self.self_ip, self.parameterPort) as sock:
			if isinstance(commands, list):
				responses = [None] * len(commands)
				for i, command in enumerate(commands):
					responses[i] = transmitCommand(sock, self.fpga_ip, self.parameterPort, command, waitForResponse)
					if responses[i][0:4]==b'NACK':
						raise Exception(f"FPGA did not acknowledge command {i}: {responses[i]}. You might need to reset the FPGA")
				return responses
			return transmitCommand(sock, self.fpga_ip, self.parameterPort, commands, waitForResponse)
	slowDataWordSize = 32
	def getSlowDataDictionaryAndSize(self):
		#returns an empty dictionary for the slow data reception, and the length of the expected slow words
		slowData = {
			"startTimes": [],
			"configuration": [],
			"reachedThreshold": [],
			"timing": [],
		}
		return slowData, self.slowDataWordSize
	def addValueToSlowData(self, slowData, startTime, val):
		word_size = self.slowDataWordSize
		reachedThreshold = (val >> 28) & 1
		currentConfig = val >> 29 & 0x3
		val = val & 0x0fffffff
		if val >= (1 << (word_size - 1)):
			val -= (1 << word_size)
		slowData["startTimes"].append(startTime)
		slowData["configuration"].append(currentConfig)
		slowData["reachedThreshold"].append(reachedThreshold)
		slowData["timing"].append(val / self.fpga_controller_clock)

	def getDataStream_old(self, time = 1, **dimensions):
		#receive the data stream from the FPGA for the specified time (in seconds). The returned value is a dictionary
			#where the keys are the names of the different values sent by the FPGA (specified in dataValuesFromFPGA),
			#and the values are the lists of values received during the reception time.
			#you can specify the final dimension of the various signal (add to the declaration <signalName> = <desiredDimension>)
		with setupReception(self.self_ip, self.dataPort) as sock:
			retData : Dict[str, list]= {}
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
		
	def getDataStream(self, time = 1, **dimensions):
		#upgrade of getDataStream, with a reception that can have a variable amount of data. Data can be of 2 types: 
			# fast data: (fast because it is sent as soon as it is ready in the fpga), has a fixed size, but you can 
			#   have a transmission without this value
			# slow data: (slow because it is sent only if the fpga is already sending a fast data, or if the slow data 
			#   buffer is filling up), has a variable size, and can also be ommitted.
		with setupReception(self.self_ip, self.dataPort) as sock:
			fastData : Dict[str, list]= {}
			for name in self.dataValuesFromFPGA.keys():
				fastData[name] = []
			fastData["times"] = []
			slowData, slowWordSize = self.getSlowDataDictionaryAndSize()
			endTime = t.time() + time
			startTime = t.time()
			while t.time() < endTime:
				received, address = sock.recvfrom(2048)
				currentTime = t.time() - startTime#we'll add it to fastData["times"] only if we received some fast data
				#received[0] tells if fast/slow data is present, and how many slow words are present
				isThereFastData = received[0] & 0x1
				isThereSlowData = received[0] & 0x2				
				byteIdx = 1
				if(isThereFastData):
					fastData["times"].append(currentTime)
					for name, register in self.dataValuesFromFPGA.items():
						val = int(received[byteIdx+1] << 8) + int(received[byteIdx])
						if(val >= 0x8000):
							val = -0x10000 + val
						
						if name in dimensions.keys():
							fastData[name].append(register.fixedPointToFloat(val, dimensions[name]))
						else:
							fastData[name].append(register.fixedPointToFloat(val))
						byteIdx += 2
						
				if(isThereSlowData):
					nOfSlowWords = received[0] >> 2
					word_size = self.slowDataWordSize
					word_mask = (1 << slowWordSize) - 1
					bytesPerWord = (slowWordSize + 7) >> 3
					currentBit = 0
					for i in range(nOfSlowWords):
						val = (int.from_bytes(received[byteIdx:byteIdx+bytesPerWord], byteorder='little') >> currentBit) & word_mask
						currentBit += word_size
						byteIdx += (currentBit >> 3)
						currentBit = currentBit & 0x07
						self.addValueToSlowData(slowData, currentTime, val)
			return fastData, slowData
		
	def startDataStream(self, maxTime = 70, updateFunction = None, dataStreamPeriod = None, **dimensions):
		#start a thread dedicated to reading the datastream from the FPGA. It works
			#similarly to getDataStream, but it is not a blocking procedure, and you
			#don't have to specify the duration of the reading.Remember  that you're
			#supposed to close the thread (and so the data reception) with
			#stopDataStream, which also returns the read data.
			#you can execute a function at every reception of data (example, to update a
			#scatter plot in real time)
		if dataStreamPeriod is None:
			#default value
			dataStreamPeriod = 0x40000 / self.fpga_controller_clock
		sock = setupReception(self.self_ip, self.dataPort)
		try:
			self.dataStreamThread = Thread(target=self._dataStreamThreadRun, args=(sock,dataStreamPeriod,maxTime,updateFunction),kwargs= dimensions)
			self.dataStreamRunning = True
			self.dataStreamBuffer = {}
			self.slowData = {}
			self.dataStreamThread.start()
		except:
			try:
				sock.close()
			except:
				pass
	#FPGA controller clock
	fpga_controller_clock = 50e6																							#	Hz
	def _dataStreamThreadRun(self, sock, dataStreamPeriod, maxTime = 70, updateFunction = None, useFixedTimings = True, **dimensions):
		try:
			for name in self.dataValuesFromFPGA.keys():
				self.dataStreamBuffer[name] = []

			self.dataStreamBuffer["times"] = []
			self.slowData, slowWordSize = self.getSlowDataDictionaryAndSize()
			absoluteTime = t.time()
			startTime = 0
			maxendTime = absoluteTime + maxTime
			while self.dataStreamRunning:
				received, address = sock.recvfrom(2048)
				
				currentTime = t.time() - absoluteTime#we'll add it to fastData["times"] only if we received some fast data
				#received[0] tells if fast/slow data is present, and how many slow words are present
				isThereFastData = received[0] & 0x1
				isThereSlowData = received[0] & 0x2
				byteIdx = 1
				
				if(isThereFastData):
					if useFixedTimings:
						self.dataStreamBuffer["times"].append(startTime)
						startTime += dataStreamPeriod
					else:
						self.dataStreamBuffer["times"].append(currentTime)
					for name, register in self.dataValuesFromFPGA.items():
						val = int(received[byteIdx+1] << 8) + int(received[byteIdx])
						if(val >= 0x8000):
							val = -0x10000 + val
							
						if name in dimensions.keys():
							self.dataStreamBuffer[name].append(register.fixedPointToFloat(val, dimensions[name]))
						else:
							self.dataStreamBuffer[name].append(register.fixedPointToFloat(val))
						byteIdx += 2
				
				if(isThereSlowData):
					nOfSlowWords = received[0] >> 2
					word_size = self.slowDataWordSize
					word_mask = (1 << slowWordSize) - 1
					bytesPerWord = (slowWordSize + 7) >> 3
					currentBit = 0
					for i in range(nOfSlowWords):
						val = (int.from_bytes(received[byteIdx:byteIdx+bytesPerWord], byteorder='little') >> currentBit) & word_mask
						currentBit += word_size
						byteIdx += (currentBit >> 3)
						currentBit = currentBit & 0x07
						self.addValueToSlowData(self.slowData, currentTime, val)

				if updateFunction is not None:
					updateFunction(self.dataStreamBuffer, self.slowData)
				if t.time() > maxendTime:
					self.dataStreamRunning = False
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
			return self.dataStreamBuffer, self.slowData
		print("start the stream first!")
		return {}
	
	def getArraysFromDataStreamBuffer(self):
		
		t = np.array(self.dataStreamBuffer["times"])
		pts = t.shape[0]-2#todo there's problems when the current row of dataStreamBuffer is being filled, t, can have one more element compared to the rest of the columns
		y = np.zeros((pts, 3), dtype=np.float64)
		y[:,0] = np.array(self.dataStreamBuffer["x"][:pts])
		y[:,1] = np.array(self.dataStreamBuffer["y"][:pts])
		y[:,2] = np.array(self.dataStreamBuffer["z"][:pts])
		if len(t) != len(y):
			m = min(len(t), len(y))
			t = t[:m]
			y = y[:m,:]
		
		return(t, y)

		
	def plotReceivedData(self, time = 3, elementsToShow = None, elementsToRemove = None, **dimensions):
		#receive a dataStream and print the values (or some of the values) received.
		data = self.getDataStream(time, **dimensions)[0]
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
		return data
		
class bioTweezerController(fpgaHandler):
	
	dimLink = dimensionLinker()
	dimLink.addDimension("bead_position", "m")
	dimLink.addDimension("bead_positionSquare_unshifted", "m^2")
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
	dimLink.addDimension("FPGA_smallTimeRegister", "bit", bitSize = 19, isSigned = False)
	dimLink.addDimension("FPGA_bf_cfg", bitSize = 1, isSigned = False)
	dimLink.addDimension("FPGA_bf_transmissionCfg", bitSize = 2, isSigned = False)
	dimLink.addDimension("FPGA_usedInputCfg", bitSize = 3, isSigned = False)
	dimLink.addDimension("FPGA_bitShift", bitSize = 8, isSigned = False, defaultValue=0)
	dimLink.addDimension("control_voltage", "V")
	dimLink.addDimension("generator_input", "V")
	dimLink.addDimension("generator_current", "I")
	dimLink.addDimension("generator_debugVoltage", "V")
	dimLink.addDimension("laserPower", "W")
	dimLink.addDimension("time", "s")
	dimLink.addDimension("piezo_voltage", "V")
	dimLink.addDimension("byte", "B", bitSize = 8, isSigned = False)
	dimLink.addDimension("word", "B", bitSize = 32, isSigned = False)
	dimLink.addDimension("edge_register", bitSize = 64)
	dimLink.addDimension("FPGA_RampFloatValue", "[adimensional]")
	dimLink.addDimension("q_register", "bit", bitSize = 64)
	dimLink.addDimension("m_register", "bit", bitSize = 64)
	...

	def initializeDimensionLinker(self):
		self.dimLink = bioTweezerController.dimLink
			
		
		
	
	def __init__(self, **kwargs):
		
		self.initializeDimensionLinker()
		self.dataValuesFromFPGA = {
			"pid out"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"x"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "FPGA_signalRegister"),
			"y"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "FPGA_signalRegister"),
			"z"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "FPGA_signalRegister"),
			"x^2"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare_unshifted"),
			"y^2"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare_unshifted"),
			"z^2"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_positionSquare_unshifted"),
		}
		self.ParametersForFPGA = {#follow the FPGA order
			#large parameters
			"transmissionTime"		: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			"kp"					: fpgaRegister(self.dimLink, "FPGA_coeffRegister", "FPGA_floatValue"),
			"ki"					: fpgaRegister(self.dimLink, "FPGA_coeffRegister", "FPGA_floatValue"),
			"SUM_multiplierFor_div" : fpgaRegister(self.dimLink, "FPGA_largeCoeffRegister", "FPGA_floatValue"),
			"SUM_multiplierFor_z"	: fpgaRegister(self.dimLink, "FPGA_largeCoeffRegister", "FPGA_floatValue"),
			"toggleEnableTime"		: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			# "binFeedback_activeFeedbackMaxCycles"	: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			# "binFeedback_idleWaitCycles"			: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			# "binFeedback_cyclesForActivation"		: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			"binFeedback_maxTimeOn_x0"		: fpgaRegister(self.dimLink, "FPGA_timeRegister", "time"),
			"binFeedback_preAverageTime"	: fpgaRegister(self.dimLink, "FPGA_smallTimeRegister", "time"),
			"offset_ms3210"					: fpgaRegister(self.dimLink, "m_register", "m_register"),
		
			"offset_edgePoints3210"			: fpgaRegister(self.dimLink, "edge_register", "edge_register"),
			"offset_qs3210"					: fpgaRegister(self.dimLink, "q_register", "q_register"),
			
			#small parameters
			"outWhenPiDisabled"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"setpoint"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"limitLow"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"limitHigh"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"SUM_offsetFor_div"				: fpgaRegister(self.dimLink, "FPGA_SUMsignalRegister", "QPD_output"),
			"SUM_offsetFor_z"				: fpgaRegister(self.dimLink, "FPGA_SUMsignalRegister", "QPD_output"),
			"x_offset"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"y_offset"						: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"useToggleEnable"				: fpgaRegister(self.dimLink, "FPGA_bitRegister", "FPGA_bitRegister"),
			"usedInput"						: fpgaRegister(self.dimLink, "FPGA_usedInputCfg", "FPGA_usedInputCfg"),
			# "xDiff_offset"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "QPD_output"),
			"yDiff_offset"					: fpgaRegister(self.dimLink, "FPGA_signalRegister", "QPD_output"),			
			"binFeedback_valueWhenIn_x1"	: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"binFeedback_valueWhenIn_x0"	: fpgaRegister(self.dimLink, "FPGA_signalRegister", "generator_input"),
			"binFeedback_cfg"				: fpgaRegister(self.dimLink, "FPGA_bf_cfg", "FPGA_bf_cfg"),
			"binFeedback_x1"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"binFeedback_x0"				: fpgaRegister(self.dimLink, "FPGA_signalRegister", "bead_position"),
			"binFeedback_transmissionCfg"   : fpgaRegister(self.dimLink, "FPGA_bf_transmissionCfg", "FPGA_bf_transmissionCfg"),
			"squaresShift"					: fpgaRegister(self.dimLink, "FPGA_bitShift", "FPGA_bitShift"),
		}
		super(bioTweezerController, self).__init__(**kwargs)
		self.reset()
		# self.updateDimensionLinker()
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
	currentGenerator_ItoDebugV = - 2 / 100e-3 																				#	V/A
	currentGenerator_baseCurrent = 100e-3																					#	A
	currentGenerator_minCurrent = 0e-3																						#	A
	currentGenerator_maxCurrent = 250e-3																					#	A
		
	#parameters of the laser
	laser_currentToLaserPower = 340e-3 / 730e-3																				#	W/A
	
	#conversion from bead position to qpd voltage output
	sensitivity_x = sensitivity_y = 1e-3 / 1e-9																				#	[adimensional]/m
	sensitivity_z = 1e-3 / 1e-9																								#	V/m
	piezo_V_to_distance = 2e-6 / 1																							#	m/V
	
	#distance ranges (i.e. the values of x and y when their respective DIFF signals are == SUM)
	range_x = range_y = 1 / sensitivity_x																					#	m
	#value of the SUM signal when the bead is at the center of the laser (z == 0)
	SUM_at_z0 = 0.1																											#	V
	SUM_multiplierForDIFF_SUM = range_x/range_x																				#	[adimensional]
	
	#values found during calibration. Hence, let's keep them as adimensional values,
		#since we don't care about the actual value in the correct dimension
	x_offset = 0																											#	[adimensional]
	y_offset = 0																											#	[adimensional]
	xDiff_offset = 0																										#	[adimensional]
	yDiff_offset = 0																										#	[adimensional]

		
	# def initiateTweezers(self, singleCalibrationTime = 1, usedLaserPowers = [(n, "generator_current") for n in np.linspace(50e-3, 200e-3,6)], useXYDIFF_offset = True, useSUM_offset = True, checkStiffness = True):
	# 	#do some calibration measures
	# 	self.getCalibrationValues(singleCalibrationTime = singleCalibrationTime, usedLaserPowers = usedLaserPowers,
	# 						  useXYDIFF_offset = useXYDIFF_offset, useSUM_offset = useSUM_offset)
		
	# 	#set a lot of parameters in the FPGA
	# 	mz = 1 / (self.range_x * self.sensitivity_z * self.ADC_sumAttenuation)
	# 	self.setParameters(
	# 		SUM_multiplierFor_z = (mz, "FPGA_floatValue"),
	# 		SUM_offsetFor_z = (-self.SUM_at_z0, "QPD_output"),
			
	# 		SUM_multiplierFor_div = (self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
			
	# 		SUM_offsetFor_div = (self.SUM_offsetFor_div, "FPGA_floatValue"),
	# 		x_offset = (self.x_offset, "FPGA_floatValue"),
	# 		# xDiff_offset = (self.xDiff_offset, "FPGA_floatValue"),
	# 		y_offset = (self.y_offset, "FPGA_floatValue"),
	# 		yDiff_offset = (self.yDiff_offset, "FPGA_floatValue"),
	# 		outWhenPiDisabled = (0, "generator_input"),
	# 	)

		
	# 	if checkStiffness:
	# 		print(f'calculated stiffness: {self.calcStiffness(singleCalibrationTime, directions = ["x", "y"])*1e3} pN/nm')

	# 	# if(self.DAC_gain > 0):
	# 	# 	self.setParameters(
	# 	# 		limitLow = (self.currentGenerator_minCurrent, "generator_current"),
	# 	# 		limitHigh = (self.currentGenerator_maxCurrent, "generator_current"),
	# 	# 	)
	# 	# else:
	# 	# 	self.setParameters(
	# 	# 		#high and low limits are switched, because the DAC amplifier has a negative gain
	# 	# 		limitLow = (self.currentGenerator_maxCurrent, "generator_current"),
	# 	# 		limitHigh = (self.currentGenerator_minCurrent, "generator_current"),
	# 	# 	)
		
	
	def calcStiffness(self, time = 3, temperature = 300, directions = ["x", "y"]):
		dataFromFPGA = self.getDataStream(time)[0]
		signals = np.array([dataFromFPGA[direction] for direction in directions])
		squaredSignals = np.array([dataFromFPGA[direction+"^2"] for direction in directions])
		# signals = self.dimLink.convert(signals, "FPGA_floatValue", "bead_position")
		squareShift = self.readBackParameter("squaresShift")
		squaredSignals = self.dimLink.convert([squaredSignals, -squareShift], ["bead_positionSquare_unshifted", "FPGA_bitShift"], "bead_positionSquare")
		return bioTweezerController.laserStiffnessFromPositionSignal(signals, squaredSignals, temperature)

	@staticmethod
	def laserStiffnessFromPositionSignal(signal, squaredSignal, temperature = 300):
		#calculate the stiffness of the trap based on the variation on the bead position
		variance = np.mean(squaredSignal, axis=1) - np.mean(signal, axis=1)**2
		return bioTweezerController.laserStiffnessFromVariance(variance, temperature)
		
	@staticmethod
	def laserStiffnessFromVariance(variance, temperature = 300):
		kBoltzman = 1.3806504e-23
		return kBoltzman * temperature / variance
	
	def _get_zOffset(self, intensity = (0, "FPGA_floatValue"), time = 0.2):
		self.EnableConstantOutput(intensity)
		self.setParameters(
			SUM_multiplierFor_z = (- self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),#value to normalize SUM to respect to XDIFF and YDIFF (the amplification circuit has different gains for X/YDIFF and SUM)
			SUM_multiplierFor_div = (- self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
			SUM_offsetFor_z = (0, "FPGA_floatValue"),
			SUM_offsetFor_div = (0, "FPGA_floatValue"),
		)
		z = - np.mean(self.getDataStream(time)[0]["z"])
		self.reset()
		z = self.dimLink.convert(z, self.dataValuesFromFPGA["z"].preferredConversionDimension, "FPGA_signalRegister")
		z = self.dimLink.convert(z, "FPGA_SUMsignalRegister", "QPD_output")
		return z
	def initializeTweezers_noCalibration(self):
		self.setParameters(
			x_offset = (0, "FPGA_floatValue"),
			y_offset = (0, "FPGA_floatValue"),
			# xDiff_offset = (0, "FPGA_floatValue"),
			yDiff_offset = (0, "FPGA_floatValue"),
			SUM_multiplierFor_z = (- self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),#value to normalize SUM to respect to XDIFF and YDIFF (the amplification circuit has different gains for X/YDIFF and SUM)
			SUM_multiplierFor_div = ( self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
			SUM_offsetFor_z = (0, "FPGA_floatValue"),
			SUM_offsetFor_div = (0, "FPGA_floatValue"),
			offset_ms3210 = (np.array([0,0,0,0]), "m_register"),
			offset_edgePoints3210 = (np.array([0,0,0,0]), "edge_register"),
			offset_qs3210 = (np.array([0,0,0,0]), "q_register"),
		)
	# def getCalibrationValues(self, singleCalibrationTime = 0.3, usedLaserPowers = [(n, "generator_current") for n in np.linspace(50e-3, 200e-3,6)], useXYDIFF_offset = True, useSUM_offset = True):
	# 	self.set_zOffset(singleCalibrationTime)
	# 	#calculate the offsets for x and y
	# 	SUM = np.zeros(len(usedLaserPowers))
	# 	XDIFF = np.zeros(len(usedLaserPowers))
	# 	YDIFF = np.zeros(len(usedLaserPowers))
	# 	#reset every offset value, even for z, since we'll be using it to read the SUM signal
	# 	self.setParameters(
	# 		x_offset = (0, "FPGA_floatValue"),
	# 		y_offset = (0, "FPGA_floatValue"),
	# 		# xDiff_offset = (0, "FPGA_floatValue"),
	# 		yDiff_offset = (0, "FPGA_floatValue"),
	# 		SUM_multiplierFor_z = (- self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),#value to normalize SUM to respect to XDIFF and YDIFF (the amplification circuit has different gains for X/YDIFF and SUM)
	# 		SUM_multiplierFor_div = (- self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
	# 		SUM_offsetFor_z = (0, "FPGA_floatValue"),
	# 		SUM_offsetFor_div = (0, "FPGA_floatValue"),
	# 	)
	# 	debug = False
	# 	if debug:
	# 		global xd, yd, sm
	# 		SUM = sm
	# 		XDIFF = xd
	# 		YDIFF = yd
	# 		print("using debug calibration")
	# 	else:
	# 		#let's get some values for SUM, XDIFF and YDIFF
	# 		for i, intensity in enumerate(usedLaserPowers):
	# 			self.EnableConstantOutput(intensity)
				
	# 			t.sleep(0.01)#wait for the system to stabilize
	# 			data = self.getDataStream(singleCalibrationTime)[0]
				
	# 			SUM[i] = - np.mean(data["z"])
	# 			SUM[i] = self.dimLink.convert(SUM[i], self.dataValuesFromFPGA["z"].preferredConversionDimension, "FPGA_floatValue")#convert the bead position into an adimensional value
	# 			XDIFF[i] = np.mean(data["x"])
	# 			XDIFF[i] = self.dimLink.convert(XDIFF[i], self.dataValuesFromFPGA["x"].preferredConversionDimension, "FPGA_floatValue") * SUM[i]#x = XDIFF / SUM => XDIFF = x * SUM
	# 			YDIFF[i] = np.mean(data["y"])
	# 			YDIFF[i] = self.dimLink.convert(YDIFF[i], self.dataValuesFromFPGA["y"].preferredConversionDimension, "FPGA_floatValue") * SUM[i]

	# 	#now, assuming that the formula for calculating x from SUM and XDIFF is
	# 		#x = (XDIFF - o_xdiff) / (SUM - o_sum ) - o_x
	# 		#and knowing that x ~ 0, let's estimate the 3 offsets by minimizing the error of the formula on the values we obtained
	# 		#(same thing for y, with the condition that o_sum is the same for both x and y)
	# 	#let's group together all the data for X and Y
	# 	xydiff = np.append(XDIFF, YDIFF)
	# 	sumsum = np.append(SUM, SUM)
	# 	#we might disable some offsets in case we want a simpler offset calculation
	# 	sumOffsetPosition = 1 if useXYDIFF_offset else 0
	# 	xOffsetPosition = sumOffsetPosition + (1 if useSUM_offset else 0)
	# 	def fxy(oo):
	# 		o = np.array([[oo[0]]*len(XDIFF) + [oo[1]]*len(YDIFF),
	# 					  [oo[2]]*len(xydiff),
	# 					  [oo[3]]*len(XDIFF) + [oo[4]]*len(YDIFF)])
	# 		return (xydiff - (o[0] if useXYDIFF_offset else 0)) - (sumsum - (o[1] if useSUM_offset else 0)) * o[2]
	# 			#when all the offsets are enabled, this formula equals to (xydiff - o[0]) - (sumsum - o[1]) * o[2].
	# 			#minimizing this formula is the same as minimizing		( (xydiff - o[0]) / (sumsum - o[1]) - o[2] ),
	# 			#but it is more stable since it doesn't have any variable in the denominator
		
	# 	solution = least_squares(fxy, np.array([0,0,0,0,0]))

	# 	self.xDiff_offset = solution.x[0]
	# 	self.yDiff_offset = solution.x[1]
	# 	self.SUM_offsetFor_div = -solution.x[2]
	# 	self.x_offset = solution.x[3]
	# 	self.y_offset = solution.x[4]
	# 	print(solution)
				
	
	def set_zOffset(self, time = 0.2):
		self.SUM_at_z0 = self._get_zOffset(time=time)
	
	def setReset(self, reset = 1):
		self.sendCommand([b"PICL000"+reset.to_bytes(1, 'big')])
	def setMode(self, mode = 1):
		if isinstance(mode, str):
			mode = {"constant" : 0, "PI" : 1, "binaryFeedback" : 2}[mode]
		self.sendCommand([b"PIEN000"+mode.to_bytes(1, 'big')])
		self.mode = mode
	def reset(self):
		self.sendCommand([b"PICL0001", b"PIEN0000"])
		self.mode = 0
	def EnableConstantOutput(self, output = None):
		self.sendCommand([b"PICL0001"])
		if output is None:
			self.setParameters(useToggleEnable = False)
		else:
			self.setParameters(outWhenPiDisabled = output, useToggleEnable = False)
		self.sendCommand([b"PICL0000", b"PIEN0000"])
		self.mode = 0
	def EnablePI(self, **kwargs):
		self.sendCommand([b"PICL0001"])
		self.setParameters(useToggleEnable = False, **kwargs)
		self.sendCommand([b"PICL0000", b"PIEN0001"])
		self.mode = 1
		
	def EnableBinaryFeedback(self, **kwargs):
		self.sendCommand([b"PICL0001"])
		self.setParameters(useToggleEnable = False, **kwargs)
		self.sendCommand([b"PICL0000", b"PIEN0002"])
		self.mode = 2

	def updateGeneratorBaseCurrent(self, newCurrent_Ampere):
		self.currentGenerator_baseCurrent = float(newCurrent_Ampere)
		self.updateDimensionLinker()
	
	@staticmethod
	def segmentedCoefficient(x,y, finalLength = None):
		'''
			transforms the segmented function (x,y) into the list of ramps y[i](x) = q[i] + (s[i] - x * m[i]),
			s[i] is the start input value of the ramp
			q[i] is the start output value of the ramp ( y[i](s[i]) = q[i])
			m[i] is the slope of the ramp
		'''
		ordered = np.argsort(x)
		x = x[ordered]
		y = y[ordered]
		a = x[0:len(x)-1]
		b = x[1:]
		c = y[0:len(y)-1]
		d = y[1:]
		
		m = (d-c) / (b-a)
		s = a
		q = c

		if finalLength is not None:
			s = np.append(s,[-1] * (finalLength - len(m)))
			q = np.append(q,[0] * (finalLength - len(m)))
			m = np.append(m,[0] * (finalLength - len(m)))

		return (s,q,m)
	
	def SetOffsetLinearizer(self, singleCalibrationTime = 1, usedLaserPowers = [(n, "generator_current") for n in np.linspace(50e-3, 250e-3,4)]):
		maxSamples = 4
		if len(usedLaserPowers) > maxSamples+1:
			print(f"WARNING: the number of used laser powers ({len(usedLaserPowers)}) is greater than the maximum number of samples ({maxSamples}). The calibration will be done with only {maxSamples} samples.")
			usedLaserPowers = usedLaserPowers[:(maxSamples+1)]
		#calculate the offsets for x and y
		SUM = np.zeros(len(usedLaserPowers))
		XDIFF = np.zeros(len(usedLaserPowers))
		#reset every offset value, even for z, since we'll be using it to read the SUM signal
		self.setParameters(
			x_offset = (0, "FPGA_floatValue"),
			y_offset = (0, "FPGA_floatValue"),
			yDiff_offset = (0, "FPGA_floatValue"),
			SUM_multiplierFor_z = (1, "FPGA_floatValue"),
			SUM_multiplierFor_div = (- self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
			SUM_offsetFor_z = (0, "FPGA_floatValue"),
			SUM_offsetFor_div = (0, "FPGA_floatValue"),
			offset_ms3210 = (np.array([0,0,0,0]), "m_register"),
			offset_edgePoints3210 = (np.array([0,0,0,0]), "edge_register"),
			offset_qs3210 = (np.array([0,0,0,0]), "q_register"),
		)
		for i, intensity in enumerate(usedLaserPowers):
			self.EnableConstantOutput(intensity)
			
			t.sleep(0.01)#wait for the system to stabilize
			data = self.getDataStream(singleCalibrationTime)[0]
			sum = self.dimLink.convert(np.array(data["z"]), self.dataValuesFromFPGA["z"].preferredConversionDimension, "FPGA_floatValue")
			xdiff = self.dimLink.convert(np.array(data["x"]), self.dataValuesFromFPGA["x"].preferredConversionDimension, "FPGA_floatValue") * sum * (self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation)
			SUM[i] = np.mean(sum)
			XDIFF[i] = np.mean(xdiff)

		# SUM, XDIFF = np.array([0.08467611, 0.17313996]), np.array([0.00382965, 0.00383945])
		(s,q,m) = bioTweezerController.segmentedCoefficient(SUM, XDIFF, maxSamples)
		
		
		self.setParameters(
			offset_edgePoints3210 = (s, "FPGA_SUMfloatValue"),
			offset_qs3210 = (q, "FPGA_floatValue"),
			offset_ms3210 = (m, "FPGA_RampFloatValue"),
			SUM_multiplierFor_z = (1, "FPGA_floatValue"),
			SUM_multiplierFor_div = (- self.SUM_multiplierForDIFF_SUM * self.ADC_xyAttenuation / self.ADC_sumAttenuation, "FPGA_floatValue"),
		)

	@staticmethod
	def updateDimensionLinker():
		bioTweezerController.dimLink.addConnection("QPD_output", "xy_voltage", dimensionLinker.gainFunctions(bioTweezerController.ADC_xyAttenuation))
		bioTweezerController.dimLink.addConnection("QPD_output", "sum_voltage", dimensionLinker.gainFunctions(bioTweezerController.ADC_sumAttenuation))
		bioTweezerController.dimLink.addConnection("xy_voltage", "FPGA_floatValue", dimensionLinker.gainFunctions(bioTweezerController.ADC_voltageToFpgaInput))
		bioTweezerController.dimLink.addConnection("sum_voltage", "FPGA_SUMfloatValue", dimensionLinker.gainFunctions(bioTweezerController.ADC_voltageToFpgaInput))
		bioTweezerController.dimLink.addConnection("FPGA_floatValue", "FPGA_signalRegister", dimensionLinker.gainFunctions(2**15))
		bioTweezerController.dimLink.addConnection("FPGA_SUMfloatValue", "FPGA_SUMsignalRegister", dimensionLinker.gainFunctions(2**15))
		bioTweezerController.dimLink.addConnection("FPGA_floatValue", "FPGA_coeffRegister", dimensionLinker.gainFunctions(2**24))
		bioTweezerController.dimLink.addConnection("FPGA_floatValue", "FPGA_largeCoeffRegister", dimensionLinker.gainFunctions(2**22))
		bioTweezerController.dimLink.addConnection("FPGA_floatValue", "control_voltage", dimensionLinker.gain_n_shiftFunctions(bioTweezerController.DAC_fpgaOuputToVoltage, bioTweezerController.DAC_offset))
		bioTweezerController.dimLink.addConnection("control_voltage", "generator_input", dimensionLinker.shift_n_gainFunctions(-bioTweezerController.DAC_offset, bioTweezerController.DAC_gain))
		bioTweezerController.dimLink.addConnection("generator_input", "generator_current", dimensionLinker.gain_n_shiftFunctions(bioTweezerController.currentGenerator_inputVtoI, bioTweezerController.currentGenerator_baseCurrent))
		bioTweezerController.dimLink.addConnection("generator_current", "generator_debugVoltage", dimensionLinker.gainFunctions(bioTweezerController.currentGenerator_ItoDebugV))
		bioTweezerController.dimLink.addConnection("generator_current", "laserPower", dimensionLinker.gainFunctions(bioTweezerController.laser_currentToLaserPower))
		bioTweezerController.dimLink.addConnection("FPGA_floatValue", "bead_position", dimensionLinker.gainFunctions(bioTweezerController.range_x))
		bioTweezerController.dimLink.addConnection("bead_position", "bead_positionSquare_unshifted", dimensionLinker.squareFunctions())
		bioTweezerController.dimLink.addMultiConnection(["bead_positionSquare_unshifted", "FPGA_bitShift", "bead_positionSquare"], dimensionLinker.shift2Functions("bead_positionSquare_unshifted", "FPGA_bitShift", "bead_positionSquare"))
		bioTweezerController.dimLink.addConnection("piezo_voltage", "bead_position", dimensionLinker.gainFunctions(bioTweezerController.piezo_V_to_distance))
		bioTweezerController.dimLink.addConnection("time", "FPGA_timeRegister", dimensionLinker.gainFunctions(fpgaHandler.fpga_controller_clock))
		bioTweezerController.dimLink.addConnection("time", "FPGA_smallTimeRegister", dimensionLinker.gainFunctions(fpgaHandler.fpga_controller_clock))
		bioTweezerController.dimLink.addConnection("FPGA_floatValue", "q_register", dimensionLinker.gainFunctions(2**15))
		bioTweezerController.dimLink.addConnection("FPGA_RampFloatValue", "m_register", dimensionLinker.gainFunctions(2**13))
		bioTweezerController.dimLink.addConnection("FPGA_SUMfloatValue", "edge_register", dimensionLinker.gainFunctions(2**15))
		bioTweezerController.dimLink.addMultiConnection(["FPGA_SUMfloatValue", "FPGA_RampFloatValue", "FPGA_floatValue"], dimensionLinker.monomialFunctions(["FPGA_SUMfloatValue", "FPGA_RampFloatValue"], ["FPGA_floatValue"]))
		bioTweezerController.dimLink.checkForLoops()
	
	dimLink.addConnection("QPD_output", "xy_voltage", dimensionLinker.gainFunctions(ADC_xyAttenuation))
	dimLink.addConnection("QPD_output", "sum_voltage", dimensionLinker.gainFunctions(ADC_sumAttenuation))
	dimLink.addConnection("xy_voltage", "FPGA_floatValue", dimensionLinker.gainFunctions(ADC_voltageToFpgaInput))
	dimLink.addConnection("sum_voltage", "FPGA_SUMfloatValue", dimensionLinker.gainFunctions(ADC_voltageToFpgaInput))
	dimLink.addConnection("FPGA_floatValue", "FPGA_signalRegister", dimensionLinker.gainFunctions(2**15))
	dimLink.addConnection("FPGA_SUMfloatValue", "FPGA_SUMsignalRegister", dimensionLinker.gainFunctions(2**15))
	dimLink.addConnection("FPGA_floatValue", "FPGA_coeffRegister", dimensionLinker.gainFunctions(2**24))
	dimLink.addConnection("FPGA_floatValue", "FPGA_largeCoeffRegister", dimensionLinker.gainFunctions(2**22))
	dimLink.addConnection("FPGA_floatValue", "control_voltage", dimensionLinker.gain_n_shiftFunctions(DAC_fpgaOuputToVoltage, DAC_offset))
	dimLink.addConnection("control_voltage", "generator_input", dimensionLinker.shift_n_gainFunctions(-DAC_offset, DAC_gain))
	dimLink.addConnection("generator_input", "generator_current", dimensionLinker.gain_n_shiftFunctions(currentGenerator_inputVtoI, currentGenerator_baseCurrent))
	dimLink.addConnection("generator_current", "generator_debugVoltage", dimensionLinker.gainFunctions(currentGenerator_ItoDebugV))
	dimLink.addConnection("generator_current", "laserPower", dimensionLinker.gainFunctions(laser_currentToLaserPower))
	dimLink.addConnection("FPGA_floatValue", "bead_position", dimensionLinker.gainFunctions(range_x))
	dimLink.addConnection("bead_position", "bead_positionSquare_unshifted", dimensionLinker.squareFunctions())
	dimLink.addMultiConnection(["bead_positionSquare_unshifted", "FPGA_bitShift", "bead_positionSquare"], dimensionLinker.shift2Functions("bead_positionSquare_unshifted", "FPGA_bitShift", "bead_positionSquare"))
	dimLink.addConnection("piezo_voltage", "bead_position", dimensionLinker.gainFunctions(piezo_V_to_distance))
	dimLink.addConnection("time", "FPGA_timeRegister", dimensionLinker.gainFunctions(fpgaHandler.fpga_controller_clock))
	dimLink.addConnection("time", "FPGA_smallTimeRegister", dimensionLinker.gainFunctions(fpgaHandler.fpga_controller_clock))
	
	dimLink.addConnection("FPGA_floatValue", "q_register", dimensionLinker.gainFunctions(2**15))
	dimLink.addConnection("FPGA_RampFloatValue", "m_register", dimensionLinker.gainFunctions(2**13))
	dimLink.addConnection("FPGA_SUMfloatValue", "edge_register", dimensionLinker.gainFunctions(2**15))
	dimLink.addMultiConnection(["FPGA_SUMfloatValue", "FPGA_RampFloatValue", "FPGA_floatValue"], dimensionLinker.monomialFunctions(["FPGA_SUMfloatValue", "FPGA_RampFloatValue"], ["FPGA_floatValue"]))
	# dimLink.plot()
	dimLink.checkForLoops()
	

if __name__ == "__main__":	
	bt = bioTweezerController()
	
	SUM, XDIFF = np.array([0.0846253959693719, 0.17307535807291666, 0.2614683843963775]), np.array([0.000,0.000,0])
	(s,q,m) = bioTweezerController.segmentedCoefficient(SUM, XDIFF, 4)

	bt.setParameters(
		offset_edgePoints3210 = (s, "FPGA_SUMfloatValue"),
		offset_qs3210 = (q, "FPGA_floatValue"),
		offset_ms3210 = (m, "FPGA_RampFloatValue"),
		SUM_multiplierFor_z = (1, "FPGA_floatValue"),
		SUM_multiplierFor_div = (- bt.SUM_multiplierForDIFF_SUM * bt.ADC_xyAttenuation / bt.ADC_sumAttenuation, "FPGA_floatValue"),
		transmissionTime = (1e-3, "time"),
	)

	data = bt.getDataStream(5)[0]
	x=np.array(data["x"])
	xdiff=np.array(data["y"])
	sum=np.array(data["z"])
	plt.plot(x, label="x")
	plt.plot(xdiff, label="xdiff")
	plt.plot(sum, label="sum")
	plt.plot(-xdiff/sum*.7*2**15, label="xdiff/sum")
	plt.legend()
	plt.grid()

