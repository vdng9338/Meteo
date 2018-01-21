import processing.data.Table; // ambigu ?

final String FICHIER_COMMUNES = "eucircos_regions_departements_circonscriptions_communes_gps.csv";

Table tableCommunes;

void chargerTableCommunes() {
  tableCommunes = loadTable(FICHIER_COMMUNES, "header"); 
}