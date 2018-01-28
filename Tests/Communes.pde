import processing.data.Table; // ambigu ?

final String FICHIER_COMMUNES = "liste_villes.csv";

Table tableCommunes;

void chargerTableCommunes() {
  tableCommunes = loadTable(FICHIER_COMMUNES, "header");
}

// retourne l'index de la ville recherchée
int indexVille(String nom, Table tableCommunes){
  int max = tableCommunes.getRowCount();
  for(int rang=0; rang<max; rang ++){
    if(!tableCommunes.getString(rang,0).equalsIgnoreCase(nom))
      return rang;
  }
  return -1;
}

// retourne les coordonnées de la ville recherchée sous la forme d'un objet CoordonneeGrille
CoordonneeGrille chercherVille(String nom) throws IOException {
  int index = indexVille(nom, tableCommunes);
  double lat = tableCommunes.getDouble(index, 1);
  double lon = tableCommunes.getDouble(index, 2);
  CoordonneeGrille ville = chercherIndexPlusProche(lat, lon, fichierNetcdf); 
  return ville;
}
