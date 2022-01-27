/** Connections
Branch: con update
*/
import java.lang.Math; // pow

final int NONE = 0;
final int DOPAMINE = 1; // default
final int SEROTONIN = 2;
final int NORADRENALIN = 3;
final int ACETYLCHOLINE = 4;
final int ADENOSINE = 5;
final int GLUTAMATE = 6;
final int GABA = 7;
final int OPIOID = 8;
final int ATP = 9;



class ConnectableParams {
    float avg_s_eff; // linear mixing of avg_s -short term avg act- and avg_m -medium term avg act-
    float avg_m; // medium-term average activity
    float act_ext; // forced activity
    float act; // activity
    
    float avg_l_lrn;
    float avg_l; // long term average activity ?
}

interface Connectable {
    ConnectableParams params();
    void add_inhibitory(float a); // glutamate
    void add_excitatory(float a); // gaba
    void add_modulator(int type, float a); 
    float act();
    float act_ext();

}

interface ConnectableComposite {
    String name();
   Connectable[] units(); 
   float avg_act_p_eff();
   void add_from_connections(Connection from);
   void add_to_connections(Connection to);
   ArrayList<Connection> from_connections();
   ArrayList<Connection> to_connections();
   void cycle(String phase);
}



abstract class Link{
    String name;
    float wt = 0;
    float fwt = 0; // note inverse sigmoid is applied to this, and dwt is added to; then sigmoid is applied in weight update
    float dwt = 0;
    float lrate_mod = 1.0; // TAT modulation of ConnSpec learning rate
    int[] index;
    int key;
    
    Link(float w0, float fw0, int[] index){
        
        //this.pre = pre_unit;
        //this.post = post_unit;
        this.wt = w0;
        this.fwt = fw0;
        this.dwt = 0.f;
        this.key = 0;
        this.index = index;
    }

    abstract Connectable pre();
    abstract Connectable post();
    

}

class UnitLink extends Link {
    Unit pre;
    Unit post;

    UnitLink(Connectable pre_unit, Connectable post_unit, float w0, float fw0, int[] index) {
        super(w0, fw0, index);
        
        this.pre = (Unit)pre_unit;
        this.post = (Unit)post_unit;
        this.name = pre.name + " -> " + post.name;
    }

    Connectable pre()  {return this.pre;};
    Connectable post() {return this.post;};
    
}

class WeightLink extends Link {
    Unit pre;
    ConnectableWeight post;

    WeightLink(Connectable pre_unit, Connectable post_unit, float w0, float fw0, int[] index) {
        super(w0, fw0, index);
        
        this.pre = (Unit)pre_unit;
        this.post = (ConnectableWeight)post_unit;
        this.name = pre.name + " -> " + post.name;
    }
    Connectable pre()  {return this.pre;};
    Connectable post() {return this.post;};
}



class IntegratorLink extends Link {
    Unit unit;
    LeakyIntegrator integrator;
    boolean from_unit;

    IntegratorLink(Connectable pre_unit, Connectable post_unit, float w0, float fw0, int[] index) {
        super(w0, fw0, index);
        
        if(pre_unit instanceof Unit && post_unit instanceof LeakyIntegrator){
            unit = (Unit)pre_unit;
            integrator = (LeakyIntegrator) post_unit;
            from_unit = true;
            this.name = unit.name + " -> " + integrator.name;
        } else if (pre_unit instanceof LeakyIntegrator && post_unit instanceof Unit){
            unit = (Unit) post_unit;
            integrator = (LeakyIntegrator) pre_unit;
            from_unit = false;
            this.name = integrator.name + " -> " + unit.name;
        }
    }

    Connectable pre() { return from_unit ? unit : integrator;}
    Connectable post() { return from_unit ? integrator : unit;}

}




abstract class Connection  {
    String name;
    //Layer pre;
    //Layer post;
    ArrayList<Link> links = new ArrayList<Link>();
    float wt_scale_act;
    float wt_scale_rel_eff;
    ConnectionSpec spec;

    Connection(){
        this.spec = new ConnectionSpec();
    }
    
