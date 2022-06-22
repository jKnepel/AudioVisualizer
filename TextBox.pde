// Julian Knepel
// TextBox for RGB Colors using passed values for coordinates, storing int from 0-255  

class TextBox {
 //passed coordinates
 float x, y, dx, dy;
 //int 0-255
 int txt;
 //boolean check for state
 boolean focus;
 
 public TextBox(float x, float y, float dx, float dy) {
   this.x = x;
   this.y = y;
   this.dx = dx;
   this.dy = dy;
   txt = 0;
 }
 
 public void keyPressed() {
   if(focus) {
     if(key == BACKSPACE) {
       //remove last number from txt if key is backspace
       String tmp = "";
       tmp = ""+txt;
       tmp = tmp.substring(0, tmp.length()-1);
       if(tmp.length() <= 0) txt = 0; else txt = int(tmp);
     } else {
       //check if key is number and add it to txt if sum would be under 256
       int tmp = int(key)-48;
       if(tmp >= 0 && tmp <= 9)
         if((txt*10)+tmp < 256)
           txt = (txt*10)+tmp;
     }
   }
 }
 
 public void show() {
   fill(0,0,0,0);   
   rect(x,y,dx,dy); //txt container
   
   fill(255);
   text(txt, x+5, y+18); //txt
 }
}
