class ThalamusModule implements NetworkModule {
    static final String IN = "in";
    static final String OUT = "out";
    
    String name = "ThalamusModule";
    String info;
    
    Layer[] layers = new Layer[2];
    Connection[] connections = new Connection[1];
    int layersize = 2;
    color fill_col = 60;
    int boundary_w = 220;
    int boundary_h = 100;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer in_layer; // used for translation to pop code to engage effort
    Layer out_layer;
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    LayerConnection in_out_conn; // population to gain
    

    ThalamusModule() {
        this.init();
    }

    ThalamusModule(int size, String name) {
        this.layersize = size;
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
        excite_unit_spec.g_bar_l=0.5; // quick reset
        excite_unit_spec.g_l=1;
        excite_unit_spec.g_bar_i=0.40;

        UnitSpec auto_unit_spec = new UnitSpec(excite_unit_spec);
        auto_unit_spec.bias = 0.3;

        // connection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;

        ConnectionSpec oto_inh_spec = new ConnectionSpec();
        oto_inh_spec.proj = "1to1";
        oto_inh_spec.type = GLUTAMATE;

        in_layer = new Layer(layersize, new LayerSpec(false), auto_unit_spec, HIDDEN, "In (in)");
        out_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Out (out)");
        
        int layerix = 0;
        layers[layerix++] = in_layer;
        layers[layerix++] = out_layer;

        in_out_conn = new LayerConnection(in_layer, out_layer, oto_inh_spec);
        connections[0] = in_out_conn;
        
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
        fill(fill_col);
        stroke(fill_col + 20);
        rect(0, 0, boundary_w, boundary_h, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(in_layer.getOutput(), in_layer.name);
        drawStrip(out_layer.getOutput(), out_layer.name);
        
        popMatrix();
    }

    

    

}
