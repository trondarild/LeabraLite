//
// port from Balkenius et al 2020
//
class ValueAccumulator {
    float alpha = 0.05; // integration gain
    float beta = 0.2; // lateral inhibtion
    float gamma = 0; // feedback excitation
    float delta = 1; // feedback inhibition
    float lambda = 0; // decay factor for leaky integrator
    float mean = 0; // mean of noise
    float sigma = 1.0; // noise sigma
    float[] index; //
    float[] input;
    int size = 0;
    float[] state;
    float[] choice;
    float[] output;
    float[] rt_mean;
    float[] rt_sum;
    float[] choice_probability;
    float[] choice_count;
    float reaction_time;
    float[][] rt_histogram;

    int max_rt = 40;
    int rt_size_x = max_rt;
    int rt_size_y = 10;

    ValueAccumulator (int size) {
        this.size = size;
        this.state = zeros(size);
        this.choice = zeros(size);
        this.output = zeros(size);
        this.choice_probability = zeros(size);
        this.choice_count = new float[size];
        this.rt_mean = zeros(size);
        this.rt_histogram = zeros(rt_size_y, rt_size_x);
        this.rt_sum = zeros(size);
    }

    void setSpatialIx(float[] a) {
        assert(a.length == this.size);
        index = a;
        
    }

    void setInput(float[] a) {
        // value input, will be summed if size > 1
        input = a;
    }

    float[] getState(){return state;}
    float[] getChoice(){return choice;}
    float[] getOutput(){return output;}
    float[] getRtMean(){return rt_mean;}
    float[] getChoiceProbability(){return choice_probability;}
    float[] getChoiceCount(){return choice_count;}
    float getReactionTime() {return reaction_time;}
    float[][] getRtHistogram() {return rt_histogram;}

    void cycle() {
        reset(choice);

        // Apply update rule

        float E = sumArray(input);
        // printf("%f\t%f\n", E*index[0], E*index[1]);
        
        for(int i=0; i<size; i++) {
            state[i] = (1-lambda)*state[i] + alpha*index[i]*E - beta*(1-index[i])*E + gamma*state[i];
        }
        
        // recurrent inhibition
        for(int i=0; i<size; i++) {
            for(int j=0; j<size; j++)
                if(i!=j)
                    state[i] -= delta*state[j];
        }
        
        // Noise
        for(int i=0; i<size; i++)
            state[i] += gaussian1(mean, sigma);
        state = limitval(0, 1, state);
        
        reset(output);
        if(max(state) == 1)
        {
            int c = argmax(state);
            output[c] = 1;

            // compute meta info
            if(reaction_time/5 < max_rt)
                rt_histogram[int(reaction_time)/5][c] += 1;
            choice_count[c] += 1;
            //copy_array(choice_probability, choice_count, size);
            System.arraycopy(choice_count, 0, choice_probability, 0, size);
            choice_probability = normalize(choice_probability);
            rt_sum[c] += reaction_time;
            for(int i=0; i<size; i++)
                if(choice_count[i]> 0)
                    rt_mean[i] = rt_sum[i] / choice_count[i];
                else
                    rt_mean[i] = 0;
            reset(state);
            set_one(choice, c);
            reaction_time = 0;
        }
        else {
            reaction_time += 1;
            
        }
    }

}
