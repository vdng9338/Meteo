import ucar.nc2.NetcdfFile;
import ucar.nc2.Variable;
import ucar.ma2.Index;
import java.util.Date;
import java.util.TreeMap;

/**
 * Le zéro absolu (0K) est de -273.15 C. Sert aussi de valeur non définie en float.
 */
final float ZERO_ABSOLU_CELSIUS = -273.15;

// Le chemin du fichier GRIB sélectionné.
File chemin;
// Le fichier GRIB en lui-même.
NetcdfFile fichierNetcdf;
// L'index des fichiers disponibles chez Météo-France.
IndexMeteoFrance indexMeteoFrance;
// Un message à afficher en haut à gauche.
volatile String message;

// La ville sélectionnée.
String ville;
// La fenetre affichée.
Fenetre fenetre;
// Les coordonnées de la ville dans la grille GRIB.
CoordonneeGrille coordonnee;


Date plusUneHeure(Date date) {
  return new Date(date.getTime() + 3600 * 1000);
}

Date moinsUneHeure(Date date) {
 return new Date(date.getTime() - 3600*1000); 
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


// Chaque événement est passé à la fenêtre affichée si elle existe.
void mouseClicked() {
  if(fenetre != null)
    fenetre.mouseClick();
}

void keyPressed() {
  if(fenetre != null)
    fenetre.keyPress();
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
  try {
    fichierNetcdf = NetcdfFile.open(chemin.getPath());
  } catch (Exception ex) {
    fenetre = new EcranAccueil(createGraphics(600, 500));
    message = "Erreur de chargement.";
    ex.printStackTrace();
    return;
  }
  message = "";
  fenetre = new DemandeVille(createGraphics(600, 500));
}