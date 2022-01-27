import java.util.HashMap;
import java.util.Map;

class NetworkSpec{
    // """Network parameters"""
    int quarter_size = 25;
    boolean do_reset = true;
    NetworkSpec(){}
    
    NetworkSpec(int quarter_size){
        // number of cycles in a settle period
        this.quarter_size = quarter_size;

        // for key, value in kwargs.items():
        //     assert hasattr(self, key) // making sure the parameter exists.
        //     setattr(self, key, value)
    }

}

//
// network modules 
//
interface NetworkModule {
    String name();
    Layer[] layers();
    Connection[] connections();
    void cycle(); 
    void draw();
    Layer layer(int code);

}

class Network{
    // """Leabra Network class"""
    NetworkSpec spec;
    int trial_length = 5; // number of quarters per trial
    int cycle_count;
    int cycle_tot;
    int quarter_nb;
    int trial_count;
    String phase;

    ArrayList<Layer> layers = new ArrayList<Layer>();
    ArrayList<Connection> connections = new ArrayList<Connection>();
    ArrayList<ConnectableComposite> composites = new ArrayList<ConnectableComposite>();
    ArrayList<NetworkModule> modules = new ArrayList<NetworkModule>();
    Map<String, FloatList> inputs = new HashMap<String, FloatList>();
    Map<String, FloatList> outputs = new HashMap<String, FloatList>();

    Network (NetworkSpec spec, Layer[] layers, Connection[] connections){
        this.spec = spec;
        if (this.spec == null)
            this.spec = new NetworkSpec();

        this.cycle_count = 0; // number of cycles finished in the current trial
        this.cycle_tot   = 0; // total number of cycles executed (not reset at end of trial)
        this.quarter_nb  = 1; // current quarter number (1, 2, 3 or 4)
        this.trial_count = 0; // number of trial finished
        this.phase       = "minus";
        
        // this.layers      = new ArrayList<Layers>(Arrays.asList(layers));
        assert(layers != null);
        for (Layer l : layers) {this.layers.add(l);}
        
        // this.connections = new ArrayList<Connection>(Arrays.asList(connections));
        assert(connections != null);
        for (Connection c : connections) {this.connections.add(c);}
        // this._inputs; 
        // this._outputs = {}, {}
        
        this.build();
    }

    Network (NetworkSpec spec, Layer[] layers, Connection[] connections, ConnectableComposite[] composite){
        this.spec = spec;
        if (this.spec == null)
            this.spec = new NetworkSpec();

        this.cycle_count = 0; // number of cycles finished in the current trial
        this.cycle_tot   = 0; // total number of cycles executed (not reset at end of trial)
        this.quarter_nb  = 1; // current quarter number (1, 2, 3 or 4)
        this.trial_count = 0; // number of trial finished
        this.phase       = "minus";
        
        // this.layers      = new ArrayList<Layers>(Arrays.asList(layers));
        assert(layers != null);
        for (Layer l : layers) {this.layers.add(l);}
        
        // this.connections = new ArrayList<Connection>(Arrays.asList(connections));
        assert(connections != null);
        for (Connection c : connections) {this.connections.add(c);}
        // this._inputs; 
        // this._outputs = {}, {}
        assert(composites != null);
        for(ConnectableComposite c : composites) {this.composites.add(c);}
        
        this.build();
    }

    void add_connection(Connection connection){
        this.connections.add(connection);
        this.build();
    }

    void add_layer(Layer layer){
        this.layers.add(layer);
    }

    void add_composite(ConnectableComposite comp) {
        this.composites.add(comp);
    }

    void add_module(NetworkModule mod) {
        this.modules.add(mod);
        // add layers and connections in module
        for(Layer l: mod.layers()) this.add_layer(l);
        for(Connection c: mod.connections()) this.add_connection(c);
    }

