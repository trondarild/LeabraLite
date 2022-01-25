class TestForceActivity{
    String modelname = "Test force activity";

    int inputvecsize = 24; // ctx:3 reward:1 pos:2 color:4 number:10
    int behaviours = 2; // TODO update when calc number of discrete behaviours, including gating ones
    
    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    

    // layer
    Layer input_layer;
    Layer striatum_d1_layer; // go - contains input, (learned, manually set) temporal combination patterns
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();

    LayerConnection ID1_conn; // input to striatum D1 - go
    
    float[][] ID1_weights = zeros(inputvecsize, behaviours); // weights to trigger a particular D1 unit based on input
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map<String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;
    
    float[][] testinputs = {
        
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}, // even: no
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 1, 0, 0, 0, 0, 0, 0, 0, 0,  0}, // even: yes
        
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0, 0, 0, 0, 0, 0, 0,  0}, // 
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 1, 0, 0, 0, 0, 0, 0,  0}, //
        
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 1, 0, 0, 0, 0, 0,  0}, // 
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 1, 0, 0, 0, 0,  0}, //
        
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 1, 0, 0, 0,  0}, // 
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 1, 0, 0,  0}, //
        
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 1, 0,  0},
        {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 1,  0}
    };


    TestForceActivity(){
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
        ffexcite_spec.rnd_mean=0.75;
        ffexcite_spec.rnd_var=0.0;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        striatum_d1_layer = new Layer(behaviours, new LayerSpec(false), excite_unit_spec, HIDDEN, "StriatumD1");
        
        // connections
        ID1_conn = new LayerConnection(input_layer,  striatum_d1_layer, ffexcite_spec);
        
        this.setWeights(); // test setting weights which are sums of valid input combinations

        Layer[] layers =  {input_layer, striatum_d1_layer};
        Connection[] conns = {ID1_conn};

        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void tick(){
        //FloatList inpvals = new FloatList();
        //inpvals.set(inputvecsize - 1, 0.0); // set dim of list
        //inpvals.set((int)random(0, inputvecsize), 0.5 * sig.getOutput());
        
        //if(cyc % (quart_num * netw.trial_length) == 0){
        if(netw.accept_input()){
            println();
            //printArray("input", testinputs[inp_ix % testinputs.length]);
            FloatList inpvals = arrayToList(testinputs[inp_ix++ % testinputs.length]);
            //println("floatlist: " + inpvals.toString());
            inputs.put("Input", inpvals);
            netw.set_inputs(inputs);
        }
        netw.cycle();
    }

    void draw(){
        pushMatrix();
        
        pushMatrix();
        translate(10,20);
        text(modelname, 0, 0);
        popMatrix();

        float[][] inp_viz = zeros(1,inputvecsize);
        inp_viz[0] = input_layer.getOutput();
        //printArray("input layer output", inp_viz[0]);
        
        float[][] d1_viz = zeros(1,inputvecsize);
        d1_viz[0] = striatum_d1_layer.getOutput();
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
            text(striatum_d1_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, d1_viz));
            popMatrix();
            popMatrix();
        popMatrix();

        popMatrix();
    }

    void setWeights(){
        // ctx: 010 pos: 10 shp:1000 color:1000 num:1000000000 
        float[][] tstweights_d1 = {
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 1, 0, 1, 0, 1, 0, 1, 0,  0}, // odd, press left
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 1, 0, 1, 0, 1, 0, 1,  0} // even, press right

            //{0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 1, 0, 1, 0, 1, 0, 1,  0}, // even, press right
            //{0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0} // odd, press left
            
        };
        ID1_conn.weights(transpose(multiply(0.71, tstweights_d1)));
    }
}