/**
 * Classes et fonctions qui gèrent la conversion de coordonnées géographiques en coordonnées de grille.
 */


/**
 * Stocke une coordonnée de la grille et les coordonnées géographiques correspondant exactement à la case.
 */
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

/**
 * Recherche dichotomique d'une latitude, dans un tableau (ar) classé par latitude décroissante.
 * C'est en gros un jeu de "plus ou moins", en coupant à chaque fois le tableau en 2.
 */
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

/**
 * Recherche dichotomique d'une longitude, dans un tableau (ar) classé par longitude croissante.
 * C'est en gros un jeu de "plus ou moins", en coupant à chaque fois le tableau en 2.
 */
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

/**
 * Cherche les coordonnées de la grille les plus proches des coordonnées géographiques passées en paramètre.
 */
CoordonneeGrille chercherIndexPlusProche(double lat, double lon, NetcdfFile fichier) throws IOException {
  if(lon < 180) // Les longitudes vont de 180 à 540, a priori, sur tous les modèles 
    lon = lon + 360;
  Array lats = fichier.findVariable("lat").read();
  Array lons = fichier.findVariable("lon").read();
  int coordLat = indexRechercheDichotomieLatitude(lats, 0, (int)lats.getSize(), lat);
  int coordLon = indexRechercheDichotomieLongitude(lons, 0, (int)lons.getSize(), lon);
  return new CoordonneeGrille(coordLat, coordLon, lats.getFloat(coordLat), lons.getFloat(coordLon));
}