    void build(){
        /** """Precompute necessary network datastructures.

        This needs to be run every time a layer or connection is added or removed from the network,
        or if the value of a connection's `wt_scale_rel` is changed. This automatically run when
        using the `add_connection()` method.

        #Note TAT 2022-01-07: connections will affect unit activation, even if not explicitly added to 
                                to network due to processing here 
        """ */
        for (Layer layer : this.layers){
            // rel_sum = sum(connection.spec.wt_scale_rel for connection in layer.to_connections)
            float rel_sum = 0;
            for (int i = 0; i < layer.to_connections.size(); ++i) {
                rel_sum += layer.to_connections.get(i).spec.wt_scale_rel;
            }
            // println(layer.name + ": " + rel_sum + "; " + layer.to_connections.size());
            for (Connection connection : layer.to_connections)
                connection.wt_scale_rel_eff = connection.spec.wt_scale_rel / rel_sum;
        }
        for(Connection con : this.connections){
            if(con instanceof LayerConnection){
                LayerConnection lcon = (LayerConnection)con;
                float rel_sum = 0;
                
                for (int i = 0; i < lcon.to_connections.size(); ++i) {
                    rel_sum += lcon.to_connections.get(i).spec.wt_scale_rel;
                }
                // println(lcon.name + ": " + rel_sum + "; " + lcon.to_connections.size());
                // handle the dendrite connections of the layerconnection
                for (Connection connection : lcon.to_connections) {
                    //DendriteConnection dc = (DendriteConnection) connection;
                    connection.wt_scale_rel_eff = connection.spec.wt_scale_rel / rel_sum;
                }

            }
            
        }
        for(ConnectableComposite res : this.composites) {
            float rel_sum = 0;
            for (int i = 0; i < res.to_connections().size(); ++i) {
                rel_sum += res.to_connections().get(i).spec.wt_scale_rel;
            }
            // println(layer.name + ": " + rel_sum + "; " + layer.to_connections.size());
            for (Connection connection : res.to_connections())
                connection.wt_scale_rel_eff = connection.spec.wt_scale_rel / rel_sum;
        }
        
    }

    Layer get_layer(String name){
        /* """Get a layer from its name.

        If layers share the name, return the first one added to the network.
        """ */
        for (Layer layer : this.layers)
            if (layer.name == name)
                return layer;
        println("layer " + name + " not found.");
        return null;
    }

    void set_inputs(Map<String, FloatList> act_map){
        /* """Set inputs activities, set at the beginning of all quarters.

        :param act_map:  a dict with layer names as keys, and activities arrays
                         as values.
        """ */
        this.inputs = act_map;
    }

    void set_outputs(Map<String, FloatList> act_map){
        /* 
        """Set inputs activities, set at the beginning of all quarters.
        # Note: "outputs" appears only to be used to compute error signal (sse),
            ie difference between a (learning) signal and actual layer output
        :param act_map:  a dict with layer names as keys, and activities arrays
                         as values
        """ */
        this.outputs = act_map;
    }

    void set_targets(Map<String, FloatList> act_map){
        /** syntactic sugar - calls set_output */
        set_outputs(act_map);
    }

    void pre_cycle(){
        /* """Check if some action needs to be done before starting the cycle.

        Checks if the network is at a special moment (beginning of trial, start
        or end of phase, etc.), and if some action needs to be done.
        """ */
        if (this.cycle_count == this.spec.quarter_size) { // a quarter just ended
            this.quarter_nb += 1;
            if (this.quarter_nb == this.trial_length){ // 5){ // a trial just ended
                this.trial_count += 1;
                this.quarter_nb = 1;
            }
            this.cycle_count = 0;
        }

        if (this.cycle_count == 0){ // start of a quarter
            for (Connection connection : this.connections){
              assert(connection != null); 
              connection.compute_netin_scaling();
            }

            if (this.quarter_nb == 1){ // start of trial, // TAT: set inputs only on first quarter
                // reset all layers
                // if (this.quarter_nb == 1) // TAT: could this "if" be removed?
                if (this.spec.do_reset) // TAT: may not want to reset
                    for (Layer layer : this.layers)
                        layer.trial_init(); // will reset units in layer
                // force activities for inputs
                // for name, activities in this._inputs.items():
                // inputs.forEach((k, v) ->  this.get_layer(k).force_activity(Floats.toArray(v)));
                for (Map.Entry<String, FloatList> entry : inputs.entrySet()) {
                    // println("network: precycle: ");
                    // println(entry.getValue().toString());
                    this.get_layer(entry.getKey()).force_activity(entry.getValue());
                }
                   
            }
            else if (this.quarter_nb == 4) // start of plus phase
                // force activities for outputs - TAT for prediction error and computing weight changes?
                // for name, activities in this._outputs.items():
                //     this._get_layer(name).force_activity(activities)
                for (Map.Entry<String, FloatList> entry : outputs.entrySet()) {
                    this.get_layer(entry.getKey()).force_activity(entry.getValue());
                }
        }
    }

