class TestEffortAchDecisionModel {
    String modelname = "Test effortful context switch with ACh and decisionmaking";

    int ctx_inp_sz = 3; // ctx:3 reward:1 pos:2 color:4 number:10
    int pos_inp_sz = 2;
    int hiddensize = 3; // TODO update when calc number of discrete behaviours, including gating ones
    int gainsize = 5;
    int magnitudesize = 1;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec auto_unit_spec; // for interneurons
    // layer
    Layer ctx_input_layer; 
    Layer pos_input_layer;
    Layer hidden_layer;
    Layer interneuron_layer; 
    Layer predictionerror_layer; // diff between input and hidden/context
    
    // connections
    ConnectionSpec full_spec  = new ConnectionSpec();
    ConnectionSpec oto_inh_spec;
    ConnectionSpec inh_full_spec;
    ConnectionSpec full_weak_spec;
    ConnectionSpec oto_strong_spec;
    ConnectionSpec oto_middle_spec;

    LayerConnection pe_intern_conn; // input to context
    LayerConnection gain_hidden_conn;
    DendriteConnection intern_gainproj_conn; // inhibits proj from gain to hidden
    //LayerConnection pop_gain_conn; // population to gain
    LayerConnection hidden_self_conn;
    LayerConnection inp_pe_conn; // input to pred error, excitative
    LayerConnection hidden_pe_conn; // context to pred error, inhibitive
    LayerConnection pe_magnitude_conn; // 
    LayerConnection gain_ach_conn; // effort to ACh to modulate learing rate
    LayerConnection avoid_decval_conn; // avoid valence to decide valence - inhibitive
    LayerConnection appr_decval_conn; // approach valence to decide valence - excitative
    LayerConnection pos_avoid_conn; // position to avoid
    LayerConnection pos_approach_conn; // position to avoid
    LayerConnection avoid_spatix_conn; // avoid to spatial index
    LayerConnection approach_spatix_conn; // approach to spatial index

