class DecisionModule implements NetworkModule {
    /** This module has a value accumulator part
        built on that described in Balkenius et al 2020
    */
    static final String VALUE = "value";
    static final String SPATIAL_IX = "spatial_ix";
    static final String CHOICE = "choice";

    String name = "DecisionModule";
    Layer[] layers = new Layer[3];
    Connection[] connections = new Connection[0];
    int valuesize = 1;
    int choicesize = 2;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer value_layer;
    Layer spatial_ix_layer;
    ValueAccumulator acc;
    Layer choice_layer;

    DecisionModule() {
        this.init();
    }

    DecisionModule(String name) {
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
        // full_spec.proj="full";
        // full_spec.rnd_type="uniform" ;
        // full_spec.rnd_mean=0.5;
        // full_spec.rnd_var=0.0;

        // layers
        value_layer = new Layer(valuesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Value (in)");
        spatial_ix_layer = new Layer(choicesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Spatial ix (in)");
        choice_layer = new Layer(choicesize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Choice (out)");

        // accumlator
        acc = new ValueAccumulator(choicesize);

        int ix = 0;
        layers[ix++] = value_layer;
        layers[ix++] = spatial_ix_layer;
        layers[ix++] = choice_layer;

    }

    
    String name(){return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String code) {
        switch(code) {
            case VALUE:
                return value_layer;
            case CHOICE:
                return choice_layer;
            case SPATIAL_IX:
            default:
                return spatial_ix_layer;
        }
    }
    
    void cycle() {
        acc.setSpatialIx(spatial_ix_layer.getOutput());
        acc.setInput(value_layer.getOutput());
        acc.cycle();
        choice_layer.force_activity(acc.getOutput());

    }
    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 260, 210, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        //drawStrip(value_layer.output(), value_layer.name());
        drawBarChart(value_layer.getOutput(), value_layer.name());
        //drawStrip(spatial_ix_layer.output(), spatial_ix_layer.name());
        drawBarChart(spatial_ix_layer.output(), spatial_ix_layer.name());
        drawBarChart(acc.getOutput(), "Acc output");
        translate(0,10);
        drawStrip(choice_layer.output(), choice_layer.name());
        popMatrix();

    }

}
