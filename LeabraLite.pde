//
// branch main
//
import java.util.HashMap;
import java.util.Map;

import themidibus.*; //Import the library
import javax.sound.midi.MidiMessage; 

MidiBus myBus; 
int midiDevice  = 0;

// TestTemplate test = new TestTemplate(); // template for tests or models
// TestEffortAchDecisionModules test = new TestEffortAchDecisionModules();
// TestAdenoModel test = new TestAdenoModel();
// TestRuleMod test = new TestRuleMod();
TestDecDemand test = new TestDecDemand();
//TestSpatialAtt test = new TestSpatialAtt();




void setup(){
	size(1000, 1500);
	// unit.show_config();
  frameRate(30);
  MidiBus.list(); 
  myBus = new MidiBus(this, midiDevice, 1); 

}

void update(){
	test.tick();
}

void draw(){
	update();
	background(51);
	scale(0.9);
	test.draw();
}

void keyPressed() {
  // if (key == ' ') {
  //   test.setInput(1.0);
  // }
  test.handleKeyDown(key); 
}

void keyReleased() {
  // if(key== ' ')
  //   test.setInput(0.0);
  test.handleKeyUp(key);
}

void midiMessage(MidiMessage message, long timestamp, String bus_name) { 
  int note = (int)(message.getMessage()[1] & 0xFF) ;
  int vel = (int)(message.getMessage()[2] & 0xFF);

  test.handleMidi(note, vel);

}
