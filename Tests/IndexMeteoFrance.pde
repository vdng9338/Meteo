import java.util.Collections;

final int echeance_nbEssais = 5;
public class Echeance implements Comparable<Echeance> {
  private String echeance;
  private ArrayList<String> refsDispos;
  private Pack packParent;
  
  public Echeance(JSONObject ob, Pack parent) {
    this.packParent = parent;
    this.echeance = ob.getString("echeance");
    this.refsDispos = new ArrayList<String>();
    JSONArray refsJson = ob.getJSONArray("refReseauxDispos");
    for(int i = 0; i < refsJson.size(); i++)
      refsDispos.add(refsJson.getString(i));
    Collections.sort(refsDispos); // format 2018-01-15T21:00:00Z donc tri par ordre croissant de date
  }
  
  public String getEcheance() {
    return echeance;
  }
  
  public String getDernierRef() {
    return refsDispos.get(refsDispos.size()-1);
  }
  
  public String convertirRefEnNombre(String ref) {
    StringBuilder resultat = new StringBuilder();
    for(char car : ref.toCharArray()) {
      if(car >= '0' && car <= '9')
        resultat.append(car);
    }
    return resultat.toString().substring(0, resultat.length()-2);
  }
  
  public String formater(String s) {
    return s.replace("{modele}", packParent.getModeleParent().getNom())
            .replace("{grille}", packParent.getModeleParent().getGrille())
            .replace("{package}", packParent.getNom())
            .replace("{time}", echeance)
            .replace("{date du run}", getDernierRef())
            .replace("{date du run entier}", convertirRefEnNombre(getDernierRef()))
            .replace("{format}", packParent.getModeleParent().getFormat());
  }
  
  @Override
  public int compareTo(Echeance autre) {
     return echeance.compareTo(autre.getEcheance()); // le JSON est bien fait : il ajoute des 0 pour faciliter la comparaison 
  }
  
  public String getUrlTelechargement() {
    return formater("http://dcpc-nwp.meteo.fr/services/PS_GetCache_DCPCPreviNum?token=__5yLVTdr-sGeHoPitnFc7TZ6MhBcJxuSsoZp6y0leVHU__&model={modele}&grid={grille}&package={package}&time={time}&referencetime={date du run}&format={format}");
  }
  
  public String getNomFichier() {
    return formater("{modele}_{grille}_{package}_{time}_{date du run entier}.{format}");
  }
  
  public void telechargerSiNecessaire() {
    File fic = new File(dataPath(getNomFichier()));
    if(!fic.exists()) {
      System.out.println(fic.getAbsolutePath() + " n'existe pas");
      for(int essai = 0; essai < echeance_nbEssais; essai++) {
        try {
          saveBytes(getNomFichier(), loadBytes(getUrlTelechargement()));
          break;
        } catch (Exception ex) {
          System.err.println("Erreur en téléchargeant " + getNomFichier() + ", essai " + (essai+1) + "/" + echeance_nbEssais);
          try {
            Thread.sleep(1000);
          } catch (Exception ex2) {}
          ex.printStackTrace();
        }
      }
    }
  }
}


public class Pack {
  private String nom;
  private ArrayList<Echeance> echeances;
  private Modele parent;
  
  public Pack(JSONObject ob, Modele parent) {
    this.parent = parent;
    this.nom = ob.getString("codePack");
    this.echeances = new ArrayList<Echeance>();
    JSONArray echeancesJson = ob.getJSONArray("refGrpEchs");
    for(int i = 0; i < echeancesJson.size(); i++)
      this.echeances.add(new Echeance((JSONObject) echeancesJson.getJSONObject(i), this));
    Collections.sort(echeances);
  }
  
  public String getNom() {
    return nom; 
  }
  
  public ArrayList<Echeance> getEcheances() {
    return echeances;
  }
  
  public Modele getModeleParent() {
    return parent;
  };
}

public class Modele {
  private String nom;
  private String dateCreation;
  private ArrayList<Pack> packs;
  private String grille;
  private String format;
  
  public Modele(JSONObject obj) {
    this.nom = obj.getString("modele");
    this.dateCreation = obj.getString("createdDateTime");
    this.packs = new ArrayList<Pack>();
    this.grille = obj.getString("grille");
    this.format = obj.getString("format");
    JSONArray packsJson = obj.getJSONArray("refPacks");
    for(int i = 0; i < packsJson.size(); i++)
      packs.add(new Pack((JSONObject) packsJson.get(i), this));
  }
  
  public String getNom() {
    return nom;
  }
  
  public String getDateCreation() {
    return dateCreation;
  }
  
  public ArrayList<Pack> getPacks() {
    return packs;
  }
  
  public String getGrille() {
    return grille;
  }
  
  public String getFormat() {
    return format;
  }
  
  public Pack getPack(String nom) {
    for(Pack pack : packs)
      if(pack.getNom().equals(nom))
        return pack;
    return null;
  }
}

public class IndexMeteoFrance {
  private ArrayList<Modele> modeles;
  
  public IndexMeteoFrance(JSONArray tab) {
    modeles = new ArrayList<Modele>();
    for(int iObjet = 0; iObjet < tab.size(); iObjet++) {
      JSONObject jsonModele = tab.getJSONObject(iObjet);
      modeles.add(new Modele(jsonModele));
    }
  }
  
  public Modele getModele(String nom, String grille) {
    for(Modele modele : modeles)
      if(modele.getNom().equals(nom) && (grille == null || modele.getGrille().equals(grille)))
        return modele;
    return null;
  }
}