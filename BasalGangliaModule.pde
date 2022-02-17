class BasalGangliaModule implements NetworkModule {
    static final String STR_D1 = "striatal_d1"; // go (in)
    static final String STR_D2 = "striatal_d2"; // brake (in)
    static final String GPE = "gpe"; // globus pallidus externa
    static final String STN = "stn"; // subthalamic nucleus - nonspecific brake (in)
    static final String GPI = "gpi"; // globus pallidus interna (out)
    static final String SNC = "snc"; // subst nigra pars compacta
    
    String name = "BasalGangliaModule";

    int boundary_w = 220;
    int boundary_h = 160;
    int fill_col = 60;
    
    Layer[] layers = new Layer[6];
    Connection[] connections = new Connection[4];
    int layersize = 2;
    int dopasize = 1;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec bias_spec; // for disinh
    // TODO dopa spec for D1 and D2
    UnitSpec d1_unit_spec;
    UnitSpec d2_unit_spec;

    // layers
    Layer str_d1_layer; // used for translation to pop code to engage effort
    Layer str_d2_layer;
    Layer gpe_layer;
    Layer stn_layer;
    Layer snc_layer;
    Layer gpi_layer;
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    ConnectionSpec oto_spec;
    ConnectionSpec oto_inh_spec;

    LayerConnection strd1_gpi_conn; // population to gain
    LayerConnection strd2_gpe_conn;
    LayerConnection gpe_stn_conn;
    LayerConnection stn_gpi_conn;

    

    BasalGangliaModule() {
        this.init();
    }

    BasalGangliaModule(int size, String name) {
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

        d1_unit_spec = new UnitSpec(excite_unit_spec);
        d1_unit_spec.g_bar_l = 0.3;
        d1_unit_spec.receptors.append("D1");
        d1_unit_spec.use_modulators = false; // TODO: turn true
        
        d2_unit_spec = new UnitSpec(excite_unit_spec);
        d2_unit_spec.receptors.append("D2");
        d2_unit_spec.use_modulators = false; // TODO: turn true
        bias_spec = new UnitSpec(excite_unit_spec);
        bias_spec.bias = 0.1;

        // connection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.375;
        full_spec.rnd_var=0.0;
        //full_spec.type = GABA;

        oto_spec = new ConnectionSpec(full_spec);
        oto_spec.proj = "1to1";
        oto_spec.type = GLUTAMATE;

        oto_inh_spec = new ConnectionSpec(oto_spec);
        oto_inh_spec.type = GABA;

        

        str_d1_layer = new Layer(layersize, new LayerSpec(false), d1_unit_spec, HIDDEN, "Str_d1 (in)");
        str_d2_layer = new Layer(layersize, new LayerSpec(false), d2_unit_spec, HIDDEN, "Str_d2 (in)");
        gpe_layer = new Layer(layersize, new LayerSpec(false), bias_spec, HIDDEN, "Gpe");
        stn_layer = new Layer(layersize, new LayerSpec(false), bias_spec, HIDDEN, "Stn (in)");
        snc_layer = new Layer(dopasize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Snc (inout)");
        gpi_layer = new Layer(layersize, new LayerSpec(false), bias_spec, HIDDEN, "BGi (out)");
        
        int ix = 0;
        layers[ix++] = str_d1_layer;
        layers[ix++] = str_d2_layer;
        layers[ix++] = gpe_layer;
        layers[ix++] = stn_layer;
        layers[ix++] = snc_layer;
        layers[ix++] = gpi_layer;

        strd1_gpi_conn = new LayerConnection(str_d1_layer, gpi_layer, oto_inh_spec);
        strd2_gpe_conn = new LayerConnection(str_d2_layer, gpe_layer, oto_inh_spec);
        gpe_stn_conn = new LayerConnection(gpe_layer, stn_layer, oto_inh_spec);
        stn_gpi_conn = new LayerConnection(stn_layer, gpi_layer, oto_spec);
        
        ix = 0;
        connections[ix++] = strd1_gpi_conn;
        connections[ix++] = strd2_gpe_conn;
        connections[ix++] = gpe_stn_conn;
        connections[ix++] = stn_gpi_conn;
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    
    Layer layer(String l) {
        switch(l) {
            case STR_D1:
                return str_d1_layer; // input
            case STR_D2:
                return str_d2_layer; // input
            case GPI:
                return gpi_layer; // output
            case STN:
                return stn_layer;
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
        stroke(fill_col + 10);
        rect(0, 0, boundary_w, boundary_h, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(str_d1_layer.getOutput(), str_d1_layer.name);
        drawStrip(str_d2_layer.getOutput(), str_d2_layer.name);
        drawStrip(gpe_layer.getOutput(), gpe_layer.name);
        drawStrip(stn_layer.getOutput(), stn_layer.name);
        drawStrip(snc_layer.getOutput(), snc_layer.name);
        drawStrip(gpi_layer.getOutput(), gpi_layer.name);
        
        popMatrix();
    }

    

    

}