    Connection( ConnectionSpec spec){
        /* """
        Parameters:
            pre_layer   the layer sending its activity.
            post_layer  the layer receiving the activity.
        """
        */ 
        
        //this.pre   = pre_layer;
        //this.post  = post_layer;

        // name = pre().name() + " -> " + post().name();
        
        this.spec  = spec;
        if (this.spec == null)
            this.spec = new ConnectionSpec();

        this.wt_scale_act = 1.0;  // scaling relative to activity.
        this.wt_scale_rel_eff = 0;  // effective relative scaling weight, once other connections
                                      // are taken into account (computed by the network).

        //this.spec.projection_init(this);

        //pre_layer.from_connections.add(this);
        //post_layer.to_connections.add(this);

        
    }

    abstract ConnectableComposite pre();
    abstract ConnectableComposite post();
    abstract Link createLink(Connectable pre, Connectable post, float w0, float fw0, int[] ix);

    float wt_scale(){
        //try:
        return this.wt_scale_act * this.wt_scale_rel_eff;
        // except TypeError as e:
        //     println("Error: did you correctly run the network.build() method?");
        //     raise e
    }

    float[][] weights(){
        // """Return a matrix of the links weights"""
        // TODO add support for general topologies
        int pre_end = this.spec.pre_endix == -1 ? this.pre().units().length-1 : this.spec.pre_endix - this.spec.pre_startix + 1;
        int post_end = this.spec.post_endix == -1 ? this.post().units().length-1 : this.spec.post_endix - this.spec.post_startix + 1;
        
        float[][] W;
        if (this.spec.proj.toLowerCase() == "1to1"){
            //return np.array([[link.wt for link in this.links]])
            W = zeros(1, links.size());
            for (int i = 0; i < links.size(); ++i) {
                W[0][i] = links.get(i).wt;
            }
            return W;
        }
        else { // proj == 'full'
            W = zeros(this.pre().units().length, this.post().units().length);  // weight matrix
            // link_it = iter(this.links)  // link iterator
            // for i, pre_u in enumerate(this.pre.units):
            //     for j, post_u in enumerate(this.post.units):
            //         W[i, j] = next(link_it).wt
            int l = 0;
            for (int j = 0; j <= pre_end; ++j) { // sources
                for (int i = 0; i <= post_end; ++i) { // targets
                    //W[j][i] = links.get(l++).wt;
                    int[] ix = links.get(l).index;
                    float wt = links.get(l++).wt;
                    W[ix[0]][ix[1]] = wt;
                }
                
            }
            return W;
        }
    }

    void weights(float[][] value){
        // """Override the links weights""" 
        // value: source as columns, destination as rows
        // TAT: use this to manually set connections to activate beh.
        int pre_end = this.spec.pre_endix == -1 ? this.pre().units().length-1 : this.spec.pre_endix - this.spec.pre_startix + 1;
        int post_end = this.spec.post_endix == -1 ? this.post().units().length-1 : this.spec.post_endix - this.spec.post_startix + 1;
        
        if (this.spec.proj.toLowerCase() == "1to1"){
            assert (value[0].length == this.links.size());
            //for wt, link in zip(value, this.links):
            for (int i = 0; i < value.length; ++i) {
                links.get(i).wt  = value[0][i];
                links.get(i).fwt = this.spec.sig_inv(value[0][i]);
            }
        }
        else{  // proj == 'full'
            // link_it = iter(this.links)  // link iterator
            assert (value.length * value[0].length == this.links.size()) : 
              this.name + ": inp length = " + value.length * value[0].length + "; links size = " + this.links.size();
            // for i, pre_u in enumerate(this.pre.units):
            //     for j, post_u in enumerate(this.post.units):
            //         link = next(link_it)
            //         link.wt = value[i][j]
            //         link.fwt = this.spec.sig_inv(value[i][j])
            int l = 0;
            for (int j = 0; j <= pre_end; ++j) { // sources
                for (int i = 0; i <= post_end; ++i) { // targets
                    links.get(l).wt  = value[j][i];
                    links.get(l).fwt = this.spec.sig_inv(value[j][i]);
                    
                    links.get(l).index[0] = j;
                    links.get(l).index[1] = i; 
                    l++;
                }
            }
        }
    }


    void learn(){
        this.spec.learn(this);
    }

    public void cycle(){
        this.spec.cycle(this);
    }

    void compute_netin_scaling(){
        this.spec.compute_netin_scaling(this);
    }
}


class LayerConnection extends Connection implements ConnectableComposite {
    Layer pre;
    Layer post;
    ConnectableWeight[] units; // to-weights are connectable for inhibition
    ArrayList<Connection> from_connections = new ArrayList<Connection>(); // not applicable and should be empty, but keep for compatibility
    ArrayList<Connection> to_connections = new   ArrayList<Connection>();
    float avg_act_p_eff;

