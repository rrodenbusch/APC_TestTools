#!/usr/bin/python3
#  sudo apt-get install python3-matplotlib
from gpiozero import CPUTemperature
from time import sleep, strftime, time
import matplotlib.pyplot as plt

cpu = CPUTemperature()

plt.ion()
x = []
y = []

def write_temp(temp):
    with open("/home/pi/cpu_temp.csv", "a") as log:
        log.write("{0},{1}\n".format(strftime("%Y-%m-%d %H:%M:%S"),str(temp)))

def graph(temp):
    y.append(temp)
    x.append(time())

    plt.figure(1)
    plt.subplot(211)
#    plt.clf()
    plt.scatter(x,y)
    plt.plot(x,y)
    plt.draw()
#    plt.pause(0.05);

    plt.subplot(212)
#    plt.clf()
    plt.scatter(x,y)
    plt.plot(x,y)
    plt.draw()
#    plt.pause(0.05);

while True:
    temp = cpu.temperature
    write_temp(temp)
    graph(temp)
    #sleep(.1)
