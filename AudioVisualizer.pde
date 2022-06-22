// Julian Knepel and Tom Krause
// MultiMedia AudioVisualization Project

// Visualization via fft from ddf.minim library by ddf

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

float cwidth;

// audio I/O using minim
Minim minim;
FilePlayer player; //ugens player used to play store audio and play/analyse it
AudioPlayer testPlayer; //test player used to get songs sample rate and channelCount, bc Fileplayer.sampleRate()/type() is bugged and practically useless
AudioOutput out; //ugens out to which to patch and play the song
Gain gain; //"level" of output audio 
float vol;
FFT fft; //minim fft algorithm used to divide songs samples into their frequencies

String filename = "No File Selected";
boolean playing = false;
int songPosition; //pos in millisec

// control buttons
boolean fileHover, playHover, plusHover, minusHover, ffHover, reHover, vizHover;
boolean vizShow = false;
color focusColor = color(150);

// color options
boolean autoColorHover, randomColorHover, customColorHover, waveColorHover;
boolean autoColor = true, randomColor = false, customColor = false, waveColor = false;

boolean redBoxHover, greenBoxHover, blueBoxHover;
TextBox redBox, greenBox, blueBox;

float wave = 0; //variables for waveColor
color currentColor, nextColor; //colors for randomColor lerping
color vizColor; //color for visualizer

// visualizer
String[] viz = {"Simple Line", "Simple Circle", "Simple Rectangle", "Equalizer", "Unknown Pleasures", "Dark Side Of The Moon"}; //available visualizers
String vizSelection = ""; //tmp viz selection before click
String currentViz = "No Visualizer Selected"; //selected visualizers
boolean optViz; //true for visualizers with fft/osc option
boolean fftOsc = true; //true == fft, false = osc
boolean fftHover, oscHover;
ArrayList<Square> squares;
UnknownPleasures upViz;
ArrayList<Star> starMap;
FloatList oscValues;

// misc and effects
int frameCounter = 0; //tracks frames for more accurate calc of intervalls
  // scale options
  Multiplier multiplier;
  boolean scaleHover, scaleFocus;
  float scalePos, scale;
  // speed options
  TickRate tickRate;
  boolean speedHover, speedFocus;
  float speedPos, speed;
  // reverb options
  Delay delay;
  boolean reverbHover, reverbFocus;
  float reverbPos, reverb;
  
void setup() {
  size(1280, 720);
  cwidth = width*0.7;
  
  //set song attributes
  minim = new Minim(this);
  out = minim.getLineOut();
  fft = new FFT(out.bufferSize(), out.sampleRate());
  
  scale = 0;
  multiplier = new Multiplier(scale);
  speed = 1;
  tickRate = new TickRate(speed);
  reverb = 0;
  delay = new Delay(1, reverb, true, true);
  vol = 0;
  gain = new Gain(vol);
  
  // set color values
  vizColor = currentColor = nextColor = color(255); 
  redBox = new TextBox((cwidth+60), 395, 40, 25);
  greenBox = new TextBox((cwidth+155), 395, 40, 25);
  blueBox = new TextBox((cwidth+238), 395, 40, 25);
  
  squares = new ArrayList<Square>();
  upViz = new UnknownPleasures(); //unknown pleasures visualizer
  starMap = new ArrayList<Star>(); //starmap for the dark side of the moon background
  oscValues = new FloatList(); //list of frequencies with highest amp on each frame
  
  //slider positions
  scalePos = cwidth+25;
  speedPos = cwidth+115;
  reverbPos = cwidth+25;
}