    LayerConnection(Layer pre_layer, Layer post_layer, ConnectionSpec spec) {
        super(spec);
        pre = pre_layer;
        post = post_layer;
        pre.add_from_connections(this);
        post.add_to_connections(this);
        
        
        this.spec.projection_init(this);
        this.name = pre.name + " -> " + post.name;
        
        units = new ConnectableWeight[this.links.size()];
        for (int i = 0; i < units.length; ++i) {
            units[i] = new ConnectableWeight((UnitLink)this.links.get(i)); // default is on==1
            //units[i].wt = this.links.get(i).wt;
        }
    }

    LayerConnection(Layer pre_layer, Layer post_layer, ConnectionSpec spec, ConnectableWeightSpec unit_spec) {
        super(spec);
        pre = pre_layer;
        post = post_layer;
        pre.add_from_connections(this);
        post.add_to_connections(this);
        
        
        this.spec.projection_init(this);
        this.name = pre.name + " -> " + post.name;
        
        units = new ConnectableWeight[this.links.size()];
        for (int i = 0; i < units.length; ++i) {
            units[i] = new ConnectableWeight((UnitLink)this.links.get(i), unit_spec); // default is on==1
            //units[i].wt = this.links.get(i).wt;
        }
    }

    // applicable to Layers    
    ConnectableComposite pre() {return pre;}
    ConnectableComposite post() {return post;}
    Link createLink(Connectable pre, Connectable post, float w0, float fw0, int[] ix) {
        return new UnitLink(pre, post, w0, fw0, ix);        
    }


    // applicable to ConnectableWeights
    String name() {return pre.name + " -> " + post.name;}
    Connectable[] units() {return units;} 
    float avg_act_p_eff() {return avg_act_p_eff;}
    void add_from_connections(Connection from) { /* not applicable */}
    void add_to_connections(Connection to) {
        // println(this.name + " add: " + to.name);
        //to_connections.add((DendriteConnection)to);
        assert(to instanceof DendriteConnection): "Layerconnection can only be connected to DendriteConnections";
        to_connections.add(to);
    }
    ArrayList<Connection> from_connections() {return from_connections;}
    ArrayList<Connection> to_connections() {return to_connections;}
    
    
    void cycle(String phase) {
      // TODO for learning; minus, plus phase for connectableweights
      // this.cycle();
    }

    public void cycle() {
        
        // take care of the connectable weight units
        // TODO: fix
        for (ConnectableWeight w: units){
            // println(this.name + "_" + w.name + " bef: " + w.link.wt + "; " + w.act());
            // //w.wt = w.link.wt;
            // w.link.wt = limitval(0, 1, w.wt * w.act());
            // println(this.name + " after: " + w.link.wt);
            w.calculate_net_in();
            w.cycle();
        }
        super.cycle();
    }

    void weights(float[][] value) {
        // """Override the links weights""" 
        // value: source as columns, destination as rows
        
        
        int pre_end = this.spec.pre_endix == -1 ? this.pre().units().length-1 : this.spec.pre_endix - this.spec.pre_startix + 1;
        int post_end = this.spec.post_endix == -1 ? this.post().units().length-1 : this.spec.post_endix - this.spec.post_startix + 1;
        
        if (this.spec.proj.toLowerCase() == "1to1"){
            assert (value[0].length == this.links.size());
            //for wt, link in zip(value, this.links):
            for (int i = 0; i < value.length; ++i) {
                links.get(i).wt  = value[0][i];
                links.get(i).fwt = this.spec.sig_inv(value[0][i]);
                // update connectableweight
                units[i].wt = value[0][i];
            }
        }
        else{  // proj == 'full'
            // link_it = iter(this.links)  // link iterator
            assert (value.length * value[0].length == this.links.size()) : 
              this.name + ": inp length = " + value.length * value[0].length + "; links size = " + this.links.size();
            // for i, pre_u in enumerate(this.pre.units):
            //     for j, post_u in enumerate(this.post.units):
            //         link = next(link_it)
            //         link.wt = value[i][j]
            //         link.fwt = this.spec.sig_inv(value[i][j])
            int l = 0;
            for (int j = 0; j <= pre_end; ++j) { // sources
                for (int i = 0; i <= post_end; ++i) { // targets
                    links.get(l).wt  = value[j][i];
                    links.get(l).fwt = this.spec.sig_inv(value[j][i]);
                    
                    links.get(l).index[0] = j;
                    links.get(l).index[1] = i; 
                    units[l].wt = value[j][i];
                    l++;
                }
            }
        }

        


    }