    // modules
    EffortModule effort_mod = new EffortModule(gainsize, "Effort");
    DecisionModule dec_mod = new DecisionModule("Decision");
    ValenceLearningModule val_mod = new ValenceLearningModule(2, "Valence learning");
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] ctx_inputval = zeros(ctx_inp_sz);
    float[] pos_inputval = zeros(pos_inp_sz);


    float[][] w_intern = tileCols(gainsize, id(ctx_inp_sz));
    float forcegain =0;
    float forceintern = 0;



    TestEffortAchDecisionModel () {
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=false;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        auto_unit_spec = new UnitSpec(excite_unit_spec);
        auto_unit_spec.bias = 0.2; // inh neurons need to fire to allow disinh

        // connection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;

        full_weak_spec = new ConnectionSpec(full_spec);
        full_weak_spec.rnd_mean = 0.25/gainsize;

        oto_inh_spec = new ConnectionSpec();
        oto_inh_spec.proj = "1to1";
        oto_inh_spec.inhibit = true;
        oto_inh_spec.rnd_mean=0.5;
        oto_inh_spec.rnd_var =0;

        inh_full_spec = new ConnectionSpec(oto_inh_spec);
        inh_full_spec.proj = "full";

        oto_strong_spec = new ConnectionSpec(oto_inh_spec);
        oto_strong_spec.inhibit = false;
        oto_strong_spec.rnd_mean = 0.5;

        oto_middle_spec = new ConnectionSpec(oto_strong_spec); // for now same wt as strong

        // layers
        ctx_input_layer = new Layer(ctx_inp_sz, new LayerSpec(false), excite_unit_spec, INPUT, "Input ctx");
        pos_input_layer = new Layer(pos_inp_sz, new LayerSpec(false), excite_unit_spec, INPUT, "Input pos");
        hidden_layer = new Layer(ctx_inp_sz, new LayerSpec(true), excite_unit_spec, HIDDEN, "Context");
        interneuron_layer = new Layer(ctx_inp_sz, new LayerSpec(false), auto_unit_spec, HIDDEN, "Interneurons");
        //gain_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Gain");
        //pop_layer = new Layer(gainsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Population");
        predictionerror_layer = new Layer(ctx_inp_sz, new LayerSpec(false), excite_unit_spec, HIDDEN, "Prediction error");
        //pe_magnitude_layer = new Layer(magnitudesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Magnitude");
        
        // connections
        inp_pe_conn = new LayerConnection(ctx_input_layer, predictionerror_layer, oto_middle_spec);
        hidden_pe_conn = new LayerConnection(hidden_layer, predictionerror_layer, oto_inh_spec);
        pe_intern_conn = new LayerConnection(predictionerror_layer, interneuron_layer, oto_inh_spec);
        gain_hidden_conn = new LayerConnection(effort_mod.layer(EffortModule.GAIN), hidden_layer, full_weak_spec);
        intern_gainproj_conn = new DendriteConnection(interneuron_layer, gain_hidden_conn, inh_full_spec);
        intern_gainproj_conn.weights(w_intern);
        //pop_gain_conn = new LayerConnection(pop_layer, gain_layer, full_spec);
        //pop_gain_conn.weights(w_effort);
        hidden_self_conn = new LayerConnection(hidden_layer, hidden_layer, oto_strong_spec);
        pe_magnitude_conn = new LayerConnection(predictionerror_layer, effort_mod.layer(EffortModule.MAGNITUDE), full_weak_spec);
        gain_ach_conn = new LayerConnection(effort_mod.layer(EffortModule.GAIN), val_mod.layer(ValenceLearningModule.NEG_LR), full_weak_spec);
        avoid_decval_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.AVOIDANCE), dec_mod.layer(DecisionModule.VALUE), inh_full_spec);
        appr_decval_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.APPROACH), dec_mod.layer(DecisionModule.VALUE), full_spec);
        pos_avoid_conn = new LayerConnection(pos_input_layer, val_mod.layer(ValenceLearningModule.PROPERTY), oto_strong_spec);
        pos_approach_conn = new LayerConnection(pos_input_layer, val_mod.layer(ValenceLearningModule.PROPERTY), oto_strong_spec);
        avoid_spatix_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.AVOIDANCE), dec_mod.layer(DecisionModule.SPATIAL_IX), inh_full_spec);
        approach_spatix_conn = new LayerConnection(val_mod.layer(ValenceLearningModule.APPROACH), dec_mod.layer(DecisionModule.SPATIAL_IX), full_spec);
        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {ctx_input_layer, hidden_layer, interneuron_layer, 
            predictionerror_layer, pos_input_layer};
            
        Connection[] conns = {pe_intern_conn, gain_hidden_conn, 
            intern_gainproj_conn, hidden_self_conn,
            inp_pe_conn, hidden_pe_conn, pe_magnitude_conn,
            gain_ach_conn, avoid_decval_conn, appr_decval_conn,
            pos_avoid_conn, pos_approach_conn,
            avoid_spatix_conn, approach_spatix_conn};


        netw = new Network(network_spec, layers, conns);
        //netw.build();
        for(Layer l: effort_mod.layers())
            netw.add_layer(l);
        for(Layer l: dec_mod.layers())
            netw.add_layer(l);
        for(Layer l: val_mod.layers())
            netw.add_layer(l);
        
        for(Connection c: effort_mod.connections())
            netw.add_connection(c);
        for(Connection c: dec_mod.connections())
            netw.add_connection(c);
        for(Connection c: val_mod.connections())
            netw.add_connection(c);
    }

    void setInput(float[] inp) { ctx_inputval = inp; }

    void tick() {
        //float[] pop_act = zeros(gainsize);
        //pop_act = populationEncode(
        //        pe_magnitude_layer.units[0].getOutput(), //forcegain,
        //        gainsize,
        //        0, 1,
        //        0.25
        //    );    
        //pop_layer.force_activity(pop_act);
        effort_mod.cycle();
        dec_mod.cycle();
        val_mod.cycle();

        if(netw.accept_input()) {
            float[] inp = ctx_inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input ctx", inpvals.copy());
            inputs.put("Input pos", arrayToList(pos_inputval));
            //inpvals = arrayToList(multiply(forcegain, ones(gainsize)));
            //inputs.put("Gain", inpvals.copy());
            //inpvals = arrayToList(multiply(forceintern, ones(ctx_inp_sz)));
            //inputs.put("Interneurons", inpvals.copy()); // note: forced units cannot be inh

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

        float[][] inp_viz = zeros(1,ctx_inp_sz);
        inp_viz[0] = ctx_input_layer.getOutput();
        //printArray("input layer output", inp_viz[0]);
        
        float[][] h_viz = zeros(1, hiddensize);
        h_viz[0] = hidden_layer.getOutput();

        
        translate(10,50);
        pushMatrix();
            //rotate(-HALF_PI);
            //pushMatrix();
            //text(ctx_input_layer.name, 0, 0);
            //pushMatrix();
            //translate(100, -10);
            //drawColGrid(0,0, 10, multiply(200, inp_viz));
            //popMatrix();
            //popMatrix();
            drawLayer(ctx_input_layer);
            drawLayer(pos_input_layer);

            drawLayer(predictionerror_layer);
            drawLayer(interneuron_layer);
            drawLayer(hidden_layer);
            effort_mod.draw();
            translate(0, 100);
            val_mod.draw();
            translate(0, 120);
            dec_mod.draw();

            
            
        popMatrix();

        popMatrix();

    }

    void handleKeyDown(char k){
        float[] ctx = zeros(ctx_inp_sz);
        if (k=='z')
            ctx[0] = 1.f;
        else if(k=='x')
            ctx[1] = 1.f;
        else if(k=='c')
            ctx[2] = 1.f;

        this.setInput(ctx);

    }

    void handleKeyUp(char k){
        this.setInput(zeros(ctx_inp_sz));
    }

    void handleMidi(int note, int vel){
        println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        if(note==81)
            ctx_inputval[0] = scale * vel; 
        if(note==82)
            ctx_inputval[1] = scale * vel; 
        if(note==83)
            ctx_inputval[2] = scale * vel; 
        if(note==1)
            forcegain = scale * vel;
        if(note==2)
            forceintern = scale * vel;
        if(note==65) // first button by knobs
            pos_inputval[0] = scale * vel;
        if(note==66) // first button by knobs
            pos_inputval[1] = scale * vel;
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

//
// network modules 
//
interface NetworkModule {
    String name();
    Layer[] layers();
    Connection[] connections();
    void cycle(); 
    void draw();
    Layer layer(int code);

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


class DecisionModule implements NetworkModule {
    /** This module has a value accumulator part
        built on that described in Balkenius et al 2020
    */
    static final int VALUE = 0;
    static final int SPATIAL_IX = 1;
    static final int CHOICE = 2;

    String name = "DecisionModule";
    Layer[] layers = new Layer[3];
    Connection[] connections = new Connection[0];
    int valuesize = 1;
    int choicesize = 2;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer value_layer;
    Layer spatial_ix_layer;
    ValueAccumulator acc;
    Layer choice_layer;

    DecisionModule() {
        this.init();
    }

    DecisionModule(String name) {
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
        // full_spec.proj="full";
        // full_spec.rnd_type="uniform" ;
        // full_spec.rnd_mean=0.5;
        // full_spec.rnd_var=0.0;

        // layers
        value_layer = new Layer(valuesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Value (in)");
        spatial_ix_layer = new Layer(choicesize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Spatial ix (in)");
        choice_layer = new Layer(choicesize, new LayerSpec(true), excite_unit_spec, HIDDEN, "Choice (out)");

        // accumlator
        acc = new ValueAccumulator(choicesize);

        int ix = 0;
        layers[ix++] = value_layer;
        layers[ix++] = spatial_ix_layer;
        layers[ix++] = choice_layer;

    }

    
    String name(){return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(int code) {
        switch(code) {
            case VALUE:
                return value_layer;
            case CHOICE:
                return choice_layer;
            case SPATIAL_IX:
            default:
                return spatial_ix_layer;
        }
    }
    
    void cycle() {
        acc.setSpatialIx(spatial_ix_layer.getOutput());
        acc.setInput(value_layer.getOutput());
        acc.cycle();
        choice_layer.force_activity(acc.getOutput());

    }
    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 260, 210, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawLayer(value_layer);
        drawLayer(spatial_ix_layer);
        drawBarChart(acc.getOutput(), "Acc output");
        translate(0,10);
        drawLayer(choice_layer);
        popMatrix();

    }

}


class ValenceLearningModule implements NetworkModule {
    /** This module models avoid approach learning.
        It has a choline-like population that modulates
        learning rate.
    */
    static final int NEG_LR = 0;
    static final int PROPERTY = 1;
    static final int AVOIDANCE = 2;
    static final int APPROACH = 3;

    String name = "Valence learning module";
    int popsize = 1; // size of populations representing positive and negative valence
    Layer[] layers = new Layer[4];
    Connection[] connections = new Connection[3];

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer neg_lr_layer; // choline-like, modulates learning rate on neg. valence
    Layer property_layer; // input interface; projects to valence layers; proj. susc. to learning rate mod
    Layer avoidance_layer; // learns negative valence
    Layer approach_layer; // learns positive valence

    // connections
    ConnectionSpec oto_spec = new ConnectionSpec(); //  
    ConnectionSpec choline_spec = new ConnectionSpec(); 
    LayerConnection property_avoidance_conn;
    LayerConnection property_approach_conn;
    DendriteConnection lr_avoidance_conn;

    ConnectableWeightSpec chol_w_spec = new ConnectableWeightSpec();



    ValenceLearningModule() {
        this.init();
    }

    ValenceLearningModule(int popsize, String name) {
        this.popsize = popsize;
        this.name = name;
        this.init();
    }

    void init() {
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=false;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        // connection spec
        choline_spec.proj="full";
        choline_spec.rnd_type="uniform" ;
        choline_spec.rnd_mean=0.5;
        choline_spec.rnd_var=0.0;
        choline_spec.type = ACETYLCHOLINE;

        oto_spec.proj = "1to1";
        oto_spec.rnd_type="uniform" ;
        oto_spec.rnd_mean=0.05;
        oto_spec.rnd_var=0.0;
        oto_spec.lrule = "delta";
        oto_spec.lrate = .1;

        chol_w_spec.receptors.append("M1"); // add M1 receptor support to modulate learning rate

        // layers
        neg_lr_layer = new Layer(1, new LayerSpec(false), excite_unit_spec, HIDDEN, "ACh (in)");
        property_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Properties (in)");
        avoidance_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, OUTPUT, "Neg val (out)");
        approach_layer = new Layer(popsize, new LayerSpec(false), excite_unit_spec, OUTPUT, "Pos val (out)");

        // connections
        property_avoidance_conn = new LayerConnection(property_layer, avoidance_layer, oto_spec, chol_w_spec);
        property_approach_conn = new LayerConnection(property_layer, approach_layer, oto_spec);
        lr_avoidance_conn = new DendriteConnection(neg_lr_layer, property_avoidance_conn, choline_spec);

        int ix = 0;
        layers[ix++] = neg_lr_layer;
        layers[ix++] = property_layer;
        layers[ix++] = avoidance_layer;
        layers[ix++] = approach_layer;
        ix =0;
        connections[ix++] = property_avoidance_conn;
        connections[ix++] = property_approach_conn;
        connections[ix++] = lr_avoidance_conn;


    }

    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {return connections;}
    Layer layer(int code) {
        switch(code) {
            case NEG_LR:
                return neg_lr_layer;
            case PROPERTY:
                return property_layer;
            case AVOIDANCE:
                return avoidance_layer;
            case APPROACH:
            default:
                return approach_layer;
        }
    }
    void cycle() {}

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(60);
        stroke(100);
        rect(0, 0, 220, 120, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawLayer(neg_lr_layer);
        drawLayer(property_layer);
        drawLayer(avoidance_layer);
        drawLayer(approach_layer);
        popMatrix();
    }


}
