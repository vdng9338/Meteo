import ucar.nc2.NetcdfFile;
import ucar.nc2.Variable;
import ucar.ma2.Index;
import java.util.Date;
import java.util.TreeMap;

/**
 * Le zéro absolu (0K) est de -273.15 C. Sert aussi de valeur non définie en float. (à séparer ?)
 */
final float ZERO_ABSOLU_CELSIUS = -273.15;

// Le chemin du fichier GRIB sélectionné.
File chemin;
// Le fichier GRIB en lui-même.
NetcdfFile fichierNetcdf;
// L'index des fichiers disponibles chez Météo-France.
IndexMeteoFrance indexMeteoFrance;
// Un message à afficher.
volatile String message;
// La fenetre affichée.
Fenetre fenetre;

interface Fenetre {
  PGraphics getContenu() ;
  
  void mouseClick();
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
}

// Le chemin d'enregistrement d'un résumé.
File cheminResume; 
// Evite de relire les variables à chaque accès.
TreeMap<String, Array> cacheVariables = new TreeMap<String, Array>();

// Lit une variable seulement si c'est nécessaire.
Array lireVariable(Variable var) throws IOException {
  if(var == null)
    return null;
  String nom = var.getFullNameEscaped();
  if(cacheVariables.containsKey(nom))
    return cacheVariables.get(nom);
  Array tab = var.read();
  cacheVariables.put(nom, tab);
  return tab;
}

// Récupère la (iDate+1)-ième date de la variable passée en paramètre sous la forme d'une Date Java.
Date getDate(Variable varTime, int iDate) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  return unit.makeDate(lireVariable(varTime).getDouble(iDate));
}

Date plusUneHeure(Date date) {
  return new Date(date.getTime() + 3600 * 1000);
}

// Donne l'index d'une certaine date (exacte à la milliseconde près) dans la variable passée en paramètre.
int indexDate(Variable varTime, Date dateRecherche) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  Array tab = lireVariable(varTime);
  for(int i = 0; i < tab.getSize(); i++) {
    double valeur = tab.getDouble(i);
    Date date = unit.makeDate(valeur);
    if(date.equals(dateRecherche)) // à l'heure près ?
      return i;
  }
  return -1;
}


// Retourne l'index de l'intervalle dont la fin est dateRecherche.
int indexDateFinIntervalle(Variable varTimeBounds, Variable varTime, Date dateRecherche) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  Array refs = lireVariable(varTime);
  Array bounds = lireVariable(varTimeBounds);
  for(int i = 0; i < refs.getSize(); i++) {
    double reference = /*refs.getDouble(i)*/ 0; // à quoi sert le time ?
    Index indexBounds = bounds.getIndex();
    indexBounds.set0(i);
    indexBounds.set1(0);
    double coord1 = bounds.getDouble(indexBounds);
    indexBounds.set1(1);
    double coord2 = bounds.getDouble(indexBounds);
    double heure = reference + Math.abs(coord2 - coord1);
    Date dateCorresp = unit.makeDate(heure);
    if(dateRecherche.equals(dateCorresp))
      return i;
  }
  return -1;
}

// Fonction générique qui retourne une information float avec les paramètres donnés.
float getInformationFloat(float lat, float lon, Date date, String nom) throws IOException {
  CoordonneeGrille index = chercherIndexPlusProche(lat, lon, fichierNetcdf);
  Variable var = fichierNetcdf.findVariable(nom);
  if(var != null) {
    // Dimensions : time/time1, (height_above_ground/1,) lat, lon
    Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
    Array tab = lireVariable(var);
    Index indexTemp = tab.getIndex();
    if(nom.contains("height_above_ground")) {
      indexTemp.set1(0);
      indexTemp.set2(index.getLat());
      indexTemp.set3(index.getLon());
    }
    else {
      indexTemp.set1(index.getLat());
      indexTemp.set2(index.getLon());
    }
    int iDate = indexDate(varTime, date);
    indexTemp.set0(iDate);
    float val = tab.getFloat(indexTemp);
    return val;
  }
  return ZERO_ABSOLU_CELSIUS;
}

