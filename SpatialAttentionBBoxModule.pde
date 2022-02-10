class SpatialAttentionBBoxModule implements NetworkModule {
    static final String IN = "in";
    static final String OUT = "out";
    
    String name = "SpatialAttentionBBoxModule";
    
    Layer[] layers = new Layer[2];
    Connection[] connections; // = new Connection[1];
    int layersize = 2;
    int fill_col = 60;
    int boundary_w = 220;
    int boundary_h = 100;
    boolean do_saccade = true; // whether to do_saccade or saccade

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer in_layer; // used for translation to pop code to engage effort
    Layer out_layer;
    

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
        out_layer = new Layer(layersize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Out (out)");
        
        int layerix = 0;
        layers[layerix++] = in_layer;
        layers[layerix++] = out_layer;

        in_out_conn = new LayerConnection(in_layer, out_layer, full_spec);
        //ConnectionSpec out_in_connection(out_layer, in_layer)
        connections = new Connection[0];
        //connections[0] = in_out_conn;
        
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
            out_layer.force_activity(outval); 

            if (similar(max(out_layer.output()), max(outval), 0.1)){
                in_layer.force_activity(zeros(layersize));
                do_saccade = true;
            }
        }
        */
        //hysteresis(float in, float prev, float lo_thr, float hi_thr)
        float sinval = sin(0.07 * ctr++);
        //ctr = (ctr + 0.5) % 360;
        reset(outval);
        if(sinval > 0.0) 
            outval[0] = in_layer.output()[0];     
        else
            outval[1] = in_layer.output()[1];
        out_layer.force_activity(outval); 


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

        translate(0, 20);
        pushMatrix();
        scale(1.5);
        text(do_saccade ? "Saccading" : "Fixating", 0, 0);
        popMatrix();

        // draw the layers
        drawStrip(in_layer.getOutput(), in_layer.name);
        drawStrip(out_layer.getOutput(), out_layer.name);
        
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
