def install_and_import(package):
	import subprocess
	import sys
	try:
		__import__(package)
	except ImportError:
		try:
			subprocess.check_call([sys.executable, "-m", "pip", "uninstall", package])
			subprocess.check_call([sys.executable, "-m", "pip", "install", package])
		except:
			subprocess.check_call([sys.executable, "-m", "pip", "install", f"py{package}"])
		__import__(package)
		
install_and_import("matplotlib")


import matplotlib.pyplot as plt
import matplotlib.figure

class interactivePlot(matplotlib.figure.Figure):
	nOfClicks = 1
	def __init__(self, functionOnClick, **kwargs):
		super().__init__(**kwargs)
		self.clicks = []
		self.cid = self.canvas.mpl_connect('button_press_event', self.onclick)
		self.functionOnClick = functionOnClick

	def onclick(self, event):
		print(event)
		if event.inaxes:
			self.clicks.append((event.xdata, event.ydata))
			if len(self.clicks) >= 3:  # Change this number to the desired amount of clicks
				self.functionOnClick(self.clicks)
				self.clicks = []


if __name__ == '__main__':
	# Example of how to use the interactivePlot class
	def functionOnClick(clicks):
		print(clicks)

	fig = plt.figure()
	ax = fig.add_subplot(111)
	ax.plot([1, 2, 3], [1, 2, 3])

	interactivePlot(functionOnClick)
	plt.show()


	