// Julian Knepel
// rotating and growing squares as fft visualizer

class Square {
  public float length;
  private float rotation;
  
  public Square() {
    length = 0;
    rotation = 0;
  }
  
  
  private void show() {
    pushMatrix();
    translate(cwidth/2, height/2);
    rotate(rotation);
    rotation+=0.005;
    fft.forward(out.mix);
    for(int i = 0; i < fft.specSize(); i++) {
      if(i*5 < length) {
        if(autoColor) {
          colorMode(HSB);
          stroke(map(fft.getBand(i), 0, fft.specSize(), 0, 360), 100, 100);
          fill(map(fft.getBand(i), 0, fft.specSize(), 0, 360), 100, 100);
        } else if(waveColor) {
          colorMode(HSB);
          fill((wave+i*3)%361, 100, 100);
          stroke((wave+i*3)%361, 100, 100);
          if(random(1)<0.01) wave++;
          if(wave>=360) wave = 0; //reset
        }
        float x = map(fft.getBand(i), 0, fft.specSize(), 0, 150)*map(length, 0, height, 0, 2);
        rect((i*5)-(length/2), -(length/2), 5, -x); //top
        rect((length/2)-(i*5), length/2, -5, x); //bottom
        rect((length/2), (i*5)-(length/2), x, 5); //right
        rect(-(length/2), ((length/2)-5)-(i*5), -x, 5); //left
      } else break;
    }
    popMatrix(); 
  }
  
  void update(float growth) {
    length+=growth; 
    show();
  }
}
