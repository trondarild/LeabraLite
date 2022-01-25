class TestDopa {
    String modelname = "Test dopamine";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec dopa_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    
    
    LayerConnection IH_conn; // input to context
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    float dopa =  0.0;
    float adeno = 0.0;

    TestDopa () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        dopa_unit_spec.adapt_on = false;
        dopa_unit_spec.noisy_act=true;
        dopa_unit_spec.c_act_thr=0.99; // use this instead of act_thr for dopa mod
        dopa_unit_spec.act_gain=100;
        dopa_unit_spec.tau_net=40;
        dopa_unit_spec.g_bar_e=1.0;
        dopa_unit_spec.g_bar_l=0.1;
        dopa_unit_spec.g_bar_i=0.40;
        dopa_unit_spec.use_modulators = true;

        // connection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.20;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), dopa_unit_spec, HIDDEN, "Hidden");
        
        // connections
        IH_conn = new LayerConnection(input_layer, hidden_layer, ffexcite_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer};
        Connection[] conns = {IH_conn};


        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals);
            netw.set_inputs(inputs);

            // set dopa and adeno on hidden layer
            hidden_layer.set_dopa(multiply(dopa, ones(hiddensize)));
            hidden_layer.set_adeno(multiply(adeno, ones(hiddensize)));


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

            translate(0, 20);
            pushMatrix();
            text(hidden_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, h_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            float[] da = multiply(dopa, ones(hiddensize));
            pushMatrix();
            translate(10, 50);
            barchart_array(da, "dopa");
            popMatrix();

            translate(0, 20);
            float[] ado = multiply(adeno, ones(hiddensize));
            pushMatrix();
            translate(10, 100);
            barchart_array(ado, "adeno");
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
        else if(k=='n')
            dopa = limitval(0, 1, dopa-0.1);
        else if(k=='m')
            dopa = limitval(0, 1, dopa+0.1);
        else if(k==',')
            adeno = limitval(0, 1, adeno-0.1);
        else if(k=='.')
            adeno = limitval(0, 1, adeno+0.1);

        this.setInput(ctx);

    }

    void handleKeyUp(char k){
        this.setInput(zeros(inputvecsize));
    }


}