void draw() {
  textSize(15);
  strokeWeight(1);

  //visualizer container
  fill(30);
  rect(0, 0, cwidth, height-1);
  
  if(player != null) {  
    if(currentViz == "Unknown Pleasures") {
      autoColor = true;
      randomColor = customColor = waveColor = false;
    } else if(optViz && !fftOsc && waveColor) {
      waveColor = false;
      autoColor = true;
    }
    
    //visualizer
    updateColor();
    if(currentViz == "Simple Line") simpleLine();
    else if(currentViz == "Simple Circle") simpleCircle();
    else if(currentViz == "Simple Rectangle") simpleRectangle();
    else if(currentViz == "Equalizer") equalizer();
    else if(currentViz == "Unknown Pleasures") unknownPleasures();
    else if(currentViz == "Dark Side Of The Moon") darkSide();
    colorMode(RGB);
    strokeWeight(1);  
  }
  
  noFill();
  stroke(200);
  rect(0, 0, cwidth, height-1);
  
  //button container
  fill(30);
  stroke(200, 200, 200);
  rect(cwidth, 0, (width-cwidth)-1, height-1);

  //select file
  fill(255);
  textAlign(RIGHT);
  text(filename, width-115, 96);
  textAlign(LEFT);

  noFill();
  if(fileHover) stroke(focusColor); else stroke(255);
  rect(width-110, 75, 95, 30);
  if(fileHover) fill(focusColor); else fill(255);
  text("choose file", width-102, 96);

  //play button
  noFill();
  if(playHover || player == null) stroke(focusColor); else stroke(255);
  rect(width-45, 135, 30, 30);
  if(playHover || player == null) fill(focusColor); else fill(255);
  if(!playing) triangle(width-38, 142, width-38, 158, width-22, 150);
  else {
    rect(width-38, 140, 5, 20);
    rect(width-27, 140, 5, 20);
  }

  //plus amp button
  noFill();
  if(plusHover || player == null) stroke(focusColor); else stroke(255);
  rect(width-110, 135, 30, 30);
  if(plusHover || player == null) fill(focusColor); else fill(255);
  rect(width-97.5, 140, 5, 20);
  rect(width-105, 147.5, 20, 5);

  //minus amp button  
  noFill();
  if(minusHover || player == null) stroke(focusColor); else stroke(255);
  rect(width-175, 135, 30, 30);
  if(minusHover || player == null) fill(focusColor); else fill(255);
  rect(width-170, 147.5, 20, 5);

  //fast-forward
  noFill();
  if(ffHover || player == null) stroke(focusColor); else stroke(255);
  rect(width-240, 135, 30, 30);
  if(ffHover || player == null) fill(focusColor); else fill(255);
  triangle(width-233, 143, width-233, 157, width-224, 150);
  triangle(width-225, 143, width-225, 157, width-216, 150);

  //rewind
  noFill();
  if(reHover || player == null) stroke(focusColor); else stroke(255);
  rect(width-305, 135, 30, 30); 
  if(reHover || player == null) fill(focusColor); else fill(255);
  triangle(width-291, 150, width-282, 143, width-282, 157);
  triangle(width-299, 150, width-290, 143, width-290, 157);

  if(player != null) {
    //color editor
    fill(255);
    stroke(255);
    text("Color Editor", (cwidth+15), 260);
    fill(0, 0, 0, 0);
    if(customColor) rect(cwidth+15, 265, (width-cwidth)-30, 165);
    else rect(cwidth+15, 265, (width-cwidth)-30, 135);
  
    //color options button
    if(autoColorHover || currentViz == "Unknown Pleasures") stroke(focusColor); else stroke(255);
    rect((cwidth+25), 275, 25, 25); //Automatic Color Button
    if(randomColorHover || currentViz == "Unknown Pleasures") stroke(focusColor); else stroke(255);
    rect((cwidth+25), 310, 25, 25); //Random Color Button
    if(customColorHover || currentViz == "Unknown Pleasures") stroke(focusColor); else stroke(255);
    rect((cwidth+25), 345, 25, 25); //Custom Color Button
    if(waveColorHover || currentViz == "Unknown Pleasures" || optViz && !fftOsc) stroke(focusColor); else stroke(255);
    rect((cwidth+200), 275, 25, 25); //Wave Color Button
  
    //mark selected color option button
    strokeWeight(3);
    if(autoColor) {
      if(autoColorHover || currentViz == "Unknown Pleasures") stroke(focusColor); 
      else stroke(255);
      line((cwidth+30), 280, (cwidth+45), 295);
      line((cwidth+45), 280, (cwidth+30), 295);
    } else if(randomColor) {
      if(randomColorHover || currentViz == "Unknown Pleasures") stroke(focusColor); 
      else stroke(255);
      line((cwidth+30), 315, (cwidth+45), 330);
      line((cwidth+45), 315, (cwidth+30), 330);
    } else if(customColor) {
      if(customColorHover || currentViz == "Unknown Pleasures") stroke(focusColor); 
      else stroke(255);
      line((cwidth+30), 350, (cwidth+45), 365);
      line((cwidth+45), 350, (cwidth+30), 365);
    } else {
      if(waveColorHover) stroke(focusColor); else stroke(255);
      line((cwidth+205), 280, (cwidth+220), 295);
      line((cwidth+220), 280, (cwidth+205), 295);      
    }
    strokeWeight(1);
  
    //color options text
    if(currentViz == "Unknown Pleasures") fill(focusColor); else fill(255);
    textSize(14);
    if(currentViz == "Unknown Pleasures" || optViz && !fftOsc) text("Standard Color", (cwidth+55), 293); else text("Automatic Color", (cwidth+55), 293);
    text("Random Color", (cwidth+55), 328);
    text("Custom Color", (cwidth+55), 363);
    if(optViz && !fftOsc) fill(focusColor);
    text("Wave Color", (cwidth+230), 293);
  
    //textbox for custom color selection
    if(customColor) {
      if(redBoxHover || redBox.focus) stroke(focusColor); else stroke(255);
      text("Red:", (cwidth+25), 413);
      redBox.show();
      if(greenBoxHover || greenBox.focus) stroke(focusColor); else stroke(255);
      text("Green:", (cwidth+105), 413);
      greenBox.show();
      if(blueBoxHover || blueBox.focus) stroke(focusColor); else stroke(255);
      text("Blue:", (cwidth+200), 413);
      blueBox.show();
    }
  
    //visualizer options
      //container
      textSize(15);
      fill(255);
      text("Visualizer Customisation", (cwidth+15), 455);
      noFill();
      stroke(255);
      rect(cwidth+15, 460, (width-cwidth)-30, 200);
  
  
      //fft/osc options
      noFill();
      if(fftHover || !optViz) stroke(focusColor); else stroke(255);
      rect((cwidth+25), 470, 25, 25); //fft
      if(oscHover || !optViz) stroke(focusColor); else stroke(255);
      rect((cwidth+100), 470, 25, 25); //oscillator
  
      if(!optViz) fill(focusColor);
      text("FFT", (cwidth+55), 488);
      if(!optViz) fill(focusColor);
      text("Oscilloscope", (cwidth+130), 488);
  
      strokeWeight(3);
      if(fftOsc) {
        if(fftHover || !optViz) stroke(focusColor); else stroke(255);
        line((cwidth+30), 475, (cwidth+45), 490);
        line((cwidth+45), 475, (cwidth+30), 490);
      } else {
        if(oscHover || !optViz) stroke(focusColor); else stroke(255);
        line((cwidth+105), 475, (cwidth+120), 490);
        line((cwidth+120), 475, (cwidth+105), 490);
      }
      strokeWeight(1);
  
      //effects
        //scale slider
        stroke(255);
        fill(255);
        line(cwidth+25, 520, cwidth+280, 520); //0 = cwidth+25, 10 = cwidth+280
        
        textSize(14);
        text("0", cwidth+23, 545);
        text("20", cwidth+270, 545);
        textSize(15);
        text("Scaling", cwidth+295, 525);
        
        if(scaleFocus && mouseX >= cwidth+25 && mouseX <= cwidth+280 && !vizShow) scalePos = mouseX;
        if(scaleHover || scaleFocus) stroke(focusColor);
        fill(30);
        rectMode(CENTER);
        rect(scalePos, 520, 10, 20);
        rectMode(CORNER);
        
        scale = map(scalePos, cwidth+25, cwidth+275, 0, 20);
        
        multiplier.setValue(scale);
        
        //speed slider
        stroke(255);
        fill(255);
        line(cwidth+25, 560, cwidth+280, 560); //0 = cwidth+25, 1 = cwidth+115, 10 = cwidth+280
        
        textSize(14);
        text("0", cwidth+23, 585);
        text("1", cwidth+110, 585);
        text("10", cwidth+270, 585);
        textSize(15);
        text("Speed", cwidth+295, 565);
        
        if(speedFocus && mouseX >= cwidth+25 && mouseX <= cwidth+280 && !vizShow) speedPos = mouseX;
        if(speedHover || speedFocus) stroke(focusColor);
        fill(30);
        rectMode(CENTER);
        rect(speedPos, 560, 10, 20);
        rectMode(CORNER);
        
        if(speedPos <= cwidth+115) speed = map(speedPos, cwidth+25, cwidth+115, 0, 1);
        else speed = map(speedPos, cwidth+115, cwidth+275, 1, 10);
        
        tickRate.value.setLastValue(speed);
        
        //reverb slider
        stroke(255);
        fill(255);
        line(cwidth+25, 600, cwidth+280, 600); //0 = cwidth+25, 10 = cwidth+280
        
        textSize(14);
        text("0", cwidth+23, 625);
        text("1", cwidth+270, 625);
        textSize(15);
        text("Reverb", cwidth+295, 605);
        
        if(reverbFocus && mouseX >= cwidth+25 && mouseX <= cwidth+280 && !vizShow) reverbPos = mouseX;
        if(reverbHover || reverbFocus) stroke(focusColor);
        fill(30);
        rectMode(CENTER);
        rect(reverbPos, 600, 10, 20);
        rectMode(CORNER);
        
        reverb = map(reverbPos, cwidth+25, cwidth+280, 0, 1);
             
        delay.setDelAmp(reverb);
        if(!playing) delay.setDelAmp(0);

    // visualizer select button
    textSize(15);
    fill(0, 0, 0, 0);
    if(vizHover) stroke(focusColor); else stroke(255);
    rect((cwidth+15), 195, (width-cwidth)-30, 30);
    if(vizHover) fill(focusColor); else fill(255);
    triangle((width-25), 205, (width-40), 205, (width-32.5), 215);
    text(currentViz, cwidth+20, 216);
  
    //menu for visualizers
    if(vizShow) {
      for(int i = 1; i < viz.length+1; i++) {
        if(mouseX >= cwidth+15 && mouseX <= (width-15) && mouseY >= 195+(30*i) && mouseY <= 225+(30*i)) stroke(focusColor); else stroke(255); 
        fill(35);
        rect((cwidth+15), 195+(30*i), (width-cwidth)-30, 30);
  
        if(mouseX >= cwidth+15 && mouseX <= (width-15) && mouseY >= 195+(30*i) && mouseY <= 225+(30*i)) fill(focusColor); else fill(255);
        textAlign(LEFT);
        text(viz[i-1], cwidth+20, 216+(30*i));
      }
    }
  }

  //update mouse position and states/elements in focus
  if(mouseX >= width-110 && mouseX <= width-15 && mouseY >= 75 && mouseY <= 105) {
    fileHover = true;
    cursor(HAND);
  } else if(mouseX >= width-45 && mouseX <= width-15 && mouseY >= 135 && mouseY <= 165 && player != null) {
    playHover = true;
    cursor(HAND);
  } else if(mouseX >= width-110 && mouseX <= width-80 && mouseY >= 135 && mouseY <= 165 && player != null) {
    plusHover = true;
    cursor(HAND);
  } else if(mouseX >= width-175 && mouseX <= width-145 && mouseY >= 135 && mouseY <= 165 && player != null) {
    minusHover = true;
    cursor(HAND);
  } else if(mouseX >= width-240 && mouseX <= width-215 && mouseY >= 135 && mouseY <= 165 && player != null) {
    ffHover = true;
    cursor(HAND);
  } else if(mouseX >= width-305 && mouseX <= width-275 && mouseY >= 135 && mouseY <= 165 && player != null) {
    reHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+15 && mouseX <= width-15 && mouseY >= 195 && mouseY <= 225 && player != null) {
    vizHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+15 && mouseX <= width-15 && mouseY >= 226 && mouseY <= 226+(30*viz.length) && vizShow && player != null) {
    vizHover = false;
    cursor(HAND);
    try {
      vizSelection = viz[(mouseY-226)/30];
    } 
    catch(ArrayIndexOutOfBoundsException e) {}
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+50 && mouseY >= 275 && mouseY <= 300 && !vizShow && player != null && currentViz != "Unknown Pleasures") {
    autoColorHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+50 && mouseY >= 310 && mouseY <= 335 && !vizShow && player != null && currentViz != "Unknown Pleasures") {
    randomColorHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+50 && mouseY >= 345 && mouseY <= 370 && !vizShow && player != null && currentViz != "Unknown Pleasures") {
    customColorHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+200 && mouseX <= cwidth+225 && mouseY >= 275 && mouseY <= 300 && !vizShow && player != null) {
    if(currentViz == "Unknown Pleasures" || optViz && !fftOsc) {} else {
      waveColorHover = true;
      cursor(HAND);
    }
  } else if(mouseX >= (cwidth+60) && mouseX <= (cwidth+100) && mouseY >= 395 && mouseY <= 420 && customColor && player != null) {
    redBoxHover = true;
    cursor(HAND);
  } else if(mouseX >= (cwidth+155) && mouseX <= (cwidth+195) && mouseY >= 395 && mouseY <= 420 && customColor && player != null) {
    greenBoxHover = true;
    cursor(HAND);
  } else if(mouseX >= (cwidth+238) && mouseX <= (cwidth+278) && mouseY >= 395 && mouseY <= 420 && customColor && player != null) {
    blueBoxHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+50 && mouseY >= 470 && mouseY <= 495 && !vizShow && optViz && player != null) {
    fftHover = true;
    oscHover = false;
    cursor(HAND);
  } else if(mouseX >= cwidth+100 && mouseX <= cwidth+125 && mouseY >= 470 && mouseY <= 495 && !vizShow && optViz && player != null) {
    fftHover = false;
    oscHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+280 && mouseY >= 510 && mouseY <= 530 && !vizShow && player != null) {
    scaleHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+280 && mouseY >= 550 && mouseY <= 570 && !vizShow && player != null) {
    speedHover = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+280 && mouseY >= 590 && mouseY <= 610 && !vizShow && player != null) {
    reverbHover = true;
    cursor(HAND);
  } else {
    fileHover = false;
    playHover = plusHover = minusHover = ffHover = reHover = false;
    vizHover = false;
    vizSelection = "";
    autoColorHover = randomColorHover = customColorHover = waveColorHover = false;
    redBoxHover = greenBoxHover = blueBoxHover = false;
    fftHover = oscHover = false;
    scaleHover = false;
    speedHover = false;
    reverbHover = false;
    cursor(ARROW);
  }

  // stop playing when song is over
  if(player != null) {
    songPosition = player.position();
    if(!player.isPlaying() && playing) { //no actual pause method in minim, so we have to save the position
      player.pause();
      player.rewind();
      playing = false;
    }
  }
  
  // update framecounter for reference in methods
  frameCounter += 1;
  if(frameCounter == 101) frameCounter = 0;
}

