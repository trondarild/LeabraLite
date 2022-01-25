/**
    2022-01-13: using dACC populations for each context appears both
                inelegant, and not plausible -> requires always increasing
                amount of units; have to use dendrite-connections instead, so 
                can control flow of effort from single population to req. target 
*/
class TestCtxChangeWithRecruitment {
    String modelname = "Test context prediction error with recruitment";
    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    int populationsize = 5; // number of effort-units in dACC
    int magnitudesize = 1;
    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec excite_auto_unit_spec = new UnitSpec();
    

    // layer
    Layer input_layer; 
    Layer context_layer; // go - contains input, learned, /manually set/ temporal combination patterns
    Layer predictionerror_layer; //
    Layer pe_magnitude_layer; // used to excite population coded layer
    Layer population_layer; // regulates number of units to engage in acc 
    Layer acc_layer; // effort layer; anterior cingulate/anterior insula
    Layer interneuron_layer; // gates effort to correct place
    
    // connections
    ConnectionSpec full_spec  = new ConnectionSpec();
    ConnectionSpec full_weak_spec = new ConnectionSpec();
    ConnectionSpec onetoone_excite_spec = new ConnectionSpec();
    ConnectionSpec onetoone_excite_weak_spec = new ConnectionSpec();
    ConnectionSpec onetoone_inh_spec = new ConnectionSpec();
    ConnectionSpec pop_dacc_spec = new ConnectionSpec();

    //LayerConnection inp_ctx_conn; // input to context
    LayerConnection inp_pe_conn; // input to CtxPredError
    LayerConnection ctx_pe_conn; // context to prediction error
    LayerConnection pe_magnitude_conn; // pred error to magnitude
    //LayerConnection magn_pop_conn; // prediction error magnitude to population
    LayerConnection pop_acc_conn; // population to dACC 
    LayerConnection ctx_ctx_conn; // context self-sustaining
    LayerConnection acc_ctx_conn; // effort
    DendriteConnection effort_gating_conn; // interneuron gating
    LayerConnection pe_intern_conn; // pe control gating

    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);


    float[][] w_effort = {  {1,0,0,0,0},
                            {1,1,0,0,0},
                            {1,1,1,0,0},
                            {1,1,1,1,0},
                            {1,1,1,1,1} };
    float[][] w_interneuron = tileCols(populationsize, id(inputvecsize)); // for dendrite inh of effort
    //float[][] w_effort = tileRows(hiddensize, w_effort_ptrn);

    TestCtxChangeWithRecruitment() {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=false;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        excite_auto_unit_spec.adapt_on = false;
        excite_auto_unit_spec.noisy_act=false;
        excite_auto_unit_spec.act_thr=0.5;
        excite_auto_unit_spec.act_gain=100;
        excite_auto_unit_spec.tau_net=40;
        excite_auto_unit_spec.g_bar_e=1.0;
        excite_auto_unit_spec.g_bar_l=0.1;
        excite_auto_unit_spec.g_bar_i=0.40;
        excite_auto_unit_spec.bias = 0.05; // 0.0075; // bias incr from 0
        excite_auto_unit_spec.g_l = 0.9; // leak reduced from 1.0
        excite_auto_unit_spec.e_rev_l = 0.3;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        context_layer = new Layer(hiddensize, new LayerSpec(true), excite_auto_unit_spec, HIDDEN, "Context");
        predictionerror_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Pred error");
        pe_magnitude_layer = new Layer(magnitudesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Magnitude");
        population_layer = new Layer(populationsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Population");
        acc_layer = new Layer(populationsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "dACC");
        interneuron_layer = new Layer(hiddensize, new LayerSpec(false), excite_auto_unit_spec, HIDDEN, "Interneuron");
       
        // LayerConnection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;

        full_weak_spec.proj="full";
        full_weak_spec.rnd_type="uniform" ;
        full_weak_spec.rnd_mean=0.1;
        full_weak_spec.rnd_var=0.0;

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

        
        // connections
        //inp_ctx_conn = new LayerConnection(input_layer, context_layer, onetoone_excite_weak_spec);
        inp_pe_conn = new LayerConnection(input_layer, predictionerror_layer, onetoone_excite_spec);
        ctx_pe_conn = new LayerConnection(context_layer, predictionerror_layer, onetoone_inh_spec);
        pe_magnitude_conn = new LayerConnection(predictionerror_layer, pe_magnitude_layer, full_spec);
        //magn_pop_conn = new LayerConnection(pe_magnitude_layer, population_layer); // prediction error to population - handle separately for now
        pop_acc_conn = new LayerConnection(population_layer, acc_layer, full_spec);
        pop_acc_conn.weights(w_effort);
        ctx_ctx_conn = new LayerConnection(context_layer, context_layer, onetoone_excite_spec);
        acc_ctx_conn = new LayerConnection(acc_layer, context_layer, full_weak_spec); // - effort
        effort_gating_conn = new DendriteConnection(interneuron_layer, acc_ctx_conn, full_spec);
        effort_gating_conn.weights(w_interneuron); // allow inh of projections
        pe_intern_conn = new LayerConnection(predictionerror_layer, interneuron_layer, onetoone_inh_spec);
         
        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, context_layer, acc_layer, population_layer,
                            predictionerror_layer, pe_magnitude_layer, interneuron_layer};
        Connection[] conns = {/*inp_ctx_conn,*/ 
            inp_pe_conn, 
            ctx_pe_conn, 
            pe_magnitude_conn,
            pop_acc_conn, 
            /* ctx_ctx_conn, */
            acc_ctx_conn,
            effort_gating_conn,
            pe_intern_conn
            }; 
        


        netw = new Network(network_spec, layers, conns);
              
                    
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp;}

    void tick() {
        // pop code prediction error to get graded effort
        // TODO implement particular PopCodingLayer and connection
        float[] pop_act = zeros(populationsize);
        pop_act = populationEncode(
                pe_magnitude_layer.units[0].getOutput(),
                populationsize,
                0, 1,
                0.25
            );    
        population_layer.force_activity(pop_act);

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


            drawLayer(context_layer);
            drawLayer(predictionerror_layer);
            drawLayer(pe_magnitude_layer);
            drawLayer(population_layer);
            drawLayer(acc_layer);
            drawLayer(interneuron_layer);
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
        //println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            inputval[0] = scale * vel; 
        if(note==82)
            inputval[1] = scale * vel; 
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
