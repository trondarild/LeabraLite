/**
Implementation of a Leabra Unit, reproducing the behavior of emergent 8.0.

We implement only the rate-coded version. The code is intended to be as simple
as possible to understand. It is not in any way optimized for performance.
*/

// type of layer and correspondingly, unit behaviors
import java.util.HashMap;
import java.util.Map;
import javafx.util.Pair;


static int INPUT  = 0;
static int HIDDEN = 1;
static int OUTPUT = 2;
static int TARGET = 2; // same as output and used for error training

class Unit implements Connectable {
    String name;
    UnitSpec spec;
    int genre = INPUT;
    Buffer buffer;

    ConnectableParams params;

    int default_buf_sz = 100;
    
    Map<String, FloatList> logs = new HashMap<String, FloatList>();
    String[] log_names = {"net", "I_net", "v_m", "act", "v_m_eq", "adapt"};
    float avg_ss; // super-short-term avg
    float avg_s; // short term avg
    //float avg_m; // medium term avg
    //float avg_l; // long term avg
    //float avg_s_eff; // linear mix of short and medium term avg, used in learning
    ArrayList<Float> ex_inputs = new ArrayList<Float>();
    ArrayList<Float> inh_inputs = new ArrayList<Float>(); // TAT 2021-12-10: added inh inputs, different from internal inh
    ArrayList<Pair<Integer, Float> > mod_inputs = new ArrayList<Pair<Integer, Float> >(); // neuromodulators
    
    float g_e; // 
    float I_net;
    float I_net_r;
    float v_m;
    float v_m_eq;
    //float act_ext = 0;
    //float act = 0;
    float act_nd = 0; // non-depressed activity (pre-inhibition?)
    float act_m = 0; // "minus activity", to be compared with act in plus phase
    float adapt = 0;
    float spike = 0;
    float net = 0;
    float act_thr = 0;
    // dopa and adenosine
    float r_d1 = 0.0;
    float r_d2 = 0.0;
    float r_a1 = 0.0;
    float r_a2 = 0.0;
    float r_m1 = 0.0;

    Unit(){
        /*        
        spec:  UnitSpec instance with custom values for the unit parameters.
               If None, default values will be used.
        
        */
        genre = HIDDEN;  // type of Unit

        // this.spec = spec;
        // if (this.spec == Null)
            this.spec = new UnitSpec();
            this.params = new ConnectableParams();

        // this.log_names = {"net", "I_net", "v_m", "act", "v_m_eq", "adapt"};
        //this.logs  = {name: [] for name in this.log_names}

        this.reset();

        // averages of the activity
        this.avg_ss    = this.spec.avg_init; // super-short-term average
        this.avg_s     = this.spec.avg_init; // short-term average
        this.params.avg_m     = this.spec.avg_init; // medium-term average
        this.params.avg_l     = this.spec.avg_l_init; // long term avg(?)
        this.params.avg_s_eff = 0.0 ; // linear mixing of avg_s and avg_m

        buffer = new Buffer (default_buf_sz);

    }
    Unit(UnitSpec spec, int genre){
        this.spec = spec;
        this.genre = genre;
        this.log_names = new String[1];
        this.params = new ConnectableParams();
        this.reset();

        // averages of the activity
        this.avg_ss    = this.spec.avg_init; // super-short-term average
        this.avg_s     = this.spec.avg_init; // short-term average
        this.params.avg_m     = this.spec.avg_init; // medium-term average
        this.params.avg_l     = this.spec.avg_l_init;
        this.params.avg_s_eff = 0.0 ; // linear mixing of avg_s and avg_m

        buffer = new Buffer (default_buf_sz);
    }
    
    Unit(UnitSpec spec, int genre, String[] log_names){
        this.spec = spec;
        this.genre = genre;
        this.log_names = log_names;
        this.params = new ConnectableParams();
        this.reset();

        // averages of the activity
        this.avg_ss    = this.spec.avg_init; // super-short-term average
        this.avg_s     = this.spec.avg_init; // short-term average
        this.params.avg_m     = this.spec.avg_init; // medium-term average
        this.params.avg_l     = this.spec.avg_l_init;
        this.params.avg_s_eff = 0.0 ; // linear mixing of avg_s and avg_m

        buffer = new Buffer (default_buf_sz);
    }

