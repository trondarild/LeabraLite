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

class TestRuleMod {
    String modelname = "Test rule module";
    String description = "";

    int inputvecsize = 10; // ctx:3 reward:1 pos:2 color:4 number:10
    int hiddensize = 2; // TODO update when calc number of discrete behaviours, including gating ones
 
    // Modules
    
    ArrayList<float[][]> rulelist;

    RuleModule rule_mod;

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    
    // layer
    Layer input_layer; 
    Layer hidden_layer; 
    
    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection input_rule_conn; // input to context
    LayerConnection rule_hidden_conn; // input to context
    
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map <String, FloatList> inputs = new HashMap<String, FloatList>();
    int inp_ix = 0;

    float[] inputval = zeros(inputvecsize);

    TestRuleMod () {
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
        float[][] oddevenrule = {
        {1,0,1,0,1,0,1,0,1,0},
        {0,1,0,1,0,1,0,1,0,1}//zeros(10)
        };
        float[][] lt5rule = {
            {1,1,1,1,0,0,0,0,0,0},
            {0,0,0,0,1,1,1,1,1,1}
            
        };
        rulelist = new ArrayList<float[][]>();
        rulelist.add(transpose(oddevenrule));
        rulelist.add(transpose(lt5rule));
        rule_mod = new RuleModule(rulelist);
        
        //rule_mod = new RuleModule(rulelist);

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        hidden_layer = new Layer(hiddensize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Hidden");
        
        // connections
        input_rule_conn = new LayerConnection(input_layer, rule_mod.layer("in"), ffexcite_spec);
        rule_hidden_conn = new LayerConnection(rule_mod.layer("out"), hidden_layer, ffexcite_spec);

        // network
        network_spec.do_reset = false; // since dont use learning, avoid resetting every quarter

        Layer[] layers = {input_layer, hidden_layer};
        Connection[] conns = {input_rule_conn, rule_hidden_conn};


        netw = new Network(network_spec, layers, conns);
        netw.add_module(rule_mod);
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
        translate(0,20);
        text(description, 0, 0);
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

            translate(0,0);

            rule_mod.draw();
            translate(0,230);
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
        if(note>=81)
            inputval[note-81] = scale * vel; 
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