    void learn(){
        super.learn();
        // update weight on units if learning on
        if(this.spec.lrule!=""){
            for(ConnectableWeight cw: units){
                cw.wt = cw.link.wt;
            }
        }

    }
}

class DendriteConnection extends Connection  {
    Layer pre;
    LayerConnection post;
    //float[][] dest_weights;
    float avg_act_p_eff;

    DendriteConnection(Layer pre_layer, LayerConnection post_connection, ConnectionSpec spec){
        super(spec);
        this.pre   = pre_layer;
        this.post = post_connection;
        pre.add_from_connections(this);
        post.add_to_connections(this);
        
        //this.post  = post_layer;
        this.spec.projection_init(this);
        this.name = pre.name + " -> " + post.name;

      
    }


    ConnectableComposite pre() {return pre;}
    ConnectableComposite post() {return post;}
    Link createLink(Connectable pre, Connectable post, float w0, float fw0, int[] ix) {
        return new WeightLink(pre, post, w0, fw0, ix);
    }
    void learn() {
        //println("DendriteConn::learn");
        super.learn();
        // TODO
    }
}

class ReservoirConnection extends Connection {
    Reservoir res;
    Layer layer;
    boolean from_layer = true;
    float avg_act_p_eff;

    ReservoirConnection(Layer pre_layer, Reservoir post_res, ConnectionSpec spec) {
        super(spec);
        this.layer = pre_layer;
        this.res = post_res;
        this.name = layer.name + " -> " + res.name;
        layer.add_from_connections(this);
        res.add_to_connections(this);
        from_layer = true;
        
        this.spec.projection_init(this);
    }

    ReservoirConnection(Reservoir res, Layer layer, ConnectionSpec spec) {
        super(spec);
        assert(res != null && layer != null);
        this.layer = layer;
        this.res = res;
        this.name = res.name + " -> " + layer.name;
        res.add_from_connections(this);
        layer.add_to_connections(this);
        from_layer = false;
        
        this.spec.projection_init(this);
    }

    ConnectableComposite pre() { return from_layer ? layer : res; }
    ConnectableComposite post() { return from_layer ? res : layer; }

    Link createLink(Connectable pre, Connectable post, float w0, float fw0, int[] ix) {
        return new IntegratorLink(pre, post, w0, fw0, ix);
    }
}

class ConnectionSpec{
    String[] legal_proj = {"full", "1to1"};

    boolean inhibit    = false;   // if True, inhibitory connection
    String proj     = "full";  // connection pattern between units.
                            // Can be 'Full' or '1to1'. In the latter case,
                            // the layers must have the same size.
    int type = GLUTAMATE; // generalizes inhibit or exc

    // random initialization
    String rnd_type = "uniform"; // shape of the weight initialization
    float rnd_mean = 0.5;       // mean of the random variable for weights init.
    float rnd_var  = 0.25;      // variance (or ±range for uniform)

    // learning
    String lrule    = "" ;   // the learning rule to use (None or 'leabra')
    float lrate    = 0.01;    // learning rate TAT 2022-01-20: move to Link to support modulation per link

    // xcal learning
    float m_lrn    = 1.0;     // weighting of the error driven learning
    float d_thr    = 0.0001;  // threshold value for XCAL check-mark function
    float d_rev    = 0.1;     // reversal value for XCAL check-mark function (?)
    float sig_off  = 1.0;     // sigmoid offset
    float sig_gain = 6.0;     // sigmoid gain (noradrenalin?)  

    // netin scaling
    float wt_scale_abs = 1.0;  // absolute scaling weight: direct multiplier, strength of the connection
    float wt_scale_rel = 1.0;  // relative scaling weight, relative to other connections.

    // partial 
    int pre_startix = 0;
    int pre_endix = -1; // use all
    int post_startix = 0;
    int post_endix = -1; // use all;
    int[] pre_indeces; // set of population indeces
    int[] post_indeces;

    // for dendrite connections
    //float wt_scale_rel = 1.0;


