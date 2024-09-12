from tkinter import *
from tkinter import filedialog, ttk
import matplotlib.lines
import matplotlib.pyplot as plt
try:
     import nidaqmx
     from nidaqmx.constants import (
     LineGrouping, AcquisitionType, Edge, Signal)

     import nidaqmx.constants
     from nidaqmx.stream_writers import (AnalogMultiChannelWriter, AnalogSingleChannelWriter)
     from nidaqmx.stream_readers import (AnalogMultiChannelReader, AnalogSingleChannelReader)
     nidaq_status = 0
except:
     nidaq_status = -1

import numpy as np
import time
from typing import List, Tuple
from typing_extensions import Self

import matplotlib
matplotlib.use('TkAgg')
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
from matplotlib.figure import Figure

import pandas as pd
import re
import os
from types import SimpleNamespace
from functools import partial
try:
     from bioTweezerController import bioTweezerController
except:
     print('Could not import bio controller library')
     

class ProtocolNode:
     def __init__(self:Self, wave_type:List[str], amp:List[float], freq:List[float], off:List[float], duration:float, rate:float, n_chans:int=2):
          self.wave_type = wave_type
          self.amplitude = amp
          self.frequency = freq
          self.offset = off
          self.duration = duration
          self.data_rate = rate
          self.n_channels = n_chans


     def duplicate(self:Self):
          p = ProtocolNode(self.wave_type, self.amplitude, self.frequency, self.offset, self.duration, self.data_rate, self.n_channels)
          return p
     
     def compute_ao_buffer_from_parameters(self:Self)->np.ndarray:
         t = self.duration
         rate = self.data_rate

         npn = int(t * rate)
         if npn < 5:
              print('Too few points to compose a wave!!')
              return np.zeros((self.n_channels, 1000))
         
         buf = np.zeros((self.n_channels, npn))

         for i in range(self.n_channels):
              tp = self.wave_type[i]
              off = self.offset[i]
              freq = self.frequency[i]
              amp = self.amplitude[i]

              #print(f'Node t={self.duration}, rate={self.data_rate}, type={tp}, amplitude={amp}, frequency={freq}, offset={off}')
              if tp == 'constant': # constant
                   buf[i,:] +=  off
                   print(f'Offset: {off}')
              elif tp == 'sine': #sine
                   npn_cycle = int(self.data_rate / freq)
                   cycles = int(npn / npn_cycle)
                   phase = -np.pi/2
                   buf_one_cycle = amp/2 * np.sin(2*np.pi  * np.arange(0.0, npn_cycle) / float(npn_cycle) + phase) + amp /2.0 + off

                   for j in range(cycles):
                        buf[i, j*npn_cycle : j*npn_cycle + npn_cycle] = buf_one_cycle
                   
                   last_points = buf.shape[1] - cycles * npn_cycle
                   if last_points > 0:
                         buf[i, cycles * npn_cycle:] = buf_one_cycle[: last_points]

              elif tp == 'ramp': #ramp
                   npn_cycle = int(self.data_rate / freq)
                   # try to force npn_cycle in multiple of 4
                   m4 = int(npn_cycle / 4)
                   npn_cycle = 4 * m4
                   cycles = int(npn / npn_cycle)
                   buf_one_cycle = np.zeros((1, npn_cycle), dtype=np.float64)
                   #buf_one_cycle[0,:m4] = np.arange(0.0, float(m4),1.0) / (float(m4-1.0)) * amp/2
                   #buf_one_cycle[0,m4:2 * m4] = buf_one_cycle[0,m4-1::-1]
                   #buf_one_cycle[0,2*m4:3 * m4] = buf_one_cycle[0,m4:2 * m4] - amp/2
                   #buf_one_cycle[0,3*m4:] = buf_one_cycle[0,:m4] - amp /2

                   buf_one_cycle[0,:2*m4] = np.arange(0.0, float(2*m4),1.0) / (float(2*m4-1.0)) * amp
                   buf_one_cycle[0, 2*m4] = amp
                   #buf_one_cycle[0,2*m4] = buf_one_cycle[0, 2+m4 -1]
                   buf_one_cycle[0, 2*m4+1:] = buf_one_cycle[0,2*m4-1:0:-1]

                   buf_one_cycle += off

                   for j in range(cycles):
                        buf[i, j*npn_cycle : j*npn_cycle + npn_cycle] = buf_one_cycle
                   
                   last_points = buf.shape[1] - cycles * npn_cycle
                   if last_points > 0:
                         buf[i, cycles * npn_cycle:] = buf_one_cycle[0,: last_points]

              
              buf[i,:] /= 2.0

         return buf


