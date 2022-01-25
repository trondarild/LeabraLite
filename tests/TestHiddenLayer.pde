//
// Test for simple 3 layer network
class TestHiddenLayer{

    String[] lognames = {};
    SignalGenerator sig = new SignalGenerator(eTickSquare, 50, 40, 100);

    // units
    UnitSpec unit_spec = new UnitSpec();
    // Unit unit = new Unit(spec, INPUT, lognames);

    // layers
    Layer sense_layer ; //= new Layer(1, new LayerSpec(), unit_spec, INPUT, "Input");
    Layer input_layer ; //= new Layer(3, new LayerSpec(), unit_spec, HIDDEN, "Hidden");
    Layer hidden_layer; // = new Layer(3, new LayerSpec(), unit_spec, HIDDEN, "Output");

    // connections
    ConnectionSpec ffexcite_spec  = new ConnectionSpec();
    LayerConnection SI_conn; // = new LayerConnection(sense_layer, input_layer, ffexcite_spec);
    LayerConnection IH_conn; // = new LayerConnection(input_layer,  hidden_layer, ffexcite_spec);
    LayerConnection HI_conn; // = new LayerConnection(hidden_layer,  input_layer, ffexcite_spec);

    // network
    int quart_num = 10;
    NetworkSpec network_spec = new NetworkSpec(quart_num);
    
    Network netw; // = new Network(network_spec, layers, conns);

    Map<String, FloatList> inputs = new HashMap<String, FloatList>();

    boolean phase = true;
    int cyc = 0;
    
    TestHiddenLayer(){
        sense_layer = new Layer(1, new LayerSpec(), unit_spec, INPUT, "Input");
        input_layer = new Layer(3, new LayerSpec(), unit_spec, HIDDEN, "Hidden");
        hidden_layer = new Layer(3, new LayerSpec(), unit_spec, HIDDEN, "Output");

        ffexcite_spec.proj="full";
        ffexcite_spec.rnd_type="gaussian" ;
        ffexcite_spec.rnd_mean=0.25;
        ffexcite_spec.rnd_var=0.52;
        

        SI_conn = new LayerConnection(sense_layer, input_layer, ffexcite_spec);
        IH_conn = new LayerConnection(input_layer,  hidden_layer, ffexcite_spec);
        HI_conn = new LayerConnection(hidden_layer,  input_layer, ffexcite_spec);

        Layer[] layers =  {sense_layer, input_layer, hidden_layer};
        Connection[] conns = {SI_conn, IH_conn};
        netw = new Network(network_spec, layers, conns);
        netw.build();
    }

    void tick(){
        // update network
        FloatList inpvals = new FloatList();
        inpvals.append(sig.getOutput());
        inputs.put("Input", inpvals);
        
        if(cyc++ % quart_num == 0)
            netw.set_inputs(inputs);
        netw.cycle();
	    sig.tick();
    }

    void draw(){
        // visualize activity
        translate(0, -50);
        pushMatrix();
        translate(10, 100);
        drawTimeSeries(sense_layer.getBuffers()[0].array(), 2, 1, 0);
        popMatrix();

        pushMatrix();
        translate(100,100);
        drawTimeSeries(input_layer.getBuffers()[2].array(), 2, 1, 0);
        popMatrix();

        pushMatrix();
        translate(100,200);
        drawTimeSeries(input_layer.getBuffers()[1].array(), 2, 1, 0);
        popMatrix();

        pushMatrix();
        translate(100,300);
        drawTimeSeries(input_layer.getBuffers()[0].array(), 2, 1, 0);
        popMatrix();

        pushMatrix();
        translate(200,100);
        drawTimeSeries(hidden_layer.getBuffers()[2].array(), 2, 1, 0);
        popMatrix();

        pushMatrix();
        translate(200,200);
        drawTimeSeries(hidden_layer.getBuffers()[1].array(), 2, 1, 0);
        popMatrix();

        pushMatrix();
        translate(200,300);
        drawTimeSeries(hidden_layer.getBuffers()[0].array(), 2, 1, 0);
        popMatrix();

        pushMatrix();
        float[][] tmp = zeros(3,3);
        tmp[0][1] = sense_layer.getOutput()[0];
        tmp[1] = input_layer.getOutput();
        tmp[2] = hidden_layer.getOutput();
        translate(10,650);
        pushMatrix();
        rotate(-HALF_PI);
        drawColGrid(0,0, 40, multiply(200, tmp));
        popMatrix();
        
        popMatrix();
    }
}
