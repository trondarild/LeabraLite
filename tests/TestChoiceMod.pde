class TestChoiceMod {
    String modelname = "Test template";

    int inputvecsize = 2; // ctx:3 reward:1 pos:2 color:4 number:10
    int valsize = 1;
    int hiddensize = 2; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();

    // modules
    ChoiceModule choice = new ChoiceModule();
    
    // layer
    Layer input_layer; 
    Layer val_layer;
    Layer hidden_layer; 
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection spat_choice_conn; // input to context
    LayerConnection val_choice_conn;
    LayerConnection choice_hidden_conn;
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);
    float[] valueval = zeros(valsize);

    float dopa_gbarl = 2;
    float dopa_gl = 0.2;
    float d2_thr = 0.1;
    float d2_w = 1.0;

    TestChoiceMod () {
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
        ffexcite_spec.proj="1to1";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.5;
        ffexcite_spec.rnd_var=0.20;

        // modules

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        val_layer = new Layer(valsize, new LayerSpec(false), excite_unit_spec, INPUT, "Value");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Hidden");
        
        // connections
        spat_choice_conn = new LayerConnection(input_layer, choice.layer("spatial_ix"), ffexcite_spec);
        val_choice_conn = new LayerConnection(val_layer, choice.layer("value"), ffexcite_spec);
        choice_hidden_conn = new LayerConnection(choice.layer("choice"), hidden_layer, ffexcite_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer, val_layer};
        Connection[] conns = {spat_choice_conn, val_choice_conn, choice_hidden_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(choice);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        choice.acc.dopa_unit_spec.g_bar_l = 2*dopa_gbarl;
        choice.acc.dopa_unit_spec.g_l = dopa_gl;
        choice.acc.dopa_unit_spec.d2_thr = d2_thr;
        choice.dopa_spec.rnd_mean = 4 * d2_w;
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
            choice.draw();
            translate(0, 300);
            drawLayer(hidden_layer);

            float[] bch = {dopa_gbarl, dopa_gl, d2_thr};
            drawBarChart(bch, "gbarl gl d2thr");
            Unit a = (Unit)(choice.acc.layer("accumulator").units()[0]);
            Unit b = (Unit)(choice.acc.layer("accumulator").units()[1]);
            float[] d2r = {a.r_d2, b.r_d2};
                
            drawBarChart(d2r, "r_d2");

            
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

        if(note==1)
            dopa_gbarl = scale * vel; 
        if(note==2)
            dopa_gl = scale * vel;
        if(note==3)
            d2_thr = scale * vel; 
        if(note==4)
            d2_w = scale * vel; 
        
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
