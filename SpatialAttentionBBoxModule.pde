class SpatialAttentionBBoxModule implements NetworkModule {
    static final String IN = "in";
    static final String VALUE = "value";
    static final String SPATIALIX = "spatial_ix";
    
    String name = "SpatialAttentionBBoxModule";
    
    Layer[] layers = new Layer[3];
    Connection[] connections; // = new Connection[1];
    int layersize = 2;
    int fill_col = 60;
    int boundary_w = 220;
    int boundary_h = 130;
    boolean do_saccade = true; // whether to do_saccade or saccade
    float freq_scale = 0.035;
    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer in_layer; // used for translation to pop code to engage effort
    Layer value_layer;
    Layer spatial_ix_layer;
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    LayerConnection in_out_conn; // population to gain

    float[] outval;
    float ctr = 0;
    

    SpatialAttentionBBoxModule() {
        this.init();
    }

    SpatialAttentionBBoxModule(int size, String name) {
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

        outval = zeros(layersize);
        

        in_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "In (in)");
        value_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "Value (out)");
        spatial_ix_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Spatial ix (out)");
        
        int layerix = 0;
        layers[layerix++] = in_layer;
        layers[layerix++] = value_layer;
        layers[layerix++] = spatial_ix_layer;

        //in_out_conn = new LayerConnection(in_layer, value_layer, full_spec);
        //ConnectionSpec out_in_connection(value_layer, in_layer)
        ConnectionSpec oto_inh_spec = new ConnectionSpec();
        oto_inh_spec.proj = "1to1";
        oto_inh_spec.type = GABA;
        oto_inh_spec.rnd_mean = 0.32; // maintains actual input value, maintains dynamic range
        oto_inh_spec.rnd_var = 0;

        LayerConnection auto_inh_conn = new LayerConnection(in_layer, in_layer, oto_inh_spec);
        connections = new Connection[1];
        connections[0] = auto_inh_conn;
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String l) {
        switch(l) {
            case IN:
                return in_layer; // input
            case SPATIALIX:
                return spatial_ix_layer;
            case VALUE:
                return value_layer; // output
            default:
                assert(false): "No layer named '" + l + "' defined, check spelling.";
                return null;
        }
    }

    void cycle() {  
        /*
        if (max(in_layer.output()) < 0.5) return;

        if(do_saccade) {
            //println("saccading");
            outval = spatialAttention(in_layer.output(), outval);
            do_saccade = false;
        }
        else {
            //println("fixating");
            outval = multiply(0.999, outval); // downregulate to induce saccade
            value_layer.force_activity(outval); 

            if (similar(max(value_layer.output()), max(outval), 0.1)){
                in_layer.force_activity(zeros(layersize));
                do_saccade = true;
            }
        }
        */
        //hysteresis(float in, float prev, float lo_thr, float hi_thr)
        float sinval = sin(freq_scale * ctr++);
        //ctr = (ctr + 0.5) % 360;
        reset(outval);
        //if(sinval > 0.0) 
        //    outval[0] = in_layer.output()[0];     
        //else
        //    outval[1] = in_layer.output()[1];
        float[] in_val = in_layer.output();
        int ix = (sinval - in_val[0] + in_val[1])   < 0.0 ? 0 : 1; // TODO: stay longer at higher value
        //int ix = sinval > 0.0 ? 0 : 1; // TODO: stay longer at higher value
        float[] value = {in_layer.output()[ix]};
        value_layer.force_activity(value); //max(outval));
        outval[ix] = 1;
        spatial_ix_layer.force_activity(outval); 


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

        // translate(0, 20);
        // pushMatrix();
        // scale(1.5);
        // text(do_saccade ? "Saccading" : "Fixating", 0, 0);
        // popMatrix();

        // draw the layers
        drawStrip(in_layer.output(), in_layer.name());
        drawStrip(spatial_ix_layer.output(), spatial_ix_layer.name());
        drawStrip(value_layer.output(), value_layer.name());
        
        popMatrix();
    }

    float[] spatialAttention(float[] value, float[] prevalue){
        float[] retval = zeros(value.length);
        float[] attend = {random(value[0]), random(value[1])};
        int prevarg = argmax(prevalue);
        int arg = argmax(attend);
        if(prevarg == arg) 
            arg = argmin(attend);
        retval[arg] = value[arg];
        // printArray("attend", attend);
        return retval;
    }
    

    

}
