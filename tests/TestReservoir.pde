class TestReservoir {
    String modelname = "Test Reservoir";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec dopa_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    Layer fromres_layer;
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec dopa_spec;
    LayerConnection IH_conn; // input to context
    ReservoirConnection hidden_res_conn;
    ReservoirConnection res_fromres_conn;
    LayerConnection inp_fromres_conn;

    // reservoir
    Reservoir reservoir;
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    TestReservoir () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        dopa_unit_spec.receptors.append("D2");
        dopa_unit_spec.receptors.append("D1");
        dopa_unit_spec.use_modulators = true;

        // connection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.4;
        ffexcite_spec.rnd_var=0.2;

        dopa_spec = new ConnectionSpec(ffexcite_spec);
        dopa_spec.proj = "1to1";
        dopa_spec.type = DOPAMINE;



        // reservoir
        //reservoir = new Reservoir(hiddensize, new ReservoirSpec(), new LeakyIntegratorSpec(), DOPAMINE, "Reservoir");
        reservoir = new Reservoir(hiddensize, "Reservoir");
        
        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Hidden");
        fromres_layer = new Layer(hiddensize, new LayerSpec(false), dopa_unit_spec, HIDDEN, "From resorvoir");
        
        // connections
        IH_conn = new LayerConnection(input_layer, hidden_layer, ffexcite_spec);
        hidden_res_conn = new ReservoirConnection(hidden_layer, reservoir, dopa_spec);
        res_fromres_conn = new ReservoirConnection(reservoir, fromres_layer, dopa_spec);
        inp_fromres_conn = new LayerConnection(input_layer, fromres_layer, ffexcite_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer, fromres_layer};
        Connection[] conns = {IH_conn, hidden_res_conn, res_fromres_conn, inp_fromres_conn};
        ConnectableComposite[] comps = {reservoir};


        netw = new Network(network_spec, layers, conns, comps);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals);
            netw.set_inputs(inputs);
        }
        // reservoir.setInput(hidden_layer.getOutput());
        // reservoir.cycle("");
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

            drawLayer(hidden_layer);
            drawBarChart(reservoir.output(), reservoir.name());
            drawLayer(fromres_layer);
            drawTimeSeriesPlot(fromres_layer.getBufferVals(), fromres_layer.name());
            //translate(0, 20);
            //pushMatrix();
            //translate(10, 50);
            //barchart_array(multiply(0.10, reservoir.getOutput()), reservoir.name);
            //popMatrix();

            

            
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