    ConnectionSpec(){
        // TODO add params, get, set
    }

    ConnectionSpec(ConnectionSpec c) {
        // copy constructor
        // 
        
        this.inhibit = c.inhibit; 
        this.type = c.type;
        this.proj = c.proj;    
        this.rnd_type = c.rnd_type;
        this.rnd_mean = c.rnd_mean;
        this.rnd_var = c.rnd_var; 
        this.lrule = c.lrule;   
        this.lrate = c.lrate;   
        this.m_lrn = c.m_lrn;   
        this.d_thr = c.d_thr;   
        this.d_rev = c.d_rev;   
        this.sig_off = c.sig_off; 
        this.sig_gain = c.sig_gain;
        this.wt_scale_abs = c.wt_scale_abs;
        this.wt_scale_rel = c.wt_scale_rel;
        this.pre_startix = c.pre_startix;
        this.pre_endix = c.pre_endix;
        this.post_startix = c.post_startix;
        this.post_endix = c.post_endix;
        this.pre_indeces = c.pre_indeces != null ? copyArray(c.pre_indeces) : null;
        this.post_indeces = c.post_indeces != null ? copyArray(c.post_indeces) : null;
    }

    void cycle(Connection connection){
        // """Transmit activity."""
        for (Link link : connection.links){
            if (link.post().act_ext() ==0){ // activity not forced
                // println("conspec preswitch: wt_scale_abs= " + this.wt_scale_abs + "; wt_scale= " + connection.wt_scale() + "; link.wt= " + link.wt + "; link.pre().act()= " +link.pre().act() );            
                float scaled_act = this.wt_scale_abs * connection.wt_scale() * link.wt * link.pre().act();
                
                if(this.inhibit) this.type = GABA; // backward compatibility
                switch(this.type){
                    case GABA :
                        link.post().add_inhibitory(scaled_act);
                        break;	
                    case GLUTAMATE:
                        link.post().add_excitatory(scaled_act);
                        break;
                    default:
                        // println(link.name);
                        // println("conspec postswitch: " + this.wt_scale_abs + "; " + connection.wt_scale() + "; " + link.wt + "; " +link.pre().act() );
                        link.post().add_modulator(this.type, scaled_act);

                }
            }
        }
    }

    float rnd_wt(){
        // """Return a random weight, according to the specified distribution"""
        if (this.rnd_type == "uniform")
            return random(this.rnd_mean - this.rnd_var,
                                  this.rnd_mean + this.rnd_var);
        else if (this.rnd_type == "gaussian" ){
            float val = randomGaussian();
            return val * sqrt(this.rnd_var) + this.rnd_mean;
        }
        return 0;
    }

    void full_projection(Connection connection){
        // creating unit-to-unit links
        connection.links.clear();
        //for i, pre_u in enumerate(connection.pre.units):
        //    for j, post_u in enumerate(connection.post.units):
        if(pre_indeces != null && post_indeces != null) {
            // first approx, use lists for both pre and post
            for (int j: this.pre_indeces) {
                for(int i: this.post_indeces){
                    Connectable pre_u = connection.pre().units()[j];
                    Connectable post_u = connection.post().units()[i];
                    float w0 = this.rnd_wt();
                    float fw0 = this.sig_inv(w0);
                    int[] ix = {j, i};
                    
                    connection.links.add(connection.createLink(pre_u, post_u, w0, fw0, ix));
                }
            }
        }
        else {
            int pre_end = this.pre_endix == -1 ? connection.pre().units().length-1 : this.pre_endix;
            int post_end = this.post_endix == -1 ? connection.post().units().length-1 : this.post_endix;
            // TODO: add assert here
            for (int j = pre_startix; j <= pre_end; ++j) {
                for (int i = post_startix; i <= post_end; ++i) {
                    Connectable pre_u = connection.pre().units()[j];
                    Connectable post_u = connection.post().units()[i];
                    float w0 = this.rnd_wt();
                    float fw0 = this.sig_inv(w0);
                    int[] ix = {j, i};
                    connection.links.add(connection.createLink(pre_u, post_u, w0, fw0, ix));
                }
            }
        }
    }

