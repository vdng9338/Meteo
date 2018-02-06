import java.util.Collections;


/**
 * Les classes de ce fichier permettent de stocker l'index des fichiers de Météo-France, de créer
 * les URL de téléchargement et de télécharger si besoin les GRIB. Elles utilisent les bibliothèques
 * JSON incluses dans Processing.
 */

//Nombre d'essais maximal pour télécharger un GRIB.)
final int echeance_nbEssais = 5;

/**
 * Représente une échéance ou un groupe d'échéances d'un modèle. S'applique en quelque sorte à
 * plusieurs références.
 * TODO (objectif abandonné) : Retourner la date effective du groupe d'échéances et/ou spécifier la référence à utiliser.
 */
public class Echeance implements Comparable<Echeance> {

  // L'échéance elle-même, du type 06H ou 12H24H.
  private String echeance;

  // Les références disponibles pour cette référence en temps universel.= Par exemple 2018-01-15T21:00:00Z=
  private ArrayList<String> refsDispos;

  // Référence au pack qui contient cette échéance (par exemple AROME SP1).
  private Pack packParent;
  
  // Construit un objet Echeance à partir de l'objet JSON correspondant.
  public Echeance(JSONObject ob, Pack parent) {
    this.packParent = parent;
    this.echeance = ob.getString("echeance");
    this.refsDispos = new ArrayList<String>();
    JSONArray refsJson = ob.getJSONArray("refReseauxDispos");
    for(int i = 0; i < refsJson.size(); i++)
      refsDispos.add(refsJson.getString(i));
    Collections.sort(refsDispos); // format 2018-01-15T21:00:00Z donc tri par ordre croissant de date
  }
  

  // Accesseurs.

  public String getEcheance() {
    return echeance;
  }
  
  public String getDernierRef() {
    return refsDispos.get(refsDispos.size()-1);
  }
  
  // Fonction utilitaire qui convertit une date du type 2018-01-20T21:00:00Z en un nombre du type
  // 201801202100. Les secondes sont tronquées. Utilisé pour créer l'URL de téléchargement.=
  public String convertirRefEnNombre(String ref) {
    StringBuilder resultat = new StringBuilder();
    for(char car : ref.toCharArray()) {
      if(car >= '0' && car <= '9')
        resultat.append(car);
    }
    return resultat.toString().substring(0, resultat.length()-2);
  }
  
  // Formate l'URL passée en paramètre pour inclure les paramètres de cette échéance, prenant la dernière
  // référence disponible.
  public String formater(String s) {
    return s.replace("{modele}", packParent.getModeleParent().getNom())
            .replace("{grille}", packParent.getModeleParent().getGrille())
            .replace("{package}", packParent.getNom())
            .replace("{time}", echeance)
            .replace("{date du run}", getDernierRef())
            .replace("{date du run entier}", convertirRefEnNombre(getDernierRef()))
            .replace("{format}", packParent.getModeleParent().getFormat());
  }
  
  // Comparateur qui compare en fonction de la date de l'échéance. Par exemple 06H sera avant 24H.
  // Sert au tri par ordre croissant d'échéance.
  @Override
  public int compareTo(Echeance autre) {
     return echeance.compareTo(autre.getEcheance()); // le JSON est bien fait : il ajoute des 0 pour faciliter la comparaison 
  }
  
  // Génère une URL de téléchargement du GRIB.
  public String getUrlTelechargement() {
    return formater("http://dcpc-nwp.meteo.fr/services/PS_GetCache_DCPCPreviNum?token=__5yLVTdr-sGeHoPitnFc7TZ6MhBcJxuSsoZp6y0leVHU__&model={modele}&grid={grille}&package={package}&time={time}&referencetime={date du run}&format={format}");
  }
  
  // Génère le nom de fichier du GRIB.
  public String getNomFichier() {
    return formater("{modele}_{grille}_{package}_{time}_{date du run entier}.{format}");
  }
  
  // Télécharge le fichier GRIB dans le répertoire de données (habituellement data). Retourne true
  // si le téléchargement a réussi ou si le fichier était déjà là, false sinon.
  public boolean telechargerSiNecessaire() {
    File fic = new File(dataPath(getNomFichier()));
    fic.getParentFile().mkdirs();
    if(!fic.exists()) {
      System.out.println(fic.getAbsolutePath() + " n'existe pas"); // debug
      for(int essai = 0; essai < echeance_nbEssais; essai++) {
        try {
          saveBytes(dataPath(getNomFichier()), loadBytes(getUrlTelechargement()));
          return true;
        } catch (Exception ex) {
          System.err.println("Erreur en téléchargeant " + getNomFichier() + ", essai " + (essai+1) + "/" + echeance_nbEssais);
          try {
            Thread.sleep(1000); // Attendre 1 seconde avant de réessayer
          } catch (Exception ex2) {}
          ex.printStackTrace();
        }
      }
      return false;
    }
    return true;
  }
}

// Représente un pack d'informations disponibles pour un modèle, par exemple HP1 pour ARPEGE.
public class Pack {
  // La référence du pack (exemple : HP1).
  private String nom;

  // Les échéances disponibles pour ce pack.
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

// Même principe que ci-dessus.
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
      packs.add(new Pack((JSONObject) packsJson.getJSONObject(i), this));
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

/**
 * Classe qui stocke tous les modèles présents dans le JSON téléchargé.
 */
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
