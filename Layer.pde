/* Layer implementation
*/

class Layer implements ConnectableComposite {
    int size;
    int genre;
    String name;
    LayerSpec spec;
    Unit[] units;

    float gc_i = 0.0;  // inhibitory conductance
    float ffi  = 0.0;  // feedforward component of inhibition
    float fbi  = 0.0;  // feedback component of inhibition

    float avg_act       = 0.0;  // average activity, computed after every cycle.
    float avg_act_p_eff = 0;

    ArrayList<Connection> from_connections = new ArrayList<Connection>();
    ArrayList<Connection> to_connections = new   ArrayList<Connection>();
    Buffer[] buffers;


    Layer(int size, LayerSpec spec, UnitSpec unit_spec, int genre, String name){
        /* """
        size     :  Number of units in the layer.
        spec     :  LayerSpec instance with custom values for the parameter of
                    the layer. If None, default values will be used.
        unit_spec:  UnitSpec instance with custom values for the parameters of
                    the units of the layer. If None, default values will be used.

        2021-12-05 TAT: this is like a "population" or "ensemble" of neurons
        """
        */
        this.size = size;
        this.genre = genre;  // type of layer

        this.name = name;
        this.spec = spec;
        if (this.spec == null)
            this.spec = new LayerSpec();

        // this.units = [Unit(spec=unit_spec, genre=genre) for _ in range(size)]
        units = new Unit[size];
        for (int i = 0; i < size; ++i) {
            units[i] = new Unit(unit_spec, genre);
            units[i].name = this.name + "_" + i;
        }
        avg_act_p_eff = spec.avg_act_targ_init;

        buffers = new Buffer[size];

        // this.logs = {'gc_i': []}
    }

    String name() {return name;}
    Connectable[] units() {return units;}; 
    float avg_act_p_eff() {return avg_act_p_eff;};
    void add_from_connections(Connection from) {from_connections.add(from);};
    void add_to_connections(Connection to) {
        // println("add to " + this.name + ": " + to.spec.wt_scale_rel);
        to_connections.add(to);};

    void  trial_init(){
        // """Initialize the layer for a new trial. Reset all units, decays fbi and ffi."""
        this.spec.trial_init(this);
    }

    float[] getOutput(){
      return activities();
    }

    float[] activities(){
        // """Return the matrix of the units's activities"""
        float[] retval = zeros(units.length);
        // return [u.act for u in self.units]
        for (int i = 0; i < units.length; ++i) {
            retval[i] = units[i].act_eq();
        }
        return retval;
    }

    float[] g_e(){
        // """Return the matrix of the units's net exitatory input"""
        // return [u.g_e for u in self.units]}
        float[] retval = zeros(units.length);
        // return [u.act for u in self.units]
        for (int i = 0; i < units.length; ++i) {
            retval[i] = units[i].g_e;
        }
        return retval;
    }

    float[] act_thr(){
        float[] retval = zeros(this.size);
        for (int i = 0; i < this.size; ++i) {
            retval[i] = units[i].act_thr;
        }
        return retval;
    }

    Buffer[] getBuffers(){
        return buffers;
    }

    float[][] getBufferVals() {
        float[][] retval = zeros(units.length, buffers[0].data.size());
        for (int j = 0; j < units.length; ++j) {
            retval[j] = buffers[j].data.array();
        }
        return retval;
    }

    void update_logs(){
        // """Record current state. Called after each cycle."""
        // TODO: self.logs['gc_i'].append(self.gc_i)
    }

    void force_activity(float[] activities){
        // """Set the units's activities equal to the inputs."""
        assert (activities.length == units.length);
        //for u, act in zip(self.units, activities):
        for (int i = 0; i < units.length; ++i) {
            units[i].force_activity(activities[i]);
        }
    }
    void force_activity(FloatList activities){
        // """Set the units's activities equal to the inputs."""
        assert (activities.size() == units.length) : activities.size() + " != " + units.length;
        //for u, act in zip(self.units, activities):
        for (int i = 0; i < units.length; ++i) {
            units[i].force_activity(activities.get(i));
        }
    }

    void add_excitatory(float[] inputs){
        // """Add excitatory inputs to the layer's units."""
        assert (inputs.length == units.length);
        //for u, net_raw in zip(self.units, inputs):
        for (int i = 0; i < units.length; ++i) {
            units[i].add_excitatory(inputs[i]);
        }
    }

