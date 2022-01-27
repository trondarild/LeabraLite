
class ValenceLearningModule implements NetworkModule {
    /** This module models avoid approach learning.
        It has a choline-like population that modulates
        learning rate.
    */
    static final String NEG_LR = "neg_lr";
    static final String POS_LR = "pos_lr";
    static final String PROPERTY = "property";
    static final String AVOIDANCE = "avoidance";
    static final String APPROACH = "approach";

    String name = "Valence learning module";
    int popsize = 1; // size of populations representing positive and negative valence
    Layer[] layers = new Layer[5];
    Connection[] connections = new Connection[4];

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer neg_lr_layer; // choline-like, modulates learning rate on neg. valence
    Layer pos_lr_layer; // dopa-like, modulates learning rate on pos. valence
    Layer property_layer; // input interface; projects to valence layers; proj. susc. to learning rate mod
    Layer avoidance_layer; // learns negative valence
    Layer approach_layer; // learns positive valence

    // connections
    ConnectionSpec oto_spec = new ConnectionSpec(); //  
    ConnectionSpec choline_spec = new ConnectionSpec(); 
    LayerConnection property_avoidance_conn;
    LayerConnection property_approach_conn;
    DendriteConnection lr_avoidance_conn;
    DendriteConnection lr_approach_conn;

    ConnectableWeightSpec chol_w_spec = new ConnectableWeightSpec();



    ValenceLearningModule() {
        this.init();
    }

    ValenceLearningModule(int popsize, String name) {
        this.popsize = popsize;
        this.name = name;
        this.init();
    }

    void init() {
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=false;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        // connection spec
        choline_spec.proj="full";
        choline_spec.rnd_type="uniform" ;
        choline_spec.rnd_mean=0.5;
        choline_spec.rnd_var=0.0;
        choline_spec.type = ACETYLCHOLINE;

        oto_spec.proj = "1to1";
        oto_spec.rnd_type="uniform" ;
        oto_spec.rnd_mean=0.05;
        oto_spec.rnd_var=0.0;
        oto_spec.lrule = "delta";
        oto_spec.lrate = .1;

        chol_w_spec.receptors.append("M1"); // add M1 receptor support to modulate learning rate

        // layers
        neg_lr_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "ACh (in)");
        pos_lr_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "DA (in)"); // positive learning is likely dopa, but model as same ACh here
        property_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Properties (in)");
        avoidance_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, OUTPUT, "Neg val (out)");
        approach_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, OUTPUT, "Pos val (out)");

        // connections
        property_avoidance_conn = new LayerConnection(property_layer, avoidance_layer, oto_spec, chol_w_spec);
        property_approach_conn = new LayerConnection(property_layer, approach_layer, oto_spec, chol_w_spec);
        lr_avoidance_conn = new DendriteConnection(neg_lr_layer, property_avoidance_conn, choline_spec);
        lr_approach_conn = new DendriteConnection(pos_lr_layer, property_approach_conn, choline_spec);

        int ix = 0;
        layers[ix++] = neg_lr_layer;
        layers[ix++] = pos_lr_layer;
        layers[ix++] = property_layer;
        layers[ix++] = avoidance_layer;
        layers[ix++] = approach_layer;
        ix =0;
        connections[ix++] = property_avoidance_conn;
        connections[ix++] = property_approach_conn;
        connections[ix++] = lr_avoidance_conn;
        connections[ix++] = lr_approach_conn;


    }

    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(String code) {
        switch(code) {
            case NEG_LR:
                return neg_lr_layer;
            case POS_LR:
                return pos_lr_layer;
            case PROPERTY:
                return property_layer;
            case AVOIDANCE:
                return avoidance_layer;
            case APPROACH:
            default:
                return approach_layer;
        }
    }
    void cycle() {}

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 320, 340, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(neg_lr_layer.output(), neg_lr_layer.name());
        drawStrip(pos_lr_layer.output(), pos_lr_layer.name());
        drawStrip(property_layer.output(), property_layer.name());
        drawStrip(avoidance_layer.output(), avoidance_layer.name());
        drawStrip(approach_layer.output(), approach_layer.name());
        // draw weights for inspection
        drawBarChart(ravel(property_avoidance_conn.weights()), "Avoidance w");
        drawBarChart(ravel(property_approach_conn.weights()), "Approach w");
        popMatrix();
    }


}
