// Test inhibition of units in a layer by inhibitive projections
import java.util.HashMap;
import java.util.Map;

class TestInhibition{
    String name = "Test inhibition";
    String[] lognames = {};
    SignalGenerator sig = new SignalGenerator(eTickSquare, 50, 40, 100);

    // units
    UnitSpec unit_spec = new UnitSpec();
    UnitSpec excite_unit_spec = new UnitSpec();
    UnitSpec inhib_unit_spec = new UnitSpec();
    UnitSpec unit_spec_bias = new UnitSpec();
    // Unit unit = new Unit(spec, INPUT, lognames);

    int numunits = 4;
    // layers

    Layer input_layer; // = new Layer(numunits, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
    Layer inhib_layer; // = new Layer(2, new LayerSpec(false), unit_spec, HIDDEN, "Hidden");
    Layer hidden_layer; // = new Layer(numunits, new LayerSpec(false), inhib_unit_spec, HIDDEN, "Output");

    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    ConnectionSpec ffinhib_spec  = new ConnectionSpec(); 
    ConnectionSpec fbinhib_spec  = new ConnectionSpec(); 
    ConnectionSpec inhib_spec  = new ConnectionSpec(); 
    ConnectionSpec inhibinhib_spec  = new ConnectionSpec(); 
    LayerConnection IH_conn; // = new LayerConnection(input_layer,  hidden_layer, ffexcite_spec);
    LayerConnection Ii_conn; // = new LayerConnection(input_layer,  inhib_layer,  ffinhib_spec);
    LayerConnection Hi_conn; // = new LayerConnection(hidden_layer, inhib_layer,  fbinhib_spec);
    LayerConnection iH_conn; // = new LayerConnection(inhib_layer,  hidden_layer, inhib_spec);
    LayerConnection ii_conn; // = new LayerConnection(inhib_layer,  inhib_layer,  inhibinhib_spec);

    // network
    int quart_num = 10;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    Layer[] layers =  {input_layer, inhib_layer, hidden_layer};
    Connection[] conns = {IH_conn}; //,
    //Ii_conn,
    //Hi_conn,
    //iH_conn,
    //ii_conn};
    Network netw; // = new Network(network_spec, layers, conns);

    Map<String, FloatList> inputs = new HashMap<String, FloatList>();

    boolean phase = true;
    int cyc = 0;

    TestInhibition(){
        unit_spec_bias.bias = 0.1;

        excite_unit_spec.adapt_on = false;
        excite_unit_spec.noisy_act=true;
        excite_unit_spec.act_thr=0.5;
        excite_unit_spec.act_gain=100;
        excite_unit_spec.tau_net=40;
        excite_unit_spec.g_bar_e=1.0;
        excite_unit_spec.g_bar_l=0.1;
        excite_unit_spec.g_bar_i=0.40;

        inhib_unit_spec.adapt_on = false;
        inhib_unit_spec.noisy_act = true;
        inhib_unit_spec.act_thr = 0.4;
        inhib_unit_spec.act_gain = 100;
        inhib_unit_spec.tau_net = 20;
        inhib_unit_spec.g_bar_e = 1.0;
        inhib_unit_spec.g_bar_l = 0.1;
        inhib_unit_spec.g_bar_i = 0.75;

        // layer spec


        // connection spec
        // unit.show_config();
        ffexcite_spec.proj="1to1";
        ffexcite_spec.rnd_type="uniform" ;
        ffexcite_spec.rnd_mean=0.25;
        ffexcite_spec.rnd_var=0.2;

        ffinhib_spec.proj="full";
        ffinhib_spec.rnd_type="gaussian" ;
        ffinhib_spec.rnd_mean=0.25;
        ffinhib_spec.rnd_var=0.2;

        fbinhib_spec.proj="full";
        fbinhib_spec.rnd_type="uniform" ;	
        fbinhib_spec.rnd_mean=0.25;	
        fbinhib_spec.rnd_var=0.2;	

        // inhib proj
        inhib_spec.proj="full";	
        inhib_spec.rnd_type="uniform" ;	
        inhib_spec.rnd_mean=0.5;	
        inhib_spec.rnd_var=0.f;	
        inhib_spec.inhibit = true;
        
        inhibinhib_spec.proj="full";	
        inhibinhib_spec.rnd_type="uniform" ;	
        inhibinhib_spec.rnd_mean=0.2;	
        inhibinhib_spec.rnd_var=0.f;	

        input_layer = new Layer(numunits, new LayerSpec(false), excite_unit_spec, INPUT, "Input");
        inhib_layer = new Layer(2, new LayerSpec(false), unit_spec, HIDDEN, "Hidden");
        hidden_layer = new Layer(numunits, new LayerSpec(false), inhib_unit_spec, HIDDEN, "Output");

        IH_conn = new LayerConnection(input_layer,  hidden_layer, ffexcite_spec);
        Ii_conn = new LayerConnection(input_layer,  inhib_layer,  ffinhib_spec);
        Hi_conn = new LayerConnection(hidden_layer, inhib_layer,  fbinhib_spec);
        iH_conn = new LayerConnection(inhib_layer,  hidden_layer, inhib_spec);
        ii_conn = new LayerConnection(inhib_layer,  inhib_layer,  inhibinhib_spec);

        Layer[] layers =  {input_layer, inhib_layer, hidden_layer};
        Connection[] conns = {IH_conn,
        Ii_conn,
        Hi_conn,
        iH_conn,
        ii_conn};
        netw = new Network(network_spec, layers, conns);

        netw.build();
    }

    void tick(){
        FloatList inpvals = new FloatList();
        inpvals.set(numunits-1, 0.0); // set dim of list
        inpvals.set((int)random(0, numunits), 0.25 * sig.getOutput());
        inputs.put("Input", inpvals);
        if(cyc++ % quart_num == 0)
            netw.set_inputs(inputs);
        netw.cycle();
    
        sig.tick();
    }

    void draw(){
        pushMatrix();
        translate(10, 10);
        text(name, 0,0);
        popMatrix();
        pushMatrix();
        float[][] tmp = zeros(3,numunits);
        tmp[0] = input_layer.getOutput();
        tmp[1][0] = inhib_layer.getOutput()[0];
        tmp[1][1] = inhib_layer.getOutput()[1];
        tmp[2] = hidden_layer.getOutput();
        
        translate(10,250);
        pushMatrix();
        rotate(-HALF_PI);
        drawColGrid(0,0, 40, multiply(200, tmp));
        popMatrix();
        
        popMatrix();
    }

}
