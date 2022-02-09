class RuleModule implements NetworkModule {
    static final String IN = "in";
    static final String OUT = "out";
    static final String INHIBITION = "inhibition";
    static final String DISINHIBITION = "disinhibition";
    
    String name = "RuleModule";

    int boundary_w = 200;
    int boundary_h = 200;
    int fill_col = 60;
    
    Layer[] layers; // = new Layer[2];
    // Connection[] connections; //
    ArrayListExt<Connection> rule_connections = new ArrayListExt<Connection>();
    ArrayListExt<Connection> inh_connections = new ArrayListExt<Connection>();
    int layersize = 2;
    ArrayList<float[][]> rules; // in effect the weight matrix of the in-out connection

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer in_layer; // used for translation to pop code to engage effort
    Layer out_layer;
    Layer inh_layer; // inhibitits all rule connections and must be disinh
    Layer disinh_layer;
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    // LayerConnection in_out_conn; // population to gain
    

    RuleModule(ArrayList<float[][]> rule_topologies) {
        this.rules = rule_topologies;
        this.init();
    }

    RuleModule(ArrayList<float[][]> rule_topologies, String name) {
        this.rules = rule_topologies;
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


        UnitSpec auto_spec = new UnitSpec(excite_unit_spec);
        auto_spec.bias = 0.1;

        // connection spec
        full_spec.proj="full";
        full_spec.rnd_type="uniform" ;
        full_spec.rnd_mean=0.5;
        full_spec.rnd_var=0.0;


        float[][] tmp = rules.get(0);
        String shortname = this.name.substring(0,3);
        in_layer = new Layer(tmp.length, new LayerSpec(false), excite_unit_spec, HIDDEN, shortname + " In (in)");
        inh_layer = new Layer(rules.size(), new LayerSpec(false), auto_spec, HIDDEN, shortname + " Inhib (in)");
        disinh_layer = new Layer(rules.size(), new LayerSpec(false), excite_unit_spec, HIDDEN, shortname + " Disinh (in)");
        out_layer = new Layer(tmp[0].length, new LayerSpec(false), excite_unit_spec, HIDDEN, shortname + " Out (out)");
        
        int layerix = 0;
        layers = new Layer[4];
        layers[layerix++] = in_layer;
        layers[layerix++] = out_layer;
        layers[layerix++] = inh_layer;
        layers[layerix++] = disinh_layer;
        // connections = new ArrayListExt<Connection>(); //new Connection[rules.size()];
        for (int i = 0; i < rules.size(); ++i) {
            LayerConnection lc = new LayerConnection(in_layer, out_layer, full_spec);
            lc.weights(rules.get(i));
            rule_connections.add(lc);
            
            ConnectionSpec dc_spec = new ConnectionSpec(full_spec);
            dc_spec.pre_startix = i;
            dc_spec.pre_endix = i;
            dc_spec.type = GABA;
            DendriteConnection dc = new DendriteConnection(inh_layer, lc, dc_spec);
            inh_connections.add(dc);
        }
        ConnectionSpec oto_spec = new ConnectionSpec();
        oto_spec.proj = "1to1";
        LayerConnection disinh_conn = new LayerConnection(disinh_layer, inh_layer, oto_spec);
        inh_connections.add(disinh_conn);
        
        
    }
    String name() {return name;}
    Layer[] layers() {return layers;}
    Connection[] connections() {
        ArrayListExt<Connection> combined = new ArrayListExt<Connection>();
        Connection[] retval = new Connection[
            rule_connections.size()
            + inh_connections.size()];
        combined.add(rule_connections);
        combined.add(inh_connections);
        combined.toArray(retval);
        return retval;
    }
    Layer layer(String l) {
        switch(l) {
            case INHIBITION:
                return inh_layer; // rule/dendrite inhibition
            case DISINHIBITION:
                return disinh_layer; // rule/dendrite inhibition
            case IN:
                return in_layer; // input
            case OUT:
                return out_layer; // output
            default:
                assert(false): "No layer named '" + l + "' defined, check spelling.";
                return null;
        }
    }

    void cycle() {   
    }

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(fill_col);
        stroke(fill_col + 20);
        rect(0, 0, boundary_w, boundary_h, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0,0);

        // draw the layers
        drawStrip(in_layer.getOutput(), in_layer.name);
        drawStrip(inh_layer.getOutput(), inh_layer.name);
        drawStrip(disinh_layer.getOutput(), disinh_layer.name);
        drawStrip(out_layer.getOutput(), out_layer.name);
        // draw the rules
        translate(0,30);
        pushMatrix();
        int ctr = 1;
        // for (float[][] o : rules) {
        //     drawColGrid(0, 0, 10, 2, "Rule " + ctr++, multiply(200, o));
        //     translate(50, 0);
        // }
        for(Object c: rule_connections) {
            float[][] w = ((Connection) c).weights();
            drawColGrid(0, 0, 10, 2, "Rule " + ctr++, multiply(200, w));
            translate(50, 0);
        }
        popMatrix();
        
        
        popMatrix();
    }

    

    

}
