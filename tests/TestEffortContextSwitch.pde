class TestEffortContextSwitch {
    String modelname = "Test effortful context switch";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    int gainsize = 5;
    int magnitudesize = 1;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec auto_unit_spec; // for interneurons
    // layer
    Layer input_layer; 
    Layer hidden_layer;
    Layer interneuron_layer; 
    Layer pop_layer;
    Layer gain_layer; // excites hidden layer
    Layer predictionerror_layer; // diff between input and hidden/context
    Layer pe_magnitude_layer; // used for translation to pop code to engage effort
    
    // connections
    ConnectionSpec full_spec  = new ConnectionSpec();
    ConnectionSpec oto_inh_spec;
    ConnectionSpec inh_full_spec;
    ConnectionSpec full_weak_spec;
    ConnectionSpec oto_strong_spec;
    ConnectionSpec oto_middle_spec;

    LayerConnection pe_intern_conn; // input to context
    LayerConnection gain_hidden_conn;
    DendriteConnection intern_gainproj_conn; // inhibits proj from gain to hidden
    LayerConnection pop_gain_conn; // population to gain
    LayerConnection hidden_self_conn;
    LayerConnection inp_pe_conn; // input to pred error, excitative
    LayerConnection hidden_pe_conn; // context to pred error, inhibitive
    LayerConnection pe_magnitude_conn; // 
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    float[][] w_intern = tileCols(gainsize, id(inputvecsize));
    float forcegain =0;
    float forceintern = 0;

    float[][] w_effort = {  {1,0,0,0,0},
                            {1,1,0,0,0},
                            {1,1,1,0,0},
                            {1,1,1,1,0},
                            {1,1,1,1,1} };

    TestEffortContextSwitch () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=false;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        auto_unit_spec = new UnitSpec(excite_unit_spec);
        auto_unit_spec.bias = 0.2; // inh neurons need to fire to allow disinh

        // connection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;

        full_weak_spec = new ConnectionSpec(full_spec);
        full_weak_spec.rnd_mean = 0.5/gainsize;

        oto_inh_spec = new ConnectionSpec();
        oto_inh_spec.proj = "1to1";
        oto_inh_spec.inhibit = true;
        oto_inh_spec.rnd_mean=0.5;
        oto_inh_spec.rnd_var =0;

        inh_full_spec = new ConnectionSpec(oto_inh_spec);
        inh_full_spec.proj = "full";

        oto_strong_spec = new ConnectionSpec(oto_inh_spec);
        oto_strong_spec.inhibit = false;
        oto_strong_spec.rnd_mean = 0.5;

        oto_middle_spec = new ConnectionSpec(oto_strong_spec); // for now same wt as strong

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(inputvecsize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Context");
        interneuron_layer = new Layer(inputvecsize, new LayerSpec(false), auto_unit_spec, HIDDEN, "Interneurons");
        gain_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Gain");
        pop_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Population");
        predictionerror_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Prediction error");
        pe_magnitude_layer = new Layer(magnitudesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Magnitude");
        
        // connections
        inp_pe_conn = new LayerConnection(input_layer, predictionerror_layer, oto_middle_spec);
        hidden_pe_conn = new LayerConnection(hidden_layer, predictionerror_layer, oto_inh_spec);
        pe_intern_conn = new LayerConnection(predictionerror_layer, interneuron_layer, oto_inh_spec);
        gain_hidden_conn = new LayerConnection(gain_layer, hidden_layer, full_weak_spec);
        intern_gainproj_conn = new DendriteConnection(interneuron_layer, gain_hidden_conn, inh_full_spec);
        intern_gainproj_conn.weights(w_intern);
        pop_gain_conn = new LayerConnection(pop_layer, gain_layer, full_spec);
        pop_gain_conn.weights(w_effort);
        hidden_self_conn = new LayerConnection(hidden_layer, hidden_layer, oto_strong_spec);
        pe_magnitude_conn = new LayerConnection(predictionerror_layer, pe_magnitude_layer, full_weak_spec);
        
        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer, interneuron_layer, 
            gain_layer, pop_layer, predictionerror_layer, pe_magnitude_layer};
        Connection[] conns = {pe_intern_conn, gain_hidden_conn, 
            intern_gainproj_conn, pop_gain_conn, hidden_self_conn,
            inp_pe_conn, hidden_pe_conn, pe_magnitude_conn};


        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        float[] pop_act = zeros(gainsize);
        pop_act = populationEncode(
                pe_magnitude_layer.units[0].getOutput(), //forcegain,
                gainsize,
                0, 1,
                0.25
            );    
        pop_layer.force_activity(pop_act);

        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals.copy());
            //inpvals = arrayToList(multiply(forcegain, ones(gainsize)));
            //inputs.put("Gain", inpvals.copy());
            //inpvals = arrayToList(multiply(forceintern, ones(inputvecsize)));
            //inputs.put("Interneurons", inpvals.copy()); // note: forced units cannot be inh

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

            drawLayer(predictionerror_layer);
            drawLayer(pe_magnitude_layer);
            drawLayer(interneuron_layer);
            drawLayer(hidden_layer);
            drawLayer(pop_layer);
            drawLayer(gain_layer);

            
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

    void handleMidi(int note, int vel){
        //println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            inputval[0] = scale * vel; 
        if(note==82)
            inputval[1] = scale * vel; 
        if(note==83)
            inputval[2] = scale * vel; 
        if(note==1)
            forcegain = scale * vel;
        if(note==2)
            forceintern = scale * vel;
    }

    void drawLayer(Layer layer){
        float[][] viz = {layer.getOutput()};
        

        translate(0, 20);
        pushMatrix();
        text(layer.name, 0,0);
        pushMatrix();
        translate(100, -10);
        drawColGrid(0,0, 10, multiply(200, viz));
        popMatrix();
        popMatrix();
            
    }

}
