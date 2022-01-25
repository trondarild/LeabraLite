//
// sketch test for experimental task network
// 

class TestTaskNet{
    String modelname = "Task net test";
    int inputvecsize = 24; // ctx:3 reward:1 pos:2 color:4 number:10
    int behaviours = 4; // TODO update when calc number of discrete behaviours, including gating ones
    int outputvecsize = 4;
    int stn_size = 9; // same as Wiecki and Frank 2012
    int acc_size = 1; // same as Wiecki and Frank 2012

    String[] lognames = {};
    SignalGenerator sig = new SignalGenerator(eTickSquare, 50, 40, 100);

    // unit spec
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec inhib_unit_spec = new UnitSpec();
    UnitSpec bias_unit_spec = new UnitSpec();
    

    // layer
    
    Layer input_layer;
    
    Layer striatum_d1_layer; // go - contains input, (learned, manually set) temporal combination patterns
    Layer striatum_d2_layer; // no go
    Layer gpe_layer;
    Layer gpi_snr_layer;
    Layer stn_layer; // input from dacc
    Layer thalamus_layer; // cogn and motor

    Layer acc_layer; // will handle effort and get tired - perhaps make inherited layer?
    Layer pfc_maintenance_layer; // 
    Layer pfc_gate_layer;
    Layer m1_layer; // output

    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec ffexcite_rnd_spec  = new ConnectionSpec();
    ConnectionSpec ffexcite_1to1_spec  = new ConnectionSpec();
    ConnectionSpec inhib_spec  = new ConnectionSpec(); 
    ConnectionSpec thal_inhib_spec  = new ConnectionSpec(); 

    LayerConnection ID1_conn; // input to striatum D1 - go
    LayerConnection ID2_conn; // input to striatum D1 - nogo
    LayerConnection D1GPi_conn; // D1 to GPi "direct"
    LayerConnection D2Gpe_conn; // D2 to GPe "indirect"
    LayerConnection GpeGpi_conn; // GPe to GPi "indirect"
    LayerConnection AccStn_conn; // ACC to STN "hyperdirect"
    LayerConnection StnGpi_conn; // STN to GPi "hyperdirect"
    LayerConnection GPiThal_conn; // GPi to thalamus
    LayerConnection ThalPfcGate_conn; // Thalamus to PFC gate layer 4
    LayerConnection PfcGateMaint_conn; // PFC gate to maintenance layer 2,3/5.6
    LayerConnection PfcMaintM1_conn; // PFC maintenance to M1 output
    LayerConnection PfcMaintD1_conn; // temporal context to keep track of sequence

    float[][] ID1_weights = zeros(inputvecsize, behaviours); // weights to trigger a particular D1 unit based on input
    int quart_num = 25;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Network netw; // network model to contain layers and connections

