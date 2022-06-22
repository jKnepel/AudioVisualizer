// Julian Knepel
// Visualizer inspired by Joy Divisions Original Unknown Pleasures Album Cover
// noise missing (for sharper edges/ "mountains")

class UnknownPleasures {
  float xStart = cwidth*0.3;
  float graphWidth = cwidth*0.4;
  float xEnd = xStart+graphWidth;
  float[] soundBuffer;
  UnknownPleasures() {}
  
  public void show() {
    stroke(255);
    fill(30);
    for(int i = 0; i < 50; i+=1) {
      float xOffset = map(noise(i), 0, 1, -100, 100);
      float yMult = 0;
      beginShape();
      //first half
      for(int j = 0; j < cwidth/2; j+=30) {
        float y = map(soundBuffer[(int)cwidth/2-j], 0, soundBuffer.length, 0, 50);
        if(j+cwidth/2+xOffset >= cwidth/2+50) yMult = 0.1; else
          yMult = map(xOffset, -100, 100, 1, 2);
        curveVertex(j+xOffset, (100+i*10)-y*yMult);
      }
      //second half
      for(int j = 0; j < cwidth/2; j+=30) {
        float y = map(soundBuffer[j], 0, soundBuffer.length, 0, 50);
        if(j+cwidth/2+xOffset >= cwidth/2+50) yMult = 0.1; else
          yMult = map(xOffset, -100, 100, 1, 2);
        curveVertex(j+cwidth/2+xOffset, (100+i*10)-y*yMult);
      }
      endShape(); 
    }
    stroke(30);
    rect(0,0,xStart,height);
    rect(xEnd,0,xStart,height);
  }
  
  public void update(float[] soundBuffer) {
    this.soundBuffer = soundBuffer;
  }
}
