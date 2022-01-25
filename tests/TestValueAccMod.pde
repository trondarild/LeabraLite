class TestValueAccMod {
    String modelname = "Test value accumulator";

    int inputvecsize = 2; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 2; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();

    // modules
    NetworkModule mod;;
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    Layer val_layer;
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec oto_spec;
    LayerConnection inp_spatix_conn; // input to context
    LayerConnection inpval_val_conn; // input to context
    LayerConnection acc_hidden_conn; // acc to hidden
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);
    float[] valueval = zeros(1);

    TestValueAccMod () {
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

        oto_spec = new ConnectionSpec(ffexcite_spec);
        oto_spec.proj = "1to1";

        mod = new ValueAccumulatorModule();

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        val_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, INPUT, "Value");
        hidden_layer = new Layer(hiddensize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Hidden");
        
        // connections
        inp_spatix_conn = new LayerConnection(input_layer, mod.layer(ValueAccumulatorModule.SPAT_IX), oto_spec);
        inpval_val_conn = new LayerConnection(val_layer, mod.layer(ValueAccumulatorModule.VALUE), ffexcite_spec);
        acc_hidden_conn = new LayerConnection(mod.layer(ValueAccumulatorModule.ACC), hidden_layer, oto_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer, val_layer};
        Connection[] conns = {inp_spatix_conn, acc_hidden_conn, inpval_val_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(mod);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals);
            inputs.put("Value", arrayToList(valueval));
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

            drawLayer(val_layer);

            translate(0, 20);
            mod.draw();
            translate(0,200);

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
            inputval[0] = scale * vel; 
        if(note==82)
            inputval[1] = scale * vel; 
        if(note==83)
            valueval[0] = scale * vel; 
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