    void post_cycle(){
        // """Same as _pre_cycle, but after the cycle has executed"""
        if (this.cycle_count == this.spec.quarter_size){ // end of a quarter
            if (this.quarter_nb == 3) // end of minus phase (TAT: prediction?)
                this.end_minus_phase();

            if (this.quarter_nb == 4) // end of plus phase (TAT: sensory pred error?)
                this.end_plus_phase();
        }
    }

    void cycle(){
        // """Execute a cycle"""
        // takes care of minus (prediction) and
        // plus (sensing, outcome) phases
        this.pre_cycle();
        for (NetworkModule mod: this.modules)
            mod.cycle();
        for (Connection conn : this.connections)
            conn.cycle();
        for (Layer layer : this.layers)
            layer.cycle(this.phase);
        for (ConnectableComposite com: this.composites)
            com.cycle(this.phase);
        
        this.cycle_count += 1;
        this.cycle_tot   += 1;
    
        this.post_cycle();
    }

    void quarter(){ // FIXME:
        // """Execute a quarter"""
        // simply cycles <quarter> number of times
        this.cycle();
        while (this.cycle_count < this.spec.quarter_size)
            this.cycle();
    }

    float trial(){
        // """Execute a trial. Will execute up until the end of the plus phase."""
        this.quarter();
        while (this.quarter_nb != 4){
            assert (this.cycle_count == this.spec.quarter_size);
            this.quarter();
        }
        return this.compute_sse();
    }

    float compute_sse(){
        /* """Compute the sum of squared error in prediction (SSE).

        Should be run only after the minus phase is finished.
        """ */
        float sse = 0;
        //for name, activities in this._outputs.items():
        for (Map.Entry<String, FloatList> entry : this.outputs.entrySet()) {
            String name = entry.getKey();
            FloatList act = entry.getValue();
            Layer layer = this.get_layer(name);
            //for act, unit in zip(activities, this._get_layer(name).units):
            for (int i = 0; i < act.size(); ++i) {
                sse += pow((act.get(i) - layer.units[i].act_m), 2);
                println("output: " + i + "; act: " + 
                    act.get(i) + "; prd " + layer.units[i].act_m + 
                    " absdiff: " + abs(act.get(i)-layer.units[i].act_m));
            }
            println(); println();
                
        }
        return sse;
    }

    float compute_hamming_dist() {
        // TODO
        return 0;
    }

    void end_minus_phase(){
        // """End of the minus phase. Current unit activity is stored."""
        // TODO process ConnectableComposites in general?
        for(Layer layer : this.layers)
            for(Unit unit : layer.units)
                unit.act_m = unit.act();
        this.phase = "plus";
    }

    void end_plus_phase(){
        // """End of the plus phase. Connections change weights."""
        for (Connection conn : this.connections)
            conn.learn();
        for (Layer layer : this.layers)
            for (Unit unit : layer.units)
                unit.update_avg_l(); // longterm avgs

        this.phase = "minus";
    }

    boolean accept_input(){
        return this.cycle_count == this.spec.quarter_size &&
            this.quarter_nb == this.trial_length-1;
    }


}
