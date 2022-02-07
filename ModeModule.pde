class ModeModule implements NetworkModule {
    // static final String IN = "in";
    // static final String OUT = "out";
    static final String MODE = "mode";
    
    String name = "ModeModule";
    
    Layer[] layers = new Layer[1];
    Connection[] connections = new Connection[1];
    int layersize = 2;
    int fill_col = 60;
    int boundary_w = 220;
    int boundary_h = 100;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer mode_layer; // used for translation to pop code to engage effort
    //Layer out_layer;
    

    // connections
    ConnectionSpec oto_spec = new ConnectionSpec();
    LayerConnection self_conn; // population to gain
    

    ModeModule() {
        this.init();
    }

    ModeModule(int size, String name) {
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
        oto_spec.proj="1to1";
        oto_spec.rnd_type="uniform" ;
        oto_spec.rnd_mean=0.5; // note: this should be modulated e.g. by norad
        oto_spec.rnd_var=0.0;

        

        mode_layer = new Layer(layersize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Mode");
        // out_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Out (out)");
        
        int layerix = 0;
        layers[layerix++] = mode_layer;
        // layers[layerix++] = out_layer;

        self_conn = new LayerConnection(mode_layer, mode_layer, oto_spec);
        connections[0] = self_conn;
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String l) {
        switch(l) {
            case MODE:
                return mode_layer; // input
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
        drawStrip(mode_layer.getOutput(), mode_layer.name);
        
        popMatrix();
    }

    

    

}
