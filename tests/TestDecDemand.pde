/*
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:1000000000 out: 1000 // do num task: even num?
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0010000000 out: 1000 -> 
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0000100000 out: 1000
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0000001000 out: 1000
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0000000010 out: 1000
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0100000000 out: 0100
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0001000000 out: 0100
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0000010000 out: 0100
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0000000100 out: 0100
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:1000 num:0000000001 out: 0100

**Less than 5?**
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:1000000000 out: 0100 // < 5?
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0100000000 out: 0100
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0010000000 out: 0100
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0001000000 out: 0100
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0000010000 out: 1000
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0000001000 out: 1000
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0000000100 out: 1000
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0000000010 out: 1000
1. ctx: 010 tctx: 01 pos: 10 shp:1000 color:0010 num:0000000001 out: 1000

*/

/**
    2022-02-09 TODO:
        * call setAnswer on task when output is > threshold, and choose stack, triggering new
            getNewCard() call
        * move viz code to task; draw cards on top of test screen (scaled down)
*/

class TestDecDemand {
    String modelname = "Test decision demand task with mental effort model";
    String description = "Faders 1-3 control input";

    int inputvecsize = 27; // ctx:3 tmpctx:2 pos:2 shape:4 color:4 number:10 reward:2
    int hiddensize = 4; // TODO update when calc number of discrete behaviours, including gating ones

    final int DECDEMAND_TASKCTX_IX = 0;
    final int WISCONSIN_TASKCTX_IX = 1;
    final int USERULES_IX = 3; // first ix of temporal ix
    final int USECHOICE_IX = 4;
    final int LEFTPOS_IX = 5;
    final int RIGHTPOS_IX = 6;
    final int REWARD_IX = 25;

    float[] card; // [0-9 number, 10-13 colour]
    int stack; //
    
    // exp task
    DemandSelectionTask task = new DemandSelectionTask();
 
