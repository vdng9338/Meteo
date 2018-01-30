

void draw() {
  background(#ffffff);
  textSize(15);
  text(message, 10, 15);
  text(text1, 10, 30);
}

String text1="";

void keyPressed() {
  if (key==CODED) {
    if (keyCode==LEFT) {
      println ("left");
    } else {
      // message
      println ("unknown special key");
    } // else
  } else {
    if (key==BACKSPACE) {
      if (text1.length()>0) {
        text1=text1.substring(0, text1.length()-1);
      } // if
    } else if (key==RETURN || key==ENTER) {
      println ("ENTER");
      try {
        coordonnee = chercherVille(text1);
      } catch (IOException ex) {
        ex.printStackTrace();
      }
      thread("ecrireResume");
    } else {
      text1+=key;
    } // else
    // output
    println (text1);
  } // else
} // func
