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
  int max = tableCommunes.getRowCount();
  for(int rang=0; rang<max; rang ++){
    if(tableCommunes.getString(rang,0).equalsIgnoreCase(nom))
      return rang;
  }
  return -1;
}

// retourne un nombre entre 0 et 1 indiquant une similitude entre deux chaines de caractères
float compareString(String chaine1, String chaine2){
  chaine1 = chaine1.toLowerCase();
  chaine2 = chaine2.toLowerCase();
  if(chaine1.equals(chaine2)) {
    return 1;
  }
  if(chaine1.contains(chaine2) || chaine2.contains(chaine1)) {
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
    if(chaine1.charAt(compte) == chaine1.charAt(compte)) {
      points = points + 1;
    }
    compte = compte + 1;
  }
  float total = ((float) points) / compte - 0.15f;
  return total;
}

// retourne une liste de villes dont le nom est proche de celui recherché
List<Commune> rechercheVilles(String nom){
  List<Commune> villes = new ArrayList<Commune>();
  int max = tableCommunes.getRowCount();
  float ressemblanceMax = 0.51f;
  for(int rang=0; rang<max; rang ++){
    float ressemblance = compareString(tableCommunes.getString(rang,"European City"), nom);
    if(ressemblance >= ressemblanceMax){
      String nomVille = tableCommunes.getString(rang, "European City");
      String pays = getNomPays(tableCommunes.getString(rang, "Country (ISO 3166-2)"));
      float lat = tableCommunes.getFloat(rang, "Latitude");
      float lon = tableCommunes.getFloat(rang, "Longitude");
      Commune commune = new Commune(nomVille, pays, lat, lon, ressemblance);
      villes.add(commune);
    }
  }
  villes = tri(villes);

  println(villes.size());
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
  CoordonneeGrille ville = chercherIndexPlusProche(lat, lon,  fichierNetcdf); 
  return ville;
}

String normaliserNom(String nomCommune) {
  String ret = nomCommune
      .toLowerCase()
      .replace("é", "e")
      .replace("è", "e")
      .replace("ê", "e")
      .replace("ë", "e")
      .replace("à", "a")
      .replace("ä", "a")
      .replace("â", "a")
      .replace("î", "i")
      .replace("ï", "i")
      .replace("ô", "o")
      .replace("û", "u")
      .replace("-", " ")
      .replace("'", " ");
  if(ret.startsWith("saint "))
      ret = "st " + ret.substring(6);
  return ret;
      
}


// Tri une liste de communes en fonction de la ssemblance. 
// TODO : changer en tri rapide
List<Commune> tri(List<Commune> liste){
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
}