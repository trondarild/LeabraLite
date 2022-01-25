//
// Test for (dis)inhibiting a particular population given 
// a context
class TestCtxRuleInh {
    String modelname = "Context rule inhibition test";

    int inputvecsize = 4;
    int ctxsize = 3;
    int hiddensize = ctxsize * 2;

     // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();

    // layer
    
    Layer input_layer;
    Layer context_layer; // repr context
    Layer rule_layer; // go - contains input, (learned, manually set) temporal combination patterns

    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec inh_spec = new ConnectionSpec();
    LayerConnection context_rule_conn; // input to striatum D1 - go
    LayerConnection sensory_rule_conn; // pfc to inp-D1 dendrite, setting weights

    // network
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map<String, FloatList> inputs = new HashMap<String, FloatList>();

    float[][] inputval = id(ctxsize);

    float[][] ruleinputs = id(inputvecsize);
    int inp_ix = 0;
    



    TestCtxRuleInh() {
         // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        // LayerConnection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.2;

        inh_spec.proj="full";
        inh_spec.rnd_type="uniform" ;
        inh_spec.rnd_mean=0.7;
        inh_spec.rnd_var=0.0;
        inh_spec.inhibit = true;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Sensory");
        context_layer = new Layer(ctxsize, new LayerSpec(false), excite_unit_spec, INPUT, "Context");
        rule_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Rule");

        // connections
        context_rule_conn = new LayerConnection(context_layer, rule_layer, inh_spec);
        sensory_rule_conn = new LayerConnection(input_layer, rule_layer, ffexcite_spec);

        Layer[] layers = {input_layer, rule_layer, context_layer};
        Connection[] conns = {context_rule_conn, sensory_rule_conn};

        netw = new Network(network_spec, layers, conns);
        netw.build();

        // change weights for inh connection
        float[][] inh_w = context_rule_conn.weights();
        println("inh_w: " + inh_w.length + ", " + inh_w[0].length);
        // rows are targets, cols are sources
        float[][] inhmask = {{0,1, 1}, {1,0,1}, {1,1,0}};
        inhmask = repeatCols(2, inhmask);
        assert(inh_w.length == inhmask.length) : inh_w.length + "; " + inhmask.length;
        inh_w = mult_per_elm(inh_w, inhmask);
        printMatrix("inhw", inh_w);
        context_rule_conn.weights(inh_w);

    }
    void setInput(float[][] inp) {inputval = inp;}

    void tick() {
        if(netw.accept_input()){
            // println();
            //printArray("input", testinputs[inp_ix % testinputs.length]);
            FloatList ctxvals = arrayToList(inputval[inp_ix++ % inputval.length]);
            FloatList inpvals = arrayToList(ruleinputs[inp_ix++ % ruleinputs.length]);
            //println("floatlist: " + inpvals.toString());
            inputs.put("Context", ctxvals);
            inputs.put("Sensory", inpvals);
            netw.set_inputs(inputs);
        }
        netw.cycle();

    }

    void draw() {
        pushMatrix();
        
        pushMatrix();
        translate(10,20);
        text(modelname, 0, 0);
        popMatrix();

        float[][] inp_viz = zeros(1,inputvecsize);
        inp_viz[0] = input_layer.getOutput();
        //printArray("input layer output", inp_viz[0]);
        
        float[][] h_viz = zeros(1, ctxsize);
        h_viz[0] = context_layer.getOutput();

        float[][] r_viz = zeros(1, hiddensize);
        r_viz[0] = rule_layer.getOutput();

        translate(10,50);
        pushMatrix();
            //rotate(-HALF_PI);
            pushMatrix();
            text(input_layer.name, 0, 0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, inp_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(context_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, h_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(rule_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, r_viz));
            popMatrix();
            popMatrix();

          
        popMatrix();

        popMatrix();
    }

    void handleKeyDown(char k){
        float[][] ctx = zeros(ctxsize, ctxsize);
        if (k=='z')
            ctx[0][0] = 1.f;
        else if(k=='x')
            ctx[1][1] = 1.f;
        else if(k=='c')
            ctx[2][2] = 1.f;

        this.setInput(ctx);

    }

    void handleKeyUp(char k){
        this.setInput(zeros(ctxsize, ctxsize));
    }
}
