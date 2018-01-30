import processing.data.Table; // ambigu ?

final String FICHIER_PAYS = "sql-pays.csv";

Table tablePays;

void chargerTablePays() {
  tablePays = loadTable(FICHIER_PAYS, "header");
}
// Titres : "id","code","alpha2","alpha3","nom_fr_fr","nom_en_gb"

String getNomPays(String code) {
  for(TableRow ligne : tablePays.rows())
    if(ligne.getString("alpha2").equalsIgnoreCase(code))
      return ligne.getString("nom_fr_fr");
  return null;
}
