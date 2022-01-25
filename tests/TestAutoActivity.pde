class TestAutoActivity {
    String modelname = "Test auto activity";
    int inputvecsize = 1; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    
    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec excite_auto_unit_spec = new UnitSpec();
    

    // layer
    Layer input_layer; 
    Layer hidden_layer; // go - contains input, (learned, manually set) temporal combination patterns
    Layer support_layer;
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();

    LayerConnection IH_conn; // input to hidden
    LayerConnection HS_conn; // hidden to support, autoactivity
    LayerConnection SH_conn; // support to hidden, autoactivity
    
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map<String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float inputval;

    TestAutoActivity() {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        excite_auto_unit_spec.adapt_on = false;
        excite_auto_unit_spec.noisy_act=true;
        excite_auto_unit_spec.act_thr=0.5;
        excite_auto_unit_spec.act_gain=100;
        excite_auto_unit_spec.tau_net=40;
        excite_auto_unit_spec.g_bar_e=1.0;
        excite_auto_unit_spec.g_bar_l=0.1;
        excite_auto_unit_spec.g_bar_i=0.40;
        excite_auto_unit_spec.bias = 0.0; // 0.0075;
        excite_auto_unit_spec.g_l = 1.0;
        excite_auto_unit_spec.e_rev_l = 0.25;

        // LayerConnection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.20;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_auto_unit_spec, HIDDEN, "Hidden");
        support_layer = new Layer(hiddensize, new LayerSpec(false), excite_auto_unit_spec, HIDDEN, "Support");

        // connections
        IH_conn = new LayerConnection(input_layer, hidden_layer, ffexcite_spec);
        HS_conn = new LayerConnection(hidden_layer, support_layer, ffexcite_spec);
        SH_conn = new LayerConnection(support_layer, hidden_layer, ffexcite_spec);

        Layer[] layers = {input_layer, hidden_layer, support_layer};
        Connection[] conns = {IH_conn, HS_conn, SH_conn};

        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float inp) { inputval = inp;}

    void tick() {
      if(netw.accept_input()) {
            float[] inp = {inputval};
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals);
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
        
        float[][] h_viz = zeros(1, hiddensize);
        h_viz[0] = hidden_layer.getOutput();

        float[][] s_viz = zeros(1,hiddensize);
        s_viz[0] = support_layer.getOutput();

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
            text(hidden_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, h_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(support_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, s_viz));
            popMatrix();
            popMatrix();
        popMatrix();

        popMatrix();
    }

}
