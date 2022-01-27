class TestEffortAchDecisionModules {
    String modelname = "Test effortful context switch with ACh and decisionmaking";

    int ctx_inp_sz = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int pos_inp_sz = 2;
    int rew_inp_sz = 1; // reward
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    int gainsize = 5;
    int magnitudesize = 1;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec auto_unit_spec; // for interneurons
    // layer
    Layer ctx_input_layer; 
    Layer pos_input_layer;
    Layer rew_input_layer; // will increase learning rate for approach
    Layer hidden_layer;
    Layer interneuron_layer; 
    Layer predictionerror_layer; // diff between input and hidden/context
    
    // connections
    ConnectionSpec full_spec  = new ConnectionSpec();
    ConnectionSpec oto_inh_spec;
    ConnectionSpec inh_full_spec;
    ConnectionSpec full_weak_spec;
    ConnectionSpec gain_spec;
    ConnectionSpec oto_strong_spec;
    ConnectionSpec oto_middle_spec;

    LayerConnection pe_intern_conn; // input to context
    LayerConnection gain_hidden_conn;
    DendriteConnection intern_gainproj_conn; // inhibits proj from gain to hidden
    //LayerConnection pop_gain_conn; // population to gain
    LayerConnection hidden_self_conn;
    LayerConnection inp_pe_conn; // input to pred error, excitative
    LayerConnection hidden_pe_conn; // context to pred error, inhibitive
    LayerConnection pe_magnitude_conn; // 
    LayerConnection rew_dopa_conn; // reward to dopa to modulate learning rate for approach
    LayerConnection gain_ach_conn; // effort to ACh to modulate learing rate for avoid
    LayerConnection avoid_decval_conn; // avoid valence to decide valence - inhibitive
    LayerConnection appr_decval_conn; // approach valence to decide valence - excitative
    LayerConnection pos_avoid_conn; // position to avoid
    LayerConnection pos_approach_conn; // position to avoid
    LayerConnection avoid_spatix_conn; // avoid to spatial index
    LayerConnection approach_spatix_conn; // approach to spatial index

    // modules
    EffortModule effort_mod = new EffortModule(gainsize, "Effort");
    DecisionModule dec_mod = new DecisionModule("Decision");
    ValenceLearningModule val_mod = new ValenceLearningModule(2, "Valence learning");
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] ctx_inputval = zeros(ctx_inp_sz);
    float[] pos_inputval = zeros(pos_inp_sz);
    float[] rew_inputval = zeros(rew_inp_sz);

    float[][] w_intern = tileCols(gainsize, id(ctx_inp_sz));
    float forcegain =0;
    float forceintern = 0;
    



    TestEffortAchDecisionModules () {
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
        full_weak_spec.rnd_mean = 0.25;

        gain_spec = new ConnectionSpec(full_spec);
        gain_spec.rnd_mean = 0.25/gainsize;

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
        ctx_input_layer = new Layer(ctx_inp_sz, new LayerSpec(false), excite_unit_spec, INPUT, "Input ctx");
        pos_input_layer = new Layer(pos_inp_sz, new LayerSpec(false), excite_unit_spec, INPUT, "Input pos");
        rew_input_layer = new Layer(rew_inp_sz, new LayerSpec(false), excite_unit_spec, INPUT, "Input rew");
        
        hidden_layer = new Layer(ctx_inp_sz, new LayerSpec(true), excite_unit_spec, HIDDEN, "Context");
        interneuron_layer = new Layer(ctx_inp_sz, new LayerSpec(false), auto_unit_spec, HIDDEN, "Interneurons");
        //gain_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Gain");
        //pop_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Population");
        predictionerror_layer = new Layer(ctx_inp_sz, new LayerSpec(false), excite_unit_spec, HIDDEN, "Prediction error");
        //pe_magnitude_layer = new Layer(magnitudesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Magnitude");
        
        // connections
        inp_pe_conn = new LayerConnection(ctx_input_layer, predictionerror_layer, oto_middle_spec);
        hidden_pe_conn = new LayerConnection(hidden_layer, predictionerror_layer, oto_inh_spec);
        pe_intern_conn = new LayerConnection(predictionerror_layer, interneuron_layer, oto_inh_spec);
        gain_hidden_conn = new LayerConnection(effort_mod.layer(EffortModule.GAIN), hidden_layer, full_weak_spec);
        intern_gainproj_conn = new DendriteConnection(interneuron_layer, gain_hidden_conn, inh_full_spec);
        intern_gainproj_conn.weights(w_intern);
        //pop_gain_conn = new LayerConnection(pop_layer, gain_layer, full_spec);
        //pop_gain_conn.weights(w_effort);
        hidden_self_conn = new LayerConnection(hidden_layer, hidden_layer, oto_strong_spec);
        pe_magnitude_conn = new LayerConnection(predictionerror_layer, effort_mod.layer(EffortModule.MAGNITUDE), full_weak_spec);
        gain_ach_conn = new LayerConnection(effort_mod.layer(EffortModule.GAIN), val_mod.layer(ValenceLearningModule.NEG_LR), gain_spec);
        rew_dopa_conn = new LayerConnection(rew_input_layer, val_mod.layer(ValenceLearningModule.POS_LR), full_spec);
        avoid_decval_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.AVOIDANCE), dec_mod.layer(DecisionModule.VALUE), inh_full_spec);
        appr_decval_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.APPROACH), dec_mod.layer(DecisionModule.VALUE), full_spec);
        pos_avoid_conn = new LayerConnection(pos_input_layer, val_mod.layer(ValenceLearningModule.PROPERTY), oto_strong_spec);
        pos_approach_conn = new LayerConnection(pos_input_layer, val_mod.layer(ValenceLearningModule.PROPERTY), oto_strong_spec);
        avoid_spatix_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.AVOIDANCE), dec_mod.layer(DecisionModule.SPATIAL_IX), inh_full_spec);
        approach_spatix_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.APPROACH), dec_mod.layer(DecisionModule.SPATIAL_IX), full_spec);
        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {ctx_input_layer, hidden_layer, interneuron_layer, 
            predictionerror_layer, pos_input_layer, rew_input_layer};
            
        Connection[] conns = {pe_intern_conn, gain_hidden_conn, 
            intern_gainproj_conn, hidden_self_conn,
            inp_pe_conn, hidden_pe_conn, pe_magnitude_conn,
            gain_ach_conn, avoid_decval_conn, appr_decval_conn,
            pos_avoid_conn, pos_approach_conn,
            avoid_spatix_conn, approach_spatix_conn,
            rew_dopa_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(effort_mod);
        netw.add_module(dec_mod);
        netw.add_module(val_mod);
        
    }

    void setInput(float[] inp) { ctx_inputval = inp; }

    void tick() {


        if(netw.accept_input()) {
            float[] inp = ctx_inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input ctx", inpvals.copy());
            inputs.put("Input pos", arrayToList(pos_inputval));
            inputs.put("Input rew", arrayToList(rew_inputval));
            //inpvals = arrayToList(multiply(forcegain, ones(gainsize)));
            //inputs.put("Gain", inpvals.copy());
            //inpvals = arrayToList(multiply(forceintern, ones(ctx_inp_sz)));
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

        float[][] inp_viz = zeros(1,ctx_inp_sz);
        inp_viz[0] = ctx_input_layer.getOutput();
        //printArray("input layer output", inp_viz[0]);
        
        float[][] h_viz = zeros(1, hiddensize);
        h_viz[0] = hidden_layer.getOutput();

        
        translate(10,50);
        pushMatrix();
            //rotate(-HALF_PI);
            //pushMatrix();
            //text(ctx_input_layer.name, 0, 0);
            //pushMatrix();
            //translate(100, -10);
            //drawColGrid(0,0, 10, multiply(200, inp_viz));
            //popMatrix();
            //popMatrix();
            drawLayer(ctx_input_layer);
            drawLayer(pos_input_layer);
            drawLayer(rew_input_layer);

            drawLayer(predictionerror_layer);
            drawLayer(interneuron_layer);
            drawLayer(hidden_layer);
            effort_mod.draw();
            translate(0, 100);
            val_mod.draw();
            translate(0, 320);
            dec_mod.draw();

            
            
        popMatrix();

        popMatrix();

    }

    void handleKeyDown(char k){
        float[] ctx = zeros(ctx_inp_sz);
        if (k=='z')
            ctx[0] = 1.f;
        else if(k=='x')
            ctx[1] = 1.f;
        else if(k=='c')
            ctx[2] = 1.f;

        this.setInput(ctx);

    }

    void handleKeyUp(char k){
        this.setInput(zeros(ctx_inp_sz));
    }

    void handleMidi(int note, int vel){
        //println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            ctx_inputval[0] = scale * vel; 
        if(note==82)
            ctx_inputval[1] = scale * vel; 
        if(note==83)
            ctx_inputval[2] = scale * vel; 
        if(note==1)
            forcegain = scale * vel;
        if(note==2)
            forceintern = scale * vel;
        if(note==65) // first button by knobs
            pos_inputval[0] = scale * vel;
        if(note==66) // second button by knobs
            pos_inputval[1] = scale * vel;
        if(note==67) // third button by knobs
            rew_inputval[0] = scale * vel;
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