//################################ Event Listeners ################################

void mousePressed() {
  if(fileHover) selectInput("Choose a Soundfile:", "fileSelected");
  else if(playHover) {
    if(!playing) player.play(songPosition); else player.pause();
    playing = !playing;
  } else if(plusHover) {
    gain.setValue(vol+=3);  
  } else if(minusHover) {  
    gain.setValue(vol=-3);
  } else if(ffHover) {
    if(player.position()+10 < player.length()) player.skip(10000);
  } else if(reHover && playing) {
    if(player.position()-10 > 0) player.skip(-10000);
  } else if(vizHover) {
    vizShow = !vizShow;
  } else if(vizSelection != "" & vizShow) {
    currentViz = vizSelection;
    vizShow = false;
  } else if(autoColorHover) {
    autoColor = true;
    randomColor = customColor = waveColor = false;
  } else if(randomColorHover) {
    randomColor = true;
    autoColor = customColor = waveColor = false;
  } else if(customColorHover) {
    customColor = true;
    autoColor = randomColor = waveColor = false;
  } else if(waveColorHover) {
    waveColor = true;
    autoColor = randomColor = customColor = false;
  } else if(redBoxHover) {
    redBox.focus = true;
    greenBox.focus = blueBox.focus = false;
  } else if(greenBoxHover) {
    greenBox.focus = true;
    redBox.focus = blueBox.focus = false;
  } else if(blueBoxHover) {
    blueBox.focus = true;
    redBox.focus = greenBox.focus = false;
  } else if(fftHover && optViz) fftOsc = true;
  else if(oscHover && optViz) fftOsc = false;
  else if(scaleHover) scaleFocus = true;
  else if(speedHover) speedFocus = true;
  else if(reverbHover) reverbFocus = true;
  else {
    redBox.focus = greenBox.focus = blueBox.focus = false;
    vizShow = false;
  }
}

