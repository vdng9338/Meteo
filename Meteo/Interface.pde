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
  if(message != null)
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
    contenu.text("Validez par Entrée.\nIMPORTANT : Les données fournies par Météo-France sont des\nrésultats de modèles numériques. La création de prévisions\nimplique une analyse par des prévisionnistes.", GAUCHE + 10, HAUT + 40);
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
      contenu.textSize(15);
      contenu.text("Sélectionnez une ville", GAUCHE, 50);
      if(listeVilles.size()>=debut+6){
        contenu.text((debut+1) + "-" + (debut+6) + "/" + listeVilles.size(), GAUCHE, 80);
      }else{
        contenu.text((debut+1) + "-" + listeVilles.size() + "/" + listeVilles.size(), GAUCHE, 80);
      }
      for(int i=0; i<=5; i++){
        if(i+debut < listeVilles.size()){
          affichage = listeVilles.get(i+debut).nom + ", " + listeVilles.get(i+debut).pays;
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
        contenu.rect(100, 350, 100, 40, 7);
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
    Commune choix = null;
    if(mouseX >= GAUCHE && mouseX <= GAUCHE+200 && mouseY>=HAUT && mouseY<=HAUT+240) {
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
        } else if(mouseY>HAUT+200 && mouseY<HAUT+240) {
          choix = this.listeVilles.get(debut+5);
        }
        
        fenetre = new AfficheResume(createGraphics(600,500), choix);
      } 
      catch (ArrayIndexOutOfBoundsException ex) {}
      catch (Exception ex) {
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
  Date date;
  Commune ville;
  boolean modifie = true;
  String erreur = "";
  
  private PGraphics contenu;
  public AfficheResume (PGraphics contenu, Commune ville) {
    println(ville);
    this.ville = ville;
    this.contenu = contenu;
    try {
      this.date = getDateDebut();
    } catch (IOException ex) {
      ex.printStackTrace();
      erreur = "Un problème est survenu !";
    }
  }
  
  PGraphics getContenu() {
    if(!modifie)
      return contenu;
    contenu.beginDraw();
    try{
      int milieuHoriz = contenu.width/2;
      int bas = contenu.height;
      
      
      contenu.background(#ffffff);
      contenu.fill(#ffffff);
      contenu.rect(0, 0, 200, 20);
      contenu.fill(#000000);
      contenu.textSize(14);
      contenu.text(ville.nom + ", " + ville.pays, GAUCHE+5, HAUT+15);
      if(ville.coordonneeGrille().estBordGrille()) {
        erreur = "Attention, la ville est probablement hors de la grille !";
      }
      contenu.fill(#ff0000);
      contenu.text(erreur, GAUCHE+5, HAUT+35);
      contenu.fill(#000000);
      
      contenu.text("Données disponibles du " + formatDate.format(getDateDebut()) + " au " + formatDate.format(getDateFin()), GAUCHE, HAUT+55);
      
      float temp = getTemperatureCelsius(ville.lat, ville.lon, date);
      contenu.text(String.format("Température : %.1f°C", temp), GAUCHE+20, HAUT +55 + 40);
      float directionVent = (getDirectionOrigineVent(ville.lat, ville.lon, date) + 180) % 360;
      float vitesseVentKmh = getVitesseVent(ville.lat, ville.lon, date) * 3.6;
      float vitesseRafalesKmh = getVitesseRafales(ville.lat, ville.lon, date) * 3.6;
      contenu.text(String.format("Direction du vent (vers laquelle il souffle) : %.0f°", directionVent), GAUCHE+20, HAUT+55+60); 
      contenu.text(String.format("Vitesse du vent : %.0f km/h", vitesseVentKmh), GAUCHE+20, HAUT+55+80);
      contenu.text(String.format("Rafales : %.0f km/h", vitesseRafalesKmh), GAUCHE+20, HAUT+55+100);
      
      float nuage = getNebulositeTotale(ville.lat, ville.lon, date);
      String interpretationNuage = ", ciel dégagé";
      if(nuage >= 12.5 && nuage < 37.5)
        interpretationNuage = ", quelques nuages";
      else if(nuage >= 37.5 && nuage < 75.0)
        interpretationNuage = ", ciel nuageux";
      else if(nuage >= 75.0)
        interpretationNuage = ", ciel très couvert";
      contenu.text(String.format("Nébulosité (nuages) : %.0f%%%s", nuage, interpretationNuage), GAUCHE+20, HAUT+55+120);
      
      drawArrow(contenu, GAUCHE+400, HAUT+55+60, 30, directionVent);
      
      if(!date.equals(getDateFin())) {
        float precipitations = getPrecipitation(ville.lat, ville.lon, date, plusUneHeure(date));
        float neige = getFonteNeige(ville.lat, ville.lon, date, plusUneHeure(date));
        float pluie = Math.max(0, precipitations-neige);
        String interpretationPluie = ", pas de pluie (ou presque)";
        if(pluie >= 1 && pluie < 4)
          interpretationPluie = ", pluie faible";
        else if(pluie >= 4 && pluie < 8)
          interpretationPluie = ", pluie modérée";
        else if(pluie >= 8)
          interpretationPluie = ", pluie forte";
        
        contenu.text(String.format("Précipitations sur l'heure qui suit : %.1f kg/m²", precipitations), GAUCHE+20, HAUT+55+(getNbDates()+2)*20);
        contenu.text(String.format("Dont neige : %.1f kg/m²", neige), GAUCHE+20, HAUT+55+(getNbDates()+3)*20);
        contenu.text(String.format("Dont pluie : %.1f mm%s", pluie, interpretationPluie), GAUCHE+20, HAUT+55+(getNbDates()+4)*20);
      }
        
      if(!this.date.equals(getDateDebut())) {
        contenu.fill(#ffffff);
        contenu.rect(milieuHoriz-100, bas-60, 20, 20, 7);
        contenu.fill(#000000);
        contenu.text("<", milieuHoriz-100+5, bas-45);
      }
      if(!this.date.equals(getDateFin())) {
        contenu.fill(#ffffff);
        contenu.rect(milieuHoriz+80, bas-60, 20, 20, 7);
        contenu.fill(#000000);
        contenu.text(">", milieuHoriz+80+5, bas-45);
      }
      contenu.text(formatDate.format(this.date), milieuHoriz-60, bas-45);
      
      contenu.fill(#ffffff);
      contenu.rect(milieuHoriz-50, bas-30, 100, 30, 7);
      contenu.fill(#000000);
      contenu.text("Retour", milieuHoriz-22, bas-10);
    } catch (Exception ex){
      ex.printStackTrace();
      erreur = "Une erreur est survenue !";
      contenu.fill(#ff0000);
      contenu.text(erreur, GAUCHE+5, HAUT+35);
      contenu.fill(#000000);
    }
    
    //contenu.text("Pressez ENTREE pour chercher une autre ville", GAUCHE+100, HAUT+450);
    contenu.endDraw();
    modifie = false;
    return contenu;
  }
  
  void drawArrow(PGraphics contenu, int cx, int cy, int len, float angle){
    contenu.pushMatrix();
    contenu.translate(cx, cy);
    contenu.rotate(radians(angle-90)); // 0 degrés signifie droite, 90 bas, 180 gauche, 270 haut. Donc on tourne tout de 90 deg dans le sens trigonométrique
    contenu.line(0,0,len, 0);
    contenu.line(len, 0, len - 8, -8);
    contenu.line(len, 0, len - 8, 8);
    contenu.popMatrix();
  }
  
  void keyPress() {
    try {
      if(key == ENTER)
        fenetre = new DemandeVille(createGraphics(600,500));
      else if(key == CODED && keyCode == LEFT)
        datePrecedente();
      else if(key == CODED && keyCode == RIGHT)
        dateSuivante();
    } catch (Exception ex) {
      erreur = "Une erreur est survenue !";
    }
  }

  void dateSuivante() throws IOException {
    if(!date.equals(getDateFin())) {
      date = plusUneHeure(date);
      modifie = true;
    }
  }
  
  void datePrecedente() throws IOException {
    if(!date.equals(getDateDebut())) {
      date = moinsUneHeure(date);
      modifie = true;
    }
  }

  void mouseClick() {
    try {
      int bas = contenu.height;
      int milieu = contenu.width/2;
      if(mouseY >= bas-60 && mouseY <= bas-40) {
        if(mouseX >= milieu-100 && mouseX <= milieu-80) {
          datePrecedente();
        }
        else if(mouseX >= milieu+80 && mouseX <= milieu+100) {
          dateSuivante();
        }
      }
      if(mouseY >= bas-30 && mouseY <= bas) {
        if(mouseX >= milieu-50 && mouseX <= milieu+50) {
          fenetre = new DemandeVille(createGraphics(600,500));
        }
      }
    } catch (Exception ex) {
      erreur = "Une erreur est survenue !";
      modifie = true;
      ex.printStackTrace();
    }
  }
}
