# LeabraLite
A processing port and modification of the Leabra neural modeling framework. Based on a python port of Leabra 8.0 (TODO add link).

* 2022-01-28: This is heavily in development; nothing can be expected to work!

## Installation
1. Intall the required processing libraries: TheMidiBus (for controlling sketches with MIDI)
1. clone the repository, e.g. into your Processing sketchbook folder
2. Open the LeabraLite.pde sketch in Processing
## Modifications
1. Connection class is abstract, and is implemented by
    1. LayerConnection: standard connection between layers, but weights are also connectable using ConnectableWeight class 
    1. DendriteConnection: allows connection to a connection; typically used for modulation of a connection in terms of gating or learning rate  
    2. ReservoirConnection: connection between layers and Reservoir instances, which can be used to model intercellular space, and non-synaptic connections
2. Support for NetworkModules; this is a java interface which can be implemented and added to a network; typically a collection of Layers and Connections. The thought is that this may help tidy up creating "brain modules" like Amygdala, Basal Ganglia etc

## Building blocks
### Leabra classes
1. Unit: 
2. Layer
3. Connection
4. Network
### LeabraLite classes
1. Reservoir: set of leaky integrators for modeling intercellular accumulation of neuromodulators
### LeabraLite modules
1. ChoiceModule: integrates value for alternatives until a choice is made 
2. EffortModule: recruits a neural population based on a control signal, to be directed at a population in need of extra excitation
3. ValenceLearningModule: increases weights of avoid or approach pathways for a set of properties based on positive and negative valence
4. BasalGangliaModule: simple BG module which control "gas", "break" for behaviours. Currently has only on/off behaviours, not graded responses
5. RuleModule: input-output mapping with definable weights which can be used to model rules for experimental tasks; use DendriteConnection to turn on and off rules
### Templates
* TestTemplate.pde: template for testing networks
* ModuleTemplate.pde: template for modules
* TestModuleTemplate.pde: template for testing modules
## Links to original Leabra resources
TODO

## References
TODO