//when dragging mouse over slider
void mouseDragged() {
  if(mouseX >= cwidth+25 && mouseX <= cwidth+280 && mouseY >= 510 && mouseY <= 530 && !vizShow && scaleFocus) {
    scaleFocus = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+280 && mouseY >= 550 && mouseY <= 570 && !vizShow && speedFocus) {
    speedFocus = true;
    cursor(HAND);
  } else if(mouseX >= cwidth+25 && mouseX <= cwidth+280 && mouseY >= 590 && mouseY <= 610 && !vizShow && reverbFocus) {
    reverbFocus = true;
    cursor(HAND);
  }
}

//when releasing mouse after dragging over slider
void mouseReleased() {
  if(scaleFocus) scaleFocus = false;
  else if(speedFocus) speedFocus = false;
  else if(reverbFocus) reverbFocus = false;
}

//when pressing hotkeys or inputting colour values
void keyPressed() {
  if(key == 32 && player != null) { //pause/play when pressing spacebar
    if(player != null) {
      if(!playing) player.play(songPosition);
      else {
        songPosition = player.position();
        player.pause(); //save position bc minim has no actual pause function, only stop
      }
      playing = !playing;
    }
  } else if(key == 43 && player != null) { //increase volume when pressing +
    if(vol < 60) vol+=6;
    gain.setValue(vol);    
  } else if(key == 45 && player != null) { //decrease volume when pressing -
    if(vol > -100) vol-=6;  
    gain.setValue(vol);
  } else if(key == 60 && player != null) { //replay when pressing <
    if(player.position()-10 > 0) player.skip(-10000);
  } else if(key == 62 && player != null) { //fastforward when pressing >
    if(player.position()+10 < player.length()) player.skip(10000);
  } else if(player != null) {
    redBox.keyPressed();
    greenBox.keyPressed();
    blueBox.keyPressed();
  }
}

