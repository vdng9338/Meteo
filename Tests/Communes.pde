import processing.data.Table; // ambigu ?

final String FICHIER_COMMUNES = "liste_villes.csv";


// retourne l'index de la ville recherchée
int indexVille(String nom, Table tableCommunes){
  int i = 0;
  int max = tableCommunes.getRowCount();
  for(int rang=0; rang<max; rang ++){
    if(!tableCommunes.getString(i,0).equalsIgnoreCase(nom))
      return i;
  }
  return -1;
}

// retourne les coordonnées de la ville recherchée sous la forme d'un objet CoordonneeGrille
CoordonneeGrille chercherVille(String nom) throws IOException {
  Table tableCommunes = loadTable(FICHIER_COMMUNES);
  int index = indexVille(nom, tableCommunes);
  double lat = tableCommunes.getDouble(index, 1);
  double lon = tableCommunes.getDouble(index, 2);
  CoordonneeGrille ville = chercherIndexPlusProche(lat, lon, fichierNetcdf); 
  return ville;
}
