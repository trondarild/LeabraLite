class TestFbModeShift {
    String modelname = "Test fb mode shift";
    String description = "";

    int inputvecsize = 1; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
 
    // modules
    ModeModule mode_mod;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; // fb valence
    Layer modeinp_layer;
    Layer prederror_layer; //


    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection IH_conn; // input to context
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);
    float[] modeval = zeros(hiddensize);

    TestFbModeShift () {
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
        ffexcite_spec.rnd_var=0.10;

        ConnectionSpec oto_inh_spec = new ConnectionSpec();
        oto_inh_spec.proj = "1to1";
        oto_inh_spec.rnd_var = 0.;
        oto_inh_spec.type = GABA;

        ConnectionSpec oto_spec = new ConnectionSpec(oto_inh_spec);
        oto_spec.type = GLUTAMATE;


        // modules
        mode_mod = new ModeModule(hiddensize, "Rule ctx");

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        modeinp_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, INPUT, "Modeinp");
        prederror_layer = new Layer(hiddensize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Hidden");
        
        // connections
        IH_conn = new LayerConnection(input_layer, prederror_layer, ffexcite_spec);
        LayerConnection mode_prederror_conn = new LayerConnection(mode_mod.layer("mode"), prederror_layer, oto_inh_spec);
        LayerConnection inp_mode_conn = new LayerConnection(modeinp_layer, mode_mod.layer("mode"), oto_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, prederror_layer, modeinp_layer};
        Connection[] conns = {IH_conn, mode_prederror_conn, inp_mode_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(mode_mod);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals);
            inputs.put("Modeinp", arrayToList(modeval));
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
            translate(0,20);
            drawLayer(modeinp_layer);

            translate(0,20);
            mode_mod.draw();

            translate(0, 120);
            drawLayer(prederror_layer);

            
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
        println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            inputval[0] = scale * vel; 
        if(note >= 65 && note <= 65 + hiddensize)
            modeval[note-65] = scale*vel;
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