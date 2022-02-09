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

class TestDecDemand {
    String modelname = "Test decision demand task with mental effort model";
    String description = "Faders 1-3 control input";

    int inputvecsize = 27; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 4; // TODO update when calc number of discrete behaviours, including gating ones

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

    int ix_bias = 0;

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
        card = task.getNewCard(0);
        inputval[0] = 1; // dec demand task
        System.arraycopy(card, 10, inputval, 11, 2); // color
        System.arraycopy(card, 0, inputval, 15, 10); // number

    }

    void setInput(float[] inp) { inputval = inp; }

    void tick() {
        task.tick();
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
        translate(0,20);
        text(description, 0, 0);
        popMatrix();

        float[][] inp_viz = zeros(1,inputvecsize);
        inp_viz[0] = input_layer.getOutput();
        //printArray("input layer output", inp_viz[0]);
        
        translate(10,50);
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