    ConnectableParams params() {return params;}
    float act() {return act_eq();}
    float act_ext() {return params.act_ext;}

    float getOutput(){
        return act_eq();
    }

    Buffer getBuffer(){
        return buffer;
    }

    float act_eq(){
        return params.act;
    }

    float avg_l_lrn(){
        return this.spec.avg_l_lrn(this);
    }

    void cycle(String phase){
        this.cycle(phase, 0.0, 1);
    }

    void cycle(String phase, float g_i, float dt_integ){
        // """Cycle the unit"""
        // phase = "minus", "plus" -> predict, sample
        // g_i - inhibition input 0..1 # TAT for wta
        // dt_integ - time delta (?)
        // return self.spec.cycle(self, phase, g_i=g_i, dt_integ=dt_integ)
        // 2021-12-05 change to use dopa, adeno
        
        // this.spec.cycle_da(this, phase, g_i, dt_integ);
        if(this.spec.use_modulators)
            this.spec.cycle_mod(this, phase, g_i, dt_integ);
        else
            this.spec.cycle(this, phase, g_i, dt_integ);
        buffer.append(act_eq());
    }

    void calculate_net_in(){
        this.spec.calculate_net_in(this, 1);
    }

    float net(){
        // """Excitatory conductance."""
        return this.spec.g_bar_e * this.g_e;
    }

    void force_activity(float act_ext){
        /** """Force the activity of a unit.

        The activity of the unit will remain at that value for subsequent cycles,
        until `force_activity()` is called with a different values, or until
        `add_excitatory()` is called, which will resume updating `I_net` and
        `v_m` and compute `act` based on those.
        """
        */
        assert (this.ex_inputs.size() == 0);  // avoiding mistakes
        this.params.act_ext = act_ext; //# forced activity
        this.spec.force_activity(this);

        // # self.act    = act  # FIXME: should the activity be delayed until the start of the next cycle?
        // # self.act_nd = act
    }

    void add_excitatory(float inp_act){
        // """Add an input for the next cycle."""
        //println(this.name + ": " + inp_act);
        this.ex_inputs.add(inp_act);

    }

    void add_inhibitory(float inp_inh){ // TAT 2021-12-10: for inh projections
        this.inh_inputs.add(inp_inh);
    }

    void add_modulator(int type, float a) {
        this.mod_inputs.add(new Pair<Integer, Float>(type, a));
    }

    void update_avg_l(){
        this.spec.update_avg_l(this);
    }

    void set_dopa(float da) { // TAT 2022-01-09
        // first approx: set dependent on D1 D2 thresholds
        // TODO add weights on dedicated connection
        // TODO perhaps probability of dopa based on gaussian?
        this.r_d1 = da < this.spec.d1_thr ? da : 0.0;
        this.r_d2 = da >= this.spec.d2_thr ? da : 0.0;
    }

    void set_adeno(float ado) { // TAT 2022-01-09
        // first approx: set dependent on A1 A2 thresholds
        // TODO add weights on dedicated connection
        this.r_a1 = ado <  this.spec.a1_thr ? ado : 0.0;
        this.r_a2 = ado >= this.spec.a2_thr ? ado : 0.0;
    }


    void reset(){
        // """Reset the Unit state. Called at creation, and at every trial."""
        this.ex_inputs.clear();              // excitatory inputs for the next cycle
        this.g_e     = 0;                  // excitatory conductance
        this.I_net   = 0;                  // net current
        this.I_net_r = this.I_net;         // net current, equilibrium version (for v_m_eq)
        this.v_m     = this.spec.v_m_init; // membrane potential
        this.v_m_eq  = this.v_m;           // equilibrium membrane potential
                                          // (not reseted after a spike)
        this.params.act_ext = 0;               // externally forced activity (None for not forced)
        this.params.act     = 0;                  // current activity
        this.act_nd  = this.params.act;           // non-depressed activity # FIXME: not implemented yet
        this.act_m   = this.params.act;           // activity at the end of the minus phase; prediction

        this.adapt   = 0;     // adaptation current: causes the rate of activation
                              // to decrease over time
        this.r_d1 = 0;
        this.r_d2 = 0;
        this.r_a1 = 0;
        this.r_a1 = 0;
        this.r_m1 = 0;
    }

