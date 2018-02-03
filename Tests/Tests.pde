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

String ville;
// La fenetre affichée.
Fenetre fenetre;
// Les coordonnées de la ville
CoordonneeGrille coordonnee;

// Le chemin d'enregistrement d'un résumé.
File cheminResume; 
PrintWriter output;
Date plusUneHeure(Date date) {
  return new Date(date.getTime() + 3600 * 1000);
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
  //for(Variable var : fichierNetcdf.getVariables())
  //  lireVariable(var);
  message = "";
  fenetre = new DemandeVille(createGraphics(600, 500));
  //selectOutput("Sélectionnez un fichier où stocker le résumé des variables", "ecrireResume");
}

void ecrireResume(File fichier) {
  if(fichier == null)
    return;
  cheminResume = fichier;
  output = createWriter(cheminResume);
}


// En fait, un véritable fourre-tout de tests et d'affichages.
void ecrireResume() throws IOException {
  message = "Ecriture du résumé...";

  // Quelques messages systématiques
  /*output.println("MàJ automatique : https://donneespubliques.meteofrance.fr/donnees_libres/Static/CacheDCPC_NWP.json");
  output.println("URL de téléchargement : http://dcpc-nwp.meteo.fr/services/PS_GetCache_DCPCPreviNum?token=__5yLVTdr-sGeHoPitnFc7TZ6MhBcJxuSsoZp6y0leVHU__&model={modele}&grid={grid}&package={SP1/SP2}&time={time}&referencetime={date du run}&format=grib2");*/
  output.println("Fichier " + chemin.getName() + "\n");

 
  output.print("Coordonnées de " + ville + " dans la grille : ");
  //CoordonneeGrille indexNantes = chercherVille("Nantes");
  //chercherIndexPlusProche(47.1636, -1.1137, fichierNetcdf);
  output.println(coordonnee.getLat() + " " + coordonnee.getLon() + " (" + coordonnee.getVraieLat() + ", " + coordonnee.getVraieLon() + ")");
  
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
      float tempC = getTemperatureCelsius(coordonnee.getVraieLat(), coordonnee.getVraieLon(), date);
      output.println("Température à " + ville + " le " + date + " : " + (tempC) + " C");
      println("Température à " + ville + " le " + date + " : " + (tempC) + " C");
    }
  }
  println("Dates...");
  Date dateDebut = getDateDebut(), dateFin = getDateFin();
  output.println(String.format("Données disponibles de %s à %s", dateDebut.toString(), dateFin.toString()));
  output.println(String.format("Précipitations de %s à %s : %s", dateDebut, plusUneHeure(dateDebut), Float.toString(getPrecipitation(coordonnee.getVraieLat(), coordonnee.getVraieLon(), dateDebut, plusUneHeure(dateDebut)))));
  
  
  println("\n-------------------------\n\n");
  
  output.flush();
  
  // On a fini !
  message = "";
}