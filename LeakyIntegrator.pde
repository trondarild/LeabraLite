class LeakyIntegrator implements Connectable{
    String name;
    
    LeakyIntegratorSpec spec;
    float store;
    float input;
    // float growth;
    // float accumulate;
    // float decaythreshold;
    // float decayfactor;
    Buffer buffer;
    ConnectableParams params;
    ArrayList<Float> mod_inputs = new ArrayList<Float>();
    
    LeakyIntegrator() {
        this.spec = new LeakyIntegratorSpec();
        //this.type = DOPAMINE;
        buffer = new Buffer(spec.default_buf_size);
        params = new ConnectableParams();
    }

    LeakyIntegrator(LeakyIntegratorSpec spec){
        this.spec = spec;
        // this.type = type;
        buffer = new Buffer(spec.default_buf_size);
        params = new ConnectableParams();
    }

    ConnectableParams params() {return params;}
    void add_inhibitory(float a) {} // not applicable
    void add_excitatory(float a) {}
    void add_modulator(int type, float a) {
        // println(this.name + ": type= " + type + "; input= " + a);
        this.spec.type = type; // should always be same
        this.mod_inputs.add(a);
    } // type set in spec
    float act() {return getOutput();}
    float act_ext() {return 0;} // not applicable 

    Buffer getBuffer() {
        return buffer;
    }

    float getOutput() {
        return store;
    }

    float output() {
        return store;
    }

    void calculate_net_in() {
        this.spec.calculate_net_in(this);
    }

    void cycle(){
        this.spec.cycle(this);
        buffer.append(this.store);
    }

    void setInput(float inp){
        input = inp; 
    }


}

class LeakyIntegratorSpec {
    float growth = 0.9; // how much of input to use when integrating
    float accumulate = 0.9; // how much of store to retain when growing
    float decaythreshold = 0.1; // leak if input less than this
    float decayfactor = 0.1; // how much to in total of input and store to pass on
    int default_buf_size = 100;
    int type = DOPAMINE;

    LeakyIntegratorSpec() {

    }

    void calculate_net_in(LeakyIntegrator unit){
        float net_raw = 0;

        if(unit.mod_inputs.size() > 0) {
            net_raw = sumArray(unit.mod_inputs);
            unit.mod_inputs.clear();
        }
        unit.input = net_raw;
    }

    void cycle(LeakyIntegrator a){
        float epsilon = this.growth;
        float lambda = this.accumulate;
        if(a.input < this.decaythreshold){
            epsilon = this.decayfactor;
            lambda = 0;
        }
        a.store += epsilon*(a.input - (1-lambda)*a.store);
        a.params.act = a.store;
    }
}
