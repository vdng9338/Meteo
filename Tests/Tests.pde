import ucar.nc2.NetcdfFile;
import ucar.nc2.Variable;
import ucar.ma2.Index;
import java.util.Date;

final float ZERO_ABSOLU_CELSIUS = -273.15;

File chemin;
NetcdfFile fichierNetcdf;
IndexMeteoFrance indexMeteoFrance;
volatile String message;
int etape = 0;
boolean change = false;
File cheminResume; 

Date getDate(Variable varTime, int iDate) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  return unit.makeDate(varTime.read().getDouble(iDate));
}

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

float getInformationFloat(float lat, float lon, Date date, String nom, boolean inclureAltitude) throws IOException {
  CoordonneeGrille index = chercherIndexPlusProche(lat, lon, fichierNetcdf);
  Variable var = fichierNetcdf.findVariable(nom);
  if(var != null) {
    // Dimensions : time/time1, (height_above_ground/1,) lat, lon
    Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
    Array tab = var.read();
    Index indexTemp = tab.getIndex();
    if(inclureAltitude) {
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

float getTemperatureCelsius(float lat, float lon, Date date) throws IOException {
  float temperatureK = getInformationFloat(lat, lon, date, "Temperature_height_above_ground", true);
  if(temperatureK == ZERO_ABSOLU_CELSIUS)
    return ZERO_ABSOLU_CELSIUS;
  else
    return temperatureK + ZERO_ABSOLU_CELSIUS;
}

void setup() {
  size(400,200);
  background(#ffffff);
  frameRate(30);
  fill(#000000);
  thread("chargerIndexMeteoFrance");
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
    Echeance arpege = indexMeteoFrance.getModele("ARPEGE", "0.1").getPack("SP1").getEcheances().get(0);
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

void ecrireResume() throws IOException {
  message = "Ecriture du résumé...";
  PrintWriter output = createWriter(cheminResume);
  output.println("MàJ automatique : https://donneespubliques.meteofrance.fr/donnees_libres/Static/CacheDCPC_NWP.json");
  output.println("URL de téléchargement : http://dcpc-nwp.meteo.fr/services/PS_GetCache_DCPCPreviNum?token=__5yLVTdr-sGeHoPitnFc7TZ6MhBcJxuSsoZp6y0leVHU__&model={modele}&grid={grid}&package={SP1/SP2}&time={time}&referencetime={date du run}&format=grib2");
  output.println("Fichier " + chemin.getName() + "\n");
  for(Variable var : fichierNetcdf.getVariables())
    output.println(var);
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
  
  
  
  
  output.flush();
  output.close();
  
  message = "";
}