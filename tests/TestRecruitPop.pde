class TestRecruitPop {
    String modelname = "Test recruitment population";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    int populationsize = 5;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    Layer population_layer;
    Layer effort_layer;
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec full_spec  = new ConnectionSpec();

    LayerConnection IH_conn; // input to context
    LayerConnection PE_conn; // population to effort
    
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
                            {1,1,1,1,1},
                            };

    TestRecruitPop () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        // connection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.20;

        full_spec.proj="full";

        
        
        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Hidden");
        population_layer = new Layer(populationsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Population");
        effort_layer  = new Layer(populationsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Effort");
        // connections
        IH_conn = new LayerConnection(input_layer, hidden_layer, ffexcite_spec);
        PE_conn = new LayerConnection(population_layer, effort_layer, full_spec);
        
        PE_conn.weights(w_effort);

        printMatrix("conn0", PE_conn.weights());
        //printMatrix("conn2", PE_conn_2.weights());
        //printMatrix("conn3", PE_conn_3.weights());
        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer, population_layer, effort_layer};
        Connection[] conns = {IH_conn, PE_conn };


        netw = new Network(network_spec, layers, conns);
        netw.build();

        
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        float[] pop_act = populationEncode(
            input_layer.units[0].getOutput(),
            populationsize,
            0, 1,
            0.25
        );
        population_layer.force_activity(pop_act);
        // PE_conn.weights(w_effort);

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

        float[][] p_viz = zeros(1, populationsize);
        p_viz[0] = population_layer.getOutput();

        float[][] e_viz = zeros(1, populationsize);
        e_viz[0] = effort_layer.getOutput();
        
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
            text(population_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, p_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(effort_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, e_viz));
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

    void handleMidi(int note, int vel){
        //println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            inputval[0] = scale * vel; 
    }

}
