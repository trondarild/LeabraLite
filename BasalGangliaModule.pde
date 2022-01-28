class BasalGangliaModule implements NetworkModule {
    static final String STR_D1 = "striatal_d1";
    static final String STR_D2 = "striatal_d2";
    static final String GPI = "gpi";
    
    String name = "BasalGangliaModule";
    
    Layer[] layers = new Layer[2];
    Connection[] connections = new Connection[1];
    int layersize = 2;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer in_layer; // used for translation to pop code to engage effort
    Layer out_layer;
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    LayerConnection in_out_conn; // population to gain
    

    BasalGangliaModule() {
        this.init();
    }

    BasalGangliaModule(String name, int size) {
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
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        // connection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;

        

        in_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Striatum D1 (in)");
        out_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "BGi (out)");
        
        int layerix = 0;
        layers[layerix++] = in_layer;
        layers[layerix++] = out_layer;

        in_out_conn = new LayerConnection(in_layer, out_layer, full_spec);
        connections[0] = in_out_conn;
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String l) {
        switch(l) {
            case STR_D1:
            case STR_D2:
                return in_layer; // input
            case GPI:
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
        rect(0, 0, 220, 100, 10);
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
