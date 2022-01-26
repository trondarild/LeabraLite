class ModuleTemplate implements NetworkModule {
    static final int IN = 0;
    static final int OUT = 1;
    
    String name = "ModuleTemplate";
    
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
    

    ModuleTemplate() {
        this.init();
    }

    ModuleTemplate(String name) {
        
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

        

        in_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "In (in)");
        out_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Out (out)");
        
        int layerix = 0;
        layers[layerix++] = in_layer;
        layers[layerix++] = out_layer;

        in_out_conn = new LayerConnection(in_layer, out_layer, full_spec);
        connections[0] = in_out_conn;
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(int l) {
        switch(l) {
            case IN:
                return in_layer; // input
            case OUT:
            default:
                return out_layer; // output
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