//################################ runtime methods #################################

/*
loads, checks file and sets needed attributes

Because of a problem with how minim processes samplerates and outs, different samplerates cant be used for one out and UGens cant be patched to multiple outs if they have different samplerates.
That requires one to duplicate the whole sample/UGen chain for each sample/out. This is not very efficient and well thought out, but since even ddf says "(he) won't be able to provide this kind of functionality within Minim any time soon",
this is the best solution we came up with. This can also result in a possible memory leak since the loadFileStream saves a buffer and cant be collected by the JVMLGarbage Collector.
https://github.com/ddf/Minim/issues/91
the thread for this problem for reference

Another problem is the incompatibility of the out sample rate and the chosen songs and the inability to scale the songs to the needed sample rate, wrong channel types, file sizes and unknown decoders, try/catch also doesnt help since the exception ocurrs within the minim library itself and cant be caught.
Only way to prevent crashes is too restrict play of large files and making sure the number of channels of the out and song are identical (sample rates cant be tested for correctly via minim either)
The Problems with minims are further explained in the written report
*/
void fileSelected(File selection) {
  if(player != null) {
    player.pause();
    playing = false;
    songPosition = 0;
  }

  if(selection == null) {
    filename = "No File Selected";
    resetState();
  } else {
    if(checkFileType(selection)) {
      minim = new Minim(this); //initalize new minim/AudioOutput and FFT for the new sample
      
      out = minim.getLineOut();
      fft = new FFT(out.bufferSize(), out.sampleRate());
      
      testPlayer = minim.loadFile(selection.getPath());
      if(testPlayer.type() != out.type()) { //prevent play of songs with incompatible channel numbers
        filename = "Songs Channels needs to be "+out.type();
        resetState();
      } else if(testPlayer.length() > 1000000) { //restrict play of large files
        filename = "The File is too large";
        resetState();
      } else {  
        filename = selection.getName();
        if(filename.length() >= 30) filename = filename.substring(0, 20)+" ... "+filename.substring((filename.length()-6)); //shorten name if too long for window
        player = new FilePlayer(minim.loadFileStream(selection.getPath())); //initialize fileplayer
        
        multiplier = new Multiplier(scale); //initialize new UGen attributes for new out
        tickRate = new TickRate(speed);
        delay = new Delay(1, reverb, true, true);
        gain = new Gain(0);
        
        player.setSampleRate(out.sampleRate());
        player.patch(out);
        player.patch(tickRate).patch(out); //patch Ugens effects to new out
        player.patch(multiplier).patch(out);
        player.patch(delay).patch(out);
        player.patch(gain).patch(out);
      }
    } else {
      filename = "Only MP3/WAV Files allowed";
      resetState();
    }
  }
}

