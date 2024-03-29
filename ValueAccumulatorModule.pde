class ValueAccumulatorModule implements NetworkModule {
    /** Attempts to replicate accumulator behaviour described in Balkenius et al 2020
        with layers and connections

        // TODO 2022-01-26: appears that D2 may be a likelier candiate that M2 for resetting acc:
                    it too opens K leakage channels, and may be stimulated by a strong DA
                    burst upon choice completion - could also 
        // TODO 2022-01-26: add reset layer with ACh that leaks out all charge:
            Add input that inhibits Cholinergic shutting of kalium channels, increasing
            leakage of accumulators
    */
    static final String VALUE = "value";
    static final String SPAT_IX = "spatial_ix";
    static final String ACC = "accumulator";
    
    String name = "ValueAccumulatorModule";
    
    Layer[] layers = new Layer[4];
    Connection[] connections = new Connection[7];
    int layersize = 2;
    
    int boundary_w = 320;
    int boundary_h = 220;
    int fill_col = 60;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec spatix_unit_spec;
    UnitSpec dopa_unit_spec = new UnitSpec();

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
        excite_unit_spec.g_bar_l=0.47;
        excite_unit_spec.g_l=0.47;
        excite_unit_spec.g_bar_i=0.40;

        spatix_unit_spec = new UnitSpec(excite_unit_spec);
        spatix_unit_spec.g_bar_l = 0.5;
        spatix_unit_spec.g_l = 1.0;


        dopa_unit_spec.receptors.append("D2"); // for resetting
        dopa_unit_spec.use_modulators = false;
        dopa_unit_spec.g_bar_l = 0.;
        dopa_unit_spec.g_l = 0.;
        dopa_unit_spec.d2_thr = 0.1;
        dopa_unit_spec.act_thr = 0.2;

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

        ConnectionSpec oto_auto_inh_spec = new ConnectionSpec();
        oto_auto_inh_spec.proj = "1to1";
        oto_auto_inh_spec.type = GABA;
        oto_auto_inh_spec.rnd_mean = 0.32; // maintains actual input value, maintains dynamic range
        oto_auto_inh_spec.rnd_var = 0;

        // layers
        val_in_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "Value (in)");
        spatix_in_layer = new Layer(layersize, new LayerSpec(false), spatix_unit_spec, HIDDEN, "Spatial ix (in)");
        inh_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Inhibition");
        //disinh_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Disinhibition");
        acc_out_layer = new Layer(layersize, new LayerSpec(false), dopa_unit_spec, HIDDEN, "Accumulator (out)");
        
        int ix = 0;
        layers[ix++] = val_in_layer;
        layers[ix++] = spatix_in_layer;
        layers[ix++] = inh_layer;
        //layers[ix++] = disinh_layer;
        layers[ix++] = acc_out_layer;

        LayerConnection val_auto_inh_conn = new LayerConnection(val_in_layer, val_in_layer, oto_auto_inh_spec);
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
        connections[ix++] = val_auto_inh_conn;

        // set weights on connections
        float[][] w_sa = {{0,1},{1,0}};
        spat_acc_conn.weights(w_sa);
        float[][] w_si = {{1,0},{0,1}};
        spat_inh_conn.weights(w_si);
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String l) {
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
        fill(fill_col);
        stroke(fill_col + 20);
        rect(0, 0, boundary_w, boundary_h, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(val_in_layer.output(), val_in_layer.name());
        drawStrip(spatix_in_layer.output(), spatix_in_layer.name());
        drawStrip(inh_layer.output(), inh_layer.name());
        //drawStrip(disinh_layer.output(), disinh_layer.name());
        //drawStrip(acc_out_layer.output(), acc_out_layer.name());
        drawStrip(ravel(val_acc_conn.weights()), "Value->Acc W");
        drawStrip(ravel(val_inh_conn.weights()), "Value->Inh W");
        translate(0, -30);
        drawBarChart(acc_out_layer.output(), "Accum (out)");
        
        popMatrix();
    }

    

    

}