    Map<String, FloatList> inputs = new HashMap<String, FloatList>();
    boolean phase = true;
    int cyc = 0;
    int inp_ix = 0;
    //float[][] testinputs = {
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}, // even: no
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0, 0, 0, 0, 0, 0, 0,  0}, // 
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 1, 0, 0, 0, 0, 0,  0}, // 
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 1, 0, 0, 0,  0}, // 
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 1, 0,  0},
//
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 1, 0, 0, 0, 0, 0, 0, 0, 0,  0}, // even: yes
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 1, 0, 0, 0, 0, 0, 0,  0}, //
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 1, 0, 0, 0, 0,  0}, //
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 1, 0, 0,  0}, //
    //    {0, 1,  0, 1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 1,  0}
    //
    //};

    float[][] testinputs = {
        
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}, // even: no
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 1, 0, 0, 0, 0, 0, 0, 0, 0,  0}, // even: yes
     
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 1, 0, 0, 0, 0, 0, 0, 0,  0}, // 
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 1, 0, 0, 0, 0, 0, 0,  0}, //
     
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 1, 0, 0, 0, 0, 0,  0}, // 
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 1, 0, 0, 0, 0,  0}, //
     
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 1, 0, 0, 0,  0}, // 
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 1, 0, 0,  0}, //
     
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 1, 0,  0},
        {0, 1, 0,  1, 0,  1, 0, 0, 0,  1, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 1,  0}



    };

    TestTaskNet(){
        // unit
        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;
        // excite_unit_spec.bias = 0.1;

        inhib_unit_spec.adapt_on = false;
        inhib_unit_spec.noisy_act = true;
        inhib_unit_spec.act_thr = 0.4;
        inhib_unit_spec.act_gain = 100;
        inhib_unit_spec.tau_net = 20;
        inhib_unit_spec.g_bar_e = 1.0;
        inhib_unit_spec.g_bar_l = 0.1;
        inhib_unit_spec.g_bar_i = 0.75;

        bias_unit_spec.adapt_on = false;
        bias_unit_spec.noisy_act=true;
        bias_unit_spec.act_thr = 0.4;; //act_thr=0.5;
        bias_unit_spec.act_gain = 100;; //act_gain=100;
        bias_unit_spec.tau_net = 20;; //tau_net=40;
        bias_unit_spec.g_bar_e = 1.0;; //g_bar_e=1.0;
        bias_unit_spec.g_bar_l = 0.1;; //g_bar_l=0.1;
        bias_unit_spec.g_bar_i = 0.75;; //g_bar_i=0.40;
        bias_unit_spec.bias = 0.075;

        // connection spec
        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.75;
        ffexcite_spec.rnd_var=0.0;

        ffexcite_rnd_spec.proj="full";
        ffexcite_rnd_spec.rnd_type="uniform" ;
        ffexcite_rnd_spec.rnd_mean=0.15;
        ffexcite_rnd_spec.rnd_var=0.2;

        ffexcite_1to1_spec.proj="1to1";
        ffexcite_1to1_spec.rnd_type="uniform" ;
        ffexcite_1to1_spec.rnd_mean=0.75;
        ffexcite_1to1_spec.rnd_var=0.0;

        inhib_spec.proj="1to1";	
        inhib_spec.rnd_type="uniform" ;	
        inhib_spec.rnd_mean=0.5;	
        inhib_spec.rnd_var=0.f;	
        inhib_spec.inhibit = true;

        thal_inhib_spec.proj="1to1";	
        thal_inhib_spec.rnd_type="uniform" ;	
        thal_inhib_spec.rnd_mean=0.15;	// less inh prevents thalamus from just going dark
        thal_inhib_spec.rnd_var=0.f;	
        thal_inhib_spec.inhibit = true;

        // layers
        input_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        striatum_d1_layer = new Layer(behaviours, new LayerSpec(false), inhib_unit_spec, HIDDEN, "StriatumD1");
        striatum_d2_layer = new Layer(behaviours, new LayerSpec(false), inhib_unit_spec, HIDDEN, "StriatumD2");
        gpe_layer = new Layer(behaviours, new LayerSpec(false), bias_unit_spec, HIDDEN, "GPe");
        gpi_snr_layer = new Layer(behaviours, new LayerSpec(false), bias_unit_spec, HIDDEN, "GPi-SNr");
        thalamus_layer = new Layer(behaviours, new LayerSpec(false), bias_unit_spec, HIDDEN, "Thalamus");
        stn_layer = new Layer(stn_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "STN");
        acc_layer = new Layer(acc_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "ACC");
        
        // connections
        ID1_conn = new LayerConnection(input_layer,  striatum_d1_layer, ffexcite_spec);
        ID2_conn = new LayerConnection(input_layer,  striatum_d2_layer, ffexcite_spec);
        D2Gpe_conn = new LayerConnection(striatum_d2_layer,  gpe_layer, inhib_spec);
        D1GPi_conn = new LayerConnection(striatum_d1_layer, gpi_snr_layer, inhib_spec);
        GpeGpi_conn = new LayerConnection(gpe_layer, gpi_snr_layer, inhib_spec);
        GPiThal_conn = new LayerConnection(gpi_snr_layer, thalamus_layer, thal_inhib_spec);
        StnGpi_conn = new LayerConnection(stn_layer, gpi_snr_layer, ffexcite_rnd_spec);
        AccStn_conn = new LayerConnection(acc_layer, stn_layer, ffexcite_rnd_spec);
        
        this.setWeights(); // test setting weights which are sums of valid input combinations
        Layer[] layers =  {input_layer, striatum_d1_layer, striatum_d2_layer, gpe_layer,
                            gpi_snr_layer, thalamus_layer, stn_layer, acc_layer};
	    Connection[] conns = {ID1_conn, ID2_conn, D2Gpe_conn,
                                D1GPi_conn, GPiThal_conn, StnGpi_conn,
                                AccStn_conn};

        netw = new Network(network_spec, layers, conns);
        netw.build();
        
    }

    void tick(){
        //FloatList inpvals = new FloatList();
        //inpvals.set(inputvecsize - 1, 0.0); // set dim of list
        //inpvals.set((int)random(0, inputvecsize), 0.5 * sig.getOutput());
        
        //if(cyc % (quart_num * netw.trial_length) == 0){
        if(netw.accept_input()){
            //println();
            //printArray("input", testinputs[inp_ix % testinputs.length]);
            FloatList inpvals = arrayToList(testinputs[inp_ix++ % testinputs.length]);
            //println("floatlist: " + inpvals.toString());
            inputs.put("Input", inpvals);
            netw.set_inputs(inputs);
        }
        netw.cycle();
    
        sig.tick();
        cyc++;
    }

    void draw(){
        pushMatrix();
        
        pushMatrix();
        translate(10,20);
        text(modelname, 0, 0);
        popMatrix();

        float[][] inp_viz = zeros(1,inputvecsize);
        inp_viz[0] = input_layer.getOutput();
        
        float[][] d1_viz = zeros(1,inputvecsize);
        d1_viz[0] = striatum_d1_layer.getOutput();

        float[][] d2_viz = zeros(1,inputvecsize);
        d2_viz[0] = striatum_d2_layer.getOutput();

        float[][] acc_viz = zeros(1,acc_size);
        acc_viz[0] = acc_layer.getOutput();

        float[][] stn_viz = zeros(1,stn_size);
        stn_viz[0] = stn_layer.getOutput();

        float[][] gpe_viz = zeros(1,behaviours);
        gpe_viz[0] = gpe_layer.getOutput();

        float[][] gpi_viz = zeros(1,behaviours);
        gpi_viz[0] = gpi_snr_layer.getOutput();

        float[][] thal_viz = zeros(1,behaviours);
        thal_viz[0] = thalamus_layer.getOutput();
        // tmp[1][0] = striatum_d1_layer.getOutput()[0];
        // tmp[1][1] = striatum_d1_layer.getOutput()[1];
        
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

            translate(0, 20);
            pushMatrix();
            text(striatum_d1_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, d1_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(striatum_d2_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, d2_viz));
            popMatrix();
            popMatrix();
            
            translate(0, 20);
            pushMatrix();
            text(acc_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, acc_viz));
            popMatrix();

            popMatrix();
            translate(0, 20);
            pushMatrix();
            text(stn_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, stn_viz));
            popMatrix();
            popMatrix();            

            translate(0, 20);
            pushMatrix();
            text(gpe_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, gpe_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(gpi_snr_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, gpi_viz));
            popMatrix();
            popMatrix();

            translate(0, 20);
            pushMatrix();
            text(thalamus_layer.name, 0,0);
            pushMatrix();
            translate(100, -10);
            drawColGrid(0,0, 10, multiply(200, thal_viz));
            popMatrix();
            popMatrix();
        
        popMatrix();
        popMatrix();
    }

    void setWeights(){
        // ctx: 010 pos: 10 shp:1000 color:1000 num:1000000000 

        // weights for decision demand task: color = purple (check if number is even)
        float[][] ddt_even_weights_d1 = {
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 1, 0, 1, 0, 1, 0, 1, 0,  0}, // odd, press left
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 1, 0, 1, 0, 1, 0, 1,  0}, // even, press right
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0},
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}
        };
        ID1_conn.weights(transpose(multiply(0.71, ddt_even_weights_d1)));

        float[][] ddt_even_weights_d2 = {
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 1, 0, 1, 0, 1, 0, 1, 0, 1,  0}, // odd, press left
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 0, 1, 0, 1, 0, 1, 0, 1, 0,  0}, // even, press right
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0},
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}
        };
        ID2_conn.weights(transpose(multiply(0.71, ddt_even_weights_d2)));

        // weights for dec demand task: color = blue (check if number is < 5)
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0000010000 out: 1000 // < 5? no
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0000001000 out: 1000
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0000000100 out: 1000
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0000000010 out: 1000
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0000000001 out: 1000

        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:1000000000 out: 0100 // do num task: even num?
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0100000000 out: 0100
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0010000000 out: 0100
        // 1. ctx: 010 pos: 10 shp:1000 color:0010 num:0001000000 out: 0100

        // weights for less than 5 context
        float[][] ddt_lt5_weights_d1 = {
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 1, 1, 1, 1, 0,  0}, 
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 1, 1, 1, 0, 0, 0, 0, 0, 0,  0}, 
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}, 
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}
        };

        float[][] ddt_lt5_weights_d2 = {
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  1, 1, 1, 1, 0, 0, 0, 0, 0, 0,  0}, 
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 1, 1, 1, 1, 0,  0}, 
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}, 
            {0, 0, 0,  0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  0}
        };



    }
}

/** Notes
2021-12-10: can use tonic DA to keep thresholds sufficiently low; this should be contingent
    on perceiving progress or novelty (could be a separate input, or integration of some input, wm sequence);
    as progress, novelty slows, ACC is perhaps disinhibited and compensates by exciting nucl. accumbens 
    (ref Andre 2019) 
    
*/