//checks for file type, true for mp3/wav
boolean checkFileType(File file) {
  String tmp = "";
  for(int i = file.getName().length()-1; i >= 0; i--) {
    if(file.getName().charAt(i) == '.') {
      for(int j = i+1; j < file.getName().length(); j++)
        tmp += file.getName().charAt(j);
      break;
    }
  }
  if(tmp.equals("mp3") || tmp.equals("wav")) return true;
  else return false;
}

//resets values to initial state
void resetState() {
  currentViz = "No Visualizer Selected";
  player = null;
  scalePos = cwidth+25;
  speedPos = cwidth+115;
  reverbPos = cwidth+25;  
}

//updates color of visualizer
void updateColor() {
  if(randomColor) {
    if(frameCounter%20 == 0) nextColor = color(random(255), random(255), random(255));
    currentColor = lerpColor(currentColor, nextColor, .05);
    vizColor = currentColor;
  } else if(customColor) vizColor = color(redBox.txt, greenBox.txt, blueBox.txt);
}

//returns value of "loudest" current frequency
float getMaxFreq() {
  if(playing) {
    float tmp = 0;
    fft.forward(out.mix);
    for(int i = 0; i < fft.specSize(); i++) 
      if(fft.getBand(i) > tmp) tmp = fft.getBand(i);
    return tmp;
  }
  return 0;
}