    void update_logs(){
        // """Record current state. Called after each cycle."""
        // TODO: find nice way of matching string to field, or revert to if block
        // for name in self.logs.keys():
        //    this.logs[name].append(getattr(self, name))
    }

    void show_config(){
        //"""Display the value of constants and state variables."""
        // println("Parameters:");
        String[] params = {"dt_v_m", "dt_net", "g_l", "g_bar_e", "g_bar_l", "g_bar_i",
                     "e_rev_e", "e_rev_l", "e_rev_i", "act_thr", "act_gain"};
        
        //    print("   {}: {:.2f}".format(name, getattr(self.spec, name)))
        // println("State:");
        String[] state = {"g_e", "I_net", "v_m", "act", "v_m_eq"};
        for (String s : state) {
            // println(s + ": " + getField(s));
        }
        //    print('   {}: {:.2f}'.format(name, getattr(self, name)))
    }

    

    float getField(String name){
        switch(name){
        case "g_e": return g_e; 
        case "I_net": return I_net; 
        case "I_net_r": return I_net_r; 
        case "v_m": return v_m; 
        case "v_m_eq": return v_m_eq; 
        case "act_ext": return params.act_ext; 
        case "act": return params.act; 
        case "act_nd": return act_nd; 
        case "act_m": return act_m; 
        case "adapt": return adapt; 
        case "spike": return spike; 
        case "net": return net; 
        case "act_thr": return act_thr; 
        case "r_d1": return r_d1;
        case "r_d2": return r_d2;
        case "r_a1": return r_a1;
        case "r_a2": return r_a2;
        default: return -1;
        }
    }

};

class UnitSpec{
    /**
    Units specification.

    Each unit can have different parameters values. They don't change during
    cycles, and unless you know what you're doing, you should not change them
    after the Unit creation. The best way to proceed is to create the UnitSpec,
    modify it, and provide the spec when instantiating a Unit:

    >>> spec = UnitSpec() // specifying parameters at instantiation
    >>> spec.bias = 0.5               // you can also do it afterward
    >>> u = Unit(spec)           // creating a Unit instance

    ===TAT===
    * 2022-01-09: 
        * Adenosine A1 receptors can interact with Dopamine D1 
        receptors. It has the highest affinity of the adeno receptors 
        (70nM according to Dunwiddie and Masino 2001)

    */