// TODO : Extrêmement confus. Retourne une information qui porte sur un intervalle (précipitations ou neige).
float getInformationIntervalle(float lat, float lon, Date depuis, Date jusqua, String nom) throws IOException {
  CoordonneeGrille index = chercherIndexPlusProche(lat, lon, fichierNetcdf);
  Variable var = fichierNetcdf.findVariable(nom);
  Array tab = lireVariable(var);
  Variable varDate = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
  Variable varDateBounds = fichierNetcdf.findVariable(varDate.findAttribute("bounds").getStringValue());
  int indexDateDepuis = indexDateFinIntervalle(varDateBounds, varDate, depuis);
  int indexDateJusqua = indexDateFinIntervalle(varDateBounds, varDate, jusqua);
  Index indexTab = tab.getIndex();
  if(nom.contains("height_above_ground")) {
    indexTab.set1(0);
    indexTab.set2(index.getLat());
    indexTab.set3(index.getLon());
  }
  else {
    indexTab.set1(index.getLat());
    indexTab.set2(index.getLon());
  }
  indexTab.set0(indexDateDepuis);
  float informationDepuis = tab.getFloat(indexTab);
  indexTab.set0(indexDateJusqua);
  float informationJusqua = tab.getFloat(indexTab);
  return informationJusqua - informationDepuis;
}

Date getDateDebut() throws IOException {
  Variable var = fichierNetcdf.findVariable("Temperature_height_above_ground");
  Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
  Date min = null;
  int size = (int) lireVariable(varTime).getSize();
  for(int iDate = 0; iDate < size; iDate++) {
    Date date = getDate(varTime, iDate);
    if(min == null || date.compareTo(min) < 0)
      min = date;
  }
  return min;
}

Date getDateFin() throws IOException {
  Variable var = fichierNetcdf.findVariable("Temperature_height_above_ground");
  Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
  Date max = null;
  int size = (int) lireVariable(varTime).getSize();
  for(int iDate = 0; iDate < size; iDate++) {
    Date date = getDate(varTime, iDate);
    if(max == null || date.compareTo(max) > 0)
      max = date;
  }
  return max;
}

// Les fonctions suivantes douvent être assez claires.

float getTemperatureCelsius(float lat, float lon, Date date) throws IOException {
  float temperatureK = getInformationFloat(lat, lon, date, "Temperature_height_above_ground");
  if(temperatureK == ZERO_ABSOLU_CELSIUS)
    return ZERO_ABSOLU_CELSIUS;
  else
    return temperatureK + ZERO_ABSOLU_CELSIUS;
}

float getPrecipitation(float lat, float lon, Date dateDepuis, Date dateJusqua) throws IOException {
  float precipTotal = getInformationIntervalle(lat, lon, dateDepuis, dateJusqua, "Total_precipitation_rate_surface_Mixed_intervals_Accumulation");
  return precipTotal; // Qu'est-ce que ca veut dire ???
}

float getHumiditeRelative(float lat, float lon, Date date) throws IOException {
  float humidite = getInformationFloat(lat, lon, date, "Relative_humidity_height_above_ground");
  return humidite;
}

// Fonte de neige ou neige tout court ?
float getFonteNeige(float lat, float lon, Date dateDepuis, Date dateJusqua) throws IOException {
  float fonteNeige = getInformationIntervalle(lat, lon, dateDepuis, dateJusqua, "Snow_melt_surface_Mixed_intervals_Average");
  return fonteNeige;
}

float getNebulositeTotale(float lat, float lon, Date date) throws IOException {
  float nebulosite = getInformationFloat(lat, lon, date, "Total_cloud_cover_surface_layer");
  return nebulosite;
}