    void onetoone_connection(Connection connection){        
        // TODO adapt to dendrite connection
        // creating unit-to-unit links
        
        connection.links.clear();
        if(pre_indeces != null && post_indeces != null) {
            
            assert(pre_indeces.length == post_indeces.length);
            for (int i = 0; i < pre_indeces.length; ++i) {
                Connectable pre_u = connection.pre().units()[pre_indeces[i]];
                Connectable post_u = connection.post().units()[post_indeces[i]];
                float w0 = this.rnd_wt();
                float fw0 = this.sig_inv(w0);
                int[] ix = {pre_indeces[i], post_indeces[i]};
                connection.links.add(connection.createLink(pre_u, post_u, w0, fw0, ix));
            }
        }
        else {
            // assert (connection.pre.units.length == connection.post.units.length);
            // TODO: add assert, checking valid start, ends
            int pre_end = this.pre_endix == -1 ? connection.pre().units().length-1 : this.pre_endix;
            int post_end = this.post_endix == -1 ? connection.post().units().length-1 : this.post_endix;
            assert (pre_end-this.pre_startix + 1 == post_end-this.post_startix + 1) : 
                connection.name + ": " + (pre_end-this.pre_startix + 1) 
                + " != " + (post_end-this.post_startix + 1);
            // for i, (pre_u, post_u) in enumerate(zip(connection.pre.units, connection.post.units)):
            // for (int i = 0; i < connection.pre.units.length; ++i) {
            for (int i = 0; i <= pre_end-this.pre_startix; ++i) {
                Connectable pre_u = connection.pre().units()[pre_startix + i];
                Connectable post_u = connection.post().units()[post_startix + i];
                float w0 = this.rnd_wt();
                float fw0 = this.sig_inv(w0);
                int[] ix = {pre_startix+i, post_startix+i};
                connection.links.add(connection.createLink(pre_u, post_u, w0, fw0, ix));
            }
        }
        println("end: " + connection.name);
        println();
            
    }

    void compute_netin_scaling(Connection connection){
        /* """Compute Netin Scaling

        See https://grey.colorado.edu/emergent/index.php/Leabra_Netin_Scaling for details.
        
        TODO: add support for partial connection
        
        """ */
        
        float pre_act_avg = connection.pre().avg_act_p_eff();
        // int pre_size = connection.pre.units.length;
        int pre_size = this.pre_endix==-1 ? connection.pre().units().length : this.pre_endix - this.pre_startix + 1;
        int n_links = connection.links.size();
        
        float sem_extra = 2.0; // constant
        int pre_act_n = max(1, int(pre_act_avg * pre_size + 0.5)); // estimated number of active units
        
        if (n_links == pre_size)
            connection.wt_scale_act = 1.0 / pre_act_n;
        else{
            
            int post_act_n_max = min(n_links, pre_act_n);
            float post_act_n_avg = max(1, pre_act_avg * n_links + 0.5);
            float post_act_n_exp = min(post_act_n_max, post_act_n_avg + sem_extra);
            connection.wt_scale_act = 1.0 / post_act_n_exp;
        }
    }

    void projection_init(Connection connection){
        if (this.proj == "full")
            this.full_projection(connection);
        if (this.proj == "1to1")
            this.onetoone_connection(connection);
    }

    void learn(Connection connection){
        // 2022-01-18: TODO add "cholinergic" learning rule that updates weights
        // based on cholinergic learning rate? or possible to use error learning? (need to force activity)
        if (this.lrule != ""){
            this.learning_rule(connection);
            this.apply_dwt(connection);
        }
        for (Link link : connection.links)
            link.wt = max(0.0, min(1.0, link.wt)); // clipping weights after change
    }