    // time step constants
    float tau_net    = 1.4;     // net input integration time constant (net = g_e * g_bar_e)
    float tau_v_m    = 3.3;     // v_m integration time constant
    // input channels parameters
    float g_l        = 1.0;     // leak current (constant) # TAT 2022-01-26: controlled by D1, D2, M1; # TAT 2022-01-20: controlled by ACh Muscarine receptors?
    float g_bar_l    = 0.1;     // leak maximum conductance
    float g_bar_e    = 1.0;     // excitatory maximum conductance
    float g_bar_i    = 1.0;     // inhibitory maximum conductance
    // reversal potential // TAT what is this?
    float e_rev_e    = 1.0 ;    // excitatory
    float e_rev_l    = 0.3 ;    // leak 
    float e_rev_i    = 0.25;    // inhibitory
    // activation function parameters
    float act_thr    = 0.5 ;    // threshold 2021-12-05 TAT: modulate via dopa D1 D2, adeno A1 A2
    float c_act_thr = 0; // let original vary, this be constant; logistic(0) = 0.5
    float act_gain   = 100 ;    // gain
    boolean noisy_act  = true;    // If True, uses the noisy activation function
    float act_sd     = 0.01;    // standard deviation of the noisy gaussian //FIXME: variance or sd?
    float act_min    = 0.0 ;    // clamp ranges (min, max) for the activation value.
    float act_max    = 0.95;    
    // spiking behavior
    float spk_thr    = 1.2;     // spike threshold for resetting v_m // FIXME: actually used?
    float v_m_init   = 0.4;     // init value for v_m
    float v_m_r      = 0.3;     // reset value for v_m TAT: maybe useful for bursting?
    float v_m_min    = 0.0;     // clamp ranges (min, max) for v_m
    float v_m_max    = 2.0;     
    // adapt behavior
    boolean adapt_on = false  ; // if True, enable the adapt behavior
    float dt_adapt   = 1/144. ; // time-step constant for adapt update
    // float dt_v_m     = 0.0;
    float v_m_gain   = 0.04   ; // gain on v_m driving the adaptation variable
    float spike_gain = 0.00805; // value to add to the adaptation variable after spiking
    // bias 
    float bias       = 0.0;
    // average parameters
    float avg_init   = 0.15;
    float avg_ss_dt  = 0.5; //"super-short" term
    float avg_s_dt   = 0.5; // short term 
    float avg_m_dt   = 0.1; // medium term
    float avg_l_dt   = 0.1; // long term, computed once every trial //FIXME tau
    float avg_l_init = 0.4;
    float avg_l_min  = 0.2;
    float avg_l_gain = 2.5;
    float avg_m_in_s = 0.1; //avg medium term in ?
    float avg_lrn_min = 0.0001; // minimum avg_l_lrn value.
    float avg_lrn_max = 0.5;    // maximum avg_l_lrn value
    // dopa adeno
    boolean use_modulators = false; // TODO: change to use_mod to encompass all modulators
    
    float d1_thr = 0.05; // upper limit for D1 (500nM) Tratham Davidson 2004
    float d2_thr = 0.1; // lower limit for D2 (1000nM) "
    float a1_thr = 0.8; // upper limit for A1 (70 nm, wide dynamic range)
    float a2_thr = 0.9; // lower limit for A2 (5200 nm, very much higher than a1)
    String[] impl_receptors = {"D1", "D2", "A1", "A2", "M1"}; // use these names to add to receptor list for a unit
    StringList receptors = new StringList();

    float[][] nxx1_conv;
    

    UnitSpec(){
        // TODO add params 
    }
    UnitSpec(UnitSpec cp){
        // TODO copy constructor
        this.tau_net = cp.tau_net;
        this.tau_v_m = cp.tau_v_m;
        this.g_l = cp.g_l;
        this.g_bar_e = cp.g_bar_e;
        this.g_bar_l = cp.g_bar_l;
        this.g_bar_i = cp.g_bar_i;
        this.e_rev_e = cp.e_rev_e;
        this.e_rev_l = cp.e_rev_l;
        this.e_rev_i = cp.e_rev_i;
        this.act_thr = cp.act_thr;
        this.c_act_thr = cp.c_act_thr;
        this.act_gain = cp.act_gain;
        this.noisy_act = cp.noisy_act;
        this.act_sd = cp.act_sd;
        this.act_min = cp.act_min;
        this.act_max = cp.act_max;
        this.spk_thr = cp.spk_thr;
        this.v_m_init = cp.v_m_init;
        this.v_m_r = cp.v_m_r;
        this.v_m_min = cp.v_m_min;
        this.v_m_max = cp.v_m_max;
        this.adapt_on = cp.adapt_on;
        this.dt_adapt = cp.dt_adapt;
        this.v_m_gain = cp.v_m_gain;
        this.spike_gain = cp.spike_gain;
        this.bias = cp.bias;
        this.avg_init = cp.avg_init;
        this.avg_ss_dt = cp.avg_ss_dt;
        this.avg_s_dt = cp.avg_s_dt;
        this.avg_m_dt = cp.avg_m_dt;
        this.avg_l_dt = cp.avg_l_dt;
        this.avg_l_init = cp.avg_l_init;
        this.avg_l_min = cp.avg_l_min;
        this.avg_l_gain = cp.avg_l_gain;
        this.avg_m_in_s = cp.avg_m_in_s;
        this.avg_lrn_min = cp.avg_lrn_min;
        this.avg_lrn_max = cp.avg_lrn_max;
        this.use_modulators = cp.use_modulators;
        this.d1_thr = cp.d1_thr;
        this.d2_thr = cp.d2_thr;
        this.a1_thr = cp.a1_thr;
        this.a2_thr = cp.a2_thr;
        //nxx1_conv = copyMatrix(cp.nxx1_conv);
    }