    void set_dopa(float[] da) { // TAT 2022-01-09
        assert (da.length == units.length) : da.length + " != " + units.length;
        for (int i = 0; i < units.length; ++i) {
            units[i].set_dopa(da[i]);
        }
    }

    void set_adeno(float[] ado) { // TAT 2022-01-09
        assert (ado.length == units.length) : ado.length + " != " + units.length;
        for (int i = 0; i < units.length; ++i) {
            units[i].set_adeno(ado[i]);
        }
    }

    void cycle(String phase){
        this.spec.cycle(this, phase);
        for (int i = 0; i < units.length; ++i) {
            buffers[i] = units[i].getBuffer();
        }
    }

    void show_config(){
        // """Display the value of constants and state variables."""
        // TODO
        println("Parameters:");
        // for name in ['fb_dt', 'ff0', 'ff', 'fb', 'g_i']:
        //     print('   {}: {:.2f}'.format(name, getattr(self.spec, name)))
        println("State:");
        // for name in ['gc_i', 'fbi', 'ffi']:
        //     print('   {}: {:.2f}'.format(name, getattr(self, name)))
    }


}

class LayerSpec{
    boolean lay_inhib = true; // activate inhibition? (TAT: WTA inh between units)

    // time step constants:
    float fb_dt = 1/1.4;  // Integration constant for feed back inhibition

    // weighting constants
    float fb    = 1.0;    // feedback scaling of inhibition
    float ff    = 1.0;    // feedforward scaling of inhibition
    float g_i   = 1.8;    // inhibition multiplier

    float trial_decay = 1.0;  // decay factor for fbi and ffi. If 1.0, fbi and ffi will be reset to
                            // 0 at the start of every trial

    // thresholds:
    float ff0 = 0.1;

    // average activity
    float avg_act_targ_init = 0.2;    // target for adapting inhibition and
                                    // initial estimated average value level
    float avg_act_adjust    = 1.0;    // avg_p_act_eff = avg_act_adjust * avg_p_act
    boolean avg_act_fixed     = false;  // if True, `avg_act_p_eff` is constant, =`avg_act_targ_init`
    boolean avg_act_use_first = false;  // override targ_init value with the first estimation.
    boolean avg_act_tau       = false;  // time constant for integrating act_p_avg
    int cycle_count = 0;

    LayerSpec(){

    }

    LayerSpec(boolean inhib){
        lay_inhib = inhib;
    }

    float inhibition(Layer layer){
        // """Compute the layer inhibition"""
        // TAT 2021-12-10: this appears to only be for WTA inhibition
        if (this.lay_inhib) {
            // Calculate feed forward inhibition
            // netin = [u.g_e for u in layer.units]
            float[] netin = zeros(layer.units.length);
            for (int i=0; i < netin.length; i++){
                netin[i] = layer.units[i].g_e;
            }
            // if layer.genre == OUTPUT and this.cycle_count < 300:
            //     print(this.cycle_count, netin)
            layer.ffi = this.ff * max(0, mean(netin) - this.ff0);

            // Calculate feed back inhibition
            // if layer.genre == OUTPUT and this.cycle_count < 300:
            //     print(this.cycle_count, 'layer.avg_act ', layer.avg_act)
            layer.fbi += this.fb_dt * (this.fb * layer.avg_act - layer.fbi);

            // if layer.genre == OUTPUT and this.cycle_count < 300:
            //     print('gc_i ',  this.g_i * (layer.ffi + layer.fbi))
            //     print('gc_i ',  this.g_i * (layer.ffi + layer.fbi), layer.ffi, layer.fbi)
            return this.g_i * (layer.ffi + layer.fbi);
        }
        else
            return 0.0;
    }

    void cycle(Layer layer, String phase){
        // """Cycle the layer, and all the units in it."""

        // calculate net inputs for this layer
        for(Unit u : layer.units)
            u.calculate_net_in();

        // update the state of the layer
        if (phase == "minus")
            layer.gc_i = this.inhibition(layer);
        // if layer.genre == OUTPUT:
        //     print(this.cycle_count, layer.gc_i)
        for (Unit u : layer.units)
            u.cycle(phase, layer.gc_i, 1);

        layer.avg_act = mean(layer.activities());

        layer.update_logs();
        this.cycle_count += 1;
    }

    void trial_init(Layer layer){
        for(Unit u : layer.units)
            u.reset();
        layer.ffi -= this.trial_decay * layer.ffi;
        layer.fbi -= this.trial_decay * layer.fbi;
    }
}