class NiFrame(Frame):
    def __init__(self:Self, parent, dev='Dev2'):
        super().__init__(parent)
        self.dev = dev
        self.status = 'ok'
        self.root = parent

        self._ao_task = None
        self._ai_task = None
        self._ao_streams = None
        self._ai_streams = None
        self.protocol_save_last_folder = None

        if nidaq_status == 0:
          (self.dev_info, self.devs) = self.get_info()
        else:
             self.dev_info = 'No nidaq library'
             self.devs = list()

        if len(self.devs) < 1:
          self.status = 'no board'
          self.dev = None
        else:
          self.dev = self.devs[0]

        
        try:
             self.bio_controller = self.init_bioTweezerController()
        except:
             self.status = 'no bio controller'

        self.init_ni_data()
        self.init_widgets()

        
        if self.status != 'no board':
          self.bind("<<AiReadEventMain>>", self.aiReadEventInGuiThread)
          tb = np.zeros((2,1), dtype=np.float64)
          tb[:,0] = self.ao_buffer[:,0]
          self._ao_task.write(tb)
          #self.start_tasks()
        else:
          #hide unusefull widgets
          self.ao_frame.pack_forget()

        if self.status != 'no bio controller':
             pass


    def init_ni_data(self:Self):

        self.data_rate = 1000
        self.ai_chunk_size = 250
        self.ao_chunk_size = 1000
        self.ao_written_samples = 0
        self.ai_read_samples = 0
        self.output_protocol:List[ProtocolNode] = list()
        
        self._ao_n_channels = 2 #we'll be using 2 channels
        self._ai_n_channels = 7
        self.ai_buffer = None
        self.ai_buffer_times = None
        self.ai_buffer_min = np.zeros((self._ai_n_channels, 1), dtype=np.float64) + 100.0
        self.ai_buffer_max = np.zeros((self._ai_n_channels, 1), dtype=np.float64) - 100.0

        self.task_status = 'none'

        if self.status != 'no board':
          self.reset_tasks()
        else:
          self.ao_buffer = np.zeros((self._ao_n_channels, self.ao_chunk_size), dtype=np.float64)


        #self.configure_tasks_timing_continous_ao_master_ai_slave()
        #self.attach_stream_writers(self._ao_task)
        #self.attach_stream_readers(self._ai_task)

        #self.detach_writers_and_readers()
        
    def init_bioTweezerController(self:Self):
         q = bioTweezerController()

         return q

    def init_widgets(self:Self):
        self.info_label = Label(self, text=self.dev_info)
        self.info_label.pack()

        self.ao_bio_frame = LabelFrame(self, text='Controls')

        self.ao_frame = LabelFrame(self.ao_bio_frame, text='Analog out')
        self.ao_channel_number_label = list()
        self.ao_value_edit = list()
        self.ao_sliders = list()
        self.ao_desired_values = [DoubleVar(), DoubleVar()]
        self.ao_conversion_factor = 75.0 / 20.0
        self.wdg_wave_types_choices = ['constant', 'sine', 'ramp']
        self.wdg_wave_types_var = list()
        self.wdg_wave_amplitude_var = list()
        self.wdg_wave_frequency_var = list()
        self.wdg_wave_offset_var = list()
        self.pick_point_id = None
        for i in range(self._ao_n_channels):
            #lbl = Label(self.ao_frame, text=f'Channel {i+1}')
            #lbl.pack()
            #self.ao_channel_number_label.append(lbl)

            #the sliders and the edit value box in the same frame
            fr  = Frame(self.ao_frame)
            
            slider = Scale(fr, from_=0.0, to=20.0, orient='horizontal', 
                           variable=self.ao_desired_values[i], length=700, resolution=0.001,
                           digits=5,
                           command=lambda x, y=i:self.ao_slider_callback(x,y))
            slider.pack(side=LEFT)
            self.ao_sliders.append(slider)
            self.ao_desired_values[i].set(0.0)

            
            fr.pack(expand=True, fill='x')
            
            fr = Frame(self.ao_frame)
            lbl = Label(fr, text='Wave type:')
            lbl.pack(side='left')
            option_var = StringVar()
            option_var.set(self.wdg_wave_types_choices[0])
            w = OptionMenu(fr, option_var, *self.wdg_wave_types_choices)
            self.wdg_wave_types_var.append(option_var)
            w.pack(side='left')

            lbl = Label(fr, text='Amplitude:')
            lbl.pack(side='left')

            e_var = DoubleVar()
            e_var.set(0.0)
            self.wdg_wave_amplitude_var.append(e_var)

            w = Entry(fr, textvariable=e_var)
            w.pack(side='left')

            lbl = Label(fr, text='Frequency (Hz):')
            lbl.pack(side='left')

            e_var = DoubleVar()
            e_var.set(1.0)
            self.wdg_wave_frequency_var.append(e_var)

            w = Entry(fr, textvariable=e_var)
            w.pack(side='left')

            lbl = Label(fr, text='Offset:')
            lbl.pack(side='left')

            e_var = DoubleVar()
            e_var.set(0.0)
            self.wdg_wave_offset_var.append(e_var)

            w = Entry(fr, textvariable=e_var)
            w.pack(side='left')

            fr.pack(expand=True, fill='x')

        
        self.ao_frame.pack(expand=True, fill='both', side='left')

        self.bio_frame = LabelFrame(self.ao_bio_frame, text="Bio controller")
        self.bio_notebook = ttk.Notebook(self.bio_frame)
        self.bio_notebook.grid(columnspan=2)
        
        self.bio_general_frame = ttk.Frame(self.bio_notebook)
        self.bio_PI_frame = ttk.Frame(self.bio_notebook)
        self.bio_binFeedback_frame = ttk.Frame(self.bio_notebook)

        # Pack the frames (optional, depending on your layout needs)
        self.bio_general_frame.pack(fill='both', expand=True)
        self.bio_PI_frame.pack(fill='both', expand=True)
        self.bio_binFeedback_frame.pack(fill='both', expand=True)

        # Add frames to the notebook as tabs
        self.bio_notebook.add(self.bio_general_frame, text='general')
        self.bio_notebook.add(self.bio_PI_frame, text='PI')
        self.bio_notebook.add(self.bio_binFeedback_frame, text='binary feedback')
        self.bio_notebook.bind('<<NotebookTabChanged>>', self.on_bio_tab_change)
        self.bio_UI_frames = {"general" : self.bio_general_frame, "PI" : self.bio_PI_frame, "wallFeedback" : self.bio_binFeedback_frame}
        self.bio_UI_frames = {key : {"frame":val, "row":0,"col":0} for key,val in self.bio_UI_frames.items()}
        #get the current generator base current. It's important for the bioTweezerController class to know this value before setting other parameters 
        generatorCurrentSettings = self.getBaseSettingsFromFile(device = "Current Generator")[0]
        baseCurrentFrame = self.createUIElement(self.bio_UI_frames ["general"]["frame"],generatorCurrentSettings, 
                                                bindingFunction=lambda event:self.bio_controller.updateGeneratorBaseCurrent(event.widget.get()),
                                                refreshFunction=lambda x:None)
        baseCurrentFrame.grid(row=self.bio_UI_frames["general"]["row"], column=self.bio_UI_frames["general"]["col"])
        self.bio_UI_frames ["general"]["col"]=1
        #get all the parameters of the FPGA
        bioControllerSettings = self.getBaseSettingsFromFile(device = "Bio Controller")
        for element in bioControllerSettings:
            #a parameter can be useful in more than one UI, so we'll have a different frame for each of the UI
            UI_frames = element["UI position"].split(";")
            for uiFrame in UI_frames:
                frame = self.createUIElement(self.bio_UI_frames[uiFrame]["frame"],element)
                frame.grid(row=self.bio_UI_frames[uiFrame]["row"], column=self.bio_UI_frames[uiFrame]["col"])
                self.bio_UI_frames[uiFrame]["col"]+=1
                if(self.bio_UI_frames[uiFrame]["col"]>1):
                    self.bio_UI_frames[uiFrame]["col"]=0
                    self.bio_UI_frames[uiFrame]["row"]+=1

        #add some buttons
        self.bio_reset_button = Button(self.bio_frame, text="Disable all",command=self.bio_controller.reset)
        self.bio_reset_button.grid(row=1,column=0)
        self.bio_calibrate_button = Button(self.bio_frame, text="Calibrate",
                        command=lambda:(self.bio_controller.initiateTweezers(), self.bio_notebook.event_generate('<<NotebookTabChanged>>')))#after calibration, refresh the tab, to see the new offset values
        self.bio_calibrate_button.grid(row=1,column=1)

        self.bio_set_const_out_button = Button(self.bio_general_frame, text="Set constant output",command=self.bio_controller.EnableConstantOutput)
        self.bio_set_const_out_button.grid(row=self.bio_UI_frames["general"]["row"]+1,column=0)
        self.bio_enable_PI_button = Button(self.bio_PI_frame, text="Enable PI",command=self.bio_controller.EnablePI)
        self.bio_enable_PI_button.grid(row=self.bio_UI_frames["PI"]["row"]+1,column=0)
        self.bio_enable_BinaryFeedback_button = Button(self.bio_binFeedback_frame, text="Enable binary feedback",command=self.bio_controller.EnableBinaryFeedback)
        self.bio_enable_BinaryFeedback_button.grid(row=self.bio_UI_frames["wallFeedback"]["row"]+1,column=0)

        self.bio_frame.pack(expand=True, fill='both', side='right')
        self.ao_bio_frame.pack(expand=True, fill='x', side='top')

        self.protocol_frame = Frame(self)
        self.protocol_start_button_text_var = StringVar()
        self.protocol_start_button_text_var.set('Start wave')
        self.protocol_start_button = Button(self.protocol_frame, textvariable=self.protocol_start_button_text_var,
                                             command=self.start_button_cb)
        self.protocol_start_button.pack(side='left')
        self.wdg_data_rate_label = Label(self.protocol_frame, text='Data rate (samples / s):')
        self.wdg_data_rate_label.pack(side='left')
        self.data_rate_entry_var = IntVar()
        self.data_rate_entry_var.set(self.data_rate)
        self.wdg_data_rate_entry = Entry(self.protocol_frame, textvariable=self.data_rate_entry_var)
        self.wdg_data_rate_entry.pack(side='left')

        self.wdg_wave_time_label = Label(self.protocol_frame, text='Time (s):')
        self.wdg_wave_time_label.pack(side='left')
        self.wdg_wave_time_entry_var = DoubleVar()
        self.wdg_wave_time_entry_var.set(10)
        self.wdg_wave_time_entry = Entry(self.protocol_frame, textvariable=self.wdg_wave_time_entry_var)
        self.wdg_wave_time_entry.pack(side='left')

        self.wdg_save_file_button = Button(self.protocol_frame, text='Save data to:', command=self.save_data_to_file_cb)
        self.wdg_save_file_button.pack(side='left')
        self.wdg_wave_save_file_entry_var = StringVar()
        self.wdg_wave_save_file_entry_var.set('test_001.csv')
        self.wdg_wave_save_file_entry = Entry(self.protocol_frame, textvariable=self.wdg_wave_save_file_entry_var)
        self.wdg_wave_save_file_entry.pack(side='left')

        self.saveFolderButton = Button(self.protocol_frame, text="Save folder", command=self.chooseAutosaveFolder)
        self.saveFolderButton.pack(side='left')

        self.autosaveFolder = StringVar()
        self.autosaveFolder.set(os.getcwd())
        #self.columnconfigure(4, weight=2)
        self.autosaveFolderEdit = Entry(self.protocol_frame, textvariable=self.autosaveFolder, width=50)
        self.autosaveFolderEdit.pack(side="left")

        self.protocol_frame.pack(expand=True, fill='x', side='top')
        
        self.node_frame = Frame(self)
        self.protocol_n_nodes_var = StringVar()
        self.protocol_n_nodes_var.set('Protocol nodes: 0/0')
        self.protocol_n_nodes_label = Label(self.node_frame, textvariable=self.protocol_n_nodes_var)
        self.protocol_n_nodes_label.pack(side='left')
        self.protocol_current_node_var = IntVar()
        self.protocol_current_node_var.set(0)
        self.protocol_current_node_entry = Entry(self.node_frame, textvariable=self.protocol_current_node_var, width=3)
        self.protocol_current_node_entry.pack(side='left')
        self.protocol_current_node_add_button = Button(self.node_frame, text='Add', command=self.navigate_protocol_add_node)
        self.protocol_current_node_add_button.pack(side='left')
        self.protocol_current_node_del_button = Button(self.node_frame, text='Del', command=self.navigate_protocol_delete_node)
        self.protocol_current_node_del_button.pack(side='left')
        self.protocol_current_node_advance_button = Button(self.node_frame, text='<', command=self.navigate_protocol_back_node)
        self.protocol_current_node_advance_button.pack(side='left')
        self.protocol_current_node_back_button = Button(self.node_frame, text='>', command=self.navigate_protocol_advance_node)
        self.protocol_current_node_back_button.pack(side='left')
        self.protocol_current_node_update_button = Button(self.node_frame, text='Update', command=self.navigate_protocol_update_node)
        self.protocol_current_node_update_button.pack(side='left')

        

        self.protocol_save_to_file_button = Button(self.node_frame, text='Save', command=self.save_protocol_to_file_cb)
        self.protocol_save_to_file_button.pack(side='left')

        self.protocol_load_from_file_button = Button(self.node_frame, text='Load', command=self.load_protocol_from_file_cb)
        self.protocol_load_from_file_button.pack(side='left')

        self.protocol_make_gridx_button = Button(self.node_frame, text='Grid x', command=self.make_gridx_protocol_cb)
        self.protocol_make_gridx_button.pack(side='left')

        self.protocol_make_gridy_button = Button(self.node_frame, text='Grid y', command=self.make_gridy_protocol_cb)
        self.protocol_make_gridy_button.pack(side='left')

        # grid total_time
        self.protocol_grid_total_time_label = Label(self.node_frame, text='Grid time(s):')
        self.protocol_grid_total_time_label.pack(side='left')
        self.protocol_grid_total_time_var = DoubleVar()
        self.protocol_grid_total_time_var.set(20)
        self.protocol_grid_total_time_entry = Entry(self.node_frame, textvariable=self.protocol_grid_total_time_var, width=4)
        self.protocol_grid_total_time_entry.pack(side='left')

        # grid number of steps in slower dimension
        self.protocol_grid_steps_label = Label(self.node_frame, text='Steps:')
        self.protocol_grid_steps_label.pack(side='left')
        self.protocol_grid_steps_var = IntVar()
        self.protocol_grid_steps_var.set(6)
        self.protocol_grid_steps_entry = Entry(self.node_frame, textvariable=self.protocol_grid_steps_var, width=4)
        self.protocol_grid_steps_entry.pack(side='left')

        # grid amplitude in x
        self.protocol_grid_amplitude_x_label = Label(self.node_frame, text='Amplitude x:')
        self.protocol_grid_amplitude_x_label.pack(side='left')
        self.protocol_grid_amplitude_x_var = DoubleVar()
        self.protocol_grid_amplitude_x_var.set(5.0)
        self.protocol_grid_amplitude_x_entry = Entry(self.node_frame, textvariable=self.protocol_grid_amplitude_x_var, width=4)
        self.protocol_grid_amplitude_x_entry.pack(side='left')

        # grid amplitude in y
        self.protocol_grid_amplitude_y_label = Label(self.node_frame, text='Amplitude y:')
        self.protocol_grid_amplitude_y_label.pack(side='left')
        self.protocol_grid_amplitude_y_var = DoubleVar()
        self.protocol_grid_amplitude_y_var.set(5.0)
        self.protocol_grid_amplitude_y_entry = Entry(self.node_frame, textvariable=self.protocol_grid_amplitude_y_var, width=4)
        self.protocol_grid_amplitude_y_entry.pack(side='left')

        self.protocol_qpd_xynorm_var = IntVar()
        self.protocol_qpd_xynorm_var.set(0)
        self.protocol_qpd_xynorm_checkbox = Checkbutton(self.node_frame, text='QPD norm', 
                                                        variable=self.protocol_qpd_xynorm_var, 
                                                        onvalue=1, offvalue=0, command=self.qpd_xynorm_check_callback)
        self.protocol_qpd_xynorm_checkbox.pack(side='left')
        

        self.node_frame.pack(expand=False, fill='x', side='top')


        self.selection_frame = Frame(self)
        self.interval_selection_on_var = IntVar()
        self.interval_selection_on_var.set(0)
        self.interval_selection_checkbox = Checkbutton(self.selection_frame, text='Interval selection', 
                                                        variable=self.interval_selection_on_var, onvalue=1, offvalue=0,
                                                        command=self.interval_select_on_callback)
        self.interval_selection_checkbox.pack(side='left')

        self.interval_selection_min_var = DoubleVar()
        self.interval_selection_min_var.set(0)
        self.interval_selection_min_entry = Entry(self.selection_frame, textvariable=self.interval_selection_min_var, width=7)
        self.interval_selection_min_entry.pack(side='left')

        self.interval_selection_between_label = Label(self.selection_frame, text='-')
        self.interval_selection_between_label.pack(side='left')

        self.interval_selection_max_var = DoubleVar()
        self.interval_selection_max_var.set(0)
        self.interval_selection_max_entry = Entry(self.selection_frame, textvariable=self.interval_selection_max_var, width=7)
        self.interval_selection_max_entry.pack(side='left')
        self.interval_selected_number_of_points = 0


        self.qx_vs_x_button = Button(self.selection_frame, text='qx(x)', command=self.plot_qx_vs_x)
        self.qx_vs_x_button.pack(side='left')
        self.qpd_sensitivity_x = 1.0

        self.load_data_from_csv_button = Button(self.selection_frame, text='Load csv data', command=self.load_ai_data_from_csv_cb)
        self.load_data_from_csv_button.pack(side='left')

        self.plot_qpd_variance_data_button = Button(self.selection_frame, text="Plot variance on x,ydif", command=self.plot_qpd_variance_data)
        self.plot_qpd_variance_data_button.pack(side='left')

        self.selection_frame.pack(expand=False, fill='x', side='top')

        self.ai_frame = LabelFrame(self, text='Analog in')
        self.fig = Figure(figsize=(12, 6))
        self.sub_plot = self.fig.add_subplot(111)
        self.sub_plot.set_autoscaley_on(True)
        self.sub_plot.set_autoscalex_on(True)
        self.line_handle = None
        self.ai_line_handles = None
        self.custom_canvas = FigureCanvasTkAgg(self.fig, master=self.ai_frame)
        self.custom_canvas.get_tk_widget().pack(fill='both', expand=True)
        # self.plot_nav = NavigationToolbar2Tk(self.custom_canvas, self, pack_toolbar=False)
        # self.plot_nav.update()
        # self.plot_nav.pack(side='bottom')
        self.ai_frame.pack(expand=True, fill='both', side='bottom')

        self.ao_buffer[:,0] = self.ao_desired_values[0].get() / 2.0
        self.ao_buffer[:,1] = self.ao_desired_values[1].get() / 2.0

    def update_from_ao_sliders(self:Self):
         
        self.ao_buffer[0,:] = self.ao_desired_values[0].get() / 2.0
        self.ao_buffer[1,:] = self.ao_desired_values[1].get() / 2.0

        tb = np.zeros((2,1), dtype=np.float64)
        tb[0,0] = self.ao_desired_values[0].get() / 2.0
        tb[1,0] = self.ao_desired_values[1].get() / 2.0
        #print(f'Update_from_ao_sliders with: {tb}')
        self._ao_task.write(tb)


    def create_ao_task(self:Self, name:str):
         task = nidaqmx.Task(name)
         return task
    
    def add_ao_channels(self:Self, n:int):
         if self._ao_task is None:
              self.status = 'ao task is none'
              return
         
         
         self.ao_buffer = np.zeros((self._ao_n_channels, self.ao_chunk_size), dtype=np.float64)

         return self._ao_task.ao_channels.add_ao_voltage_chan(f'{self.dev}/ao0:{n-1}', min_val=0.0, max_val=10.0)
    
    def create_ai_task(self:Self, name:str):
         task = nidaqmx.Task(name)
         return task
    
    def add_ai_channels(self:Self, n:int):
         if self._ai_task is None:
              self.status = 'ao task is none'
              return
         
         #self.ai_buffer = np.zeros((self._ai_n_channels, self.ai_chunk_size), dtype=np.float64)

         return self._ai_task.ai_channels.add_ai_voltage_chan(f'{self.dev}/ai0:{n-1}', 
                    terminal_config=nidaqmx.constants.TerminalConfiguration.DIFF, min_val=-10.0, max_val=10.0)
         

    def cleanup(self:Self):
            if self.status == 'no board':
                 return

            if self._ao_task is not None:
                self._ao_task.stop()
                self._ao_task.close()
                self._ao_task = None

            if self._ai_task is not None:
                self._ai_task.stop()
                self._ai_task.close()
                self._ai_task = None
            
            local_system = nidaqmx.system.System.local()
            for device in local_system.devices:
                device.reset_device()

    def get_info(self:Self)->str:
        local_system = nidaqmx.system.System.local()
        self.n_devices = len(local_system.devices)
        self.devs = list()
        dev_info = list()
        for device in local_system.devices:
            device.reset_device()
            dev_info.append(f'Name: {device.name}, Serial:{device.serial_num}, Output analog channels:{len(device.ao_physical_chans)}')
            self.devs.append(device.name)

        return (f'Devices: {self.n_devices}, {dev_info}', self.devs)
    
    def ao_slider_callback(self:Self, x:float, sld_id:int):
         x = float(x)
         v = x / 2.0
         o = x * self.ao_conversion_factor
         print(f'slider {sld_id}, value {o}')

         self.ao_buffer[sld_id,:] = v
         tb = np.zeros((2,1), dtype=np.float64)
         tb[:,0] = self.ao_buffer[:,0]
         tb[sld_id,0] = v
         self._ao_task.write(tb)


    def configure_tasks_timing_continous_ai_master_ao_slave(self:Self):
         if self._ao_task is None:
              return
         
         self._ao_task.timing.cfg_samp_clk_timing(rate=self.data_rate, sample_mode=AcquisitionType.CONTINUOUS,
                                                  source=f'/{self.dev}/ai/SampleClock', 
                                                  samps_per_chan=self.ao_chunk_size)
         self._ai_task.timing.cfg_samp_clk_timing(rate=self.data_rate, sample_mode=AcquisitionType.CONTINUOUS,
                                                  active_edge=nidaqmx.constants.Edge.RISING,
                                                  samps_per_chan=self.ai_chunk_size)
         self._ao_task.triggers.start_trigger.cfg_dig_edge_start_trig( trigger_source=f'/{self.dev}/ai/StartTrigger') # Setting the trigger on the analog input
         #nidaqmx.constants.RegenerationMode
         self._ao_task.out_stream.regen_mode = nidaqmx.constants.RegenerationMode.DONT_ALLOW_REGENERATION
         
    def configure_tasks_timing_continous_ao_ai_separate(self:Self):
         if self._ao_task is None:
              return
         
         self._ao_task.timing.cfg_samp_clk_timing(rate=self.data_rate, sample_mode=AcquisitionType.CONTINUOUS, 
                                                  samps_per_chan=self.ao_chunk_size)
         self._ai_task.timing.cfg_samp_clk_timing(rate=self.data_rate, sample_mode=AcquisitionType.CONTINUOUS,
                                                  samps_per_chan=self.ai_chunk_size)

    def attach_stream_writers(self:Self):
        if self._ao_streams is None:
            self._ao_streams = AnalogMultiChannelWriter(self._ao_task.out_stream)


        self._ao_task.register_every_n_samples_transferred_from_buffer_event(self.ao_chunk_size, None)
        print(f'Registered ao event with chunk size {self.ao_chunk_size}')
        self._ao_task.register_every_n_samples_transferred_from_buffer_event(self.ao_chunk_size, self.ao_write_event)

    def attach_stream_readers(self:Self):
        if self._ai_streams is None:
            self._ai_streams = AnalogMultiChannelReader(self._ai_task.in_stream)

        self._ai_task.register_every_n_samples_acquired_into_buffer_event(self.ai_chunk_size, None)
        self._ai_task.register_every_n_samples_acquired_into_buffer_event(self.ai_chunk_size, self.ai_read_event)

    def detach_writers_and_readers(self:Self):
        self._ai_task.register_every_n_samples_acquired_into_buffer_event(self.ai_chunk_size, None)
        self._ao_task.register_every_n_samples_transferred_from_buffer_event(self.ao_chunk_size, None)

    def ai_read_event(self:Self, task_idx, event_type, num_samples, callback_data):
        #print (f'aiReadEvent on task {task_idx} with {num_samples} samples')

        if num_samples != self.ai_chunk_size:
             print(f'ai_read_event expected {self.ai_chunk_size} samples, recieved {num_samples}')
             return

        buf = np.zeros((self._ai_n_channels, num_samples), dtype=np.float64)
        read_samples = self._ai_streams.read_many_sample(buf, num_samples)

        
        if read_samples != num_samples:
             print(f'Error reading samples: to read {num_samples}, actually read {read_samples}')

        #print(self.ai_buffer.shape)
        #print(buf.shape)
        if self.ai_read_samples > 0:
             self.ai_buffer = np.concatenate((self.ai_buffer, buf), axis=1)
             self.ai_buffer_times = np.concatenate((self.ai_buffer_times, 
                                                   self.ai_buffer_times[-1] + np.arange(1.0, read_samples+1,1.0)))# / self.data_rate))
        else:
             self.ai_buffer = buf
             self.ai_buffer_times = np.arange(0.0, read_samples, 1.0)# / self.data_rate

        self.ai_read_samples += read_samples

        mn = buf.min(axis=1)
        mx = buf.max(axis=1)

        stop = time.perf_counter()
        #print(f"Read event after {(stop-self.start_time) * 1000} msec, read {self.ai_read_samples} samples")
        self.start_time = stop

        #print(mx)

        self.ai_buffer_max = np.maximum(self.ai_buffer_max, mx)
        self.ai_buffer_min = np.minimum(self.ai_buffer_min, mn)

        if self.ai_read_samples >= self.ao_buffer.shape[1]:
             print('read finished, resetting task')
             self.protocol_start_button_text_var.set('Start wave')
             self.reset_tasks()
             self.update_from_ao_sliders()
        
        self.event_generate("<<AiReadEventMain>>")
        

        #must get out of Nidaq callback as soon as possible.
        #all gui updates are done in the event callback aiReadEventInGuiThread

        return 0
    
    def ao_write_event(self:Self, task_idx, event_type, num_samples, callback_data):
         #self._ao_streams.write_many_sample(self.ao_buffer)

         stop = time.perf_counter()
         #print(f"Write event after {(stop-self.start_time) * 1000} msec")
         self.start_time = stop

         
         #print(f'Written samples {self.ao_written_samples}')
         buf_pts = self.ao_buffer.shape[1]
         points_left = buf_pts - self.ao_written_samples

         if points_left > 0:
              if self.ao_chunk_size < points_left:
                   self._ao_streams.write_many_sample(
                        np.ascontiguousarray(self.ao_buffer[:, self.ao_written_samples:self.ao_written_samples+self.ao_chunk_size]))
                   self.ao_written_samples += self.ao_chunk_size
              else:
                  self._ao_streams.write_many_sample(
                       np.ascontiguousarray(self.ao_buffer[:, self.ao_written_samples:]))
                  self.ao_written_samples += points_left 

         else:
            #self.reset_tasks()
            #self._ao_task.stop()
            #self.protocol_start_button_text_var.set('Start wave')
            pass
         
         
         #print(f'ao left points {points_left}, num samples event {num_samples}')
         return 0
    
    def aiReadEventInGuiThread(self, ev):
         #print(self.ai_read_samples)
         #if self.ai_buffer_times is not None:
         #      print(f'x shape is {self.ai_buffer_times.shape}, y shape is {self.ai_buffer.shape}')
         if self.ai_buffer_times is not None:
               self.ai_plot(self.ai_buffer_times / self.data_rate, self.ai_buffer, self.ai_buffer_min, self.ai_buffer_max)
         #pass

    def start_tasks(self:Self):
        if self._ao_task is not None:
              self.ao_written_samples = int(self.ao_chunk_size)
              self.ai_buffer_times = None
              self.ai_line_handles = None
              self.ai_buffer = np.zeros((self._ai_n_channels, self.ai_chunk_size), dtype=np.float64)
              self.ai_read_samples = 0
              self.ai_buffer_min = np.zeros((self._ai_n_channels, 1), dtype=np.float64) + 100.0
              self.ai_buffer_max = np.zeros((self._ai_n_channels, 1), dtype=np.float64) - 100.0
              #print(f'ao_written_smples is {self.ao_written_samples}')
              self.ao_written_samples = self._ao_streams.write_many_sample(np.ascontiguousarray(self.ao_buffer[:, :self.ao_written_samples]))
              
              #print(f'Written first {n} samples')
              
              self.start_time = time.perf_counter()
              self._ao_task.start()
              self._ai_task.start()
              
              #self._ao_streams.write_many_sample(np.ascontiguousarray(self.ao_buffer[:, 
              #                                     self.ao_written_samples : self.ao_written_samples + self.ao_chunk_size]))
              #self.ao_written_samples += self.ao_chunk_size


    def stop_tasks(self:Self):
        if self._ao_task is not None:
              
              self._ai_task.stop()
              self._ao_task.stop()

    def reset_tasks(self:Self):
         
         if self._ao_task is not None:
              #self._ao_task.stop()
              self._ao_task.close()

              #self._ai_task.stop()
              self._ai_task.close()

              #self.detach_writers_and_readers()
              #self._ao_task.timing.cfg_implicit_timing(AcquisitionType.FINITE)
              #self._ai_task.timing.cfg_implicit_timing(AcquisitionType.FINITE)

              self._ai_streams = None
              self._ao_streams = None

         self._ao_task = self.create_ao_task("AOTask")
         self._ai_task = self.create_ai_task('AITask')

         
         

         self.ao_chunk_size = int(self.data_rate / 2.0)

         self.add_ao_channels(self._ao_n_channels)
         print(f'Current ao channels: {len(self._ao_task.ao_channels)}')
              
         
         self.add_ai_channels(self._ai_n_channels)
         
         print(f'Current ai channels: {len(self._ai_task.ai_channels)}')

    def ao_plot(self:Self, data):
        
        xs = np.arange(0.0, data.shape[1])
        x_lims = (xs[0], xs[-1])
        y_lims = (np.min(data), np.max(data))
        if self.line_handle is not None:
            #print(xs.shape)
            #print(self.draw_buffer.shape)
            self.line_handle.set_ydata(np.transpose(data))
            self.line_handle.set_xdata(xs)
            self.sub_plot.set_xlim((0.0, data.shape[1]))
            self.sub_plot.set_ylim(0.0, 20.0)
            #self.sub_plot.autoscale_view()
        else:
            self.sub_plot.cla()
            #print(xs.shape)
            #print(self.draw_buffer.shape)
            self.sub_plot.plot(xs, data[0,:])
            self.sub_plot.plot(xs, data[1,:])

        self.fig.canvas.draw()

    def ai_plot(self:Self, x:np.ndarray, y:np.ndarray, mny:np.ndarray, mxy:np.ndarray):
         #x = self.ai_buffer_times

         (chans, pts) = y.shape
         if pts > 10000:
              step = pts // 10000
              x = x[::step]
              y = y[:, ::step]
              #print(step)

         y = np.transpose(y)

         qpd_norm = self.protocol_qpd_xynorm_var.get()

         if qpd_norm == 1:
               reference_signal = y[:,1]
               sum_average = np.mean(reference_signal)

         #print(f'y min is {np.min(mny)}, y max is {np.max(mxy)}')


         if self.ai_line_handles is not None:
              
              for i in range(self._ai_n_channels):
                    self.ai_line_handles[i].set_xdata(x)
                    if qpd_norm == 1:
                         if i==2 or i == 3:
                              self.ai_line_handles[i].set_ydata(y[:,i] / reference_signal)
                         elif i == 1:
                              self.ai_line_handles[i].set_ydata(y[:,i] / sum_average)
                         else:
                              self.ai_line_handles[i].set_ydata(y[:,i])
                    else:
                         self.ai_line_handles[i].set_ydata(y[:,i])

              self.sub_plot.set_xlim(x[0], x[-1])
              self.sub_plot.set_ylim(np.min(mny), np.max(mxy))
              #self.sub_plot.set_ylim(-0.5, 10.0)
         else:
              self.sub_plot.cla()
              self.ai_line_handles = self.sub_plot.plot(x, y, picker=True, pickradius=2)
              self.sub_plot.set_xlim(x[0], x[-1])
              self.sub_plot.set_ylim(np.min(mny), np.max(mxy))
              #for i in range(self._ai_n_channels):
              #    obj = self.sub_plot.plot(x, y[i,:])
              #    self.ai_line_handles.append(obj[0])

         self.fig.canvas.draw()

    def start_button_cb(self:Self):
         if self.protocol_start_button_text_var.get() == 'Start wave':
            #self.stop_tasks()
            #self.start_tasks()

            self.data_rate = int(self.wdg_data_rate_entry.get())
            self.reset_tasks()
            k = 8.0
            if self.data_rate >= 5000.0:
                 k = 4.0
          
            self.ai_chunk_size = int(self.data_rate / k)

            self._ai_task.in_stream.input_buf_size = 4 * self.ai_chunk_size

            if (self.output_protocol is None) or (len(self.output_protocol) < 1):
               buf = self.compute_ao_buffer_from_wave_parameters()
            else:
               print(f'Computing output buffer from protocol')
               buf = self.compute_ao_buffer_from_protocol()

            self.ao_plot(buf)
            self.ao_buffer = buf

            #print(self.data_rate)
            self.configure_tasks_timing_continous_ai_master_ao_slave()
            #self.configure_tasks_timing_continous_ao_ai_separate()
            self.attach_stream_writers()
            self.attach_stream_readers()

            self.bio_controller.startDataStream()

            self.start_tasks()

            self.protocol_start_button_text_var.set('Stop')
         else:
            self.reset_tasks()
            self.protocol_start_button_text_var.set('Start wave')
            self.update_from_ao_sliders()

            buf = self.bio_controller.stopDataStream()
            print(buf)


    def save_data_to_file_cb(self:Self):
         fname = self.wdg_wave_save_file_entry_var.get()  
         folder_name = self.autosaveFolder.get()

         t = self.ai_buffer_times / self.data_rate
         buf = self.ai_buffer
         nchan = self._ai_n_channels

         data = {'Time (s)' : t}
         for i in range(nchan):
              data[f'AI{i+1}'] = buf[i, :]

         df = pd.DataFrame(data)
        
         output_path = folder_name + '/' + fname
         print(output_path)
         df.to_csv(output_path, mode='a', header=not os.path.exists(output_path), sep='\t', index=False)

         self.advance_autosave_file_name()

    def advance_autosave_file_name(self, n=1):
        f = self.wdg_wave_save_file_entry_var.get()

        pat = '[0-9]{3,}.csv'
        m = re.search(pat, f)
        if m is None:
            return
        
        #print(m)
        #print(m.group(0))
        (start, stop) = m.span()
        idx = f[start:stop-4]
        idx = int(idx)
        nf = str(idx+n).zfill(stop-start-4)
        f = f[:start] + nf + '.csv'
        self.wdg_wave_save_file_entry_var.set(f)

    def chooseAutosaveFolder(self)->str:
        folder_path = filedialog.askdirectory(initialdir=self.autosaveFolder.get())
        self.autosaveFolder.set(folder_path)
        #self.autosaveOn.set(True)
        return folder_path  
    
    
    def compute_ao_buffer_from_protocol(self:Self)->np.ndarray:
         if len(self.output_protocol) > 0:
              buf = None
              lbuf = None
              for nd in self.output_protocol:
                   lbuf = nd.compute_ao_buffer_from_parameters()
                   if buf is not None:
                        end_off = buf[:,-1]
                        pts = lbuf.shape[1]
                        off = np.reshape(np.repeat((lbuf[:,0] - end_off), pts), (nd.n_channels, pts))
                        print(off.shape)
                        buf = np.append(buf, lbuf-off, 1)
                   else:
                        buf = lbuf
                         
              current_offset = np.array([self.ao_desired_values[0].get(), self.ao_desired_values[1].get()]) /2.0
              for i in range(self.output_protocol[0].n_channels):
                         buf[i,:] += current_offset[i]
                         
              return buf

         return np.zeros((self._ao_n_channels, 1000))
         

    def compute_ao_buffer_from_wave_parameters(self:Self)->np.ndarray:
         t = self.wdg_wave_time_entry_var.get()
         rate = self.data_rate_entry_var.get()
         self.data_rate = rate

         npn = int(t * rate)
         if npn < 5:
              print('Too few points to compose a wave!!')
              return np.zeros((self._ao_n_channels, 1000))
         
         buf = np.zeros((self._ao_n_channels, npn))
         current_offset = np.array([self.ao_desired_values[0].get(), self.ao_desired_values[1].get()]) /2.0
         for i in range(self._ao_n_channels):
              tp = self.wdg_wave_types_var[i].get()
              off = self.wdg_wave_offset_var[i].get()
              freq = self.wdg_wave_frequency_var[i].get()
              amp = self.wdg_wave_amplitude_var[i].get()
              if tp == self.wdg_wave_types_choices[0]: # constant
                   buf[i,:] +=  off
                   print(f'Offset: {off}')
              elif tp == self.wdg_wave_types_choices[1]: #sine
                   npn_cycle = int(self.data_rate / freq)
                   cycles = int(npn / npn_cycle)
                   buf_one_cycle = amp/2 * np.sin(2*np.pi  * np.arange(0.0, npn_cycle) / float(npn_cycle) - np.pi/2.0) + amp /2.0 + off

                   for j in range(cycles):
                        buf[i, j*npn_cycle : j*npn_cycle + npn_cycle] = buf_one_cycle
                   
                   last_points = buf.shape[1] - cycles * npn_cycle
                   if last_points > 0:
                         buf[i, cycles * npn_cycle:] = buf_one_cycle[: last_points]

              elif tp == self.wdg_wave_types_choices[2]: #ramp
                   npn_cycle = int(self.data_rate / freq)
                   # try to force npn_cycle in multiple of 4
                   m4 = int(npn_cycle / 4)
                   npn_cycle = 4 * m4
                   cycles = int(npn / npn_cycle)
                   print(f'npn {npn}, m4 {m4}, npn_cycle {npn_cycle}, cycles {cycles}')
                   buf_one_cycle = np.zeros((1, npn_cycle), dtype=np.float64)
                   #buf_one_cycle[0,:m4] = np.arange(0.0, float(m4),1.0) / (float(m4-1.0)) * amp/2
                   #buf_one_cycle[0,m4:2 * m4] = buf_one_cycle[0,m4-1::-1]
                   #buf_one_cycle[0,2*m4:3 * m4] = buf_one_cycle[0,m4:2 * m4] - amp/2
                   #buf_one_cycle[0,3*m4:] = buf_one_cycle[0,:m4] - amp /2

                   buf_one_cycle[0,:2*m4] = np.arange(0.0, float(2*m4),1.0) / (float(2*m4-1.0)) * amp
                   buf_one_cycle[0, 2*m4] = amp
                   #buf_one_cycle[0,2*m4] = buf_one_cycle[0, 2+m4 -1]
                   buf_one_cycle[0, 2*m4+1:] = buf_one_cycle[0,2*m4-1:0:-1]

                   buf_one_cycle += off

                   for j in range(cycles):
                        buf[i, j*npn_cycle : j*npn_cycle + npn_cycle] = buf_one_cycle
                   
                   last_points = buf.shape[1] - cycles * npn_cycle
                   if last_points > 0:
                         buf[i, cycles * npn_cycle:] = buf_one_cycle[0,: last_points]

              
              buf[i,:] /= 2.0
              buf[i,:] += current_offset[i]

              print(current_offset)

         return buf
    

    def navigate_protocol_add_node(self:Self):
         t = self.wdg_wave_time_entry_var.get()
         rate = self.data_rate_entry_var.get()

         tp = [x.get() for x in self.wdg_wave_types_var]
         off = [x.get() for x in self.wdg_wave_offset_var]
         freq = [x.get() for x in self.wdg_wave_frequency_var]
         amp = [x.get() for x in self.wdg_wave_amplitude_var]
         

         p = ProtocolNode(tp, amp, freq, off, t, rate)
         current_node = self.protocol_current_node_var.get()
         self.output_protocol.insert(current_node, p)
         
         n = len(self.output_protocol)
         self.protocol_current_node_var.set(current_node+1)
         self.protocol_n_nodes_var.set(f'Protocol nodes {current_node+1} / {n}:')

    def navigate_protocol_update_node(self:Self):
         current_node = self.protocol_current_node_var.get()
         if current_node < 1:
              return
         
         n = len(self.output_protocol)
         if current_node > n:
              return

         p = self.output_protocol[current_node-1]

         p.duration = self.wdg_wave_time_entry_var.get()
         p.data_rate = self.data_rate_entry_var.get()

         p.wave_type = [x.get() for x in self.wdg_wave_types_var]
         p.offset = [x.get() for x in self.wdg_wave_offset_var]
         p.frequency = [x.get() for x in self.wdg_wave_frequency_var]
         p.amplitude = [x.get() for x in self.wdg_wave_amplitude_var]



    def navigate_protocol_delete_node(self:Self):
         n = len(self.output_protocol)
         print(n)
         if n < 1:
              return
         

         current_node = self.protocol_current_node_var.get()
         if current_node < 1:
              return

         print(current_node)
         if current_node >= n:
              return
         
         del(self.output_protocol[current_node])

         if len(self.output_protocol) < 1:
              self.output_protocol = list()
         
         
         self.protocol_current_node_var.set(current_node)
         self.protocol_n_nodes_var.set(f'Protocol nodes {current_node} / {len(self.output_protocol)}:')

    def navigate_protocol_advance_node(self:Self):
         n = len(self.output_protocol)
         print(n)
         if n < 1:
              return
         

         current_node = self.protocol_current_node_var.get()
         if current_node + 1 > n:
              return
         
         current_node += 1
         self.navigate_protocol_show_node(current_node)

    def navigate_protocol_back_node(self:Self):
         n = len(self.output_protocol)
         print(n)
         if n < 1:
              return
         

         current_node = self.protocol_current_node_var.get()
         if current_node <= 1:
              return
         
         current_node -= 1
         self.navigate_protocol_show_node(current_node)

    def navigate_protocol_show_node(self:Self, nd:int):
         p = self.output_protocol[nd-1]
         self.protocol_current_node_var.set(nd)
         self.protocol_n_nodes_var.set(f'Protocol nodes {nd}/{len(self.output_protocol)}')

         self.wdg_wave_time_entry_var.set(p.duration)
         self.data_rate_entry_var.set(int(p.data_rate))

         for i in range(p.n_channels):
              self.wdg_wave_types_var[i].set(p.wave_type[i])
              self.wdg_wave_amplitude_var[i].set(p.amplitude[i])
              self.wdg_wave_frequency_var[i].set(p.frequency[i])
              self.wdg_wave_offset_var[i].set(p.offset[i])

    def save_protocol_to_file_cb(self:Self):
         f = 'test.pkl'
         if self.protocol_save_last_folder is not None:
               f = filedialog.asksaveasfilename(filetypes=[('Protocol files *.pkl', '*.pkl')], initialdir=self.protocol_save_last_folder)
         else:
              f = filedialog.asksaveasfilename(filetypes=[('Protocol files *.pkl', '*.pkl')])

         self.protocol_save_last_folder = os.path.dirname(f)
         print(self.protocol_save_last_folder)
         
         if '.pkl' not in f:
               f += '.pkl'
         self.save_protocol_to_file(f)

    def save_protocol_to_file(self:Self, f:str):
         if len(self.output_protocol) > 0:
              pd.to_pickle(self.output_protocol, f)

    def load_protocol_from_file_cb(self:Self):
         f = 'test.pkl'
         if self.protocol_save_last_folder is not None:
               f = filedialog.askopenfilename(filetypes=[('Protocol files *.pkl', '*.pkl')], initialdir=self.protocol_save_last_folder)
         else:
              f = filedialog.askopenfilename(filetypes=[('Protocol files *.pkl', '*.pkl')])

         self.load_protocol_from_file(f)

    def load_protocol_from_file(self:Self, f:str):
         
         output_protocol = pd.read_pickle(f)
         nodes = len(output_protocol)
         if nodes > 0:
               self.output_protocol = output_protocol
               n = len(self.output_protocol)
               current_node = 0
               self.protocol_current_node_var.set(current_node+1)
               self.protocol_n_nodes_var.set(f'Protocol nodes {current_node+1} / {n}:')
               self.navigate_protocol_show_node(current_node+1)

    def make_gridx_protocol_cb(self:Self):
         total_time = self.protocol_grid_total_time_var.get()
         rate = self.data_rate_entry_var.get()
         x_steps = self.protocol_grid_steps_var.get()
         y_steps = x_steps
         x_amp = self.protocol_grid_amplitude_x_var.get()
         y_amp = self.protocol_grid_amplitude_y_var.get()

         output_protocol = self.make_grid_protocol(total_time, rate, x_steps, y_steps, x_amp, y_amp, True)
         nodes = len(output_protocol)
         if nodes > 0:
               self.output_protocol = output_protocol
               n = len(self.output_protocol)
               current_node = 0
               self.protocol_current_node_var.set(current_node+1)
               self.protocol_n_nodes_var.set(f'Protocol nodes {current_node+1} / {n}:')
               self.navigate_protocol_show_node(current_node+1)
    
    def make_gridy_protocol_cb(self:Self):
         total_time = self.protocol_grid_total_time_var.get()
         rate = self.data_rate_entry_var.get()
         x_steps = self.protocol_grid_steps_var.get()
         y_steps = x_steps
         x_amp = self.protocol_grid_amplitude_x_var.get()
         y_amp = self.protocol_grid_amplitude_y_var.get()

         output_protocol = self.make_grid_protocol(total_time, rate, x_steps, y_steps, x_amp, y_amp, False)
         nodes = len(output_protocol)
         if nodes > 0:
               self.output_protocol = output_protocol
               n = len(self.output_protocol)
               current_node = 0
               self.protocol_current_node_var.set(current_node+1)
               self.protocol_n_nodes_var.set(f'Protocol nodes {current_node+1} / {n}:')
               self.navigate_protocol_show_node(current_node+1)

    def make_grid_protocol(self:Self, total_time:float, rate:float, x_steps:int, y_steps:int, 
                           x_amp:float, y_amp:float, x_first:bool=False, in_sweep_time:float=0.5):
         output_protocol:List[ProtocolNode] = list()
         if x_first:
              dy = y_amp / (y_steps - 1)
              sweep_time = (total_time - (y_steps - 1) * in_sweep_time) / y_steps
              sweep_x_freq = 1.0 / sweep_time
              pn_sine = ProtocolNode(['sine', 'constant'], [x_amp, 0.0], [sweep_x_freq, 1.0], [0.0, 0.0], sweep_time, rate)
              pn_step = ProtocolNode(['constant', 'ramp'], [0.0, dy], [1.0, 1.0 / (2.0 * in_sweep_time)],
                                     [0.0, 0.0], in_sweep_time, rate)
              
              for i in range(y_steps - 1):      
                    output_protocol.append(pn_sine)
                    output_protocol.append(pn_step)

              output_protocol.append(pn_sine)
         else:
              dx = x_amp / (x_steps - 1)
              sweep_time = (total_time - (x_steps -1) * in_sweep_time) / x_steps
              sweep_y_freq = 1.0 / sweep_time

              pn_sine = ProtocolNode(['constant', 'sine'], [0.0, y_amp], [1.0, sweep_y_freq], [0.0, 0.0], sweep_time, rate)
              pn_step = ProtocolNode(['ramp', 'constant'], [dx, 0.0], [1.0 / (2.0 * in_sweep_time), 1.0],
                                     [0.0, 0.0], in_sweep_time, rate)
              
              for i in range(x_steps - 1):      
                    output_protocol.append(pn_sine)
                    output_protocol.append(pn_step)
              
              output_protocol.append(pn_sine)

         return output_protocol
    
    def qpd_xynorm_check_callback(self:Self):
         if self.ai_buffer is None:
              return
         
         t = self.ai_buffer_times
         self.ai_plot(t / self.data_rate, self.ai_buffer, np.min(self.ai_buffer), np.max(self.ai_buffer))
    
    def plot_pick_point_event(self, event):
         #print(event)
         if isinstance(event.artist, matplotlib.lines.Line2D):
              thisline = event.artist
              xdata = thisline.get_xdata()
              ydata = thisline.get_ydata()
              ind = event.ind
              if self.interval_selected_number_of_points == 0:
                    self.interval_selection_min_var.set(xdata[ind][0])
              elif self.interval_selected_number_of_points == 1:
                   self.interval_selection_max_var.set(xdata[ind][0])

              self.interval_selected_number_of_points += 1
              if self.interval_selected_number_of_points == 2:
                   self.interval_selected_number_of_points = 0
                   #self.interval_selection_on_var.set(0)
                   #self.interval_select_on_callback()


    def interval_select_on_callback(self):
         v = self.interval_selection_on_var.get()
         print(f'Interval selection on is {v}')
         if v==1 and (self.pick_point_id is None):
              self.pick_point_id = self.fig.canvas.mpl_connect('pick_event', self.plot_pick_point_event)
              print(f'Enabling pick point with id: {self.pick_point_id}')
              return
         elif self.pick_point_id is not None:
              self.fig.canvas.mpl_disconnect(self.pick_point_id)
              self.pick_point_id = None

         self.interval_selected_number_of_points = 0

    def plot_qx_vs_x(self):
         if self.ai_buffer is None:
              return
         
         (ch, pts) = self.ai_buffer.shape
         print(f'Ai buffer shape is ({ch},{pts})')

         if pts < 1:
              return
         
         min_point = self.interval_selection_min_var.get()
         max_point = self.interval_selection_max_var.get()

         if (min_point < 0 ) or (max_point < 0) or (min_point >= pts) or (max_point >= pts) or (max_point <= min_point):
              return
         
         x = 2.0 * self.ai_buffer[0,min_point:max_point]
         qx = self.ai_buffer[2,min_point:max_point] / self.ai_buffer[1, min_point:max_point]

         fit_pol = np.polyfit(x, qx, 1)
         self.qpd_sensitivity_x = fit_pol[0]

         #print('Plotting x and qx')
         mn = np.min(x)
         mx = np.max(x)
         x_fit = np.array([mn, mx])
         y_fit = fit_pol[0] * x_fit + fit_pol[1]
         h_lines = plt.plot(x, qx, '.', x_fit, y_fit, '-r')
         plt.xlabel('x (um)')
         plt.ylabel('normalized qx (au)')
         plt.title(f'Sensibility is {fit_pol[0]} au / um')
         
         plt.show()

    def load_ai_data_from_csv_cb(self:Self):
         autosaveFolder = self.autosaveFolder.get()
         fname = filedialog.askopenfilename(filetypes=[('Data files *.csv', '*.csv')], initialdir=autosaveFolder)
         
         if fname == '':
              return
         

         fld = os.path.dirname(os.path.abspath(fname))
         self.autosaveFolder.set(fld)
         data = self.load_ai_data_from_csv(fname)
         
    def load_ai_data_from_csv(self:Self, fname:str)->np.ndarray:
         
         pf = pd.read_csv(fname, sep='\t', lineterminator='\n')
         buf = pf.to_numpy(dtype=np.float64)
         (pts, self._ai_n_channels) = buf.shape
         self._ai_n_channels -= 1
         t = buf[:,0]

         self.data_rate = int(1.0/np.mean(np.diff(t)))
         self.data_rate_entry_var.set(self.data_rate)

         self.ai_buffer = np.transpose(buf[:, 1:])
         self.ai_buffer_times = self.data_rate * t

         self.ai_plot(t, self.ai_buffer, np.min(self.ai_buffer), np.max(self.ai_buffer))

    def preprocess_ai_data(self:Self, t:np.ndarray, y:np.ndarray)->Tuple[np.ndarray, np.ndarray]:
         #selection interval
         y = y.copy()
         if self.interval_selection_on_var.get() == 1:
              min_t = self.interval_selection_min_var.get()
              max_t = self.interval_selection_max_var.get()

              min_idx = np.argmax(t >= min_t)
              max_idx = np.argmin(t <= max_t)
              #print(f'Min idx {min_idx}, max idx {max_idx}')

              t = t[min_idx:max_idx]
              y = y[:,min_idx:max_idx]

         if self.protocol_qpd_xynorm_var.get() == 1:
              sum_avg = np.mean(y[1,:])
              y[2:4,:] /= y[1,:]
              y[1,:] /= sum_avg


         return (t,y)
              

    def plot_qpd_variance_data(self:Self):
         if self.ai_buffer is None:
              return
         
         rate = self.data_rate
         window_size = rate // 4
         t = self.ai_buffer_times / self.data_rate

         (t, y) = self.preprocess_ai_data(t, self.ai_buffer)

         qSum = y[1,:]
         qX = y[2,:]
         qY = y[3,:]

         if self.interval_selection_on_var.get() == 1:
               var_qX = np.var(qX) * 1000000
               var_qY = np.var(qY) * 1000000

               print(f'Var qX - {var_qX} mV2, var qy - {var_qY} mV2, interval ({self.interval_selection_min_var.get()}, {self.interval_selection_max_var.get()})')

               #plt.show()
         else:
               p = pd.Series(qX)
               var_qX = p.rolling(window=window_size).var() * 1000000
               
               p = pd.Series(qY)
               var_qY = p.rolling(window=window_size).var() * 1000000

               p = pd.Series(qSum)
               var_Sum = p.rolling(window=window_size).var()

               #normalize qX signal in order to see them both, while maintaining the var_qX real values
               mn = np.min(var_qY)
               mx = np.max(var_qY)
               
               qY_min = np.min(qY)
               qY_max = np.max(qY)
               norm_qY = (qY - qY_min) / (qY_max - qY_min)
               norm_qY = (norm_qY * (mx-mn))+ mn

               h_lines = plt.plot(t, norm_qY, 'b', t-window_size /2.0 /rate, var_qY, 'r')
               plt.xlabel('t (s)')
               plt.ylabel('qy / var qy (au)')
               
               plt.show()
         
    def bio_setpoint_entry_callback(self:Self, event=None):
         if self.status != 'no bio controller':
              sp = self.bio_setpoint_var.get()
              print(f'Setting setpoint {sp} to bio controller!')
              self.bio_controller.setParameters(setpoint=sp)
    
    @staticmethod
    def getBaseSettingsFromFile(fileName='bio_controller.csv', device = "Bio Controller"):
          pf = pd.read_csv(fileName, sep=',', lineterminator="\n", header=1)
          l = [dict(row) for index, row in pf.iterrows()]
          for i in range(len(l)):
               l[i]["UI position"] = l[i]["UI position\r"].replace('\r','')
               l[i].pop("UI position\r")        
          return [e for e in l if e["Device"] == device]
    
    
    def on_bio_tab_change(self, event):
        notebook = event.widget
        selected_tab = notebook.nametowidget(notebook.select())
        children = selected_tab.winfo_children()
        # Filter out only the Label widgets
        labels = [child for child in children if isinstance(child, Frame)]
        for el in labels:
            el.refreshValue()

    def refreshEntryFromFPGA(self, entry):
        parent = entry.nametowidget(entry.winfo_parent())
        entry.delete(0, END)
        readvalue = self.bio_controller.readBackParameter((parent.internalName,parent.internalUnit))
        entry.insert(0, f"{readvalue:.3e}")

    def refreshCheckboxFromFPGA(self, parent, var):
        var.set(self.bio_controller.readBackParameter((parent.internalName,parent.internalUnit)))
         

    def updateBioControllerParameterFromEntry(self, event):
        entry = event.widget
        parent = entry.nametowidget(entry.winfo_parent())
        print(parent.internalName , entry.get(),parent.internalUnit)
        self.bio_controller.setParameters(**{parent.internalName : (float(entry.get()),parent.internalUnit)})
        self.refreshEntryFromFPGA(entry)

    def updateBioControllerParameterFromCheckbox(self, parent, var):
        self.bio_controller.setParameters(**{parent.internalName : var.get()})

    def createUIElement(self, root, valuesFromCsvFile, bindingFunction = None, refreshFunction = None):
        #print(valuesFromCsvFile)
        el = Frame(root)
        el.internalName = valuesFromCsvFile["Parameter internal name"]
        el.internalUnit = valuesFromCsvFile["Parameter internal unit"]
        if(valuesFromCsvFile["Parameter type"] == "float"):
            label = Label(el, text=valuesFromCsvFile["Parameter name"])
            entry = Entry(el, textvariable=DoubleVar(value=valuesFromCsvFile["Parameter value"]))
            if bindingFunction is None:
                bindingFunction = self.updateBioControllerParameterFromEntry
            entry.bind("<Return>", bindingFunction)
            # entry.event_generate("<Return>")
            fakeEvent = SimpleNamespace(widget = entry, parent = el)
            bindingFunction(fakeEvent)
            label.pack(side=LEFT)
            entry.pack(side=LEFT)
            if refreshFunction is None:
                refreshFunction = self.refreshEntryFromFPGA
            el.refreshValue = partial(refreshFunction, entry)
            
        elif (valuesFromCsvFile["Parameter type"] == "bool") or (valuesFromCsvFile["Parameter type"] == "neg_bool"):
            var = IntVar()
            if bindingFunction is None:
                bindingFunction = self.updateBioControllerParameterFromCheckbox
            on,off = (1,0) if valuesFromCsvFile["Parameter type"] == "bool" else (0,1)
            checkbox = Checkbutton(el, text=valuesFromCsvFile["Parameter name"], variable=var,onvalue=on,offvalue=off, 
                                   command=partial(bindingFunction, el, var))
            var.set(valuesFromCsvFile["Parameter value"])
            bindingFunction(el, var)
            checkbox.pack(side=BOTTOM)
            if refreshFunction is None:
                refreshFunction = self.refreshCheckboxFromFPGA
            el.refreshValue = partial(refreshFunction, el, var)
        return el              


if __name__ == '__main__':
    root = Tk()
    root.title('OT Thorlabs piezo QPD')
    root.geometry('960x600')
    niframe = NiFrame(root, 'Dev1')
    niframe.pack(expand=True, fill='both')
    root.mainloop()
    niframe.cleanup()