    float avg_l_lrn(Unit unit){
        if (unit.genre != HIDDEN)  // no self-organization for non-hidden layers
            return 0.0;
        float avg_fact = (this.avg_lrn_max - this.avg_lrn_min)/(this.avg_l_gain - this.avg_l_min); // TAT this could be precomputed?
        return this.avg_lrn_min + avg_fact * (unit.params.avg_l - this.avg_l_min); //
    }

    float dt_net(){
        return 1.0 / this.tau_net;
    }

    float dt_v_m(){
        return 1.0 / this.tau_v_m;
    }

    UnitSpec copy(){
        return new UnitSpec(this);
    }

    float xx1(float v_m){
        // """Compute the x/(x+1) activation function."""
        float X = this.act_gain * max(v_m, 0.0);
        // println("xx1: X= " + X + "v_m= "+v_m);
        return X / (X + 1);
    }

    float noisy_xx1(float v_m){
        /*
        """Compute the noisy x/(x+1) activation function.

        The noisy x/(x+1) function is the convolution of the x/(x+1) function
        with a Gaussian with a `self.spec.act_sd` standard deviation. Here, we
        precompute the convolution as a look-up table, and interpolate it with
        the desired point every time the function is called.
        """
        */
        // TODO
        return 0;
    }

    float act_fun(float v_m){
        // TODO support noisy
        return xx1(v_m);
    }

    void calculate_net_in(Unit unit, float dt_integ){
        /** """Calculate the net input for the unit. To execute before cycle().

        If the activity of the unit is forced, then normal external inputs are ignored, and
        net_in is set to the forced activity.
        """
        */
        // handle modulators
        unit.r_d1 = 0;
        unit.r_d2 = 0;
        unit.r_a1 = 0;
        unit.r_a2 = 0;
        unit.r_m1 = 0;
        if(unit.mod_inputs.size() > 0){
            for (Pair<Integer, Float> p: unit.mod_inputs){
                float val = p.getValue();
                switch (p.getKey()) {
                    case ADENOSINE:
                        if(receptors.hasValue("A1"))
                            unit.r_a1 += val < this.a1_thr ? val : 0.0;
                        if(receptors.hasValue("A2"))
                            unit.r_a2 += val >= this.a2_thr ? val : 0.0;
                        break;
                    case DOPAMINE:
                        if(receptors.hasValue("D1"))
                            unit.r_d1 += val < this.d1_thr ? val : 0.0;
                        if(receptors.hasValue("D2"))
                            unit.r_d2 += val >= this.d2_thr ? val : 0.0;
                        break;
                    case ACETYLCHOLINE:
                        if(receptors.hasValue("M1"))
                            unit.r_m1 += val;

                        break;
                    default:
                        // not implemented
                }
            }
            unit.mod_inputs.clear();
        }

        if (unit.params.act_ext != 0){  // forced activity
            assert (unit.ex_inputs.size() == 0);  // avoiding mistakes
            return; // see self.force_activity
        }

        float net_raw = 0.0;
        if (unit.ex_inputs.size() > 0){
            // computing net_raw, the total, instantaneous, excitatory input for the neuron
            net_raw = sumArray(unit.ex_inputs);
            unit.ex_inputs.clear();
        }
        if (unit.inh_inputs.size() > 0){ // TAT 2021-12-10: support for inh projections TODO check if this is valid
            // computing net_raw, the total, instantaneous, inhbitory input for the neuron
            net_raw -= sumArray(unit.inh_inputs);
            unit.inh_inputs.clear();
        }

        // updating net
        unit.g_e += dt_integ * this.dt_net() * (net_raw - unit.g_e);  // eq 2.16
        // println("spec.calcnetin: unit.g_e: " + unit.g_e);
    }

