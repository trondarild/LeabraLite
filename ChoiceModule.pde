class ChoiceModule implements NetworkModule {
    /** This module has a value accumulator part
        built on that described in Balkenius et al 2020
    */
    // static final String VALUE = "value";
    // static final String SPATIAL_IX = "spatial_ix";
    static final String CHOICE = "choice";

    String name = "ChoiceModule";
    Layer[] layers = new Layer[1];
    Connection[] connections = new Connection[2];
    int valuesize = 1;
    int choicesize = 2;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    //Layer value_layer;
    //Layer spatial_ix_layer;
    ValueAccumulatorModule acc;
    Layer choice_layer;

    // connections
    ConnectionSpec oto_spec = new ConnectionSpec();
    ConnectionSpec dopa_spec = new ConnectionSpec();
    LayerConnection acc_choice_conn;
    LayerConnection reset_conn; // resets accumulator

    ChoiceModule() {
        this.init();
    }

    ChoiceModule(String name) {
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
        excite_unit_spec.g_bar_l=0.4;
        excite_unit_spec.g_bar_i=0.40;

        // connection spec
        // full_spec.proj="full";
        // full_spec.rnd_type="uniform" ;
        // full_spec.rnd_mean=0.5;
        // full_spec.rnd_var=0.0;

        // layers
        // value_layer = new Layer(valuesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Value (in)");
        // spatial_ix_layer = new Layer(choicesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Spatial ix (in)");
        choice_layer = new Layer(choicesize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Choice (out)");

        // accumlator
        acc = new ValueAccumulatorModule(this.name + "_valueacc");

        // connections
        oto_spec.proj = "1to1";
        oto_spec.rnd_mean = 0.5;
        oto_spec.rnd_var = 0.0;

        dopa_spec.proj = "full";
        dopa_spec.type = DOPAMINE;
        dopa_spec.rnd_mean = 4.0;
        dopa_spec.rnd_var = 0.;

        acc_choice_conn = new LayerConnection(acc.layer("accumulator"), choice_layer, oto_spec);
        reset_conn = new LayerConnection( choice_layer, acc.layer("accumulator"), dopa_spec);


        int ix = 0;
        layers[ix++] = choice_layer;

        ix = 0;
        connections[ix++] = acc_choice_conn;
        connections[ix++] = reset_conn;

    }

    
    String name(){return name;}
    
    Layer[] layers() {
        Layer[] retval = new Layer[this.layers.length + acc.layers().length];
        int ix = 0;
        for(Layer l: this.layers)
            retval[ix++] = l;
        for(Layer al: acc.layers())
            retval[ix++] = al;

        return retval;
    }
    
    Connection[] connections() {
        Connection[] retval = new Connection[this.connections.length + acc.connections().length];
        int ix = 0;
        for(Connection c: this.connections)
            retval[ix++] = c;
        for(Connection ac: acc.connections())
            retval[ix++] = ac;

        return retval;
    }
    
    Layer layer(String code) {
        switch(code) {
            case CHOICE:
                return choice_layer;
            default:
                return acc.layer(code);
        }
    }
    
    void cycle() {
        // acc.setSpatialIx(spatial_ix_layer.getOutput());
        // acc.setInput(value_layer.getOutput());
        acc.cycle();
        // choice_layer.force_activity(acc.getOutput());

    }

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 260, 240, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);
        //translate(0, 20);
        acc.draw();

        translate(0,160);
        drawStrip(choice_layer.output(), choice_layer.name());
        popMatrix();

    }

}
