/**
*/
static final int eTickSquare=0;

class SignalGenerator{
  int type;
  int basetime;
  int duty;
  float offset;
  float amplitude;
  Buffer data;
  float output;
  int time=0;
  
  SignalGenerator(int atype, int abasetime, int aduty, int abufsize){
    type = atype;
    basetime = abasetime;
    duty = aduty;
    offset = 0;
    amplitude = 1;
    data = new Buffer(abufsize);
  }
  
  SignalGenerator(int atype, int abasetime, int aduty, float aoffset, float aampl, int abufsize){
    type = atype;
    basetime = abasetime;
    duty = aduty;
    offset = aoffset;
    amplitude = aampl;
    data = new Buffer(abufsize);
  }

  SignalGenerator(){ //int atype, int abasetime, int aduty, float aoffset, float aampl, int abufsize){
    type = eTickSquare;
    basetime = 200;
    duty = 100;
    offset = 0;
    amplitude = 1;
    data = new Buffer(10);
  }
  
  void tick(){
    switch (type){
      default:
      case eTickSquare:
        output = offset + amplitude * ticksquare(time++, basetime, duty);
        //println("output " +output); 
    }
    data.append(output);
  }
  
  
  float ticksquare(int atick, int abasetime, int aduty){
      if ((atick % abasetime) < aduty)
          return 1;
      else
          return 0;
  }
  
  float getOutput(){
    return output;
  }
  
  Buffer getBuffer(){
    return data;
  }
}
