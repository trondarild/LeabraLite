class ValueAccumulatorModule implements NetworkModule {
    /** Attempts to replicate accumulator behaviour described in Balkenius et al 2020
        with layers and connections

        // TODO: add reset layer with ACh that leaks out all charge
    */
    static final int VALUE = 0;
    static final int SPAT_IX = 1;
    static final int ACC = 2;
    
    String name = "ValueAccumulatorModule";
    
    Layer[] layers = new Layer[4];
    Connection[] connections = new Connection[6];
    int layersize = 2;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer val_in_layer; // value in 
    Layer spatix_in_layer; // spatial ix in; will disinhibit on pathway
    Layer inh_layer; 
    Layer acc_out_layer;
    //Layer disinh_layer; // routing of spatial index to accumulator and inh
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    ConnectionSpec full_inh_spec;
    ConnectionSpec oto_spec;
    ConnectionSpec oto_inh_spec;
    LayerConnection val_acc_conn; // value to accumulator
    LayerConnection acc_acc_conn; // auto conn  accumulator
    LayerConnection val_inh_conn; // value to inhibition
    LayerConnection inh_acc_conn; // inh to accumulator
    DendriteConnection spat_acc_conn;
    DendriteConnection spat_inh_conn;

    

    ValueAccumulatorModule() {
        this.init();
    }

    ValueAccumulatorModule(String name) {
        
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

        full_inh_spec = new ConnectionSpec(full_spec);
        full_inh_spec.type = GABA;

        oto_spec = new ConnectionSpec(full_spec);
        oto_spec.proj = "1to1";

        oto_inh_spec = new ConnectionSpec(oto_spec);
        oto_inh_spec.type = GABA;

        // layers
        val_in_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "Value (in)");
        spatix_in_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Spatial ix (in)");
        inh_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Inhibition");
        //disinh_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Disinhibition");
        acc_out_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Accumulator (out)");
        
        int ix = 0;
        layers[ix++] = val_in_layer;
        layers[ix++] = spatix_in_layer;
        layers[ix++] = inh_layer;
        //layers[ix++] = disinh_layer;
        layers[ix++] = acc_out_layer;

        val_acc_conn = new LayerConnection(val_in_layer, acc_out_layer, full_spec);
        acc_acc_conn = new LayerConnection(acc_out_layer, acc_out_layer, oto_spec);
        val_inh_conn = new LayerConnection(val_in_layer, inh_layer, full_spec);
        inh_acc_conn = new LayerConnection(inh_layer, acc_out_layer, oto_inh_spec);
        spat_acc_conn = new DendriteConnection(spatix_in_layer, val_acc_conn, full_inh_spec);
        spat_inh_conn = new DendriteConnection(spatix_in_layer, val_inh_conn, full_inh_spec);
        ix = 0;
        connections[ix++] = val_acc_conn;
        connections[ix++] = acc_acc_conn;
        connections[ix++] = val_inh_conn;
        connections[ix++] = inh_acc_conn;
        connections[ix++] = spat_acc_conn;
        connections[ix++] = spat_inh_conn;

        // set weights on connections
        float[][] w_sa = {{0,1},{1,0}};
        spat_acc_conn.weights(w_sa);
        float[][] w_si = {{1,0},{0,1}};
        spat_inh_conn.weights(w_si);
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(int l) {
        switch(l) {
            case VALUE:
                return val_in_layer; // input
            case SPAT_IX:
                return spatix_in_layer; // input
            case ACC:
            default:
                return acc_out_layer; // output
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
        rect(0, 0, 220, 200, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(val_in_layer.output(), val_in_layer.name());
        drawStrip(spatix_in_layer.output(), spatix_in_layer.name());
        drawStrip(inh_layer.output(), inh_layer.name());
        //drawStrip(disinh_layer.output(), disinh_layer.name());
        drawStrip(acc_out_layer.output(), acc_out_layer.name());
        drawStrip(ravel(val_acc_conn.weights()), "Value->Acc W");
        drawStrip(ravel(val_inh_conn.weights()), "Value->Inh W");
        
        popMatrix();
    }

    

    

}
