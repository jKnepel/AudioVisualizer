// Julian Knepel
// Starmap using random x/y values which increase by a value mapped to their position relative to their distance from the edge of the "screen" multiplied by the speed
// inspired by Daniel Shiffman/CodingTrain starfield https://github.com/CodingTrain/website/tree/master/CodingChallenges/CC_001_StarField

class Star {
  public float x, y, px, py;
  public int age; //to keep track of how long they have "lived" for
  
  public Star() {
    this.x = random(-cwidth/2, cwidth+cwidth/2);
    this.y = random(0, height);
    px = x;
    py = y;
  }
  
  private void show() {
    stroke(255);
    strokeWeight(map(dist(px, py, x, y), 0, 30, 0, 5));
    line(px, py, x, y);
  }
  
  public void update(float mult) {
    age++;
    px = x;
    py = y;
    
    //update Stars x and y Pos with how close to the edge they are
    if(x >= cwidth/2) x+=map(x, cwidth/2, cwidth, 0, 5)*mult; else x-=map(x, cwidth/2, 0, 0, 5)*mult;
    if(y >= height/2) y+=map(y, height/2, height, 0, 5)*mult; else y-=map(y, height/2, 0, 0, 5)*mult;
    show();
  }
}
