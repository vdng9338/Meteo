import ucar.nc2.NetcdfFile;
import ucar.nc2.Variable;
import ucar.ma2.Index;
import java.util.Date;

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

int etape = 0;
// Le chemin d'enregistrement d'un résumé.
File cheminResume; 


// Récupère la (iDate+1)-ième date de la variable passée en paramètre sous la forme d'une Date Java.
Date getDate(Variable varTime, int iDate) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  return unit.makeDate(varTime.read().getDouble(iDate));
}

// Donne l'index d'une certaine date (exacte à la milliseconde près) dans la variable passée en paramètre.
int indexDate(Variable varTime, Date dateRecherche) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  Array tab = varTime.read();
  for(int i = 0; i < tab.getSize(); i++) {
    double valeur = tab.getDouble(i);
    Date date = unit.makeDate(valeur);
    if(date.equals(dateRecherche)) // à l'heure près ?
      return i;
  }
  return -1;
}


// TODO : Très confus... Censé retourner l'index de l'intervalle dont la fin est dateRecherche.
int indexDateFinIntervalle(Variable varTimeBounds, Variable varTime, Date dateRecherche) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  Array refs = varTime.read();
  Array bounds = varTimeBounds.read();
  for(int i = 0; i < refs.getSize(); i++) {
    double reference = refs.getDouble(i);
    Index indexBounds = bounds.getIndex();
    indexBounds.set0(i);
    indexBounds.set1(0);
    double coord1 = bounds.getDouble(indexBounds);
    indexBounds.set1(1);
    double coord2 = bounds.getDouble(indexBounds);
    double heure = reference + (coord2 - coord1);
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
    Array tab = var.read();
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
  Array tab = var.read();
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
  size(400,200);
  background(#ffffff);
  frameRate(30);
  fill(#000000);
  thread("chargerIndexMeteoFrance"); // permet de laisser l'application répondre pendant que l'index est téléchargé
}

void draw() {
  background(#ffffff);
  textSize(15);
  text(message, 10, 15);
}

void chargerIndexMeteoFrance() {
  message = "Chargement de l'index de Météo-France...";
  /*try {
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
  } catch (Exception ex) {
    ex.printStackTrace();
    indexMeteoFrance = null;
  }*/
  message = "";
  selectInput("Sélectionnez un fichier GRIB2", "ouvrirGrib");
}

void ouvrirGrib(File fichier) {
  if(fichier == null)
    return;
  chemin = fichier;
  thread("chargerFichierNetcdf");
}

void chargerFichierNetcdf() throws IOException {
  message = "Chargement du fichier GRIB...";
  fichierNetcdf = NetcdfFile.open(chemin.getPath());
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
void ecrireResume() throws IOException {
  message = "Ecriture du résumé...";
  PrintWriter output = createWriter(cheminResume);

  // Quelques messages systématiques
  output.println("MàJ automatique : https://donneespubliques.meteofrance.fr/donnees_libres/Static/CacheDCPC_NWP.json");
  output.println("URL de téléchargement : http://dcpc-nwp.meteo.fr/services/PS_GetCache_DCPCPreviNum?token=__5yLVTdr-sGeHoPitnFc7TZ6MhBcJxuSsoZp6y0leVHU__&model={modele}&grid={grid}&package={SP1/SP2}&time={time}&referencetime={date du run}&format=grib2");
  output.println("Fichier " + chemin.getName() + "\n");

  for(Variable var : fichierNetcdf.getVariables())
    output.println(var); // Affiche le type, le nom, les dimensions et les attributs de chaque variable
  output.println("\n---------------------\n");
  
  
  
  // Nantes
  output.print("Coordonnées de Nantes (47.1636, -1.1137) dans la grille : ");
  CoordonneeGrille indexNantes = chercherIndexPlusProche(47.1636, -1.1137, fichierNetcdf);
  output.println(indexNantes.getLat() + " " + indexNantes.getLon() + " (" + indexNantes.getVraieLat() + ", " + indexNantes.getVraieLon() + ")");
  
  try {
    Variable varTime = fichierNetcdf.findVariable("time");
    output.println(getDate(varTime, 0));
  } catch (Exception ex ) {
    ex.printStackTrace();
  }
  
  // Affichage de toutes les températures disponibles dans le fichier à Nantes
  Variable varTemp = fichierNetcdf.findVariable("Temperature_height_above_ground");
  if(varTemp != null) {
    // Dimensions : time/time1, height_above_ground, lat, lon
    Variable varTime = fichierNetcdf.findVariable(varTemp.getDimension(0).getFullNameEscaped());
    int nbDates = (int)varTime.read().getSize();
    for(int iDate = 0; iDate < nbDates; iDate++) {
      Date date = getDate(varTime, iDate);
      float tempC = getTemperatureCelsius(47.1636, -1.1137, date);
      output.println("Température à Nantes le " + date + " : " + (tempC) + " C");
    }
  }
  
  output.println("\n-------------------\n");
  
  output.println(fichierNetcdf.findVariable("time1_bounds").read());
  output.println(fichierNetcdf.findVariable("time1").read());
  
  output.println("\n--------------------\n");
  
  // J'essaye de comprendre comment fonctionnent les précipitations... Et les noms de variable changent
  Variable varPrecip = fichierNetcdf.findVariable("Total_precipitation_rate_surface_Mixed_intervals_Accumulation");
  Array ar = varPrecip.read();
  Variable varTime = fichierNetcdf.findVariable("time");
  Array ar2 = varTime.read();
  for(int i = 0; i < ar2.getSize(); i++) {
    Index ind = ar.getIndex();
    ind.set0(i);
    ind.set1(indexNantes.getLat());
    ind.set2(indexNantes.getLon());
    output.println(ar.getFloat(ind));
  }
  
  
  
  output.flush();
  output.close();
  
  // On a fini !
  message = "";
}
