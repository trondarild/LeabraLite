class EffortRegulationModel implements NetworkModule {
    /** 
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
    
    Layer[] layers;
    Connection[] connections = new Connection[1];
    int inputvecsize = 23; // taskctx:3 tempctx:2 pos:2 shape: 4 color:4 number:10 valence:2; total 23
    int outputsize = 4;
    int effortsize = 5;
    int task_ctx_size = 3;
    int temp_ctx_size = 2;
    int position_size = 2;
    int shape_size = 4;
    int color_size = 4;
    int number_size = 10;
    int valence_size = 2;

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
    

    // connections
    ConnectionSpec full_spec = new ConnectionSpec();
    LayerConnection in_out_conn; // population to gain
    

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

        // layers
        in_layer = new Layer(inputvecsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "In (occipital ctx)");
        out_layer = new Layer(outputsize, new LayerSpec(false), excite_unit_spec, HIDDEN, "Out (target pos)");
        task_ctx_layer = new Layer(task_ctx_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Task_ctx");
        temp_ctx_layer = new Layer(temp_ctx_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Temp_ctx");
        shape_layer = new Layer(shape_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Shape");
        color_layer = new Layer(color_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Color");
        number_layer = new Layer(number_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Number");
        valence_layer = new Layer(valence_size, new LayerSpec(false), excite_unit_spec, HIDDEN, "Valence");
        
        layers = new Layer[8];
        int ix = 0;
        layers[ix++] = in_layer;
        layers[ix++] = out_layer;
        layers[ix++] = task_ctx_layer;
        layers[ix++] = temp_ctx_layer;
        layers[ix++] = shape_layer;
        layers[ix++] = color_layer;
        layers[ix++] = number_layer;
        layers[ix++] = valence_layer;
        
        assert(ix == layers.length) : "ix: " + ix + " layers.length: " + layers.length;

        in_out_conn = new LayerConnection(in_layer, out_layer, full_spec);
        connections[0] = in_out_conn;
        
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
        ale.add(layers);
        Layer[] retval = new Layer[ale.size()];
        ale.toArray(retval);
        return retval;

        /*
        Layer[] decdemandlayers = dec_dmnd_rule_mod.layers();
        Layer[] wisconsinlayers = wisconsin_rule_mod.layers();
        Layer[] stoplayers = stop_task_rule_mod.layers();
        Layer[] retval = new Layer[
            layers.length 
            + decdemandlayers.length
            + wisconsinlayers.length
            + stoplayers.length];
        int ctr = 0;
        for (Layer o : decdemandlayers) 
            retval[ctr++] = o;
        for (Layer o : wisconsinlayers) 
            retval[ctr++] = o;
        for (Layer o : stoplayers) 
            retval[ctr++] = o;
        for (Layer o : layers) 
            retval[ctr++] = o;
        return retval;
        */
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
        ale.add(connections);
        Connection[] retval = new Connection[ale.size()];
        ale.toArray(retval);
        return retval;
        /*
        Connection[] decdemandconns = dec_dmnd_rule_mod.connections();
        Connection[] wisconsinconns = wisconsin_rule_mod.connections();
        Connection[] stopconns = stop_task_rule_mod.connections();
        Connection[] retval = new Connection[
            connections.length 
            + decdemandconns.length
            + wisconsinconns.length
            + stopconns.length];
        int ctr = 0;
        for (Connection o : decdemandconns) 
            retval[ctr++] = o;
        for (Connection o : wisconsinconns) 
            retval[ctr++] = o;
        for (Connection o : stopconns) 
            retval[ctr++] = o;
        for (Connection o : connections) 
            retval[ctr++] = o;
        
        return retval;
        */
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
        scale(0.85);
        drawStrip(task_ctx_layer.output(), task_ctx_layer.name);
        translate(150, -20);
        drawStrip(temp_ctx_layer.output(), temp_ctx_layer.name);
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
