class TestValueAccumulator {
    String modelname = "Test template";

    int inputvecsize = 2; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 1; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; 
    Layer value_layer; 
    Layer choice_layer;
    ValueAccumulator acc;
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection IH_conn; // input to context
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    float value[] = new float[inputvecsize];
    Buffer rtbuffer = new Buffer(100);

    TestValueAccumulator () {
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

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        value_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, INPUT, "Value");
        choice_layer = new Layer(inputvecsize, new LayerSpec(true), excite_unit_spec, INPUT, "Choice");
        acc = new ValueAccumulator(inputvecsize);
        
        // connections
        //IH_conn = new LayerConnection(input_layer, value_layer, ffexcite_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, value_layer, choice_layer};
        Connection[] conns = {};


        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        // update accumulator
        acc.setSpatialIx(input_layer.getOutput());
        acc.setInput(value_layer.getOutput());
        acc.cycle();
        rtbuffer.append(acc.getRtMean()[0]);
        
        if(netw.accept_input()) {
            float[] inp = inputval;
            
            inputs.put("Input", arrayToList(inp));
            
            inputs.put("Value", arrayToList(multiply(value[argmax(inp)], ones(1))));
            
            inputs.put("Choice", arrayToList(acc.getOutput()));
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
            
            drawBarChart(input_layer.getOutput(), "Input");
            drawBarChart(value, "Value");
            drawBarChart(acc.getState(), "Acc state");
            //drawBarChart(acc.getChoice(), "Acc choice");
            drawBarChart(acc.getOutput(), "Acc output");
            drawBarChart(acc.getChoiceProbability(), "Acc choice prob");
            drawBarChart(acc.getRtMean(), "Reaction time mean");
            drawBarChart(choice_layer.getOutput(), "Choice");
            float[][] rt = {rtbuffer.array()};
            drawTimeSeriesPlot(multiply(1, rt), "reaction time mean");

            
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
        if(note==1)
            value[0] = scale * vel;
        if(note==2)
            value[1] = scale * vel;
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