//################################ Visualizers ################################

void simpleLine() {
  optViz = true;
  if(player != null) {
    stroke(vizColor);
    fill(vizColor);
    
    if(fftOsc) {
      fft.forward(out.mix);
      for(int i = 0; i < fft.specSize(); i++) {
        if(autoColor) {
          colorMode(HSB);
          stroke(map(fft.getBand(i), 0, fft.specSize(), 0, 360), 100, 100);
          fill(map(fft.getBand(i), 0, fft.specSize(), 0, 360), 100, 100);
        } else if(waveColor) {
          colorMode(HSB);
          fill((wave+i*3)%361, 100, 100);
          stroke((wave+i*3)%361, 100, 100);
          if(random(1)<0.01) wave++;
          if(wave>=360) wave = 0;
        }
        
        if(i+((cwidth/7)+(i*5)) <= cwidth-cwidth/7) {
          float x = map(fft.getBand(i), 0, fft.specSize(), 10, 400);
          rect((i+(cwidth/7)+(i*5)), height/2, 5, -x);
          rect((i+(cwidth/7)+(i*5)), height/2, 5, x);
          i+=4;
        }
      }
    } else {
      if(autoColor || waveColor) stroke(255);
      fill(30);
      if(oscValues.size() >= cwidth/3-40) oscValues.remove(0);
      oscValues.append(getMaxFreq());
            
      beginShape();
      for(int i = 0; i+1 < oscValues.size() && i <= cwidth/3-40; i++) {        
        float p1 = map(oscValues.get(i), 0, fft.specSize(), 0, 300);
        float p2 = map(oscValues.get(i+1), 0, fft.specSize(), 0, 300);
        vertex(45+(i*3), 500-p1);
        vertex(45+(i*3+1), 500-p2);
      }
      endShape();
    }
  }
}

void simpleCircle() {
  optViz = true;
  if(player != null) {
    stroke(vizColor);
    noFill();
    
    pushMatrix();      
    translate(cwidth/2,height/2);
      
    if(fftOsc) {
      fft.forward(out.mix);
      for(int i = 0; i < fft.specSize(); i++) {
        if(autoColor) {
          colorMode(HSB);
          stroke(map(fft.getBand(i), 0, fft.specSize(), 0, 360), 100, 100);
        } else if(waveColor) {
          colorMode(HSB);
          stroke((wave+i*3)%361, 100, 100);
          if(random(1)<0.01) wave++;
          if(wave>=360) wave = 0; //reset
        }
        strokeWeight(map(fft.getBand(i), 0, fft.specSize(), 1, 10));
        float x = map(fft.getBand(i), 0, fft.specSize(), 0, 600);
        circle(0, 0, x);
      }
    } else {
      if(autoColor || waveColor) stroke(255);
      fill(30);
      if(oscValues.size() > 360) oscValues.remove(0);
      oscValues.append(getMaxFreq());
      
      rotate(-PI/2); //rotate by -90° to get the starting point to the top
      beginShape();
      for(int i=oscValues.size()-1; i > 0 && i > oscValues.size()-360; i-=1) {
        float p1 = map(oscValues.get(i), 0, fft.specSize(), 0, 150);
        float p2 = map(oscValues.get(i-1), 0, fft.specSize(), 0, 150);
        vertex(cos(radians(i))*(100+p1),sin(radians(i))*(100+p1));
        vertex(cos(radians(i-1))*(100+p2),sin(radians(i-1))*(100+p2));
      }
      endShape();
    }
    popMatrix();
  }
}


void simpleRectangle() {
  optViz = false;
  if(player != null) {
    stroke(vizColor);
    fill(vizColor);
    
    if(squares.size() == 0 || squares.get(squares.size()-1).length >= height/2) squares.add(new Square());
    for(int i = squares.size(); i-- != 0;) { 
      if(squares.get(i).length >= height*2) squares.remove(i);
      else {
        squares.get(i).update(speed);
        squares.get(i).show();
      }
    }
  }
}

