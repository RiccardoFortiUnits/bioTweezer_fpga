import random
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import csv
class Particle:
	def __init__(self, mass, Lambda, k, temperature, position=0.0, velocity=0.0):
		self.mass = mass
		self.k = k
		self.l = Lambda
		self.temperature = temperature
		self.position = position
		self.velocity = velocity

	def step(self, dt):
		# Constants
		k_B = 1.380649e-23  # Boltzmann constant in J/K

		# Random force due to Brownian motion
		random_force = random.gauss(0, (2 * self.l * k_B * self.temperature / dt) ** 0.5)

		# Elastic force
		elastic_force = -self.k * self.position

		# drag force
		drag_force = -self.l * self.velocity

		# Total force
		total_force = elastic_force + drag_force + random_force

		# Update velocity and position using Langevin equation
		self.velocity += total_force * dt / self.mass
		self.position += self.velocity * dt

	def plot_movement(self, total_time, dt, saveToFile = None):
		positions = []
		times = []
		stiffnesses = []
		time = 0.0
		while time <= total_time:
			self.step(dt)
			positions.append(self.position)
			times.append(time)
			stiffnesses.append(self.k)
			time += dt

		plt.plot(times, positions)
		plt.xlabel('Time (s)')
		plt.ylabel('Position (m)')
		plt.title('Particle Movement Over Time')
		plt.show()
		if saveToFile is not None:
			with open(saveToFile, 'w', newline='') as csvfile:
				writer = csv.writer(csvfile)
				writer.writerow(['time', 'position', 'stiffness'])
				for t, p, k in zip(times, positions, stiffnesses):
					writer.writerow([t, p, k])
	
	@staticmethod
	def _thresholdCrossed(x0, prevX, x):
		return (x0 - prevX) * (x0 - x) < 0
	def firstTimePassages(self, thresholds, dt, decimation, nOfPassages, maxTime):
		time = 0.0
		passageTimes = [[] for _ in range(len(thresholds))]
		previousPosition = self.position
		states = [False] * len(thresholds)  # False: try to cross x0, True: try to cross x1
		startTimes = [-1] * len(thresholds)
		# positions = []
		# times = []
		# decimated_positions = []
		# decimated_times = []

		while maxTime < 0 or time <= maxTime:
			currentPosition = 0
			for _ in range(decimation):
				self.step(dt)
				# positions.append(self.position)
				# times.append(time)
				time += dt
				currentPosition += self.position
			currentPosition /= decimation
			# decimated_positions.append(self.position)
			# decimated_times.append(time)

			for i, (x0, x1) in enumerate(thresholds):
				if (not states[i]) and self._thresholdCrossed(x0, previousPosition, currentPosition):
					startTimes[i] = time
					states[i] = not states[i]
				elif states[i] and self._thresholdCrossed(x1, previousPosition, currentPosition):
					passageTimes[i].append(time - startTimes[i])
					states[i] = not states[i]
					if len(passageTimes[i]) >= nOfPassages:
						if all(len(passageTimes[j]) >= nOfPassages for j in range(len(thresholds))):
							# plt.plot(times, positions)
							# plt.plot(decimated_times, decimated_positions)
							# plt.xlabel('Time (s)')
							# plt.ylabel('Position (m)')
							# plt.title('Particle Movement Over Time')
							# plt.show()
							return passageTimes
			previousPosition = self.position

		# plt.plot(times, positions)
		# plt.plot(decimated_times, decimated_positions)
		# plt.xlabel('Time (s)')
		# plt.ylabel('Position (m)')
		# plt.title('Particle Movement Over Time')
		# plt.show()
		return passageTimes

# Example usage
# particle = Particle(mass=.0001, Lambda=28.3e-5, k=13e-6, temperature=300, position=0)
# thresholds = [(i, 0) for i in np.linspace(1e-9,5e-9, 5)]
# # thresholds = thresholds + [(b, a) for (a,b) in thresholds]

# times = particle.firstTimePassages(thresholds,dt=1e-6,decimation=100,nOfPassages=1000,maxTime=10)
# # times = np.array([np.array(t) for t in times])

# for i in range(len(thresholds)):
# 	x0, x1 = thresholds[i]
# 	t = times[i]
# 	# sns.kdeplot(t, label=f"{x0} to {x1}" , clip=(min(t), max(t)))
# 	plt.hist(t, bins=300, density=True, alpha=0.6, label=f"{x0} to {x1}")
# 	# plt.plot([0, 0], [0, max(t)], 'k-', lw=2)  # Ensure the probability at t=0 is 0, bins=30, density=True, alpha=0.6, label=f"{x0} to {x1}")
	
# plt.legend()
# plt.xlabel('Time (seconds)')
# plt.ylabel('Density')
# plt.show()

baseStiffness = 1e-5
higherStiffness = baseStiffness*3
x0=[0]
x1=[10e-9, -10e-9]
state = True  # True: try to cross x1, False: try to cross x0
prevPosition = 0
def crossed(previous, current, value):
	return (value - previous) * (value - current) <= 0
def changeStiffness(particle):
	global state, x0, x1, baseStiffness, higherStiffness, prevPosition
	if state:
		for x in x1:
			if crossed(prevPosition, particle.position, x):
				state = False
				particle.k = higherStiffness
	else:
		for x in x0:
			if crossed(prevPosition, particle.position, x):
				state = True
				particle.k = baseStiffness
	prevPosition = particle.position
for i in range(10):
	prevPosition = 0
	state = True
	print(f"Iteration {i+1}")
	particle = Particle(mass=.0000001, Lambda=28.3e-6, k=baseStiffness, temperature=300, position=prevPosition)
	particle.step = lambda dt: (changeStiffness(particle), Particle.step(particle, dt))[1]  # Call changeStiffness before the original step method
	particle.plot_movement(total_time=80, dt=0.0001, saveToFile=f"particle_movement_{i+1}.particleInPotential")
a=0