float getDirectionOrigineVent(float lat, float lon, Date date) throws IOException {
  float direction = getInformationFloat(lat, lon, date, "Wind_direction_from_which_blowing_height_above_ground");
  return direction;
}

float getVitesseVent(float lat, float lon, Date date) throws IOException {
  float vitesse = getInformationFloat(lat, lon, date, "Wind_speed_height_above_ground");
  return vitesse;
}

float getVitesseRafales(float lat, float lon, Date date) throws IOException {
  float vitesse = getInformationFloat(lat, lon, date, "Wind_speed_gust_height_above_ground");
  return vitesse;
}










void setup() {
  size(600, 500);
  background(#ffffff);
  frameRate(30);
  fill(#000000);
  thread("chargement"); // permet de laisser l'application répondre pendant que l'index est téléchargé
}

void chargement() {
  message = "Chargement des communes...";
  chargerTableCommunes();
  message = "Chargement des pays...";
  chargerTablePays();
  message = "Chargement de l'index de Météo-France...";
  //chargerIndexMeteoFrance();
  message = "";
  //selectInput("Sélectionnez un fichier GRIB2", "ouvrirGrib");
  fenetre = new EcranAccueil(createGraphics(600, 500));
}

void draw() {
  background(#ffffff);
  textSize(15);
  if(fenetre != null)
    image(fenetre.getContenu(), 0, 0);
  text(message, 10, 15);
}

void mouseClicked() {
  if(fenetre != null)
    fenetre.mouseClick();
}

void chargerIndexMeteoFrance() {
  message = "Chargement de l'index de Météo-France...";
  try {
    indexMeteoFrance = new IndexMeteoFrance(loadJSONArray("https://donneespubliques.meteofrance.fr/donnees_libres/Static/CacheDCPC_NWP.json"));
    String[][] modeles = new String[][]{{"AROME", "0.01"}, {"ARPEGE", "0.1"}};
    for(String[] nomModele : modeles) {
      Modele modele = indexMeteoFrance.getModele(nomModele[0], nomModele[1]);
      for(Pack pack : modele.getPacks()) {
        for(Echeance echeance : pack.getEcheances()) {
          println(echeance.getNomFichier() + " " + echeance.getUrlTelechargement());
        }
      }
    }
    Echeance arpege = indexMeteoFrance.getModele("ARPEGE", "0.1").getPack("SP1").getEcheances().get(0); // Téléchargement de ARPEGE SP1
    message = "Téléchargement de " + arpege.getNomFichier();
    arpege.telechargerSiNecessaire();
    chemin = new File(dataPath(arpege.getNomFichier()));
    chargerFichierNetcdf();
  } catch (Exception ex) {
    ex.printStackTrace();
    indexMeteoFrance = null;
    message = "Chargement échoué !";
    fenetre = new EcranAccueil(createGraphics(600, 500));
    return;
  }
  message = "";
}

void ouvrirGrib(File fichier) {
  if(fichier == null)
    return;
  fenetre = null;
  chemin = fichier;
  thread("chargerFichierNetcdf");
}

void chargerFichierNetcdf() throws IOException {
  message = "Chargement du fichier GRIB...";
  fichierNetcdf = NetcdfFile.open(chemin.getPath());
  for(Variable var : fichierNetcdf.getVariables())
    lireVariable(var);
  message = "";
  selectOutput("Sélectionnez un fichier où stocker le résumé des variables", "ecrireResume");
}

void ecrireResume(File fichier) {
  if(fichier == null)
    return;
  cheminResume = fichier;
  thread("ecrireResume");
}


// En fait, un véritable fourre-tout de tests et d'affichages.
/*void ecrireResume() throws IOException {
  message = "Ecriture du résumé...";
  PrintWriter output = createWriter(cheminResume);

  // Quelques messages systématiques
  output.println("MàJ automatique : https://donneespubliques.meteofrance.fr/donnees_libres/Static/CacheDCPC_NWP.json");
  output.println("URL de téléchargement : http://dcpc-nwp.meteo.fr/services/PS_GetCache_DCPCPreviNum?token=__5yLVTdr-sGeHoPitnFc7TZ6MhBcJxuSsoZp6y0leVHU__&model={modele}&grid={grid}&package={SP1/SP2}&time={time}&referencetime={date du run}&format=grib2");
  output.println("Fichier " + chemin.getName() + "\n");

  println("Ecriture des variables...");
  for(Variable var : fichierNetcdf.getVariables())
    output.println(var); // Affiche le type, le nom, les dimensions et les attributs de chaque variable
  output.println("\n---------------------\n");
  
  
  
  println("Recherche des coords de Nantes...");
  // Nantes
  output.print("Coordonnées de Nantes (47.1636, -1.1137) dans la grille : ");
  CoordonneeGrille indexNantes = chercherIndexPlusProche(47.1636, -1.1137, fichierNetcdf);
  output.println(indexNantes.getLat() + " " + indexNantes.getLon() + " (" + indexNantes.getVraieLat() + ", " + indexNantes.getVraieLon() + ")");
  
  println("Debug time...");
  try {
    Variable varTime = fichierNetcdf.findVariable("time");
    output.println(getDate(varTime, 0));
  } catch (Exception ex ) {
    ex.printStackTrace();
  }
  
  println("Température...");
  // Affichage de toutes les températures disponibles dans le fichier à Nantes
  Variable varTemp = fichierNetcdf.findVariable("Temperature_height_above_ground");
  if(varTemp != null) {
    // Dimensions : time/time1, height_above_ground, lat, lon
    Variable varTime = fichierNetcdf.findVariable(varTemp.getDimension(0).getFullNameEscaped());
    int nbDates = (int)lireVariable(varTime).getSize();
    for(int iDate = 0; iDate < nbDates; iDate++) {
      Date date = getDate(varTime, iDate);
      float tempC = getTemperatureCelsius(47.1636, -1.1137, date);
      output.println("Température à Nantes le " + date + " : " + (tempC) + " C");
      println("Température à Nantes le " + date + " : " + (tempC) + " C");
    }
  }
  
  output.println("\n-------------------\n");
  
  output.println("\n--------------------\n");
  
  println("Dates...");
  Date dateDebut = getDateDebut(), dateFin = getDateFin();
  output.println(String.format("Données disponibles de %s à %s", dateDebut.toString(), dateFin.toString()));
  output.println(String.format("Précipitations de %s à %s : %s", dateDebut, plusUneHeure(dateDebut), Float.toString(getPrecipitation(47.1636, -1.1137, dateDebut, plusUneHeure(dateDebut)))));
  
  
  output.flush();
  output.close();
  
  // On a fini !
  message = "";
}*/
void ecrireResume() throws IOException {
  message = "Ecriture du résumé...";
  PrintWriter output = createWriter(cheminResume);
  
  //CoordonneeGrille coordonnees = chercherVille(ville);

  // Quelques messages systématiques
  output.println("MàJ automatique : https://donneespubliques.meteofrance.fr/donnees_libres/Static/CacheDCPC_NWP.json");
  output.println("URL de téléchargement : http://dcpc-nwp.meteo.fr/services/PS_GetCache_DCPCPreviNum?token=__5yLVTdr-sGeHoPitnFc7TZ6MhBcJxuSsoZp6y0leVHU__&model={modele}&grid={grid}&package={SP1/SP2}&time={time}&referencetime={date du run}&format=grib2");
  output.println("Fichier " + chemin.getName() + "\n");
  
  
  output.println(coordonnee.getLat());
  output.println(coordonnee.getLon());
  /*for(){
    output.println();
  }*/
  
  output.flush();
  output.close();
  
  // On a fini !
  message = "";
}
