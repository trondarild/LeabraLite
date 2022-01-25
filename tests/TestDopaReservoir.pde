class TestDopaReservoir {
    String modelname = "Test dopa adeno reservoir";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    int dopasize = 1;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec excite_auto_unit_spec;
    UnitSpec dopa_unit_spec;
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    Layer dopa_layer; // typically SNc or VTA
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection IH_conn; // input to context
    
    // reservoir
    LeakyIntegratorSpec li_dopa_spec = new LeakyIntegratorSpec();
    LeakyIntegratorSpec li_adeno_spec = new LeakyIntegratorSpec();
    Reservoir dopa_res;
    Reservoir adeno_res;

    // network
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    float w_da = 0.5;
    float w_ado = 0.5;
    float w_inp = 0.75;
    float[] dopaweights = ones(hiddensize);
    float[] adenoweights = ones(hiddensize);
    float dopa_force;

    TestDopaReservoir () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        dopa_unit_spec = new UnitSpec(excite_unit_spec);
        dopa_unit_spec.c_act_thr = 0.75;
        dopa_unit_spec.use_modulators = true;

        excite_auto_unit_spec = new UnitSpec(excite_unit_spec);
        excite_auto_unit_spec.c_act_thr = 0.5;
        excite_auto_unit_spec.bias = 0; //0.25;
        

        // connection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.20;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), dopa_unit_spec, HIDDEN, "Hidden");
        dopa_layer = new Layer(dopasize, new LayerSpec(false), excite_auto_unit_spec, HIDDEN, "Dopa");
        
        // connections
        IH_conn = new LayerConnection(input_layer, hidden_layer, ffexcite_spec);

        // integrators, reservoirs
        li_dopa_spec.type = DOPAMINE;
        li_dopa_spec.growth = 0.01;
        li_dopa_spec.accumulate = 0.01;
        li_dopa_spec.decayfactor = 0.5;

        li_dopa_spec.growth = 0.001;
        li_adeno_spec.accumulate = 0.01;
        li_adeno_spec.decayfactor = 0.001;
        li_adeno_spec.decaythreshold = 0.00001;
        li_adeno_spec.type = ADENOSINE;
        dopa_res = new Reservoir(dopasize, new ReservoirSpec(), li_dopa_spec, "Dopa reservoir");
        adeno_res = new Reservoir(hiddensize, new ReservoirSpec(), li_adeno_spec, "Adeno reservoir");

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer, dopa_layer};
        Connection[] conns = {IH_conn};


        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float[] inp) { inputval = multiply(w_inp, inp); }

    void tick() {
        // update reservoirs
        dopa_res.setInput(multiply(w_da, dopa_layer.getOutput()));
        dopa_res.cycle();
        adeno_res.setInput(multiply(w_ado, hidden_layer.getOutput()));
        adeno_res.cycle();

        hidden_layer.set_dopa(multiply(dopa_res.getOutput()[0], dopaweights));
        hidden_layer.set_adeno(mult_per_elm(adenoweights, adeno_res.getOutput()));
        dopa_layer.units[0].force_activity(dopa_force);

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
        h_viz[0] = hidden_layer.getOutput();

        float[][] da_viz = zeros(1, dopasize);
        da_viz[0] = dopa_layer.getOutput();


        
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
            text(dopa_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, da_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            translate(10, 50);
            barchart_array(multiply(1.0, hidden_layer.act_thr()), "Threshold " + hidden_layer.name);
            popMatrix();

            translate(0, 20);
            pushMatrix();
            translate(10, 100);
            barchart_array(multiply(1.0, dopa_res.getOutput()), dopa_res.name);
            popMatrix();

            translate(0, 20);
            pushMatrix();
            translate(10, 150);
            barchart_array(multiply(1.0, adeno_res.getOutput()), adeno_res.name);
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

    void handleMidi(int note, int vel){
        //println("Note "+ note + ", vel " + vel);
        float scale = 1/127.0;
        if(note==1) //pot 1
            dopa_force = scale * vel;
        if(note==81) // slider 1
            dopaweights[0] = scale * vel;
        if(note==82) // slider 1
            dopaweights[1] = scale * vel;
        if(note==83) // slider 1
            dopaweights[2] = scale * vel;
        if(note==84) // slider 1
            adenoweights[0] = scale * vel;
        if(note==85) // slider 1
            adenoweights[1] = scale * vel;
        if(note==86) // slider 1
            adenoweights[2] = scale * vel;
        if(note==87) // slider 1
            inputval[0] = scale * vel;
        if(note==88) // slider 1
            inputval[1] = scale * vel;
    }
}