    void learning_rule(Connection connection){

        // """Leabra learning rule."""
        if(this.lrule=="leabra"){
            for (Link link : connection.links){
                // TAT 2022-01-20: check if need to add something to support errorlearing
                //  and that this is only Hebbian learning
                // avg_s_eff: linear mixing of avg_s -short term avg act- and avg_m -medium term avg act- 
                // avg_m: medium term avg activity
                float shortterm_avg_act = link.post().params().avg_s_eff * link.pre().params().avg_s_eff; // short term activity: post*pre
                float mediumterm_avg_act = link.post().params().avg_m * link.pre().params().avg_m; // medium term activity: post*pre
                // print('{}:{} erro {}\n  ru_avg_s_eff={}\n  su_avg_s_eff={}\n  shortterm_avg_act={}\n  ru_avg_m={}\n  su_avg_m={}\n  mediumterm_avg_act={}'.format(connection.post.name, i, this.m_lrn  * this.xcal(shortterm_avg_act, mediumterm_avg_act), link.post.avg_s_eff, link.pre.avg_s_eff, shortterm_avg_act, link.post.avg_m, link.pre.avg_m, mediumterm_avg_act))
                // print('{}:{} hebb {}\n  avg_l_lrn={}\n  xcal={}\n  shortterm_avg_act={}\n  avg_l={}'.format(connection.post.name, i, link.post.avg_l_lrn * this.xcal(shortterm_avg_act, link.post.avg_l), link.post.avg_l_lrn, this.xcal(shortterm_avg_act, link.post.avg_l), shortterm_avg_act, link.post.avg_l))
                
                // link.dwt += (  this.lrate * ( this.m_lrn * this.xcal(shortterm_avg_act, mediumterm_avg_act)
                //              + link.post().params().avg_l_lrn) * this.xcal(shortterm_avg_act, link.post().params().avg_l));        
                //float lrate = link.lrate == -1 ? this.lrate : link.lrate;
                // m_lrn = 1.0; weighting of error learning
                // avg_l_lrn = 
                // avg_l = long term avg activity
                float lrate = link.lrate_mod * this.lrate; // link modulates
                link.dwt += (  lrate * ( this.m_lrn * this.xcal(shortterm_avg_act, mediumterm_avg_act) // short, medium term -> error driven
                            + link.post().params().avg_l_lrn) 
                            * this.xcal(shortterm_avg_act, link.post().params().avg_l)); // long term -> hebbian
                println("l_rule: " + link.name + ": dwt: " + link.dwt);
        
            }
        }
        else if(lrule == "delta"){
            // todo delta = lrate*(target-actual) or lrate*(actual-predicted)
            for(Link link : connection.links){
                float lrate = link.lrate_mod * this.lrate; // link modulates
                link.dwt += (lrate * 
                    (link.pre().params().avg_s_eff
                     - link.post().params().avg_s_eff)
                    ); 
                            
                println("l_rule: " + link.name + ": dwt: " + link.dwt);
            }
        }
    }

    void apply_dwt(Connection connection){
        boolean dbg = false;
        for (Link link : connection.links){
            // print('before  wt={}  fwt={}  dwt={}'.format(link.wt, link.fwt, link.dwt))
            link.dwt *= (link.dwt > 0) ? (1 - link.fwt) : link.fwt;
            println("apl_dwt: " + link.name + ": dwt: " + link.dwt + "; fwt: " + link.fwt);
            link.fwt += link.dwt; // updates pre-sigmoid wt
            if (dbg) {println(link.name + " dwt: " + link.dwt + "; fwt: " + link.fwt);
                println("wt before: " + link.wt);}
            link.wt = this.sig(link.fwt); // 
            // print('after   wt={}  fwt={}  dwt={}'.format(link.wt, link.fwt, link.dwt))
            if( dbg ){println("wt after: " + link.wt); /* println(); println(); */}
            link.dwt = 0.0;
            
        }
        if (dbg) println();
    }
    

    float xcal(float x, float th){
        // """ extended contrastive attractor learning """
        // Ref p66 in O'Reilly et al 2020 textbook
        // x - short term avg activity of sending neuron * receiving neuron
        // th - floating threshold, determining whether weight is adj up or down; medium or long term activity
        // will be negative 
        if (x < this.d_thr) // d_thr = 0.0001
            return 0;
        else if (x > th * this.d_rev) // d_rev (reversal pot) = 0.1; point at which changes from post to neg
            return (x - th); // diff betw input and thresh
        else // 
            return (-x * ((1 - this.d_rev)/this.d_rev)); // 
    }

    float sig(float w){
        // """ Sigmoid function to increase contrast """
        // Note TAT: this may reflect noradrenalin, and 
        // should be require a noradr input 
        // (perhaps the sig_gain factor)
        return 1 / 
            (1 + 
                (this.sig_off * pow(
                    (
                        (1 - w) / w
                    ), this.sig_gain)
                )
            );
    }

    float sig_inv(float w){
        // """ Inverse sigmoid """
        if   (w <= 0.0) return 0.0;
        else if (w >= 1.0) return 1.0;
        return 1 / (1 + pow(((1 - w) / w) , (1 / this.sig_gain)) / this.sig_off);
    }



}


// 2022-01-09 TODO: add ReservoirConnection for Connection to, from reservoir and unit
