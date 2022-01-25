class TestCtxPredError {
    String modelname = "Test context prediction error";
    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    
    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec excite_auto_unit_spec = new UnitSpec();
    

    // layer
    Layer input_layer; 
    Layer context_layer; // go - contains input, (learned, manually set) temporal combination patterns
    Layer predictionerror_layer; //
    Layer dACC_layer;
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec onetoone_excite_spec = new ConnectionSpec();
    ConnectionSpec onetoone_excite_weak_spec = new ConnectionSpec();
    ConnectionSpec onetoone_inh_spec = new ConnectionSpec();

    LayerConnection IC_conn; // input to context
    LayerConnection IPE_conn; // hidden to support, CtxPredError
    LayerConnection PEdACC_conn; // support to hidden, CtxPredError
    LayerConnection dACCC_conn; // dACC to context
    LayerConnection CPE_conn; // context to prediction error
    LayerConnection CC_conn; // context self-sustaining
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    TestCtxPredError() {
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
        excite_auto_unit_spec.bias = 0.05; // 0.0075; // bias incr from 0
        excite_auto_unit_spec.g_l = 0.9; // leak reduced from 1.0
        excite_auto_unit_spec.e_rev_l = 0.3;

        // LayerConnection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.20;

        onetoone_excite_spec.proj = "1to1";
        onetoone_excite_spec.rnd_type = "uniform";
        onetoone_excite_spec.rnd_mean = 0.5;
        onetoone_excite_spec.rnd_var = 0.0;

        onetoone_excite_weak_spec.proj = "1to1";
        onetoone_excite_weak_spec.rnd_type = "uniform";
        onetoone_excite_weak_spec.rnd_mean = 0.1;
        onetoone_excite_weak_spec.rnd_var = 0.0;

        onetoone_inh_spec.proj = "1to1";
        onetoone_inh_spec.inhibit = true;
        onetoone_inh_spec.rnd_type = "uniform";
        onetoone_inh_spec.rnd_mean = 0.5;
        onetoone_inh_spec.rnd_var = 0.0;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        context_layer = new Layer(hiddensize, new LayerSpec(true), excite_auto_unit_spec, HIDDEN, "Context");
        dACC_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "dACC");
        predictionerror_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Pred error");
        // connections
        IC_conn = new LayerConnection(input_layer, context_layer, onetoone_excite_weak_spec);
        IPE_conn = new LayerConnection(input_layer, predictionerror_layer, onetoone_excite_spec);
        PEdACC_conn = new LayerConnection(predictionerror_layer, dACC_layer, onetoone_excite_weak_spec);
        dACCC_conn = new LayerConnection(dACC_layer, context_layer, onetoone_excite_spec);
        CPE_conn = new LayerConnection(context_layer, predictionerror_layer, onetoone_inh_spec);
        CC_conn = new LayerConnection(context_layer, context_layer, onetoone_excite_spec);
        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, context_layer, dACC_layer, predictionerror_layer };
        Connection[] conns = {/*IC_conn,*/ IPE_conn, PEdACC_conn, dACCC_conn, CPE_conn };


        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp;}

    void tick() {
        if(netw.accept_input()) {
            float[] inp = inputval;
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
        h_viz[0] = context_layer.getOutput();

        float[][] dacc_viz = zeros(1,hiddensize);
        dacc_viz[0] = dACC_layer.getOutput();

        float[][] pe_viz = zeros(1, hiddensize);
        pe_viz[0] = predictionerror_layer.getOutput();

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
            text(predictionerror_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, pe_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(dACC_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, dacc_viz));
            popMatrix();
            popMatrix();
        popMatrix();

        popMatrix();
    }

    void handleKeyDown(char k){
        float[] ctx = zeros(inputvecsize);
        if (k=='z')
            ctx[0] = 1.f;
        else if(k=='x')
            ctx[1] = 1.f;
        else if(k=='c')
            ctx[2] = 1.f;

        this.setInput(ctx);

    }

    void handleKeyUp(char k){
        this.setInput(zeros(inputvecsize));
    }

    void handleMidi(float note, float vel){
        println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            inputval[0] = scale * vel; 
        if(note==82)
            inputval[1] = scale * vel; 
    }

}