    void force_activity(Unit unit){
        /* """ Same as "direct in"?
        Replace calls to `calculate_net_in` and `cycle` for forced activity units.

        Note that this is computed immediately when forcing a unit's activity, and in particular
        before cycling connections.
        """
        */
        // calculate_netin
        unit.g_e = unit.params.act_ext / this.g_bar_e;  // unit.net == unit.act
        // cycle
        unit.I_net = 0.0;
        unit.params.act    = unit.params.act_ext;
        unit.act_nd = unit.params.act_ext; // non-depressed activity <- forced
        if (unit.params.act == 0)
            unit.v_m = this.e_rev_l;
        else
            unit.v_m = this.act_thr + unit.params.act_ext / this.act_gain;
        unit.v_m_eq = unit.v_m;
    }

    void cycle(Unit unit, String phase, float g_i, float dt_integ){
        /*
        """Update activity - "tick" or "step"

        unit    :  the unit to cycle
        g_i     :  inhibitory input; TAT: for WTA layer inhibition
        dt_integ:  integration time step, in ms.
        """ */
        if (unit.params.act_ext != 0) { // forced activity, used by plus phase
            this.update_avgs(unit, dt_integ);
            unit.update_logs();
            return; // see self.force_activity
        }

        // computing I_net and I_net_r
        unit.I_net   = this.integrate_I_net(unit, g_i, dt_integ, false, 2); // half-step integration
        unit.I_net_r = this.integrate_I_net(unit, g_i, dt_integ, true,  1); // one-step integration

        // updating v_m and v_m_eq
        unit.v_m    += dt_integ * this.dt_v_m() * unit.I_net  ; // - unit.adapt is done on the I_net value.
        unit.v_m_eq += dt_integ * this.dt_v_m() * unit.I_net_r;
        // unit.v_m     = max(self.v_m_min, min(unit.v_m, self.v_m_max))
        // println("cycle unit.v_m_eq= " + unit.v_m_eq);
        // modulate act_thr
        

        // reseting v_m if over the threshold (spike-like behavior)
        if (unit.v_m > this.act_thr){ // 2021-12-05 TAT may use Dopa and Adeno to modulate act_thr!
            unit.spike = 1;
            unit.v_m   = this.v_m_r;
            unit.I_net = 0.0;
        }
        else
            unit.spike = 0;

        // selecting the activation function, noisy or not. (note: could also use sigmoid here)
        // act_fun = self.noisy_xx1 if self.noisy_act else self.xx1
        float new_act = 0;
        // computing new_act, from v_m_eq (because rate-coded neuron)
        if (unit.v_m_eq <= this.act_thr){
            new_act = act_fun(unit.v_m_eq - this.act_thr);
            // print('SUBTHR {} {}\n       new_act={}'.format(unit.v_m_eq, self.act_thr, new_act))
        }
        else{
            float gc_e = this.g_bar_e * unit.g_e; // TAT: excitatory conductance?
            float gc_i = this.g_bar_i * g_i; // TAT: inhib conductance for wta?
            float gc_l = this.g_bar_l * this.g_l; // TAT: leak conductance?
            float g_e_thr = (  gc_i * (this.e_rev_i - this.act_thr)
                       + gc_l * (this.e_rev_l - this.act_thr)
                       - unit.adapt + this.bias) / (this.act_thr - this.e_rev_e);

            new_act = act_fun(gc_e - g_e_thr);  // gc_e == unit.net
            // print('ABVTHR {} net={} {}\n       new_act={}'.format(unit.v_m_eq, gc_e, g_e_thr, new_act))
        }

        // updating activity
        unit.act_nd += dt_integ * this.dt_v_m() * (new_act - unit.act_nd); //non-depressed activity, used to calc. "super-short term avg"
        // print('FASTCYV act={}'.format(unit.act_nd))

        // unit.act_nd = max(self.act_min, min(unit.act_nd, self.act_max))
        unit.params.act = unit.act_nd; // FIXME: implement stp

        // updating adaptation
        if (this.adapt_on)
            unit.adapt += dt_integ * (
                            this.dt_adapt * (this.v_m_gain * (unit.v_m - this.e_rev_l) - unit.adapt)
                            + unit.spike * this.spike_gain
                          );

        // if phase == 'minus':
        this.update_avgs(unit, dt_integ); // update avgs, used for learning
        unit.update_logs();
    }

