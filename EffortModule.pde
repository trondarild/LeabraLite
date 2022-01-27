class EffortModule implements NetworkModule {
    /** Models excitative effort, gain from  a control signal
    */
    static final String MAGNITUDE = "magnitude";
    static final String GAIN = "gain";
    
    String name = "EffortModule";
    int gainsize = 2;
    int magnitudesize = 1;

    Layer[] layers = new Layer[3];
    Connection[] connections = new Connection[1];

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer pe_magnitude_layer; // used for translation to pop code to engage effort
    Layer pop_layer;
    Layer gain_layer; // excites hidden layer

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    LayerConnection pop_gain_conn; // population to gain
    

    EffortModule() {
        this.init();
    }

    EffortModule(int gainsize, String name) {
        this.gainsize = gainsize;
        this.name = name;
        this.init();
    }

    void init() {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=false;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        // connection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;

        float[][] w_effort = generateEffortWeights(gainsize);

        pe_magnitude_layer = new Layer(magnitudesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Magnitude (in)");
        pop_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Population");
        gain_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Gain (out)");
        int layerix = 0;
        layers[layerix++] = pe_magnitude_layer;
        layers[layerix++] = pop_layer;
        layers[layerix++] = gain_layer;


        pop_gain_conn = new LayerConnection(pop_layer, gain_layer, full_spec);
        pop_gain_conn.weights(w_effort);
        connections[0] = pop_gain_conn;
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String l) {
        switch(l) {
            case MAGNITUDE:
                return pe_magnitude_layer; // input
            case GAIN:
            default:
                return gain_layer; // output
        }
    }

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 220, 100, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(pe_magnitude_layer.output(), pe_magnitude_layer.name());
        drawStrip(pop_layer.output(), pop_layer.name());
        drawStrip(gain_layer.output(), gain_layer.name());
        popMatrix();
    }

    void cycle() {
        float[] pop_act = zeros(gainsize);
        pop_act = populationEncode(
                pe_magnitude_layer.units[0].getOutput(), //forcegain,
                gainsize,
                0, 1,
                0.25
            );    
        pop_layer.force_activity(pop_act);
    }

    float[][] generateEffortWeights(int sz) {
        float[][] retval = zeros(sz, sz);
        for (int j = 1; j < sz; ++j) { // dont include first, only on at zero
            for (int i = 0; i < sz; ++i) {
                retval[j][i] = i <= j ? 1 : 0;    
            }    
        }
        return retval;
    }

}