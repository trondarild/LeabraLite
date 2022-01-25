//
// test dendrite connection

class TestDendriteConnection{
    String modelname = "Task net test";
    int inputvecsize = 24; // ctx:3 reward:1 pos:2 color:4 number:10
    int behaviours = 4; // TODO update when calc number of discrete behaviours, including gating ones
    int contexts = 10;
    int inp_ix = 0;
    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();

    // layer
    
    Layer input_layer;
    Layer pfc_layer; // origin of dendrite connection
    Layer striatum_d1_layer; // go - contains input, (learned, manually set) temporal combination patterns

    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec inh_spec_0  = new ConnectionSpec();
    ConnectionSpec inh_spec_1;
    LayerConnection ID1_conn; // input to striatum D1 - go
    DendriteConnection dendrite_conn_0; // pfc to inp-D1 dendrite, setting weights
    DendriteConnection dendrite_conn_1; // pfc to inp-D1 dendrite, setting weights

    // network
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map<String, FloatList> inputs = new HashMap<String, FloatList>();
    float[] inputval = zeros(inputvecsize);
    float[] pfcval = zeros(contexts);
    float inputmod = 1.0;

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

    int[] a = genIndeces(0, 3);
    int[] b = genIndeces(4,7);
    float[] grp_a = genMask(contexts, a);
    float[] grp_b = genMask(contexts, b);

    TestDendriteConnection(){
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
        ffexcite_spec.rnd_mean=0.1;
        ffexcite_spec.rnd_var=0.0;

        inh_spec_0.proj="full";
        inh_spec_0.rnd_type="uniform" ;
        inh_spec_0.rnd_mean=0.99;
        inh_spec_0.rnd_var=0.0;
        inh_spec_0.inhibit = true;
        inh_spec_0.pre_indeces = genIndeces(0, 0);
        int[] postix = {0, 4, 8, 12, 16, 20};
        inh_spec_0.post_indeces = postix;
        //inh_spec_0.pre_startix = 0;
        //inh_spec_0.pre_endix = 3;
        //inh_spec_0.post_startix = 0;
        //inh_spec_0.post_endix = 3;

        inh_spec_1 = new ConnectionSpec(inh_spec_0);
        inh_spec_1.pre_startix = 4;
        inh_spec_1.pre_endix = 7;
        inh_spec_1.post_startix = 4;
        inh_spec_1.post_endix = 7;




        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        striatum_d1_layer = new Layer(behaviours, new LayerSpec(false), excite_unit_spec, HIDDEN, "StriatumD1");
        pfc_layer = new Layer(contexts, new LayerSpec(true), excite_unit_spec, HIDDEN, "Pfc");

        // connections
        ID1_conn = new LayerConnection(input_layer, striatum_d1_layer, ffexcite_spec);
        
        dendrite_conn_0 = new DendriteConnection(pfc_layer, ID1_conn, inh_spec_0);
        dendrite_conn_1 = new DendriteConnection(pfc_layer, ID1_conn, inh_spec_1);

        Layer[] layers = {input_layer, striatum_d1_layer, pfc_layer};
        Connection[] conns = {ID1_conn, dendrite_conn_0, dendrite_conn_1};

        netw = new Network(network_spec, layers, conns);
        netw.build();
    }
    void setInput(float[] inp) { inputval = inp; }

    void tick(){
        if(netw.accept_input()){
            println();
            //printArray("input", testinputs[inp_ix % testinputs.length]);
            FloatList inpvals = arrayToList(multiply(inputmod, testinputs[inp_ix++ % testinputs.length]));
            FloatList pfcvals = arrayToList(pfcval);
            //println("floatlist: " + inpvals.toString());
            inputs.put("Input", inpvals);
            inputs.put("Pfc", pfcvals);
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

            drawLayer(striatum_d1_layer);
            drawLayer(pfc_layer);
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
        float[] a = zeros(contexts);
        float[] b = zeros(contexts);
        if(note==1)
            inputmod = scale * vel;
        if(note==81)
            a = multiply(scale * vel, grp_a); 
        if(note==82)
            b = multiply(scale * vel, grp_b);
        pfcval = addArray(a, b); 
        //printArray(pfcval);
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
