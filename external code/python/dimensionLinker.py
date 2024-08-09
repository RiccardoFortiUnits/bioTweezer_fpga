# -*- coding: utf-8 -*-
"""
Created on Wed Jul 31 17:06:54 2024

@author: lastline
"""

import networkx as nx
import numpy as np

def graphFromCheckedGraph(checked, startingNode):
    G=[]
    sub_graphFromCheckedGraph(G, checked, startingNode, None)
    return G
    
def sub_graphFromCheckedGraph(G, checked, currentNode, startingNode = None):
    parents = checked[currentNode][1]
    for p in parents:
        sub_graphFromCheckedGraph(G, checked, p, currentNode)
    if(startingNode is not None):
        G.append((currentNode, startingNode))

def shortestPath(G, startNodes, endNode):
    if not isinstance(startNodes, list):
        startNodes = [startNodes]
    queues = [[node] for node in startNodes]
    checked = {key: [1,[]]  for key in G.nodes}
    for node,data in G.nodes(data=True):
        if data["mult"]:
            checked[node][0] = len(G.edges(node))-1
        elif node in startNodes:
            checked[node][0] = 0
    stillSomeNodes = True
    currentDistance = 0
    while stillSomeNodes:
        for i,node in enumerate(startNodes):
            q = queues[i].copy()
            queues[i] = []
            for n in q:
                newNodes = [el[1] for el in list(G.edges(n))]
                for nn in newNodes:
                    if checked[nn][0] != 0:
                        checked[nn][0] -= 1
                        checked[nn][1].append(n)
                        if checked[nn][0] == 0:
                            if nn == endNode:
                                return graphFromCheckedGraph(checked, endNode)
                            queues[i].append(nn)
        currentDistance += 1
        stillSomeNodes = any(len(q) > 0 for q in queues)
    return []

class dimensionLinker():
    def __init__(self):
        self.g = nx.DiGraph()
    
    def addDimension(self, dimensionName, dimensionMeasurementUnit = "[adimensional]", **attr):
        # if(isinstance(dimensionName, list)):
        #     self.g.add_nodes_from(dimensionName)
        # else:
            self.g.add_node(dimensionName, unit = dimensionMeasurementUnit, mult = False, **attr)
        
    def addConnection(self, dimension0, dimension1, from0to1, from1to0 = None):
        if(from1to0 is None):
            from0to1, from1to0 = from0to1
        self.g.add_edge(dimension0, dimension1, transferFun = from0to1)
        self.g.add_edge(dimension1, dimension0, transferFun = from1to0)
    def addMultiConnection(self, dimensions, conversionFunctions=None):#, functionGenerator = None):
        # if len(dimensions) == 2:
        #     addConnection(dimensions[0],dimensions[1],...)
        l = len(dimensions)
        self.g.add_node(str(dimensions), mult = True)
        if(conversionFunctions is not None):
            for i in range(l):
                self.g.add_edge(dimensions[i], str(dimensions), transferFun = conversionFunctions[i])
                self.g.add_edge(str(dimensions), dimensions[i], transferFun = lambda x: x)
        # elif(functionGenerator is not None):
        #     for i in range(l):
        #         self.g.add_edge(dimensions[i], dimensions, transferFun = functionGenerator(i))
    
    def convert(self, values, fromDimensions, toDimension):
        if not isinstance(fromDimensions, list):
            fromDimensions = [fromDimensions]
            values = [values]
        nodeList = shortestPath(self.g, fromDimensions, toDimension)
        multiNodesInputs = {}
        for (startNode, endNode) in nodeList:
            if self.g.nodes(data= True)[startNode]["mult"]:
                fromDimensions.append(startNode)
                values.append(self.g[endNode][startNode]["transferFun"](**multiNodesInputs[startNode]))
                
            valueIdx = fromDimensions.index(startNode)
            
            if self.g.nodes(data= True)[endNode]["mult"]:
                if endNode not in multiNodesInputs.keys():
                    multiNodesInputs[endNode] = {}
                multiNodesInputs[endNode][startNode] = values[valueIdx]
            else:
                fromDimensions[valueIdx] = endNode
                values[valueIdx] = self.g[startNode][endNode]["transferFun"](values[valueIdx])
                
        return values[fromDimensions.index(toDimension)]
        # for path in allPaths:
        #     for node in path:
        #         if node not in checkedMultiNodes and self.g.nodes[node].mult:
        
        #             currentVal = value
        # for i in range(len(nodeList)-1):
        #     currentVal = self.g[nodeList[i]][nodeList[i+1]]["transferFun"](currentVal)
        # return currentVal
    
    
    def convert_old(self, value, fromDimension, toDimension):
        nodeList = nx.shortest_path(self.g, source = fromDimension, target = toDimension)
        currentVal = value
        for i in range(len(nodeList)-1):
            currentVal = self.g[nodeList[i]][nodeList[i+1]]["transferFun"](currentVal)
        return currentVal
    def clearEdges(self):
        self.g.clear_edges()
        
    def checkForLoops(self):
        #some loops would mean that a value can be converted in more than one way, which should be avoided. Use this function to check for loops
        cycles = list(nx.simple_cycles(self.g))
        cycles = [lst for lst in cycles if len(lst) > 2]
        if len(cycles) > 0:
            print("Loops found:")
            for c in cycles:
                print(c)
    
    @property
    def nodes(self):
        return self.g.nodes
    
    @staticmethod
    def gainFunctions(gain):
        def from0to1(val):
            return val * gain
        def from1to0(val):
            return val / gain
        return (from0to1, from1to0)
    @staticmethod
    def shift_n_gainFunctions(shift, gain):
        def from0to1(val):
            return (val + shift) * gain
        def from1to0(val):
            return val / gain - shift
        return (from0to1, from1to0)
    @staticmethod
    def gain_n_shiftFunctions(gain, shift):
        def from0to1(val):
            return val * gain + shift
        def from1to0(val):
            return (val - shift) / gain
        return (from0to1, from1to0)
    @staticmethod
    def squareFunctions():
        def from0to1(val):
            return val ** 2
        def from1to0(val):
            return np.sqrt(val)
        return (from0to1, from1to0)
    
    @staticmethod
    def monomialFunctions(list1, list2, constantGain = 1):
        def fun1(**kwargs):
            val = constantGain
            for key, value in kwargs.items():
                if key in list2:
                    val *= value
                elif key in list1:
                    val /= value
            return val
        
        def fun2(**kwargs):
            val = 1 / constantGain
            for key, value in kwargs.items():
                if key in list1:
                    val *= value
                elif key in list2:
                    val /= value
            return val
        return [fun1]*len(list1) + [fun2]*len(list2)
        
       
# G = dimensionLinker()  # or DiGraph, MultiGraph, MultiDiGraph, etc
# G.addDimension("pix","[a]")
# G.addDimension("x","m")
# G.addDimension("v","m/s")
# G.addDimension("t","s")
# G.addDimension("a","m/s^2")
# G.addDimension("m","kg")
# G.addDimension("p","kg*m/s")



# G.addConnection("pix", "x", dimensionLinker.gainFunctions(1/100))
# G.addMultiConnection(["x","v","t"], dimensionLinker.monomialFunctions(["x"],["v","t"]))
# G.addMultiConnection(["v","a","t"], dimensionLinker.monomialFunctions(["v"],["a","t"]))
# G.addMultiConnection(["p","v","m"], dimensionLinker.monomialFunctions(["p"],["v","m"]))
# q=G.convert([10, 0.3, 0.1], ["pix", "m", "t"], "p") 
# print(q)