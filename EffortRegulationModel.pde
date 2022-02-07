class EffortRegulationModel implements NetworkModule {
    /** 
        * 2022-02-04:
            * add re-assignable context module that mediates disinh of active rule for active task
        * 2022-02-03:
            * Next;
                * Disinhibition of specific rules based on context(dec demand) or reward (wisconsin)
                * Effort-changeable context population
        * 2022-02-01:
            * Next:
                * connections from input to task rules - ok
                * dendrite connection from task ctx to conn from number to dec demand and shp-col-num to wisconsin - ok
        * 2022-01-31: 
            * For now implement as module; later incorporate 
                network too, so can be placed in context with 
                an experimental task
            * This should not be pushed to the LeabraLite repository when 
                complete; push to a dedicated repo for the acc. paper
            * if make changes to LL framework, stash the changes and push
                to main branch; only push the model to the adeno branch
    */

    static final String IN = "in";
    static final String OUT = "out";
    
    String name = "EffortRegulationModel";
    
    ArrayListExt<Layer> layers;
    // Connection[] connections; // = new Connection[1];
    ArrayListExt<Connection> connections;
    int inputvecsize = 27; // taskctx:3 tempctx:2 pos:2 shape: 4 color:4 number:10 valence:2; total 23
    int outputsize = 4;
    int effortsize = 5;
    int task_ctx_size = 3;
    int temp_ctx_size = 2;
    int position_size = 2;
    int shape_size = 4;
    int color_size = 4;
    int number_size = 10;
    int valence_size = 2;
    int rulectx_size = 3; // handle max rules per task ctx

    int fill_col = 60;
    int boundary_w = 900; 
    int boundary_h = 1200;

    // rule topologies
    // decision demand task
    float[][] oddevenrule = {
        {1,0,1,0,1,0,1,0,1,0},
        {0,1,0,1,0,1,0,1,0,1}//zeros(10)
    };
    float[][] lt5rule = {
        {1,1,1,1,0,0,0,0,0,0},
        {0,0,0,0,1,1,1,1,1,1}
    }; 
    
    // 
    float[][] wisconsin_shape_rule = {
        {0,0,0,0, 0,0,0,0, 1,0,0,0}, 
        {0,0,0,0, 0,0,0,0, 0,1,0,0}, 
        {0,0,0,0, 0,0,0,0, 0,0,1,0}, 
        {0,0,0,0, 0,0,0,0, 0,0,0,1}, 
    };
    float[][] wisconsin_color_rule = {
        {0,0,0,0, 1,0,0,0, 0,0,0,0}, 
        {0,0,0,0, 0,1,0,0, 0,0,0,0}, 
        {0,0,0,0, 0,0,1,0, 0,0,0,0}, 
        {0,0,0,0, 0,0,0,1, 0,0,0,0}, 
    };
    float[][] wisconsin_number_rule = {
        {1,0,0,0, 0,0,0,0, 0,0,0,0}, 
        {0,1,0,0, 0,0,0,0, 0,0,0,0}, 
        {0,0,1,0, 0,0,0,0, 0,0,0,0}, 
        {0,0,0,1, 0,0,0,0, 0,0,0,0}, 
    };

    float[][] stop_task_rule = { // green is go, red is stop
        {1, 0},
        {0, 1}
    };



    // modules
    RuleModule dec_dmnd_rule_mod;
    RuleModule wisconsin_rule_mod;
    RuleModule stop_task_rule_mod;

    ValenceLearningModule val_learning_mod;

    EffortModule effort_mod;
    ChoiceModule target_choice_mod;
    ChoiceModule beh_choice_mod; // check if can be used
    BasalGangliaModule bg_mod; 
    ModeModule rule_ctx_mod; // active rule for each task

    // Reservoirs
    // Reservoir effort_adeno_res;
    // Reservoir bg_adeno_res;

    // units
    UnitSpec excite_unit_spec = new UnitSpec();

    // layers
    Layer in_layer; // used for translation to pop code to engage effort
    Layer task_ctx_layer;
    Layer temp_ctx_layer;
    Layer position_layer;
    Layer shape_layer;
    Layer color_layer;
    Layer number_layer;
    Layer valence_layer;
    Layer out_layer;

    Layer rulectx_prederror_layer; // used to drive effortful rule context
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    ConnectionSpec oto_spec;
    LayerConnection in_out_conn; // population to gain

    LayerConnection inp_task_ctx_conn; // divide up input vec so see what simulation is
    LayerConnection inp_temp_ctx_conn;
    LayerConnection inp_position_conn;
    LayerConnection inp_shape_conn;
    LayerConnection inp_color_conn;
    LayerConnection inp_number_conn;
    LayerConnection inp_valence_conn;

    LayerConnection inp_decdem_rule_conn; // connections to specific rule modules
    LayerConnection inp_wisc_rule_conn;
    LayerConnection inp_stop_rule_conn;

    LayerConnection task_ctx_decdem_conn; // connections to disinh all rules in rule modules
    LayerConnection task_ctx_wisc_conn;
    LayerConnection task_ctx_stop_conn;

    LayerConnection effort_rule_ctx_conn; // effortful change of rules
    LayerConnection negvalence_rulectxprederror_conn; // negative valence excites prediction error, driving effort
    LayerConnection rulectx_prederror_conn;
    LayerConnection prederror_effortmagn; // drives magnitude of effort
    
    // DendriteConnection task_ctx_

    

    EffortRegulationModel() {
        this.init();
    }

    EffortRegulationModel(String name) {
        
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

        oto_spec = new ConnectionSpec(full_spec);
        oto_spec.proj = "1to1";

        // modules
        ArrayList<float[][]> rulelist = new ArrayList<float[][]>();
        rulelist.add(transpose(oddevenrule));
        rulelist.add(transpose(lt5rule));
        dec_dmnd_rule_mod = new RuleModule(rulelist, "Decision demand rules (pfc)");

        rulelist = new ArrayList<float[][]>();
        rulelist.add(transpose(wisconsin_shape_rule));
        rulelist.add(transpose(wisconsin_number_rule));
        rulelist.add(transpose(wisconsin_color_rule));
        wisconsin_rule_mod = new RuleModule(rulelist, "Wisconsin task rules (pfc)");

        rulelist = new ArrayList<float[][]>();
        rulelist.add(transpose(stop_task_rule));
        stop_task_rule_mod = new RuleModule(rulelist, "Stop task rules (pfc)");

        effort_mod = new EffortModule(effortsize, "Effort (anterior insula)");
        target_choice_mod = new ChoiceModule("Target choice (ofc)");
        val_learning_mod = new ValenceLearningModule(position_size, "Valence learning (acc)");
        bg_mod = new BasalGangliaModule(3, "Motivation (bg)");
        rule_ctx_mod = new ModeModule(rulectx_size, "Rule context (pfc)");

        // layers
        in_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "In (occipital ctx)");
        out_layer = new Layer(outputsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Out (target pos)");
        task_ctx_layer = new Layer(task_ctx_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Task_ctx");
        temp_ctx_layer = new Layer(temp_ctx_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Temp_ctx");
        position_layer = new Layer(position_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Position");
        shape_layer = new Layer(shape_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Shape");
        color_layer = new Layer(color_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Color");
        number_layer = new Layer(number_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Number");
        valence_layer = new Layer(valence_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Valence");

        rulectx_prederror_layer = new Layer(rulectx_size, new LayerSpec(true), excite_unit_spec, HIDDEN, "Rule pred error");
        
        layers = new ArrayListExt<Layer>(); //new Layer[9];
        int ix = 0;
        layers.add(in_layer);
        layers.add(out_layer);
        layers.add(task_ctx_layer);
        layers.add(temp_ctx_layer);
        layers.add(position_layer);
        layers.add(shape_layer);
        layers.add(color_layer);
        layers.add(number_layer);
        layers.add(valence_layer);
        layers.add(rulectx_prederror_layer);
        
        // assert(ix == layers.length) : "ix: " + ix + " layers.length: " + layers.length;

        in_out_conn = new LayerConnection(in_layer, out_layer, full_spec);

        ConnectionSpec[] tmpspec = new ConnectionSpec[7];
        ix = 0;
        tmpspec[ix] = new ConnectionSpec(oto_spec);
        tmpspec[ix].pre_startix = 0;
        tmpspec[ix].pre_endix = 2;
        tmpspec[ix].post_startix = 0;
        tmpspec[ix].post_endix = 2;
        inp_task_ctx_conn = new LayerConnection(in_layer, task_ctx_layer, tmpspec[ix++]);
        tmpspec[ix] = new ConnectionSpec(oto_spec);
        tmpspec[ix].pre_startix = 3;
        tmpspec[ix].pre_endix = 4;
        tmpspec[ix].post_startix = 0;
        tmpspec[ix].post_endix = 1;
        inp_temp_ctx_conn = new LayerConnection(in_layer, temp_ctx_layer, tmpspec[ix++]);
        
        tmpspec[ix] = new ConnectionSpec(oto_spec);
        tmpspec[ix].pre_startix = 5;
        tmpspec[ix].pre_endix = 6;
        tmpspec[ix].post_startix = 0;
        tmpspec[ix].post_endix = 1;
        inp_position_conn = new LayerConnection(in_layer, position_layer, tmpspec[ix++]);
        
        tmpspec[ix] = new ConnectionSpec(oto_spec);
        tmpspec[ix].pre_startix = 7;
        tmpspec[ix].pre_endix = 10;
        tmpspec[ix].post_startix = 0;
        tmpspec[ix].post_endix = 3;
        inp_shape_conn = new LayerConnection(in_layer, shape_layer, tmpspec[ix++]);
        tmpspec[ix] = new ConnectionSpec(oto_spec);
        tmpspec[ix].pre_startix = 11;
        tmpspec[ix].pre_endix = 14;
        tmpspec[ix].post_startix = 0;
        tmpspec[ix].post_endix = 3;
        inp_color_conn = new LayerConnection(in_layer, color_layer, tmpspec[ix++]);
        tmpspec[ix] = new ConnectionSpec(oto_spec);
        tmpspec[ix].pre_startix = 15;
        tmpspec[ix].pre_endix = 24;
        tmpspec[ix].post_startix = 0;
        tmpspec[ix].post_endix = 9;
        inp_number_conn = new LayerConnection(in_layer, number_layer, tmpspec[ix++]);
        tmpspec[ix] = new ConnectionSpec(oto_spec);
        tmpspec[ix].pre_startix = 25;
        tmpspec[ix].pre_endix = 26;
        tmpspec[ix].post_startix = 0;
        tmpspec[ix].post_endix = 1;
        inp_valence_conn = new LayerConnection(in_layer, valence_layer, tmpspec[ix++]);

        ConnectionSpec decdem_spec = new ConnectionSpec(oto_spec);
        decdem_spec.pre_startix = 15;
        decdem_spec.pre_endix = 24;
        decdem_spec.post_startix = 0;
        decdem_spec.post_endix = 9;
        inp_decdem_rule_conn = new LayerConnection(in_layer, dec_dmnd_rule_mod.layer("in"), decdem_spec);

        ConnectionSpec wisc_spec = new ConnectionSpec(oto_spec);
        wisc_spec.pre_startix = 7;
        wisc_spec.pre_endix = 18;
        wisc_spec.post_startix = 0;
        wisc_spec.post_endix = 11;
        inp_wisc_rule_conn = new LayerConnection(in_layer, wisconsin_rule_mod.layer("in"), wisc_spec);

        ConnectionSpec stop_spec = new ConnectionSpec(oto_spec);
        stop_spec.pre_startix = 11;
        stop_spec.pre_endix = 12;
        stop_spec.post_startix = 0;
        stop_spec.post_endix = 1;
        inp_stop_rule_conn = new LayerConnection(in_layer, stop_task_rule_mod.layer("in"), stop_spec);

        ConnectionSpec rule_selection_spec = new ConnectionSpec(full_spec);
        rule_selection_spec.type = GABA;
        rule_selection_spec.pre_startix = 0;
        rule_selection_spec.pre_endix = 0;
        task_ctx_decdem_conn = new LayerConnection(in_layer, dec_dmnd_rule_mod.layer("inhibition"), rule_selection_spec);
        rule_selection_spec = new ConnectionSpec(rule_selection_spec);
        rule_selection_spec.pre_startix = 1;
        rule_selection_spec.pre_endix = 1;
        task_ctx_wisc_conn = new LayerConnection(in_layer, wisconsin_rule_mod.layer("inhibition"), rule_selection_spec);
        rule_selection_spec = new ConnectionSpec(rule_selection_spec);
        rule_selection_spec.pre_startix = 2;
        rule_selection_spec.pre_endix = 2;
        task_ctx_stop_conn = new LayerConnection(in_layer, stop_task_rule_mod.layer("inhibition"), rule_selection_spec);

        float[][] rulectx_weights = tileCols(effortsize, id(rulectx_size));
        effort_rule_ctx_conn = new LayerConnection(effort_mod.layer("gain"), rule_ctx_mod.layer("mode"), full_spec);
        ConnectionSpec rulectx_spec = new ConnectionSpec();
        rulectx_spec.proj = "full";
        rulectx_spec.pre_startix = 1; // only use negative valence to drive prediction error
        rulectx_spec.pre_endix = 1;
        rulectx_spec.rnd_var= 0.1; // only a little variation to drive wta
        negvalence_rulectxprederror_conn = new LayerConnection(valence_layer, rulectx_prederror_layer, rulectx_spec);

        ConnectionSpec oto_inh_spec = new ConnectionSpec(oto_spec);
        oto_inh_spec.type = GABA;
        rulectx_prederror_conn = new LayerConnection(rule_ctx_mod.layer("mode"), rulectx_prederror_layer, oto_inh_spec);
        prederror_effortmagn = new LayerConnection(rulectx_prederror_layer, effort_mod.layer("magnitude"), full_spec);
        // effort_rule_ctx_conn.weights(rulectx_weights);
        // TODO: 
        // color input[0,1] to rulectx_prederror
        // dendr inh population
        // dendr connection to effort_rule_ctx_conn
        // inh conn from prederror to dendr inh population
        
        ix = 0;
        // connections = new Connection[8];
        connections = new ArrayListExt<Connection>();
        connections.add(in_out_conn);
        connections.add(inp_task_ctx_conn);
        connections.add(inp_temp_ctx_conn);
        connections.add(inp_position_conn);
        connections.add(inp_shape_conn);
        connections.add(inp_color_conn);
        connections.add(inp_number_conn);
        connections.add(inp_valence_conn);
        
        connections.add(inp_decdem_rule_conn);
        connections.add(inp_wisc_rule_conn);
        connections.add(inp_stop_rule_conn);

        connections.add(task_ctx_decdem_conn);
        connections.add(task_ctx_wisc_conn);
        connections.add(task_ctx_stop_conn);

        connections.add(effort_rule_ctx_conn);
        connections.add(prederror_effortmagn);
    
    }

    String name() {return name;}
    
    Layer[] layers() {
        ArrayListExt<Layer> ale = new ArrayListExt<Layer>();
        ale.add(dec_dmnd_rule_mod.layers());
        ale.add(wisconsin_rule_mod.layers());
        ale.add(stop_task_rule_mod.layers());
        ale.add(effort_mod.layers());
        ale.add(target_choice_mod.layers());
        ale.add(val_learning_mod.layers());
        ale.add(bg_mod.layers());
        ale.add(rule_ctx_mod.layers());
        ale.add(layers);
        Layer[] retval = new Layer[ale.size()];
        ale.toArray(retval);
        return retval;
    }

    Connection[] connections() {
        ArrayListExt<Connection> ale = new ArrayListExt<Connection>();
        ale.add(dec_dmnd_rule_mod.connections());
        ale.add(wisconsin_rule_mod.connections());
        ale.add(stop_task_rule_mod.connections());
        ale.add(effort_mod.connections());
        ale.add(target_choice_mod.connections());
        ale.add(val_learning_mod.connections());
        ale.add(bg_mod.connections());
        ale.add(rule_ctx_mod.connections());
        ale.add(connections);
        Connection[] retval = new Connection[ale.size()];
        ale.toArray(retval);
        return retval;
    }
    
    Layer layer(String l) {
        switch(l) {
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
        dec_dmnd_rule_mod.cycle();
    }

    void draw() {
        translate(0, 20);
        pushMatrix();
        
        // draw a rounded rectangle around
        pushStyle();
        fill(fill_col);
        stroke(100);
        rect(0, 0, boundary_w, boundary_h, 10);
        popStyle();

        // add name
        translate(10, 20);
        text(this.name, 0, 0);

        // draw the layers
        drawStrip(in_layer.getOutput(), in_layer.name);
        translate(0,20);

        pushMatrix();
        scale(0.75);
        drawStrip(task_ctx_layer.output(), task_ctx_layer.name);
        translate(150, -20);
        drawStrip(temp_ctx_layer.output(), temp_ctx_layer.name);
        translate(150, -20);
        drawStrip(position_layer.output(), position_layer.name);
        translate(150, -20);
        drawStrip(shape_layer.output(), shape_layer.name);
        translate(170, -20);
        drawStrip(color_layer.output(), color_layer.name);
        translate(170, -20);
        drawStrip(number_layer.output(), number_layer.name);
        translate(250, -20);
        drawStrip(valence_layer.output(), valence_layer.name);
        popMatrix();

        translate(0, 20);

        pushMatrix();
        dec_dmnd_rule_mod.fill_col = this.fill_col + 10;
        dec_dmnd_rule_mod.boundary_w = 270;
        dec_dmnd_rule_mod.boundary_h = 250;
        dec_dmnd_rule_mod.draw();
        translate(290, -20);
        wisconsin_rule_mod.fill_col = this.fill_col + 10;
        wisconsin_rule_mod.boundary_w = 300;
        wisconsin_rule_mod.boundary_h = 250;
        wisconsin_rule_mod.draw();
        translate(320, -20);
        stop_task_rule_mod.fill_col = this.fill_col + 10;
        stop_task_rule_mod.boundary_w = 250;
        stop_task_rule_mod.boundary_h = 250;
        stop_task_rule_mod.draw();
        popMatrix();

        
        translate(0,270);
        pushMatrix();
        rule_ctx_mod.fill_col = this.fill_col + 10;
        rule_ctx_mod.boundary_w = 270;
        rule_ctx_mod.draw();
        translate(0, 100);
        drawStrip(rulectx_prederror_layer.output(), rulectx_prederror_layer.name());
        popMatrix();

        pushMatrix();
        translate(290, 0);
        val_learning_mod.fill_col = this.fill_col + 10;
        val_learning_mod.boundary_w = 300;
        val_learning_mod.draw();
        popMatrix();

        translate(0, 370);
        pushMatrix();
        effort_mod.boundary_w = 270;
        effort_mod.fill_col = this.fill_col + 10;
        effort_mod.draw();
        translate(290, -20);
        target_choice_mod.boundary_w = 300;
        target_choice_mod.fill_col = this.fill_col + 10;
        target_choice_mod.draw();
        popMatrix();

        translate(0, 130);
        bg_mod.fill_col = this.fill_col + 10;
        bg_mod.boundary_w = 270;
        bg_mod.draw();


        translate(0,220);
        drawStrip(out_layer.getOutput(), out_layer.name);
        
        popMatrix();
    }

    

    

}
