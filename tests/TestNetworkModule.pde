class TestNetworkModule {
    String modelname = "Test networkmodule";

    int inputvecsize = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
 

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection IH_conn; // input to context
    LayerConnection hidden_magn_conn; // hidden to effort-value
    
    NetworkModule effortmod;
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    TestNetworkModule () {
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
        ffexcite_spec.rnd_mean=0.2;
        ffexcite_spec.rnd_var=0.20;

        // modules
        effortmod = new EffortModule(5, "Effort");

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Hidden");
        
        // connections
        IH_conn = new LayerConnection(input_layer, hidden_layer, ffexcite_spec);
        hidden_magn_conn = new LayerConnection(hidden_layer, effortmod.layer(EffortModule.MAGNITUDE), ffexcite_spec);


        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer};
        Connection[] conns = {IH_conn, hidden_magn_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(effortmod);
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
            translate(0,20);
            effortmod.draw();

            
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

class EffortModule implements NetworkModule {
    static final int MAGNITUDE = 0;
    static final int GAIN = 1;
    
    String name = "EffortModule";
    int gainsize = 2;
    int magnitudesize = 1;

    Layer[] layers = new Layer[3];
    Connection[] connections = new Connection[1];

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer pe_magnitude_layer; // used for translation to pop code to engage effort
    Layer pop_layer;
    Layer gain_layer; // excites hidden layer

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    LayerConnection pop_gain_conn; // population to gain
    

    EffortModule() {
        this.init();
    }

    EffortModule(int gainsize, String name) {
        this.gainsize = gainsize;
        this.name = name;
        this.init();
    }

    void init() {
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
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;

        float[][] w_effort = generateEffortWeights(gainsize);

        pe_magnitude_layer = new Layer(magnitudesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Magnitude (in)");
        pop_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Population");
        gain_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Gain (out)");
        int layerix = 0;
        layers[layerix++] = pe_magnitude_layer;
        layers[layerix++] = pop_layer;
        layers[layerix++] = gain_layer;


        pop_gain_conn = new LayerConnection(pop_layer, gain_layer, full_spec);
        pop_gain_conn.weights(w_effort);
        connections[0] = pop_gain_conn;
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(int l) {
        switch(l) {
            case MAGNITUDE:
                return pe_magnitude_layer; // input
            case GAIN:
            default:
                return gain_layer; // output
        }
    }

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 220, 100, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawLayer(pe_magnitude_layer);
        drawLayer(pop_layer);
        drawLayer(gain_layer);
        popMatrix();
    }

    void cycle() {
        float[] pop_act = zeros(gainsize);
        pop_act = populationEncode(
                pe_magnitude_layer.units[0].getOutput(), //forcegain,
                gainsize,
                0, 1,
                0.25
            );    
        pop_layer.force_activity(pop_act);
    }

    float[][] generateEffortWeights(int sz) {
        float[][] retval = zeros(sz, sz);
        for (int j = 0; j < sz; ++j) {
            for (int i = 0; i < sz; ++i) {
                retval[j][i] = i <= j ? 1 : 0;    
            }    
        }
        return retval;
    }

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
