class TestSimpleAssociation {
    String modelname = "Simple associator, ";
    
    int numpatterns = 2;
    int patternsize = 5;
    int hots = 1;
    int ctr = 0;
    float[][] sourcepatterns;
    float[][] targetpatterns;
    int inputvecsize = patternsize;
    int outputvecsize = patternsize;
    int hiddensize = 2 * patternsize; //patternsize*patternsize;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    LayerSpec output_spec = new LayerSpec();
    Layer input_layer;
    Layer hidden_layer;
    Layer inh_hidden_layer;
    Layer output_layer;

    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec ffexcite_spec_learn  = new ConnectionSpec();
    LayerConnection input_hidden_conn;
    LayerConnection hidden_output_conn;
    LayerConnection input_output_conn;
    LayerConnection output_hidden_conn;
    

    // network
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    Map <String, FloatList> targets = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);
    Buffer sse = new Buffer(100);
    Buffer trial_sse = new Buffer(numpatterns);
    float current_sse = 0;
    
    TestSimpleAssociation() {
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
        

        ffexcite_spec_learn.proj="full";
        ffexcite_spec_learn.rnd_type="uniform" ;
        ffexcite_spec_learn.rnd_mean=0.5;
        ffexcite_spec_learn.rnd_var=0.20;
        ffexcite_spec_learn.lrate = 0.04;
        ffexcite_spec_learn.lrule = "leabra";




        // layers
        output_spec.g_i=1.5;
        output_spec.ff=1.0;
        output_spec.fb=0.5;
        output_spec.fb_dt=1/1.4;
        output_spec.ff0=0.1;
        

        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Hidden");
        output_layer = new Layer(outputvecsize, output_spec, excite_unit_spec, OUTPUT, "Output");

        // connections
        input_hidden_conn = new LayerConnection(input_layer, hidden_layer, ffexcite_spec);
        hidden_output_conn = new LayerConnection(hidden_layer, output_layer, ffexcite_spec_learn);
        output_hidden_conn = new LayerConnection(output_layer, hidden_layer, ffexcite_spec_learn);
        input_output_conn = new LayerConnection(input_layer, output_layer, ffexcite_spec_learn);
        
        // network
        
        Layer[] layers = {input_layer, /*hidden_layer,  inh_hidden_layer, */ 
            output_layer};
        Connection[] conns = { input_output_conn/*input_hidden_conn, hidden_output_conn, 
             output_hidden_conn, hidden_hidden_conn,  input_inhhidden_conn, 
            inhhidden_output_conn*/};


        netw = new Network(network_spec, layers, conns);
        netw.build();

        // create input outputs
        sourcepatterns = generateUniquePatterns(numpatterns, inputvecsize, hots);
        targetpatterns = generateUniquePatterns(numpatterns, outputvecsize, hots);
        
    }

    void tick() {
        
        if(netw.accept_input()){
            int ptrn_ix = ctr++ % numpatterns ;
            FloatList inpvals = arrayToList(sourcepatterns[ptrn_ix]);
            inputs.put("Input", inpvals);
            netw.set_inputs(inputs);

            FloatList targetvals = arrayToList(targetpatterns[ptrn_ix]);
            targets.put("Output", targetvals);
            netw.set_targets(targets);
            current_sse = netw.compute_sse();
            trial_sse.append(current_sse);
            if (ptrn_ix==0){
                sse.append(mean(trial_sse.array()));
                // printMatrix("hidden weights", hidden_output_conn.weights());
            }
        }
        current_sse = netw.trial();
        // sse.append(current_sse / sourcepatterns.length);
        // netw.cycle();
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
        
        //float[][] h_viz = zeros(1, hiddensize);
        //h_viz[0] = hidden_layer.getOutput();

        
        float[][] out_viz = zeros(1,inputvecsize);
        out_viz[0] = output_layer.getOutput();

        float[][] w_viz = input_output_conn.weights();
        //float[][] w_viz = hidden_output_conn.weights();
        // w_viz[0] = hidden_layer.weights();

        
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

            // translate(0, 20);
            // pushMatrix();
            // text(hidden_layer.name, 0,0);
            // pushMatrix();
            // translate(100, -10);
            // drawColGrid(0,0, 10, multiply(200, h_viz));
            // popMatrix();
            // popMatrix();

            
            translate(0, 20);
            pushMatrix();
            text(output_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, out_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text("Weights", 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, w_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text("SSE: " + current_sse, 0,0);
            pushMatrix();
            translate(100, -10);
            //drawColGrid(0,0, 10, multiply(200, dacc_viz));
            drawTimeSeries(sse.array(), 6.0, 1, 0);
            popMatrix();
            popMatrix();
        popMatrix();

        popMatrix();
    }

    void handleKeyDown(char k){}
    void handleKeyUp(char k){}
    void handleMidi(float a, float b ){}

   
}
