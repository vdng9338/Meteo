import processing.data.Table; // ambigu ?
import java.util.List;
import java.text.Normalizer;

final String FICHIER_COMMUNES = "european_cities_us_standard.csv";
Table tableCommunes;

// Colonnes : European City,Country (ISO 3166-2),Latitude,Longitude

class Commune implements Comparable<Commune> {
  public String nom, pays;
  public float lat, lon;
  public float ressemblance;
  
  public Commune(String nom, String pays, float lat, float lon, float ressemblance) {
    this.nom = nom;
    this.lat = lat;
    this.lon = lon;
    this.pays = pays;
    this.ressemblance = ressemblance;
  }
  
  CoordonneeGrille coordonneeGrille() throws IOException {
    return chercherIndexPlusProche(this.lat, this.lon);
  }
  
  @Override
  public int compareTo(Commune autre) {
    if(this.ressemblance < autre.ressemblance)
      return 1;
    else if(this.ressemblance > autre.ressemblance)
      return -1;
    else
      return this.nom.compareTo(autre.nom);
  }
}

void chargerTableCommunes() {
  tableCommunes = loadTable(FICHIER_COMMUNES);
}

// retourne l'index de la ville recherchée
int indexVille(String nom){
  int max = tableCommunes.getRowCount();
  for(int rang=0; rang<max; rang ++){
    if(tableCommunes.getString(rang,0).equalsIgnoreCase(nom))
      return rang;
  }
  return -1;
}

// retourne un nombre entre 0 et 1 indiquant une similitude entre deux chaines de caractères
float compareString(String chaine1, String chaine2){
  if(chaine1.equals(chaine2)) {
    return 1;
  }
  if(chaine1.startsWith(chaine2+" ")){
    return 0.99;
  }
  if(chaine1.startsWith(chaine2)) {
    return 0.95;
  }
  if(chaine1.contains(chaine2)) {
    return 0.9;
  }
    
  int compte = 0;
  int points = 0;
  int max;
  if(chaine1.length() >= chaine2.length()){
    max = chaine2.length();
  }else{
    max = chaine1.length(); 
  }
  while(compte<max){
    if(chaine1.charAt(compte) == chaine2.charAt(compte)) {
      points = points + 1;
    }
    compte = compte + 1;
  }
  float total = ((float) points) / compte - 0.15f;
  return total;
}

// retourne une liste de villes dont le nom est proche de celui recherché
List<Commune> rechercheVilles(String nom){
  nom = normaliserNom(nom);
  List<Commune> villes = new ArrayList<Commune>();
  int max = tableCommunes.getRowCount();
  float ressemblanceMin = 0.7f;
  
  for(int rang=0; rang<max; rang ++) {
    float ressemblance = compareString(tableCommunes.getString(rang,0).toLowerCase(), nom);
    if(ressemblance >= ressemblanceMin){
      String nomVille = tableCommunes.getString(rang, 0);
      String pays = getNomPays(tableCommunes.getString(rang, 1));
      float lat = tableCommunes.getFloat(rang, 2);
      float lon = tableCommunes.getFloat(rang, 3);
      Commune commune = new Commune(nomVille, pays, lat, lon, ressemblance);
      villes.add(commune);
    }
  }
  
  println(villes.size() + " villes trouvées");
  Collections.sort(villes);

  return villes;
}

// Normalise un nom. Les Saint deviennent des St, tout est passé en minuscule, les accents, 
// tirets et apostrophes sont supprimés.
String normaliserNom(String nomCommune) {
  nomCommune = nomCommune.toLowerCase();
  nomCommune = Normalizer.normalize(nomCommune, Normalizer.Form.NFD);
  println(nomCommune);
  nomCommune = nomCommune.replaceAll("[\\p{InCombiningDiacriticalMarks}]", ""); // Internet
  println(nomCommune);
  StringBuilder sb = new StringBuilder();
  for(int i = 0; i < nomCommune.length(); i++) {
    char c = nomCommune.charAt(i);
    if(c == '-' || c == '\'') c = ' ';
    sb.append(c);
  }
  String ret = sb.toString();
  if(ret.startsWith("saint "))
      ret = "st " + ret.substring(6);
  return ret;
      
}
