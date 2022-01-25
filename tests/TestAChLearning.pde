class TestAChLearning {
    String modelname = "Test ACh learning modulation";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; 
    Layer hidden_layer;
    Layer choline_layer; 
    
    // connections
    ConnectionSpec oto_spec  = new ConnectionSpec();
    ConnectionSpec choline_spec;
    LayerConnection input_hidden_conn; // input to hidden
    DendriteConnection chol_hidden_conn; // modulates learning on input-hidden conn

    ConnectableWeightSpec chol_w_spec = new ConnectableWeightSpec();
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    Map <String, FloatList> outputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);
    float cholval = 0;

    TestAChLearning () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=false;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        // connection spec
        oto_spec.proj="1to1";
        oto_spec.rnd_type="uniform" ;
        oto_spec.rnd_mean=0.05;
        oto_spec.rnd_var=0.0;
        oto_spec.lrule = "delta";
        oto_spec.lrate = .1;

        choline_spec = new ConnectionSpec(oto_spec);
        choline_spec.lrule = "";
        choline_spec.proj = "full";
        choline_spec.type = ACETYLCHOLINE;

        chol_w_spec.receptors.append("M1"); // add M1 receptor support to modulate learning rate


        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, OUTPUT, "Hidden");
        choline_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "ACh");
        // connections
        input_hidden_conn = new LayerConnection(input_layer, hidden_layer, oto_spec, chol_w_spec);
        chol_hidden_conn = new DendriteConnection(choline_layer, input_hidden_conn, choline_spec);

        // network
        network_spec.do_reset = true; // use learning on input-hidden

        Layer[] layers = {input_layer, hidden_layer, choline_layer};
        Connection[] conns = {input_hidden_conn, chol_hidden_conn};


        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            
            inputs.put("Input", inpvals);
            inputs.put("ACh", arrayToList(multiply(cholval, ones(1))));
            outputs.put("Hidden", arrayToList(input_layer.getOutput()));
            netw.set_inputs(inputs);
            netw.set_outputs(outputs);
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

            drawBarChart(choline_layer.getOutput(), "Choline");
            drawBarChart(hidden_layer.getOutput(), "Hidden");
            drawBarChart(input_hidden_conn.weights()[0], "Weights");
            drawBarChart(multiply(oto_spec.lrate, ones(1)), "OTO lrate");
            drawBarChart(multiply(oto_spec.d_rev, ones(1)), "OTO reversal pot");

            // draw 

            
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
            cholval = scale*vel;
        if(note==2)
            oto_spec.lrate = scale*vel;
        if(note==3)
            oto_spec.d_rev = scale*vel; // reversal potential contributes to changing pos or neg learning
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

    void drawBarChart(float[] data, String legend){
        translate(0, 100);
        pushMatrix();
        text(legend, 0,0);
        pushMatrix();
        translate(100, -10);
        barchart_array(data, legend);
        popMatrix();
        popMatrix();
    }

}