void equalizer() {
  optViz = false;
  if(player != null) {
    stroke(vizColor);
    fill(vizColor);
    
    fft.forward(out.mix);
    for(int i = 0; i < 14; i++) {
      float x = map(fft.getBand(i), 0, fft.specSize(), 0, 300);
      if(autoColor) {
        colorMode(HSB);
        stroke(map(fft.getBand(i), 0, fft.specSize(), 0, 360), 100, 100);
        fill(map(fft.getBand(i), 0, fft.specSize(), 0, 360), 100, 100);
      } else if(waveColor) {
        colorMode(HSB);
        fill((wave+i*3)%361, 100, 100);
        stroke((wave+i*3)%361, 100, 100);
        if(random(1)<0.05) wave++;
        if(wave>=360) wave = 0; //reset
      } 
      //draw bands for i < 14 frequencies
      rect(35+i*60, height/2+200, 50, -x);
    }
    
    //draw black bars over bands
    for(int k = 20; k < 700; k+=15) {
      for(int j = 0; j <= 780; j+=60) {
        fill(30);
        stroke(30);
        rect(35+j, height/2+(220-k)+1, 50, 5);
        noFill();
      }
    }
  }
}

//Visualizer inspired by Joy Division - Unknown Pleasures Album Cover(1979)
void unknownPleasures() {
  optViz = false;
  if(player != null) {

    if(frameCounter%3 == 0 || upViz.soundBuffer == null) {
      fft.forward(out.mix);
      float[] soundBuffer = new float[fft.specSize()];
      for(int i = 0; i < soundBuffer.length; i++)
        soundBuffer[i] = fft.getBand(i);
      upViz.update(soundBuffer);
      upViz.show();
    } else upViz.show();
  }
}

//Visualizer inspired by Pink Floyd - Dark Side of the Moon Album Cover(1973)
void darkSide() {
  optViz = false;
  if(player != null) {
    //Top Point = (448, 260)
    //BottomLeft Point = (348, 460)
    //BottomRight Point = (548, 460)
    
    //starfield
    for(int i = starMap.size(); i-- != 0;) { 
      if(starMap.get(i).py >= height || starMap.get(i).py <= 0 || starMap.get(i).age > 200) starMap.remove(i);
      else {
        starMap.get(i).update(speed);
      }
    }
    
    for(int i = 0; i < 20; i++) 
      starMap.add(new Star());
     
    strokeWeight(3);
    stroke(255);
    noFill();
    
    float x = map(getMaxFreq(), 0, fft.specSize(), 0, 50);
    if(x > 100) x = 100; //limit lines to not go over triangle
    float y = 450-(2*x);
    if(y < 280) y = 280; //limit lines to not go over triangle
    
    line(0, height/2+20, 355+x, y); //left line
    for(int i = 0; i < 6; i++) {
      stroke(vizColor);
      if(autoColor) {
        colorMode(HSB);
        stroke(30*i, 100, 100);
      } else if(waveColor) {
        colorMode(HSB);
        stroke((wave+i*30)%361, 100, 100);
        if(random(1)<0.05) wave+=7;
        if(wave>=360) wave = 0; //reset
      }
      
      strokeWeight(10);
      line(355+x, y, cwidth, (height/2+20)+i*10); //rainbow
    }
    strokeWeight(1);
    
    //triangle
    noStroke();
    fill(30);
    triangle(cwidth/2, height/2-100, cwidth/2-100, height/2+100, cwidth/2+100, height/2+100); 
    noFill();
    for(int i = 0; i < 15; i++) {
      stroke(map(i, 0, 15, 150, 30));
      beginShape();
      vertex(448, 260+i);
      vertex(348+i, 460-i/2);
      vertex(548-i, 460-i/2);
      vertex(448, 260+i);
      endShape();   
    }
    
    //inner reflection
    for(float i = 350+x, j = 1; i <= 545-x; i+=0.5, j+=0.1) {
      float lerp = map(i, 355+x, cwidth/2-20, 0, 1);
      color c = lerpColor(color(255), color(200,0), lerp);
      stroke(c);
      float k = map(y, 460, 260, 1, 0.1);
      if(y-j*k > 280 && y+j*k < 445 && i < (545-x))
      line(i, y-j*k, i, y+j*k);
    }
  }
}
