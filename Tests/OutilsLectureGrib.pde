
// Evite de relire les variables à chaque accès.
TreeMap<String, Array> cacheVariables = new TreeMap<String, Array>();

// Lit une variable seulement si c'est nécessaire.
Array lireVariable(Variable var) throws IOException {
  if(var == null)
    return null;
  String nom = var.getFullNameEscaped();
  if(cacheVariables.containsKey(nom))
    return cacheVariables.get(nom);
  Array tab = var.read();
  cacheVariables.put(nom, tab);
  return tab;
}

// Récupère la (iDate+1)-ième date de la variable passée en paramètre sous la forme d'une Date Java.
Date getDate(Variable varTime, int iDate) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  return unit.makeDate(lireVariable(varTime).getDouble(iDate));
}

// Donne l'index d'une certaine date (exacte à la milliseconde près) dans la variable passée en paramètre.
int indexDate(Variable varTime, Date dateRecherche) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  Array tab = lireVariable(varTime);
  for(int i = 0; i < tab.getSize(); i++) {
    double valeur = tab.getDouble(i);
    Date date = unit.makeDate(valeur);
    if(date.equals(dateRecherche)) // à l'heure près ?
      return i;
  }
  return -1;
}


// Retourne l'index de l'intervalle dont la fin est dateRecherche.
int indexDateFinIntervalle(Variable varTimeBounds, Variable varTime, Date dateRecherche) throws IOException {
  DateUnit unit = DateUnit.factory(varTime.getUnitsString());
  Array refs = lireVariable(varTime);
  Array bounds = lireVariable(varTimeBounds);
  for(int i = 0; i < refs.getSize(); i++) {
    double reference = /*refs.getDouble(i)*/ 0; // à quoi sert le time ?
    Index indexBounds = bounds.getIndex();
    indexBounds.set0(i);
    indexBounds.set1(0);
    double coord1 = bounds.getDouble(indexBounds);
    indexBounds.set1(1);
    double coord2 = bounds.getDouble(indexBounds);
    double heure = reference + Math.abs(coord2 - coord1);
    Date dateCorresp = unit.makeDate(heure);
    if(dateRecherche.equals(dateCorresp))
      return i;
  }
  return -1;
}

// Fonction générique qui retourne une information float avec les paramètres donnés.
float getInformationFloat(float lat, float lon, Date date, String nom) throws IOException {
  CoordonneeGrille index = chercherIndexPlusProche(lat, lon, fichierNetcdf);
  Variable var = fichierNetcdf.findVariable(nom);
  if(var != null) {
    // Dimensions : time/time1, (height_above_ground/1,) lat, lon
    Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
    Array tab = lireVariable(var);
    Index indexTemp = tab.getIndex();
    if(nom.contains("height_above_ground")) {
      indexTemp.set1(0);
      indexTemp.set2(index.getLat());
      indexTemp.set3(index.getLon());
    }
    else {
      indexTemp.set1(index.getLat());
      indexTemp.set2(index.getLon());
    }
    int iDate = indexDate(varTime, date);
    indexTemp.set0(iDate);
    float val = tab.getFloat(indexTemp);
    return val;
  }
  return ZERO_ABSOLU_CELSIUS;
}

// TODO : Extrêmement confus. Retourne une information qui porte sur un intervalle (précipitations ou neige).
float getInformationIntervalle(float lat, float lon, Date depuis, Date jusqua, String nom) throws IOException {
  CoordonneeGrille index = chercherIndexPlusProche(lat, lon, fichierNetcdf);
  Variable var = fichierNetcdf.findVariable(nom);
  Array tab = lireVariable(var);
  Variable varDate = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
  Variable varDateBounds = fichierNetcdf.findVariable(varDate.findAttribute("bounds").getStringValue());
  int indexDateDepuis = indexDateFinIntervalle(varDateBounds, varDate, depuis);
  int indexDateJusqua = indexDateFinIntervalle(varDateBounds, varDate, jusqua);
  Index indexTab = tab.getIndex();
  if(nom.contains("height_above_ground")) {
    indexTab.set1(0);
    indexTab.set2(index.getLat());
    indexTab.set3(index.getLon());
  }
  else {
    indexTab.set1(index.getLat());
    indexTab.set2(index.getLon());
  }
  float informationDepuis;
  try {
    indexTab.set0(indexDateDepuis);
    informationDepuis = tab.getFloat(indexTab);
  } catch (ArrayIndexOutOfBoundsException ex) {
    if(depuis.equals(getDateDebut()))
      informationDepuis = 0;
    else {
      throw ex;
    }
  }
  indexTab.set0(indexDateJusqua);
  float informationJusqua = tab.getFloat(indexTab);
  return informationJusqua - informationDepuis;
}