    void cycle_mod(Unit unit, String phase, float g_i, float dt_integ){
        /*
        """Update activity - "tick" or "step"
        2022-01-20: TAT changed to "mod" for modulators, 
            since plan support for several
        2021-12-05: TAT updated with dopa, adeno support    
        unit    :  the unit to cycle
        g_i     :  inhibitory input
        dt_integ:  integration time step, in ms.
        """ */
        if (unit.params.act_ext != 0) { // forced activity
            this.update_avgs(unit, dt_integ);
            unit.update_logs();
            return; // see self.force_activity
        }

        // computing I_net and I_net_r
        unit.I_net   = this.integrate_I_net(unit, g_i, dt_integ, false, 2); // half-step integration
        unit.I_net_r = this.integrate_I_net(unit, g_i, dt_integ, true,  1); // one-step integration

        // updating v_m and v_m_eq
        unit.v_m    += dt_integ * this.dt_v_m() * unit.I_net  ; // - unit.adapt is done on the I_net value.
        unit.v_m_eq += dt_integ * this.dt_v_m() * unit.I_net_r;
        // unit.v_m     = max(self.v_m_min, min(unit.v_m, self.v_m_max))

        // modulate act_thr
        // 2021-12-05 TAT: modulate threshold: act_thr
        // 2022-01-09 TAT: adeno cannot affect threshold alone -> check
        // 2022-01-26 TAT: try changing indirectly through leakage (See e.g. Neve 2004)
        // unit.act_thr = this.logistic(this.c_act_thr
        //     - max(0, unit.r_d1 - unit.r_a1)
        //     + max(0, unit.r_d2 - unit.r_a2));
        unit.act_thr = this.c_act_thr;
            
        // println(unit.name + " r_d1: " + unit.r_d1 + "; r_a1: " + unit.r_a1 );
        // println(unit.name + " r_d2: " + unit.r_d2 + "; r_a2: " + unit.r_a2 );
        // println(unit.name + " thr: " + unit.act_thr);
        // println();

        // reseting v_m if over the threshold (spike-like behavior)
        if (unit.v_m > unit.act_thr){ // 2021-12-05 TAT may use Dopa and Adeno to modulate act_thr!
            unit.spike = 1;
            unit.v_m   = this.v_m_r;
            unit.I_net = 0.0;
        }
        else
            unit.spike = 0;

        // selecting the activation function, noisy or not. (note: could also use sigmoid here)
        // act_fun = self.noisy_xx1 if self.noisy_act else self.xx1
        float new_act = 0;
        // computing new_act, from v_m_eq (because rate-coded neuron)
        if (unit.v_m_eq <= unit.act_thr){
            new_act = act_fun(unit.v_m_eq - unit.act_thr);
            // print('SUBTHR {} {}\n       new_act={}'.format(unit.v_m_eq, self.act_thr, new_act))
            // println("cycle_da: < thr" + new_act);
        }
        else{
            float gc_e = this.g_bar_e * unit.g_e;
            float gc_i = this.g_bar_i * g_i;
            float tmp_l = max(0, g_l + (1-g_l)*unit.r_d2*(1-unit.r_a2)
                 - g_l*unit.r_d1*(1-unit.r_a1) -g_l*unit.r_m1);
            float gc_l = this.g_bar_l * this.g_l * tmp_l; // TAT 2022-01-26: leakage affected by D1, D2, M1
            println("tmp_l: " + tmp_l + "; gc_l: " + gc_l);
            float g_e_thr = (  gc_i * (this.e_rev_i - this.act_thr)
                       + gc_l * (this.e_rev_l - this.act_thr)
                       - unit.adapt + this.bias) / (this.act_thr - this.e_rev_e);

            new_act = act_fun(gc_e - g_e_thr);  // gc_e == unit.net
            // print('ABVTHR {} net={} {}\n       new_act={}'.format(unit.v_m_eq, gc_e, g_e_thr, new_act))
            // println("cycle_da: > thr" + new_act);
        }
        
        // updating activity
        unit.act_nd += dt_integ * this.dt_v_m() * (new_act - unit.act_nd);
        // print('FASTCYV act={}'.format(unit.act_nd))

        // unit.act_nd = max(self.act_min, min(unit.act_nd, self.act_max))
        unit.params.act = unit.act_nd; // FIXME: implement stp

        // updating adaptation
        if (this.adapt_on)
            unit.adapt += dt_integ * (
                            this.dt_adapt * (this.v_m_gain * (unit.v_m - this.e_rev_l) - unit.adapt)
                            + unit.spike * this.spike_gain
                          );

        // if phase == 'minus':
        this.update_avgs(unit, dt_integ);
        unit.update_logs();
    }

