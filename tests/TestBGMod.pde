class TestBGMod {
    String modelname = "Test template";
    String description = "Fader 1,2: input";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec bias_spec;
    
    // layer
    Layer inputd1_layer; 
    Layer inputd2_layer; 
    Layer stop_layer; // to stn, stops all beh.
    Layer hidden_layer; 
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec oto_spec;
    ConnectionSpec oto_inh_spec;
    LayerConnection inputd1_bg_conn; // input to context
    LayerConnection inputd2_bg_conn;
    LayerConnection bg_hidden_conn;
    LayerConnection stop_stn_conn;

    // modules
    BasalGangliaModule bg = new BasalGangliaModule("BasalGanglia", inputvecsize);
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] d1val = zeros(inputvecsize);
    float[] d2val = zeros(inputvecsize);
    float[] stopval = zeros(1);

    TestBGMod () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        bias_spec = new UnitSpec(excite_unit_spec);
        bias_spec.bias = 0.2;

        // connection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.0;

        oto_spec = new ConnectionSpec(ffexcite_spec);
        oto_spec.proj = "1to1";

        oto_inh_spec = new ConnectionSpec(ffexcite_spec);
        oto_inh_spec.proj = "1to1";
        oto_inh_spec.type = GABA;

        // layers
        inputd1_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Inputd1");
        inputd2_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Inputd2");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), bias_spec, HIDDEN, "Hidden");
        stop_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "Stop");
        
        // connections
        inputd1_bg_conn = new LayerConnection(inputd1_layer, bg.layer("striatal_d1"), oto_spec);
        inputd2_bg_conn = new LayerConnection(inputd2_layer, bg.layer("striatal_d2"), oto_spec);
        bg_hidden_conn = new LayerConnection(bg.layer("gpi"), hidden_layer, oto_inh_spec);
        stop_stn_conn = new LayerConnection(stop_layer, bg.layer("stn"), ffexcite_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {inputd1_layer, hidden_layer, inputd2_layer, stop_layer};
        Connection[] conns = {inputd1_bg_conn, bg_hidden_conn, inputd2_bg_conn, stop_stn_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(bg);
        netw.build();
    }

    void setInput(float[] inp) { d1val = inp; }

    void tick() {
        if(netw.accept_input()) {
            float[] inp = d1val;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Inputd1", inpvals);
            inputs.put("Inputd2", arrayToList(d2val));
            inputs.put("Stop", arrayToList(stopval));
            netw.set_inputs(inputs);
        }
        netw.cycle();

    }

    void draw() {
        pushMatrix();
        
        pushMatrix();
        translate(10,20);
        text(modelname, 0, 0);
        translate(0,20);
        text(description, 0, 0);
        popMatrix();

        float[][] inp_viz = zeros(1,inputvecsize);
        inp_viz[0] = inputd1_layer.getOutput();
        //printArray("input layer output", inp_viz[0]);
        
        translate(10,70);
        pushMatrix();
            //rotate(-HALF_PI);
            pushMatrix();
            text(inputd1_layer.name, 0, 0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, inp_viz));
            popMatrix();
            popMatrix();
            drawLayer(inputd2_layer);
            drawLayer(stop_layer);

            translate(0,20);
            bg.draw();
            translate(0, 220);
            drawLayer(hidden_layer);

            
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
            d1val[0] = scale * vel; 
        if(note==82)
            d1val[1] = scale * vel; 
        if(note==83)
            d1val[2] = scale * vel; 
        if(note==84)
            d2val[0] = scale * vel; 
        if(note==1)
            stopval[0] = scale * vel;
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

    void drawTimeSeriesPlot(float[][] data, String legend){
        translate(0, 100);
        pushMatrix();
        text(legend, 0,0);
        pushMatrix();
        translate(100, -10);
        drawTimeSeries(data, 0., 1., 1., 0., null);
        popMatrix();
        popMatrix();
    }

}
