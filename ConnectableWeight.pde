//
// ConnectableWeight supports modulation of Connections
//
class ConnectableWeight implements Connectable {
    /**
    LayerConnection implements ConnectableComposite, and
    ConnectableWeights are its units, that can be connected to,
    but not from

    TODO: this may also need a Spec class to handle learning etc
    */
    String name;
    ArrayList<Float> inh_inputs = new ArrayList<Float>();
    ArrayList<Pair<Integer, Float> > mod_inputs = new ArrayList<Pair<Integer, Float> >(); // neuromodulators
    ConnectableParams params;
    private float wt; // actual weight to be set on link if not inhibited
    float lrate; // modulated learning rate to be set on link
    UnitLink link;
    float g_e; // excitatory current
    float tau_net    = 1.4;
    ConnectableWeightSpec spec;
    

    ConnectableWeight(UnitLink link){
        spec = new ConnectableWeightSpec();
        this.wt = link.wt;
        this.link = link;
        params = new ConnectableParams();
        this.name = ((Unit)(link.pre())).name + " -> w: " + ((Unit)(link.post())).name;
    }

    ConnectableWeight(UnitLink link, ConnectableWeightSpec spec){

        this.spec = spec;
        this.wt = link.wt;
        this.link = link;
        params = new ConnectableParams();
        this.name = ((Unit)(link.pre())).name + " -> w: " + ((Unit)(link.post())).name;
    }

    ConnectableParams params() {return params;}
    void add_inhibitory(float a) {inh_inputs.add(a);}
    void add_excitatory(float a) {} // not applicable
    void add_modulator(int type, float a) {
        this.mod_inputs.add(new Pair<Integer, Float>(type, a));
    } 
    float act() {return this.params.act;} // TODO: this should be from the inh interneuron unit, not from the pyramidal
    float act_ext() {return 0;} // cannot be activated by direct current

    float dt_net(){
        return 1.0 / this.tau_net;
    }

    void calculate_net_in() {
        // TODO, one weight can have multiple ins;
        // TODO, move to Spec class?
        this.spec.calculate_net_in(this);
    }

    void cycle() {
       this.spec.cycle(this);
    }
}

class ConnectableWeightSpec {
    /** Connectable weight specification

    References:
        TODO add references for effects of various receptors
    */

    String[] impl_receptors = {"M1"}; // use these names to add to receptor list for a unit
    StringList receptors = new StringList();
    float thr = 0.25; // threshold for on-off dynamics when used with inhibition

    ConnectableWeightSpec() {
    }

    ConnectableWeightSpec(ConnectableWeightSpec cp){
        // copy constructor
        this.receptors = cp.receptors.copy();
    }

    void calculate_net_in(ConnectableWeight unit) {
        float net_raw = 0.0;
        float dt_integ = 1.0;
        float lratemod = 0;
        
        if(unit.mod_inputs.size() > 0){
            for (Pair<Integer, Float> p: unit.mod_inputs){
                float val = p.getValue();
                switch (p.getKey()) {
                    case ACETYLCHOLINE:
                        if(receptors.hasValue("M1")) // M1 can modulate learning rate
                            lratemod += val;
                        break;
                    default:
                        // not implemented
                }
            }
            unit.mod_inputs.clear();
        }
        
        if (unit.inh_inputs.size() > 0){ // TAT 2021-12-10: support for inh projections TODO check if this is valid
            // computing net_raw, the total, instantaneous, inhbitory input for the neuron
            net_raw = sumArray(unit.inh_inputs);
            unit.inh_inputs.clear();
        }

        // updating net
        //this.g_e += dt_integ * this.dt_net() * (net_raw - this.g_e);  // eq 2.16
        unit.g_e = net_raw;
        // println(this.name + ":net_in: g_e" + this.g_e);
        unit.link.lrate_mod = lratemod; // TODO this should be scaled by number of conns, or be limited

    }

    void cycle(ConnectableWeight unit) {
        // check Unit for info on how to handle inh inputs
        unit.params.act = unit.g_e; // correct?
        // mod the post link: TODO fit this to data, see e.g. Yang 2016
        //this.link.wt = this.wt /(1+this.g_e);
        //println("ConnectableWeightSpec::cycle: unit.name: " +unit.name + "; unit.g_e: " + unit.g_e + "; un.wt: " + unit.wt);
        //unit.link.wt = unit.g_e >= unit.thr ? 0 : unit.wt; // on-off dynamics
        unit.link.wt = unit.g_e >= this.thr ? 0 : unit.wt; // on-off dynamics
        
        //println("ConnectableWeightSpec::cycle: unit.name: " +unit.name + "; unit.g_e: " + unit.g_e + "; un.wt: " + unit.wt + "; link.wt: " + unit.link.wt);
        //println(unit.name + ":cycle: post.wt: " + unit.link.wt + "; ge: " + unit.g_e);

    }
    
}
