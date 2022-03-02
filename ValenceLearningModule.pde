
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
    static final String SUM = "sum";

    String name = "Valence learning module";
    int popsize = 1; // size of populations representing positive and negative valence
    Layer[] layers = new Layer[6];
    Connection[] connections = new Connection[7];
    float sumgain = 0.4;

    int boundary_w = 320; 
    int boundary_h = 340;
    int fill_col = 60;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer neg_lr_layer; // choline-like, modulates learning rate on neg. valence
    Layer pos_lr_layer; // dopa-like, modulates learning rate on pos. valence
    Layer property_layer; // input interface; projects to valence layers; proj. susc. to learning rate mod
    Layer avoidance_layer; // learns negative valence -> motivate avoidance beh
    Layer approach_layer; // learns positive valence -> motivate approach
    Layer sum_layer; // sums up valence for convenience

    // connections
    ConnectionSpec oto_learn_spec = new ConnectionSpec(); //  
    ConnectionSpec choline_spec = new ConnectionSpec(); 
    LayerConnection property_avoidance_conn;
    LayerConnection property_approach_conn;
    DendriteConnection lr_avoidance_conn;
    DendriteConnection lr_approach_conn;
    LayerConnection avoidance_inh_sum_conn;
    LayerConnection avoidance_exc_sum_conn;
    LayerConnection approach_sum_conn;

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
        choline_spec.rnd_mean=0.05; // 2022-02-15: if this is too high, both choices will have too high avoidance, and "sum" will not be excited above threshold
        choline_spec.rnd_var=0.0;
        choline_spec.type = ACETYLCHOLINE;

        oto_learn_spec.proj = "1to1";
        oto_learn_spec.rnd_type="uniform" ;
        oto_learn_spec.rnd_mean=0.5;
        oto_learn_spec.rnd_var=0.0;
        oto_learn_spec.lrule = "delta";
        oto_learn_spec.lrate = .95;
        oto_learn_spec.normalize = true;

        ConnectionSpec oto_learn_appr_spec = new ConnectionSpec(oto_learn_spec);
        //oto_learn_appr_spec.rnd_mean = oto_learn_spec.rnd_mean + 0.035; // to force choice

        
        ConnectionSpec oto_exc_spec = new ConnectionSpec(oto_learn_spec);
        oto_exc_spec.lrule = "";
        oto_exc_spec.rnd_mean = sumgain;
        oto_exc_spec.type = GLUTAMATE;
        oto_exc_spec.normalize = false;

        ConnectionSpec oto_inh_spec = new ConnectionSpec(oto_learn_spec);
        oto_inh_spec.lrule = "";
        oto_inh_spec.rnd_mean = sumgain;
        oto_inh_spec.type = GABA;
        oto_inh_spec.normalize = false;

        chol_w_spec.receptors.append("M1"); // add M1 receptor support to modulate learning rate

        ConnectionSpec oto_exc_cross_spec = new ConnectionSpec(oto_exc_spec);
        oto_exc_cross_spec.pre_indeces = new int[2];
        oto_exc_cross_spec.pre_indeces[0] = 0;
        oto_exc_cross_spec.pre_indeces[1] = 1;
        oto_exc_cross_spec.post_indeces = new int[2]; // {1,0}; // cross connections so excite "anywhere but here"
        oto_exc_cross_spec.post_indeces[0] = 1;
        oto_exc_cross_spec.post_indeces[1] = 0;

        // layers
        neg_lr_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "ACh (in)");
        pos_lr_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "DA (in)"); // positive learning is likely dopa, but model as same ACh here
        property_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Properties (in)");
        avoidance_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, OUTPUT, "Neg val (out)");
        approach_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, OUTPUT, "Pos val (out)");
        sum_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Sum (out)");
        // connections
        property_avoidance_conn = new LayerConnection(property_layer, avoidance_layer, oto_learn_spec, chol_w_spec);
        property_approach_conn = new LayerConnection(property_layer, approach_layer, oto_learn_appr_spec, chol_w_spec);
        lr_avoidance_conn = new DendriteConnection(neg_lr_layer, property_avoidance_conn, choline_spec);
        lr_approach_conn = new DendriteConnection(pos_lr_layer, property_approach_conn, choline_spec);
        avoidance_inh_sum_conn = new LayerConnection(avoidance_layer, sum_layer, oto_inh_spec);
        avoidance_exc_sum_conn = new LayerConnection(avoidance_layer, sum_layer, oto_exc_cross_spec);
        approach_sum_conn = new LayerConnection(approach_layer, sum_layer, oto_exc_spec);


        int ix = 0;
        layers[ix++] = neg_lr_layer;
        layers[ix++] = pos_lr_layer;
        layers[ix++] = property_layer;
        layers[ix++] = avoidance_layer;
        layers[ix++] = approach_layer;
        layers[ix++] = sum_layer;
        ix =0;
        connections[ix++] = property_avoidance_conn;
        connections[ix++] = property_approach_conn;
        connections[ix++] = lr_avoidance_conn;
        connections[ix++] = lr_approach_conn;
        connections[ix++] = avoidance_inh_sum_conn;
        connections[ix++] = avoidance_exc_sum_conn;
        connections[ix++] = approach_sum_conn;


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
                return approach_layer;
            case SUM:
                return sum_layer;
            default:
                assert(false): "No layer named '" + code + "' defined, check spelling.";
                return null;
        }
    }
    void cycle() {}

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
        drawStrip(neg_lr_layer.output(), neg_lr_layer.name());
        drawStrip(pos_lr_layer.output(), pos_lr_layer.name());
        drawStrip(property_layer.output(), property_layer.name());
        drawStrip(avoidance_layer.output(), avoidance_layer.name());
        drawStrip(approach_layer.output(), approach_layer.name());
        drawStrip(sum_layer.output(), sum_layer.name());
        // draw weights for inspection
        translate(0, -10);
        drawBarChart(ravel(property_avoidance_conn.weights()), "Avoidance w");
        drawBarChart(ravel(property_approach_conn.weights()), "Approach w");
        popMatrix();
    }


}
