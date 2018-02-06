// Une interface qui permet notamment de séparer les fonctions draw(), mouseClick() etc. pour chaque affichage.
interface Fenetre {
  PGraphics getContenu() ;
  
  void mouseClick();
  void keyPress();
}

void draw() {
  background(#ffffff);
  textSize(15);
  if(fenetre != null)
    image(fenetre.getContenu(), 0, 0);
  text(message, 10, 15);
}

// Deux boutons : chargement automatique ou manuel.
class EcranAccueil implements Fenetre {
  final int HAUT = 230, GAUCHE = 90;  
  
  private PGraphics contenu;
  public EcranAccueil(PGraphics contenu) {
    contenu.beginDraw();
    contenu.rect(GAUCHE, HAUT, 200, 40, 7);
    contenu.rect(GAUCHE+210, HAUT, 200, 40, 7);
    contenu.fill(#000000);
    contenu.textSize(15);
    contenu.text("Chargement manuel", GAUCHE+10, HAUT+20);
    contenu.text("Chargement automatique", GAUCHE+210+5, HAUT+20);
    contenu.endDraw();
    this.contenu = contenu;
  }
  
  PGraphics getContenu() {
    return contenu;
  }
  
  void mouseClick() {
    if(mouseX >= GAUCHE && mouseX <= GAUCHE+200 && mouseY >= HAUT && mouseY <= HAUT+40) {
      selectInput("Sélectionnez un fichier GRIB2", "ouvrirGrib");
    }
    else if(mouseX >= GAUCHE+210 && mouseX <= GAUCHE+210+200 && mouseY >= HAUT && mouseY <= HAUT+40) {
      fenetre = null;
      thread("chargerIndexMeteoFrance");
    }
  }
  
  void keyPress(){}
}


// Demande d'entrer le nom d'une ville.
class DemandeVille implements Fenetre {
  final int HAUT = 230, GAUCHE = 90;  
  private String texte = "";
  
  private PGraphics contenu;
  public DemandeVille(PGraphics contenu) {
    this.contenu = contenu;
  }
  
  PGraphics getContenu() {
    contenu.beginDraw();
    contenu.background(#ffffff);
    contenu.fill(#000000);
    contenu.textSize(15);
    contenu.text("Entrez le nom d'une ville : ", GAUCHE+10, HAUT+20);
    contenu.text("Validez par Entrée.", GAUCHE + 10, HAUT + 40);
    if(texte != null)
      contenu.text(texte, GAUCHE+210+5, HAUT+20);
    contenu.endDraw();
    return contenu;
  }
  
  void keyPress() {
    if (key!=CODED) {
      println(key);
      if (key==BACKSPACE) {
        if (texte.length()>0) {
          texte=texte.substring(0, texte.length()-1);
        } // if
      } else if (key==RETURN || key==ENTER) {
        fenetre = new ChoixVille(createGraphics(600,500), rechercheVilles(texte), 0);
      } else {
        texte+=key;
      }
    }
  }
  
  void mouseClick(){}
}

// Demande de sélectionner une ville parmi celles proposées.
class ChoixVille implements Fenetre {
  final int HAUT = 100, GAUCHE = 100;  
  List<Commune> listeVilles;
  int debut = 0;
  
  private PGraphics contenu;
  public ChoixVille (PGraphics contenu, List<Commune> villes, int debut) {
    //texte = "";
    String affichage;
    this.listeVilles = villes;
    this.debut = debut;
    contenu.beginDraw();
    contenu.fill(#000000);
    contenu.text("Sélectionnez une ville", GAUCHE, 50);
    if(villes.size()>=debut+6){
      contenu.text((debut+1) + "-" + (debut+6) + "/" + villes.size(), GAUCHE, 80);
    }else{
      contenu.text((debut+1) + "-" + villes.size() + "/" + villes.size(), GAUCHE, 80);
    }
    for(int i=0; i<=5; i++){
      if(i+debut < villes.size()){
        affichage = villes.get(i+debut).nom + "  :  " + villes.get(i+debut).pays + " : " + villes.get(i+debut).ressemblance;
        contenu.fill(#ffffff);
        contenu.rect(GAUCHE, HAUT+40*i, 250, 40, 3);
        contenu.fill(#000000);
        contenu.text(affichage, GAUCHE+10, HAUT+40*i+20);
      }
    }
    if(villes.size()>debut+6){
      contenu.fill(#ffffff);
      contenu.rect(270, 350, 80, 40, 7);
      contenu.fill(#000000);
      contenu.text("Suivant →", 280, 370);
    }
    if(debut>0){
      contenu.fill(#ffffff);
      contenu.rect(100, 350, 80, 40, 7);
      contenu.fill(#000000);
      contenu.text("← Précédent", 110, 370);
    }
    contenu.endDraw();
    this.contenu = contenu;
  }
   
  PGraphics getContenu() {
    return contenu;
  }
  
  void keyPress() {
    if(key == ENTER)
      fenetre = new DemandeVille(createGraphics(600,500));
    if(key == CODED){
      if(keyCode == RIGHT && debut+6<listeVilles.size())
        fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut+6);
      if(keyCode == LEFT && debut>0)
        fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut-6);
    }
  }
  
  void mouseClick(){
    Commune choix;
    if(mouseX >= GAUCHE && mouseX <= GAUCHE+200 && mouseY>=HAUT && mouseY<=HAUT+200) {
      try{
        if(mouseY>=HAUT && mouseY<=HAUT+40){
          choix = this.listeVilles.get(0+debut);
        } else if(mouseY>HAUT+40 && mouseY<=HAUT+80){
          choix = this.listeVilles.get(1+debut);
        } else if(mouseY>HAUT+80 && mouseY<=HAUT+120){
          choix = this.listeVilles.get(2+debut);
        } else if(mouseY>HAUT+120 && mouseY<=HAUT+160){
          choix = this.listeVilles.get(3+debut);
        } else if(mouseY>HAUT+160 && mouseY<=HAUT+200){
          choix = this.listeVilles.get(4+debut);
        } else if(mouseY>HAUT+200 && mouseY<=HAUT+240){
          choix = this.listeVilles.get(5+debut);
        } else {
          choix = null;
        }
        
        fenetre = new AfficheResume(createGraphics(600,500), choix);
      } catch (Exception ex) {
        ex.printStackTrace();
      }
    }
    if(mouseY>=350 && mouseY<=390){
      if(mouseX>=270 && mouseX<=350 && debut+6<listeVilles.size())
        fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut+6);
      if(mouseX>=100 && mouseX<=180 && debut>0)
        fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut-6);
    }
  }
}

// Affiche le résumé de la météo
class AfficheResume implements Fenetre {
  final int HAUT = 100, GAUCHE = 20;  
  List<Commune> listeVilles;
  
  private PGraphics contenu;
  public AfficheResume (PGraphics contenu, Commune ville) {
    println(ville);
    contenu.beginDraw();
    contenu.fill(#000000);
    contenu.text(ville.nom, GAUCHE, HAUT);
    contenu.text(ville.pays, GAUCHE, HAUT+40);
    contenu.text(ville.lat, GAUCHE, HAUT+80);
    contenu.text(ville.lon, GAUCHE, HAUT+120);
    
    Variable var = fichierNetcdf.findVariable("Temperature_height_above_ground");
    Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
    try{
      contenu.text("Températures à " + ville.nom + " de " + getDateDebut() + " à " + getDateFin(), GAUCHE+100, HAUT);
      
      int size = (int) lireVariable(varTime).getSize();
      for(int iDate = 0; iDate < size; iDate++) {
        try {
          Date date = getDate(varTime, iDate);
          float temp = getTemperatureCelsius(ville.lat, ville.lon, date);
          //temp = temp.substring(0,4);
          contenu.text(String.format("%s : %.1f°C", date.toString(), temp), GAUCHE+100, HAUT +30 + iDate*20);
          //contenu.text( date + " : " + temp + "°C", GAUCHE+100, HAUT +30 + iDate*20);
        } catch (Exception ex){}
      }
      
      float precipitations = getPrecipitation(ville.lat, ville.lon, getDateDebut(), getDateFin());
      contenu.text(String.format("Précipitations : %.1fmm", precipitations), GAUCHE+100, HAUT+300);
    } catch (Exception ex){}
    
    contenu.text("Pressez ENTREE pour chercher une autre ville", GAUCHE+100, HAUT+400);
    contenu.endDraw();
    this.contenu = contenu;
  }
  
  PGraphics getContenu() {
    return contenu;
  }
  
  void keyPress() {
    if(key == ENTER)
      fenetre = new DemandeVille(createGraphics(600,500));
  }

  void mouseClick() {}
}
