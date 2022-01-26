class TestModLeakage {
    String modelname = "Test template";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    int dopasize = 1;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec mod_unit_spec;
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    Layer dopa_layer;
    
    // connections
    ConnectionSpec dopa_spec  = new ConnectionSpec();
    ConnectionSpec oto_spec;
    LayerConnection IH_conn; // input to context
    LayerConnection hidden_auto_conn; // self sustaining
    LayerConnection dopa_hidden_conn; // for reset
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);
    float[] dopaval = zeros(dopasize);

    TestModLeakage () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.4;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        mod_unit_spec = new UnitSpec(excite_unit_spec);
        mod_unit_spec.use_modulators = true; // enable modulator support
        mod_unit_spec.g_bar_l = 1.0; // max leak
        mod_unit_spec.g_l = 0.15; // default leak
        mod_unit_spec.d1_thr = 0.1;
        mod_unit_spec.d2_thr = 0.15;
        mod_unit_spec.receptors.append("D2");
        mod_unit_spec.receptors.append("D1");
        mod_unit_spec.receptors.append("A2");

        // connection spec
        dopa_spec.proj="full";
        dopa_spec.rnd_type="uniform" ;
        dopa_spec.rnd_mean=0.750;
        dopa_spec.rnd_var=0.0;
        dopa_spec.type = DOPAMINE;

        oto_spec = new ConnectionSpec(dopa_spec);
        oto_spec.rnd_mean=0.35;
        oto_spec.proj = "1to1";
        oto_spec.type = GLUTAMATE;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(true), mod_unit_spec, HIDDEN, "Hidden");
        dopa_layer = new Layer(dopasize, new LayerSpec(false), excite_unit_spec, INPUT, "Dopa");
        
        // connections
        IH_conn = new LayerConnection(input_layer, hidden_layer, oto_spec);
        hidden_auto_conn = new LayerConnection(hidden_layer, hidden_layer, oto_spec);
        dopa_hidden_conn = new LayerConnection(dopa_layer, hidden_layer, dopa_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer,dopa_layer};
        Connection[] conns = {IH_conn, hidden_auto_conn, dopa_hidden_conn};


        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals);
            inputs.put("Dopa", arrayToList(dopaval));
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

            drawLayer(hidden_layer);
            drawLayer(dopa_layer);
            drawTimeSeriesPlot(hidden_layer.getBufferVals(), "hidden");

            
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
        // println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            inputval[0] = scale * vel; 
        if(note==82)
            inputval[1] = scale * vel; 
        if(note==1)
            dopaval[0] = scale * vel;
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
