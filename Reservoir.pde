//
// Reservoir models aggregates of neuromodulaters in 
// intercellular tissue, that affects non-synaptic 
// receptors
//
// ref: 



class Reservoir implements ConnectableComposite {
    String name;
    int size;
    // int type; // type of neuromodulator
    
    ReservoirSpec spec;
    LeakyIntegrator[] units;
    Buffer[] buffers;
    float avg_act_p_eff = 0.0;
    float avg_act = 0.0;

    // TODO: make special connections for reservoirs
    ArrayList<Connection> from_connections = new ArrayList<Connection>();
    ArrayList<Connection> to_connections = new   ArrayList<Connection>();

    Reservoir(int size, String name) {
        this.name = name;
        this.size = size;
        //this.type = type;
        this.spec = new ReservoirSpec();
        //this.spec.type = type;
        LeakyIntegratorSpec unit_spec = new LeakyIntegratorSpec();
        // unit_spec.type = type;

        units = new LeakyIntegrator[size];
        for (int i = 0; i < units.length; ++i) {
            units[i] = new LeakyIntegrator(unit_spec);
            units[i].name = this.name + "_" + i;
        }
        buffers = new Buffer[size];
        avg_act_p_eff = 1.0;

    }

    Reservoir(int size, ReservoirSpec spec, LeakyIntegratorSpec unit_spec, String name){
        /**
        size - number of leaky integrators
        spec - custom values
        unit_spec - custom values for units
        type - which neuromodulator - this affects receiving neural units
        name - name of reservoir
        */
        this.name = name;
        this.size = size;
        this.spec = spec;
        //this.spec.type = type;
        if(this.spec == null) this.spec = new ReservoirSpec();

        units = new LeakyIntegrator[size];
        for (int i = 0; i < units.length; ++i) {
            units[i] = new LeakyIntegrator(unit_spec);
            units[i].name = this.name + "_" + i;
        }
        buffers = new Buffer[size];
        avg_act_p_eff = 1.0;
    }
    
    String name() {return name; }
    Connectable[] units() { return units; } 
    float avg_act_p_eff() { return avg_act_p_eff;}
    void add_from_connections(Connection from) {from_connections.add(from);};
    void add_to_connections(Connection to) {to_connections.add(to);};
    ArrayList<Connection> from_connections() {return from_connections;}
    ArrayList<Connection> to_connections() {return to_connections;}

    void cycle(String phase) {
        this.spec.cycle(this);
        for (int i = 0; i < this.size; ++i) {
            // units[i].calculate_net_in();
            // units[i].cycle();
            buffers[i] = units[i].getBuffer();
        }
    }

    void setInput(float[] inp) {
        assert(inp.length == units.length) : inp.length + " != " + units.length;
        for (int i = 0; i < inp.length; ++i) {
            units[i].setInput(inp[i]);
        }
    }

    float[] getOutput() {
        return output();
    }

    float[] output() {
        float[] retval = zeros(this.size);
        for (int i = 0; i < this.size; ++i) {
            retval[i] = units[i].getOutput();
        }
        return retval;
    }

}

class ReservoirSpec {
    // TODO is this needed?
    // int type = DOPAMINE;
    
    void cycle(Reservoir reservoir) {
        for(LeakyIntegrator u : reservoir.units){
            u.calculate_net_in();
            u.cycle();
        }
        reservoir.avg_act = mean(reservoir.output());
        // TODO update logs
    }
}