    float integrate_I_net(Unit unit, float g_i, float dt_integ, boolean ratecoded, int steps){
        /* """Integrate and returns I_net for the provided v_m

        :param steps:  number of intermediary integration steps.
        """
        */
        assert (steps >= 1);
        float I_net = 0;
        float gc_e = this.g_bar_e * unit.g_e;
        float gc_i = this.g_bar_i * g_i;
        float gc_l = this.g_bar_l * this.g_l;
        //float v_m_eff = unit.v_m_eq if ratecoded else unit.v_m;
        float v_m_eff = ratecoded ? unit.v_m_eq : unit.v_m;

        
        for (int i = 0; i < steps; ++i) {
            
        
            I_net = (  gc_e * (this.e_rev_e - v_m_eff)
                     + gc_i * (this.e_rev_i - v_m_eff) // TAT should this be subtracted?
                     + gc_l * (this.e_rev_l - v_m_eff)
                     - unit.adapt //);
                     + this.bias); // TAT
            v_m_eff += dt_integ/steps * this.dt_v_m() * I_net;
        }
        // if(this.bias == 0)
        // println("integrate_I_net: I_net no bias= " + I_net + "; w bias: " + (I_net+this.bias));
        return I_net;
    }

    void update_avgs(Unit unit, float dt_integ){
        // """Update all averages except long-term, at the end of every cycle."""
        unit.avg_ss += dt_integ * this.avg_ss_dt * (unit.act_nd - unit.avg_ss); // "super short-term"; diff betw current act and avg
        unit.avg_s  += dt_integ * this.avg_s_dt  * (unit.avg_ss - unit.avg_s ); // short term
        unit.params.avg_m  += dt_integ * this.avg_m_dt  * (unit.avg_s  - unit.params.avg_m ); // avg minus, predicted input
        unit.params.avg_s_eff = this.avg_m_in_s * unit.params.avg_m + (1 - this.avg_m_in_s) * unit.avg_s; // used for learning, to compute the actual signal, compared to predicted
        // print('avg_s_eff', unit.avg_s_eff)
    }

    void update_avg_l(Unit unit){
        /* """Update the long-term average.

        Called at the end of every trial (*not every cycle*).
        """*/
        unit.params.avg_l += this.avg_l_dt * (this.avg_l_gain * unit.params.avg_m - unit.params.avg_l);
        unit.params.avg_l = max(unit.params.avg_l, this.avg_l_min);

        // if unit.avg_m > 0.2: # FIXME: 0.2 is a magic number here
        //     unit.avg_l += self.avg_l_dt * (self.avg_l_gain - unit.avg_l)
        // else:
        //     unit.avg_l += self.avg_l_dt * (self.avg_l_min - unit.avg_l)
        // unit.avg_l = 3
    }

    float logistic(float val){
        return 1.0/(1+exp(-val));
    }

}
