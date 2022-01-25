# LeabraLite
A processing port and modification of the Leabra neural modeling framework

## Modifications
1. Connection class is abstract, and is implemented by
  1. LayerConnection: standard connection between layers, but weights are also connectable using ConnectableWeight class 
  1. DendriteConnection: allows connection to a connection; typically used for modulation of a connection in terms of gating or learning rate  
  2. ReservoirConnection: connection between layers and Reservoir instances, which can be used to model intercellular space, and non-synaptic connections
2. Support for NetworkModules; this is a java interface which can be implemented and added to a network; typically a collection of Layers and Connections

## Links to original Leabra resources
TODO

## References
TODO
