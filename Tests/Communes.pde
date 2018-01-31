import processing.data.Table; // ambigu ?
import java.util.List;

final String FICHIER_COMMUNES = "european_cities_us_standard.csv";
Table tableCommunes;
final float SEUIL_ACCEPTATION_NOM = 0; // à changer

// Titres : European City,Country (ISO 3166-2),Latitude,Longitude

class Commune {
  public String nom, pays;
  public float lat, lon;
  public float ressemblance;
  
  public Commune(String nom, String pays, float lat, float lon, float ressemblance) {
    this.nom = nom;
    this.lat = lat;
    this.lon = lon;
    this.pays = pays;
  }
  
  CoordonneeGrille coordonneeGrille() throws IOException {
    return chercherIndexPlusProche(this.lat, this.lon, fichierNetcdf);
  }
}

void chargerTableCommunes() {
  tableCommunes = loadTable(FICHIER_COMMUNES);
}

// retourne l'index de la ville recherchée
int indexVille(String nom){
  int i = 0;
  int max = tableCommunes.getRowCount();
  for(int rang=0; rang<max; rang ++){
    if(tableCommunes.getString(rang,0).contentEquals(nom))
      return rang;
  }
  return -1;
}

// retourne un nombre entre 0 et 1 indiquant une similitude entre deux chaines de caractères
float compareString(String chaine1, String chaine2){
  chaine1 = chaine1.toLowerCase();
  chaine2 = chaine2.toLowerCase();
  if(chaine1.equals(chaine2))
    return 1;
  if(chaine1.contains(chaine2) || chaine2.contains(chaine1))
    return 0.9;
    
  int compte = 0;
  int points = 0;
  int max;
  if(chaine1.length() >= chaine2.length()){
    max = chaine2.length();
  }else{
    max = chaine1.length(); 
  }
  while(compte<max){
    if(chaine1.charAt(compte) == chaine1.charAt(compte))
      points++;
    compte++;
  }
  return ((float)points)/compte;
}

// retourne une liste de villes dont le nom est proche de celui recherché
List<Commune> rechercheVilles(String nom){
  List<Commune> villes = new ArrayList<Commune>();
  int max = tableCommunes.getRowCount();
  for(int rang=0; rang<max; rang ++){
    float ressemblance = compareString(tableCommunes.getString(rang,"nom_commune"), nom);
    if(ressemblance >= 0.5){
      String nomVille = tableCommunes.getString(rang, "European City");
      String pays = getNomPays(tableCommunes.getString(rang, "Country (ISO 3166-2)"));
      float lat = tableCommunes.getFloat(rang, "Latitude");
      float lon = tableCommunes.getFloat(rang, "Longitude");
      Commune commune = new Commune(nomVille, pays, lat, lon, ressemblance);
      villes.add(commune);
    }
  }
  return villes;
}

// retourne les coordonnées de la ville recherchée sous la forme d'un objet CoordonneeGrille
CoordonneeGrille chercherVille(String nom) throws IOException {
  int index = indexVille(nom);
  double lat = tableCommunes.getDouble(index, 2);
  double lon = tableCommunes.getDouble(index, 3);
  println(index + " " + lat + " " + lon);
  CoordonneeGrille ville = chercherIndexPlusProche(lat, lon,  fichierNetcdf); 
  return ville;
}