    // Modules
    EffortRegulationModel mod;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection input_mod_conn; // input to context
    LayerConnection mod_hidden_conn; // input to context
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);
    float[] inputval_tmp = inputval;

    int ix_bias = 0;

    final String WAITING_FOR_ANSWER = "wait_answer";
    final String REGISTERING_FB = "register_fb";
    final String RESETTING_AFTER_ANSWER = "resetting_answer";
    final String RESETTING_AFTER_CHOICE = "resetting_choice";
    final String WAITING_FOR_CHOICE = "wait_choice";
    String state = WAITING_FOR_ANSWER;

    float[] answer_fb = zeros(2);
    final int FB_TIME = 10;
    int fb_ctr = FB_TIME;

    TestDecDemand () {
        
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
        ffexcite_spec.rnd_var=0.0;
        
        mod = new EffortRegulationModel();
        
        //rule_mod = new RuleModule(rulelist);

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Hidden");
        
        // connections
        input_mod_conn = new LayerConnection(input_layer, mod.layer("in"), ffexcite_spec);
        mod_hidden_conn = new LayerConnection(mod.layer("out"), hidden_layer, ffexcite_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer};
        Connection[] conns = {input_mod_conn, mod_hidden_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(mod);
        netw.build();

        // draw first card
        card = task.getNewCard(0); // start with leftmost stack
        inputval[DECDEMAND_TASKCTX_IX] = 1; // dec demand task
        inputval[USERULES_IX] = 1; // use rules, not choice
        inputval[LEFTPOS_IX] = 1; // leftmost stack
        System.arraycopy(card, 10, inputval, 11, 2); // color
        System.arraycopy(card, 0, inputval, 15, 10); // number

    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        //println("state before: " + state);
        task.tick();
        if(netw.accept_input()) {
            float[] inp = inputval;
            FloatList inpvals = arrayToList(inp);
            inputs.put("Input", inpvals);
            netw.set_inputs(inputs);
        }
        netw.cycle();

        // state machine:
        switch (state) {
            case WAITING_FOR_ANSWER:
                if(max(getSubArray(mod.layer("out").output(), 0, 2)) > 0.5){
                    // got an answer
                    answer_fb = task.setAnswer(argmax(mod.layer("out").output())==0 ? 1.0 : 0.0);
                    System.arraycopy(answer_fb, 0, inputval, REWARD_IX, 2);
                    printArray("test: after reward: ", inputval);
                    state = REGISTERING_FB;
                }
                break;
            case REGISTERING_FB:
                //println("registering fb: " + fb_ctr);
                if(fb_ctr-- <= 0) {
                    fb_ctr = FB_TIME;
                    reset(inputval);
                    inputval[USERULES_IX] = 0;
                    inputval[USECHOICE_IX] = 1; // go into choice mode
                    inputval[LEFTPOS_IX] = 1; // activate both left and right to choose
                    inputval[RIGHTPOS_IX] = 1;
                    
                    state = WAITING_FOR_CHOICE;
                } 
                
                break;
            case RESETTING_AFTER_ANSWER:
                break;
            case WAITING_FOR_CHOICE:
                if(max(getSubArray(mod.layer("out").output(), 2, 2)) > 0.5){
                    // got a choice
                    float[] choice = getSubArray(mod.layer("out").output(), 2, 2);
                    printArray("choice", choice);
                    int chix = argmax(choice);
                    println("Test:tick: Chose position: " + chix);

                    reset(inputval);
                    reset(inputval_tmp);
                    card = task.getNewCard(chix);
                    inputval_tmp[DECDEMAND_TASKCTX_IX] = 1; // dec demand task
                    inputval_tmp[USERULES_IX] = 1; // use rules, not choice
                    inputval_tmp = setSubArray(choice, inputval_tmp, LEFTPOS_IX); // leftmost stack
                    System.arraycopy(card, 10, inputval_tmp, 11, 2); // color
                    System.arraycopy(card, 0, inputval_tmp, 15, 10); // number
                    
                    state = RESETTING_AFTER_CHOICE;

                }
                break;
            default:
            case RESETTING_AFTER_CHOICE:
                if(max(mod.layer("out").output()) < 0.1) {
                    System.arraycopy(inputval_tmp, 0, inputval, 0, inputval.length);
                    state = WAITING_FOR_ANSWER;
                }
                
                // mod.layer("out").force_activity(zeros(mod.layer("out").output().length));
        }
        //println("state after: " + state);

        /*
        if(max(mod.layer("out").output()) > 0.5){
            // answer: 1.0 = yes, 0.0 = no
            // output: ix 0 = yes, 1 = no
            if(inputval[USERULES_IX] == 1) {
                task.setAnswer(argmax(mod.layer("out").output())==0 ? 1.0 : 0.0);
                reset(inputval);
                inputval[USERULES_IX] = 0;
                inputval[USECHOICE_IX] = 1; // go into choice mode
                inputval[LEFTPOS_IX] = 1; // activate both left and right to choose
                inputval[RIGHTPOS_IX] = 1;
                // mod.layer("out").force_activity(zeros(mod.layer("out").output().length));
            }
            else if (inputval[USECHOICE_IX] == 1) {
                // TODO wait 
                // get the choice
                float[] choice = getSubArray(mod.layer("out").output(), 2, 2);
                printArray("choice", choice);
                int chix = argmax(choice);
                println("Chose position: " + chix);

                //reset(inputval);
                // card = task.getNewCard(chix);
                // inputval[DECDEMAND_TASKCTX_IX] = 1; // dec demand task
                // inputval[USERULES_IX] = 1; // use rules, not choice
                // setSubArray(choice, inputval, LEFTPOS_IX); // leftmost stack
                // System.arraycopy(card, 10, inputval, 11, 2); // color
                // System.arraycopy(card, 0, inputval, 15, 10); // number
                // mod.layer("out").force_activity(zeros(mod.layer("out").output().length));

            }
        }
        */

    }

    void draw() {
        pushMatrix();
        
        pushMatrix();
        translate(10,20);
        text(modelname, 0, 0);
        translate(0,20);
        text(description, 0, 0);
        popMatrix();

        
        translate(10,50);
        pushMatrix();
        task.boundary_w = 800;
        task.boundary_h = 180;
        task.draw();
        popMatrix();

        float[][] inp_viz = zeros(1,inputvecsize);
        inp_viz[0] = input_layer.getOutput();
        //printArray("input layer output", inp_viz[0]);
        translate(0, 200);
        pushMatrix();
            drawLayer(input_layer);

            translate(0,0);
            mod.draw();
            translate(0,mod.boundary_h + 30);
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
        println("Note "+ note + ", vel " + vel);
        float scale = 1.0/127.0;
        
        if(note >= 89 && note <=92) {
            // use buttons to shift faders ix by simple bias
            int sign = vel == 0? -1 : 1;
            ix_bias = limitval(0, 4*8, ix_bias + sign * 8); 
            println("bias: " + ix_bias);

        }
        if(note >= 81 && note <= 88)
            inputval[limitval(0, inputvecsize-1, note-81 + ix_bias)] = scale * vel; 
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
