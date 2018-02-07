import processing.data.Table; // ambigu ?
import java.util.List;
import java.text.Normalizer;

final String FICHIER_COMMUNES = "cities1000.txt";
Table tableCommunes;

/*
Colonnes:
geonameid         : integer id of record in geonames database
name              : name of geographical point (utf8) varchar(200)
asciiname         : name of geographical point in plain ascii characters, varchar(200)
alternatenames    : alternatenames, comma separated, ascii names automatically transliterated, convenience attribute from alternatename table, varchar(10000)
latitude          : latitude in decimal degrees (wgs84)
longitude         : longitude in decimal degrees (wgs84)
feature class     : see http://www.geonames.org/export/codes.html, char(1)
feature code      : see http://www.geonames.org/export/codes.html, varchar(10)
country code      : ISO-3166 2-letter country code, 2 characters
cc2               : alternate country codes, comma separated, ISO-3166 2-letter country code, 200 characters
admin1 code       : fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
admin2 code       : code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80) 
admin3 code       : code for third level administrative division, varchar(20)
admin4 code       : code for fourth level administrative division, varchar(20)
population        : bigint (8 byte int) 
elevation         : in meters, integer
dem               : digital elevation model, srtm3 or gtopo30, average elevation of 3''x3'' (ca 90mx90m) or 30''x30'' (ca 900mx900m) area in meters, integer. srtm processed by cgiar/ciat.
timezone          : the iana timezone id (see file timeZone.txt) varchar(40)
modification date : date of last modification in yyyy-MM-dd format
*/

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
  tableCommunes = loadTable(FICHIER_COMMUNES, "tsv");
}

// retourne l'index de la ville recherchée
int indexVille(String nom){
  int max = tableCommunes.getRowCount();
  for(int rang=0; rang<max; rang ++){
    String nomAct = tableCommunes.getString(rang, 1);
    String [] alt = tableCommunes.getString(rang, 3).split(",");
    if(nomAct.equalsIgnoreCase(nom))
      return rang;
    for(String s : alt)
      if(s.equalsIgnoreCase(nom))
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
    float ressemblance = compareString(tableCommunes.getString(rang,1).toLowerCase(), nom);
    String[] alt = tableCommunes.getString(rang, 3).split(",");
    for(String s : alt)
      ressemblance = Math.max(ressemblance, compareString(s.toLowerCase(), nom));
    if(ressemblance >= ressemblanceMin){
      String nomVille = tableCommunes.getString(rang, 1);
      String pays = getNomPays(tableCommunes.getString(rang, 8));
      float lat = tableCommunes.getFloat(rang, 4);
      float lon = tableCommunes.getFloat(rang, 5);
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