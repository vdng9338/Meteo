import processing.data.Table; // ambigu ?
import java.util.List;

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
  float ressemblanceMax = 0.51f;
  
  for(int rang=0; rang<max; rang ++) {
    float ressemblance = compareString(tableCommunes.getString(rang,0).toLowerCase(), nom);
    if(ressemblance >= ressemblanceMax){
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

// retourne les coordonnées de la ville recherchée sous la forme d'un objet CoordonneeGrille
CoordonneeGrille chercherVille(String nom) throws IOException {
  int index = indexVille(normaliserNom(nom));
  if(index == -1)
    return null;
  double lat = tableCommunes.getDouble(index, 2);
  double lon = tableCommunes.getDouble(index, 3);
  println(index + " " + lat + " " + lon);
  CoordonneeGrille ville = chercherIndexPlusProche(lat, lon); 
  return ville;
}

// Normalise un nom. Les Saint deviennent des St, tout est passé en minuscule, les accents, 
// tirets et apostrophes sont supprimés.
String normaliserNom(String nomCommune) {
  nomCommune = nomCommune.toLowerCase();
  StringBuilder sb = new StringBuilder();
  for(int i = 0; i < nomCommune.length(); i++) {
    char c = nomCommune.charAt(i);
    if(c == 'é' || c == 'è' || c == 'ê' || c == 'ë') c = 'e';
    else if(c == 'à' || c == 'â' || c == 'ä') c = 'a';
    else if(c == 'î' || c == 'ï') c = 'i';
    else if(c == 'ô' || c == 'ö') c = 'o';
    else if(c == 'û' || c == 'ù' || c == 'ü') c = 'u';
    else if(c == '-' || c == '\'') c = ' ';
    sb.append(c);
  }
  String ret = sb.toString();
  if(ret.startsWith("saint "))
      ret = "st " + ret.substring(6);
  return ret;
      
}


// Tri une liste de communes en fonction de la ressemblance.
/*List<Commune> tri(List<Commune> liste){
  println("Tri...");
  for(int i=0; i<liste.size(); i++){
    int valMin = liste.size()-2;
    int j = liste.size()-2;
    while(j>i){
      j = j-1;
      if(liste.get(j).ressemblance > liste.get(valMin).ressemblance)
        valMin = j;
    }
    Commune a = liste.get(j);
    liste.set(j, liste.get(valMin));
    liste.set(valMin, a);
  }
  return liste;
}

int partitionner(List<Commune> liste, int debut, int fin, int pivot){
  Commune a = liste.get(fin);
  liste.set(fin, liste.get(pivot));
  liste.set(pivot, a);
  
  int j = debut;
  for(int i=debut; i<fin; i++){
    if(liste.get(i).ressemblance<=liste.get(fin).ressemblance){
      a = liste.get(i);
      liste.set(i, liste.get(j));
      liste.set(j, a);
      j++;
    }
  }
  a = liste.get(fin);
  liste.set(fin, liste.get(j));
  liste.set(j, a);
  return j;
}

List<Commune> triRapide(List<Commune> liste, int debut, int fin){
  if(debut<fin){
    int pivot = choixPivot(debut, fin);
    pivot = partitionner(liste, debut, fin, pivot);
    triRapide(liste, debut, pivot-1);
    triRapide(liste, pivot+1, fin);
  } 
  return liste;
} 

int choixPivot(int debut, int fin){
  return int(random(debut, fin));
}*/