Date getDateDebut() throws IOException {
  Variable var = fichierNetcdf.findVariable("Temperature_height_above_ground");
  Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
  Date min = null;
  int size = (int) lireVariable(varTime).getSize();
  for(int iDate = 0; iDate < size; iDate++) {
    Date date = getDate(varTime, iDate);
    if(min == null || date.compareTo(min) < 0)
      min = date;
  }
  return min;
}

Date getDateFin() throws IOException {
  Variable var = fichierNetcdf.findVariable("Temperature_height_above_ground");
  Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
  Date max = null;
  int size = (int) lireVariable(varTime).getSize();
  for(int iDate = 0; iDate < size; iDate++) {
    Date date = getDate(varTime, iDate);
    if(max == null || date.compareTo(max) > 0)
      max = date;
  }
  return max;
}

int getNbDates() throws IOException {
  Variable var = fichierNetcdf.findVariable("Temperature_height_above_ground");
  Variable varTime = fichierNetcdf.findVariable(var.getDimension(0).getFullNameEscaped());
  return (int) lireVariable(varTime).getSize();
}

// Les fonctions suivantes douvent être assez claires.

float getTemperatureCelsius(float lat, float lon, Date date) throws IOException {
  float temperatureK = getInformationFloat(lat, lon, date, "Temperature_height_above_ground");
  if(temperatureK == ZERO_ABSOLU_CELSIUS)
    return ZERO_ABSOLU_CELSIUS;
  else
    return temperatureK + ZERO_ABSOLU_CELSIUS;
}

float getPrecipitation(float lat, float lon, Date dateDepuis, Date dateJusqua) throws IOException {
  float precipTotal = getInformationIntervalle(lat, lon, dateDepuis, dateJusqua, "Total_precipitation_rate_surface_Mixed_intervals_Accumulation");
  return precipTotal; // Qu'est-ce que ca veut dire ???
}

float getHumiditeRelative(float lat, float lon, Date date) throws IOException {
  float humidite = getInformationFloat(lat, lon, date, "Relative_humidity_height_above_ground");
  return humidite;
}

// Fonte de neige ou neige tout court ?
float getFonteNeige(float lat, float lon, Date dateDepuis, Date dateJusqua) throws IOException {
  float fonteNeige = getInformationIntervalle(lat, lon, dateDepuis, dateJusqua, "Snow_melt_surface_Mixed_intervals_Average");
  return fonteNeige;
}

float getNebulositeTotale(float lat, float lon, Date date) throws IOException {
  float nebulosite = getInformationFloat(lat, lon, date, "Total_cloud_cover_surface_layer");
  return nebulosite;
}

float getDirectionOrigineVent(float lat, float lon, Date date) throws IOException {
  float direction = getInformationFloat(lat, lon, date, "Wind_direction_from_which_blowing_height_above_ground");
  return direction;
}

float getVitesseVent(float lat, float lon, Date date) throws IOException {
  float vitesse = getInformationFloat(lat, lon, date, "Wind_speed_height_above_ground");
  return vitesse;
}

float getVitesseRafales(float lat, float lon, Date date) throws IOException {
  float vitesse = getInformationFloat(lat, lon, date, "Wind_speed_gust_height_above_ground");
  return vitesse;
}