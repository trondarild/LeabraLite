class RuleModule implements NetworkModule {
    static final String IN = "in";
    static final String OUT = "out";
    
    String name = "RuleModule";
    
    Layer[] layers = new Layer[2];
    Connection[] connections; //
    int layersize = 2;
    ArrayList<float[][]> rules; // in effect the weight matrix of the in-out connection

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer in_layer; // used for translation to pop code to engage effort
    Layer out_layer;
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    // LayerConnection in_out_conn; // population to gain
    

    RuleModule(ArrayList<float[][]> rule_topologies) {
        this.rules = rule_topologies;
        this.init();
    }

    RuleModule(ArrayList<float[][]> rule_topologies, String name) {
        this.rules = rule_topologies;
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
        
        float[][] tmp = rules.get(0);
        in_layer = new Layer(tmp.length, new LayerSpec(false), excite_unit_spec, HIDDEN, "In (in)");
        out_layer = new Layer(tmp[0].length, new LayerSpec(false), excite_unit_spec, HIDDEN, "Out (out)");
        
        int layerix = 0;
        layers[layerix++] = in_layer;
        layers[layerix++] = out_layer;
        connections = new Connection[rules.size()];
        for (int i = 0; i < rules.size(); ++i) {
            connections[i] = new LayerConnection(in_layer, out_layer, full_spec);
            connections[i].weights(rules.get(i));
        }
        
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String l) {
        switch(l) {
            case IN:
                return in_layer; // input
            case OUT:
                return out_layer; // output
            default:
                assert(false): "No layer named '" + l + "' defined, check spelling.";
                return null;
        }
    }

    void cycle() {   
    }

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 270, 220, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(in_layer.getOutput(), in_layer.name);
        drawStrip(out_layer.getOutput(), out_layer.name);
        // draw the rules
        translate(0,30);
        pushMatrix();
        int ctr = 1;
        for (float[][] o : rules) {
            drawColGrid(0, 0, 10, 2, "Rule " + ctr++, multiply(200, o));
            translate(50, 0);
        }
        popMatrix();
        
        
        popMatrix();
    }

    

    

}
