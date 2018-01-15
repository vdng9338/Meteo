import ucar.nc2.NetcdfFile;
import ucar.nc2.Variable;
import ucar.ma2.Index;
import java.util.Date;

File chemin;
NetcdfFile fichierNetcdf;
IndexMeteoFrance indexMeteoFrance;
volatile String message;
final int CHARGEMENT_INDEX = 0;
int etape = 0;
boolean change = false;
File cheminResume; 

class CoordonneeGrille {
  int lat;
  int lon;
  float vraieLat;
  float vraieLon;
  
  public CoordonneeGrille(int lat, int lon, float vraieLat, float vraieLon) {
    this.lat = lat;
    this.lon = lon;
    this.vraieLat = vraieLat;
    this.vraieLon = vraieLon;
  }
  
  public int getLat() {
    return lat;
  }
  
  public int getLon() {
    return lon;
  }
  
  public float getVraieLat() {
    return vraieLat;
  }
  
  public float getVraieLon() {
    return vraieLon;
  }
}

int indexRechercheDichotomieLatitude(Array ar, int debut, int finExcl, double valeur) { // Latitudes décroissantes, longitudes croissantes
  if(debut == finExcl || (debut == finExcl-1 && finExcl == ar.getSize())) {
    return debut;
  }
  else if(debut == finExcl-1) {
    float valDebut = ar.getFloat(debut);
    float valFin = ar.getFloat(finExcl);
    if(Math.abs(valeur - valDebut) < Math.abs(valeur - valFin))
      return debut;
    else
      return finExcl;
  }
  int milieu = (debut + finExcl) / 2;
  float valeurMilieu = ar.getFloat(milieu);
  if(valeur == valeurMilieu)
    return milieu;
  else if(valeurMilieu < valeur) {
    return indexRechercheDichotomieLatitude(ar, debut, milieu, valeur);
  }
  else
    return indexRechercheDichotomieLatitude(ar, milieu, finExcl, valeur);
}

int indexRechercheDichotomieLongitude(Array ar, int debut, int finExcl, double valeur) { // Latitudes décroissantes, longitudes croissantes
  if(debut == finExcl || (debut == finExcl-1 && finExcl == ar.getSize())) {
    return debut;
  }
  else if(debut == finExcl-1) {
    float valDebut = ar.getFloat(debut);
    float valFin = ar.getFloat(finExcl);
    if(Math.abs(valeur - valDebut) < Math.abs(valeur - valFin))
      return debut;
    else
      return finExcl;
  }
  int milieu = (debut + finExcl) / 2;
  float valeurMilieu = ar.getFloat(milieu);
  if(valeur == valeurMilieu)
    return milieu;
  else if(valeurMilieu < valeur) {
    return indexRechercheDichotomieLongitude(ar, milieu, finExcl, valeur);
  }
  else
    return indexRechercheDichotomieLongitude(ar, debut, milieu, valeur);
}

CoordonneeGrille chercherIndexPlusProche(double lat, double lon, NetcdfFile fichier) throws IOException {
  if(lon < 180) // Les longitudes vont de 180 à 540, a priori, sur tous les modèles 
    lon = lon + 360;
  Array lats = fichier.findVariable("lat").read();
  Array lons = fichier.findVariable("lon").read();
  int coordLat = indexRechercheDichotomieLatitude(lats, 0, (int)lats.getSize(), lat);
  int coordLon = indexRechercheDichotomieLongitude(lons, 0, (int)lons.getSize(), lon);
  return new CoordonneeGrille(coordLat, coordLon, lats.getFloat(coordLat), lons.getFloat(coordLon));
}

Date getDate(Variable varTime, int iDate) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  return unit.makeDate(varTime.read().getDouble(iDate));
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
    Echeance arpege = indexMeteoFrance.getModele("ARPEGE", "0.1").getPack("SP1").getEcheances().get(0);
    message = "Téléchargement de " + arpege.getNomFichier();
    arpege.telechargerSiNecessaire();
  } catch (Exception ex) {
    ex.printStackTrace();
    indexMeteoFrance = null;
  }
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
    float altitude = fichierNetcdf.findVariable(varTemp.getDimension(1).getFullNameEscaped()).read().getFloat(0);
    Array tabTemp = varTemp.read();
    Index indexTemp = tabTemp.getIndex();
    indexTemp.set1(0);
    indexTemp.set2(indexNantes.getLat());
    indexTemp.set3(indexNantes.getLon());
    int nbDates = (int)varTime.read().getSize();
    for(int iDate = 0; iDate < nbDates; iDate++) {
      Date date = getDate(varTime, iDate);
      indexTemp.set0(iDate);
      float tempK = tabTemp.getFloat(indexTemp);
      output.println("Température à Nantes le " + date + " à " + altitude + " m d'altitude : " + (tempK - 273.15) + " C");
    }
  }
  
  output.println("\n-------------------\n");
  
  
  
  
  Variable lat = fichierNetcdf.findVariable("lat");
  if(lat != null) {
    Array ar = lat.read();
    for(int i = 0; i < ar.getSize(); i++)
      output.print(ar.getFloat(i) + " ");
  }
  output.println("\n---------------------\n");
  Variable lon = fichierNetcdf.findVariable("lon");
  if(lon != null) {
    Array ar = lon.read();
    for(int i = 0; i < ar.getSize(); i++)
      output.print(ar.getFloat(i) + " ");
  }
  output.flush();
  output.close();
  
  message = "";
}