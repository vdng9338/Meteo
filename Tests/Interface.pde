import java.text.SimpleDateFormat;

SimpleDateFormat formatDate = new SimpleDateFormat("dd/MM/yyyy 'à' HH'h'");

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
  boolean modifie = true;
  
  private PGraphics contenu;
  public ChoixVille (PGraphics contenu, List<Commune> villes, int debut) {
    //texte = "";
    this.listeVilles = villes;
    this.contenu = contenu;
    this.debut = debut;
  }
   
  PGraphics getContenu() {
    if(modifie) {
      String affichage;
      contenu.beginDraw();
      contenu.background(#ffffff);
      contenu.fill(#000000);
      contenu.text("Sélectionnez une ville", GAUCHE, 50);
      if(listeVilles.size()>=debut+6){
        contenu.text((debut+1) + "-" + (debut+6) + "/" + listeVilles.size(), GAUCHE, 80);
      }else{
        contenu.text((debut+1) + "-" + listeVilles.size() + "/" + listeVilles.size(), GAUCHE, 80);
      }
      for(int i=0; i<=5; i++){
        if(i+debut < listeVilles.size()){
          affichage = listeVilles.get(i+debut).nom + "  :  " + listeVilles.get(i+debut).pays + " : " + listeVilles.get(i+debut).ressemblance;
          contenu.fill(#ffffff);
          contenu.rect(GAUCHE, HAUT+40*i, 250, 40, 3);
          contenu.fill(#000000);
          contenu.text(affichage, GAUCHE+10, HAUT+40*i+20);
        }
      }
      if(listeVilles.size()>debut+6){
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
      contenu.fill(#ffffff);
      contenu.rect(100, 400, 80, 40, 7);
      contenu.fill(#000000);
      contenu.text("Retour", 110, 425);
      contenu.endDraw();
      modifie = false;
    }
    return contenu;
  }
  
  void keyPress() {
    if(key == ENTER)
      fenetre = new DemandeVille(createGraphics(600,500));
    if(key == CODED){
      if(keyCode == RIGHT && debut+6<listeVilles.size()) {
        //fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut+6);
        debut += 6;
        modifie = true;
      }
      if(keyCode == LEFT && debut>0) {
        //fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut-6);
        debut -= 6;
        modifie = true;
      }
    }
  }
  
  void mouseClick(){
    Commune choix;
    if(mouseX >= GAUCHE && mouseX <= GAUCHE+200 && mouseY>=HAUT && mouseY<=HAUT+200) {
      try{
        if(mouseY>=HAUT && mouseY<=HAUT+40){
          choix = this.listeVilles.get(debut+0);
        } else if(mouseY>HAUT+40 && mouseY<=HAUT+80){
          choix = this.listeVilles.get(debut+1);
        } else if(mouseY>HAUT+80 && mouseY<=HAUT+120){
          choix = this.listeVilles.get(debut+2);
        } else if(mouseY>HAUT+120 && mouseY<=HAUT+160){
          choix = this.listeVilles.get(debut+3);
        } else if(mouseY>HAUT+160 && mouseY<=HAUT+200){
          choix = this.listeVilles.get(debut+4);
        } else {
          choix = null;
        }
        
        fenetre = new AfficheResume(createGraphics(600,500), choix);
      } catch (Exception ex) {
        ex.printStackTrace();
      }
    }
    if(mouseY>=350 && mouseY<=390){
      if(mouseX>=270 && mouseX<=350 && debut+6<listeVilles.size()) {
        //fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut+6);
        debut += 6;
        modifie = true;
      }
      if(mouseX>=100 && mouseX<=180 && debut>0) {
        //fenetre = new ChoixVille(createGraphics(600,500), listeVilles, debut-6);
        debut -= 6;
        modifie = true;
      }
    }
    if(mouseY >= 400 && mouseY <= 440 && mouseX >= 100 && mouseX <= 180) {
      fenetre = new DemandeVille(createGraphics(600,500));
    }
  }
}

// Affiche le résumé de la météo
class AfficheResume implements Fenetre {
  final int HAUT = 0, GAUCHE = 0;  
  List<Commune> listeVilles;
  
  private PGraphics contenu;
  public AfficheResume (PGraphics contenu, Commune ville) {
    println(ville);
    
    try{
    
    contenu.beginDraw();
    contenu.fill(#ffffff);
    contenu.rect(0, 0, 200, 20);
    contenu.fill(#000000);
    contenu.textSize(14);
    contenu.text(ville.nom + ", " + ville.pays, GAUCHE+5, HAUT+15);
    if(ville.coordonneeGrille().estBordGrille()) {
      contenu.text("La ville est probablement hors de la grille !", GAUCHE+5, HAUT+35);
    }
    
      contenu.text("Températures à " + ville.nom + " du " + formatDate.format(getDateDebut()) + " au " + formatDate.format(getDateFin()) + " :", GAUCHE, HAUT+55);
      
      int size = getNbDates();
      Date date = getDateDebut();
      for(int iDate = 0; iDate < size; iDate++) {
        try {
          float temp = getTemperatureCelsius(ville.lat, ville.lon, date);
          contenu.text(String.format("%s : %.1f°C", formatDate.format(date), temp), GAUCHE+20, HAUT +55 + (iDate+1)*20);
          date = plusUneHeure(date);
        } catch (Exception ex){
          ex.printStackTrace();
        }
      }
      
      float precipitations = getPrecipitation(ville.lat, ville.lon, getDateDebut(), getDateFin());
      float neige = getFonteNeige(ville.lat, ville.lon, getDateDebut(), getDateFin());
      String interpretationPluie = ", pas de pluie (ou presque)";
      if(precipitations >= 1*(size-1) && precipitations < 4*(size-1))
        interpretationPluie = ", pluie faible";
      else if(precipitations >= 4*(size-1) && precipitations < 8*(size-1))
        interpretationPluie = ", pluie modérée";
      else if(precipitations >= 8*(size-1))
        interpretationPluie = ", pluie forte";
        
      contenu.text(String.format("Précipitations : %.1f kg/m2%s", precipitations, interpretationPluie), GAUCHE+20, HAUT+55+(getNbDates()+3)*20);
      contenu.text(String.format("Dont neige : %.1f kg/m2", neige), GAUCHE+20, HAUT+55+(getNbDates()+4)*20);
      contenu.text(String.format("Dont pluie : %.1f mm", precipitations-neige), GAUCHE+20, HAUT+55+(getNbDates()+5)*20);
    } catch (Exception ex){
      ex.printStackTrace();
    }
    
    contenu.text("Pressez ENTREE pour chercher une autre ville", GAUCHE+100, HAUT+450);
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