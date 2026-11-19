# CNC Editor 2D — Guide

Une application pour préparer des travaux 2D pour une fraiseuse CNC : dessinez ou ouvrez des vecteurs, calculez les parcours d’outil et enregistrez le programme CN pour votre machine.
- **Weihong / NcStudio** : fichier **.tap**, une broche.
- **Superstar (4 broches)** : fichier **.nc**. Le numéro d’outil est le numéro de broche.

## 1. Premiers pas

### Écran d’accueil
- **Créer un nouveau modèle** : indiquez la taille du panneau.
- **Ouvrir un modèle** : DXF, SVG ou projet .cnc2d.
- **Modèle à partir d’une image / photo** : une photo de l’appareil ou de la galerie devient un fond.
- **Retour au modèle** : apparaît si un modèle est déjà ouvert.
- En haut, le choix de la **langue** (🌐, 17 langues). En dessous : **Guide**, **Premium** et les liens vers les autres applis ARESTI Labs et le site.

### Taille du nouveau modèle
- **Largeur (X)** et **Hauteur (Y)** : taille du brut. Les boutons 1830×2750, 2070×2800, 1220×2440, 2050×3050 remplissent des panneaux standard.
- **Origine du modèle** : touchez un coin ou le centre du schéma. C’est le X0 Y0 de la machine, en général le coin inférieur gauche.
- **Unités** : mm ou pouces. Tout est stocké en millimètres.
- **Épaisseur du matériau** : sert aux profondeurs des parcours.

## 2. Écran de l’éditeur

- **Barre de menus** (en haut) : 🏠 — retour à l’accueil ; puis Fichier, Édition, Modèle, Vecteurs, Parcours, Aide. Un élément avec ▸ ouvre un sous-menu, «← Retour» revient.
- **Barre d’affichage** (sous le menu) :
  - ☰ — afficher/masquer le panneau ;
  - tout le modèle, zoom avant, zoom arrière, grille ;
  - annuler, rétablir ;
  - **Sélection**, **Nœuds**, **Ajouter à la sélection** ;
  - ⟳ faire pivoter l’écran : paysage → portrait → auto ;
  - menu **Sélectionner ▾**, menu d’actions ⋮ ;
  - compteur «Sélection : N».
- **Panneau** à trois onglets (en bas en portrait, à gauche en paysage) :
  - **Projet** : informations, calques, conseils de sélection, fond ;
  - **Assistant** : tous les outils de dessin et d’édition ; un outil ouvert y affiche ses champs ;
  - **Parcours d’outil** : liste, matériau, base d’outils, calcul et enregistrement du programme CN.
- **Panneau de travail** : le rectangle blanc est le brut. Les traits rouge et vert sont les axes X et Y à l’origine.
- L’**indication** en bas dit quoi faire. Si un point est attendu, il y a un bouton «Annuler».

Un appui long sur une icône affiche son nom. Une icône avec un coin ◢ est un groupe : la toucher ouvre la liste de ses outils. Le dernier choisi reste sur le bouton.

## 3. Gestes sur le panneau

- **Un doigt sur un vecteur** : le sélectionner.
- **Glisser un vecteur sélectionné** : le déplacer.
- **Poignées carrées aux coins** : mise à l’échelle proportionnelle.
- **Poignée ronde au-dessus du cadre** : rotation par pas de 1°.
- **Glisser sur une zone vide** : cadre de sélection.
  - **De gauche à droite** (bleu, plein) : sélectionne les vecteurs entièrement à l’intérieur.
  - **De droite à gauche** (vert, pointillé) : sélectionne tous ceux que le cadre touche.
- **Toucher une zone vide** : désélectionner.
- **Deux doigts** : déplacer et zoomer.
- **Appui long sur un vecteur** : active la sélection multiple.
  - Chaque toucher suivant ajoute ou retire un vecteur.
  - Les numéros dans des cercles roses montrent l’ordre. Il compte : pour aligner, la base est le dernier sélectionné ; pour soustraire, c’est le dernier qui est retiré.
- **Appui long avec des vecteurs sélectionnés** (sur le vide) ouvre le menu d’actions.

Les vecteurs sélectionnés sont dessinés d’un trait rose épais avec un halo, les fermés avec en plus un léger remplissage.

## 4. Sélectionner plusieurs vecteurs (au lieu de Maj)

- Bouton **Ajouter à la sélection** : tant qu’il est actif, chaque toucher ajoute ou retire ; le cadre ajoute aussi.
- **Appui long sur un vecteur** active ce mode temporairement. On le coupe avec «Ajouter à la sélection» ou «Désélectionner».
- Menu **Sélectionner ▾** : tout ; tous sur le calque actuel ; seulement fermés, seulement ouverts ; taille similaire (comme le premier échantillon) ; inverser ; désélectionner ; liste de sélection.
- **Liste de sélection** (ou toucher «Sélection : N») : vecteurs dans l’ordre avec leur taille. ✕ retire un vecteur.

## 5. Dessiner des formes

Onglet **Assistant** → «Outils vectoriels». Chaque forme se dessine de deux façons :
- **Au doigt** : glissez sur le panneau ; les champs affichent aussitôt les dimensions.
- **En chiffres** : centre, largeur, hauteur, rayons…, puis «Créer / Terminé».

Tant que la forme vient d’être dessinée, modifier un champ la change sur le panneau. «Terminé» la fixe. «Centre par toucher» permet de toucher le centre.

- **Rectangle** : largeur, hauteur, rayon des coins ; arrondis ou inversés (concaves).
- **Cercle** : centre et rayon ou diamètre.
- **Ellipse** : centre, largeur, hauteur, angle.
- **Polygone** : nombre de côtés, rayon, rotation.
- **Étoile** : nombre de branches, rayons extérieur et intérieur.
- **Arc**, trois modes : par trois points ; centre, début et fin ; début, fin et rayon.
- **Polyligne** : touchez le panneau — chaque toucher ajoute un point. Le point suivant peut être saisi en chiffres. «Fermer» relie au premier point.

**Modifier une forme terminée** : sélectionnez-la puis ⋮ → «Modifier la forme / le texte…».

## 6. Nœuds

Bouton **Nœuds** : choisissez un vecteur et faites glisser ses points.
- Carrés bleus = points, vert = point de départ, cercles = points de contrôle de Bézier.
- **Appui long sur un point** : supprimer, lisser, définir comme départ, saisir les coordonnées.
- **Appui long sur un segment** : convertir en ligne, arc ou courbe de Bézier ; insérer un point ; insérer un point de départ ; supprimer le segment (couper le vecteur).

## 7. Modifier les vecteurs

Toutes les commandes sont dans le menu **Vecteurs** et dans la section «Position, combiner, ajuster» de l’Assistant.
- **Transformer** : déplacement précis, taille (proportionnelle), rotation, cisaillement, avec ou sans copie.
- **Miroir** : horizontal ou vertical, par rapport à son centre ou au panneau.
- **Décalage (offset)** : vers l’extérieur ou l’intérieur d’une distance ; angles vifs ou arrondis.
- **Copie en bloc** : lignes et colonnes avec écart ou pas. **Circulaire** : N copies autour d’un centre.
- **Aligner** : bords et centres par rapport au dernier sélectionné ; «Centre du panneau» — par rapport au brut.
- **Grouper / Dissocier** : un groupe se sélectionne et se déplace d’un bloc.
- **Combiner des fermés** : Weld (souder) ; Intersection ; Soustraire (le dernier sélectionné est retiré) ; exclure la partie commune.
- **Fermer** : par une ligne, une courbe ou en déplaçant l’extrémité. **Joindre deux ouverts** : par une ligne, une courbe ou en déplaçant les extrémités. **Points confondus** : relie de nombreux morceaux en chaînes avec une tolérance.
- **Docteur vectoriel** : trouve points confondus, auto-intersections et boucles, et les corrige.
- **Arcs au lieu de courbes** : remplace les Bézier par des arcs et des lignes (programme CN plus court, coupe plus propre).
- **Congé** : touchez un coin, fixez le rayon. Ici aussi : prolonger deux vecteurs jusqu’à leur intersection.
- **Ciseaux (ajuster)** : toucher un segment supprime son morceau entre intersections.
- **Découpage par contour (Clipping)** : garde les vecteurs à l’intérieur ou à l’extérieur du contour choisi.
- **Trancher** : coupe les vecteurs par une ligne en X ou Y.
- **Cadre autour** : rectangle autour de la sélection avec marge.
- **Convertir** : repère cercles ou rectangles parmi les vecteurs et en fait des «formes».
- **Inverser le sens** : important pour l’ordre et le côté d’usinage.
- **Verrouiller** : le vecteur ne bouge plus par accident.
- **Propriétés** : taille, longueur, surface, nombre de points, lignes, arcs et courbes.

## 8. Texte

**Texte vectoriel** :
- police : type Arial, Times, Courier, DejaVu ou monotrait (gravure en un seul trait) ;
- hauteur, gras, italique ;
- alignement, espacement des lettres et des lignes, crénage ;
- étirement, inclinaison, rotation ;
- position X/Y.

«Créer» ajoute le texte. Plus tard, sélectionnez-le et modifiez-le via ⋮ → «Modifier la forme / le texte».

**Texte sur courbe** : choisissez une courbe ou un cercle, ouvrez «Texte sur courbe», réglez le début, le décalage et le côté. Les lettres suivent la courbe.

## 9. Enveloppe et «Coller le long d’une courbe»

- **Enveloppe** : choisissez un dessin ou un motif, ouvrez «Enveloppe». Un cadre à nœuds apparaît. Faites glisser coins et milieux des côtés. Ou appuyez sur «Courbe du haut…» / «Courbe du bas…» et touchez une courbe existante (un arc par exemple). «Appliquer» déforme le dessin : un motif tient ainsi dans une arche ou une vague.
- **Coller le long d’une courbe** : des copies du dessin sont réparties sur une courbe — en nombre ou par pas, orientées selon la courbe ou non.

## 10. Plaques et imbrication

- **Multi-Plate** : un modèle de plaque (contour + texte) est répété sur le panneau avec les lignes d’un fichier texte. Par exemple numéros d’appartement ou noms : une ligne, une plaque.
- **Imbrication (Nesting)** : les pièces choisies sont posées sur des panneaux d’une taille donnée avec un écart et une marge. La rotation peut être autorisée. Les trous restent automatiquement avec leur pièce.

## 11. Images et photos

- Menu **Fichier → Importer une image / photo** ou icône «Image». Source : **galerie** ou **appareil photo**. L’image devient un **fond** semi-transparent.
- **Réglages du fond** : opacité, affichage, verrouillage. La taille en chiffres ou **par deux points** : touchez deux points de distance connue et saisissez la distance réelle.
- **Décalque manuel** : dessinez avec la polyligne et les formes par-dessus.
- **Vectorisation** (icône «Vectoriser») :
  1. Choisissez le mode : noir et blanc (silhouette par seuil) ou contours.
  2. Réglez le seuil (ou «auto»), le lissage, la suppression des taches, l’inversion.
  3. «Aperçu» montre les futurs vecteurs sur l’image.
  4. «Créer les vecteurs» les ajoute au modèle.
- **Corriger la perspective** : si le panneau a été photographié de biais, touchez les quatre coins et saisissez la taille réelle. La photo devient droite et à l’échelle 1:1.
- **Ponts de pochoir** : petites attaches pour que l’intérieur des lettres ne tombe pas.

## 12. Parcours d’outil (usinage)

Déroulement :
1. **Matériau** (onglet Parcours → icône matériau) : épaisseur, Z de sécurité, point de repos (où va la machine à la fin).
2. **Base d’outils** : fraises avec numéro, diamètre, angle (fraises V), passe en profondeur et latérale, vitesse de broche, avance et vitesse de plongée. Avance en mm/s ou mm/min. Ajouter, copier, modifier, supprimer ; la base est gardée sur le téléphone.
3. **Sélectionnez les vecteurs** et appuyez sur le type d’usinage.

### Types d’usinage
- **Profil** : coupe à l’extérieur ou à l’intérieur du contour (rayon de fraise pris en compte) ou sur la ligne. Réglages : profondeur initiale et finale ; surépaisseur ; sens (avalant ou opposition) ; ordre.
- **Attaches (ponts)** : les pièces ne se détachent pas pendant la coupe. Automatiques (nombre ou distance) ou manuelles en touchant le contour. Longueur et hauteur réglables.
- **Plongée en rampe** : la fraise entre en biais plutôt qu’à la verticale — moins de charge et de marques.
- **Le long des vecteurs** : la fraise suit exactement la ligne. Pour la gravure, les rainures, le texte monotrait.
- **Évidement de zone** : poche dans un contour. Passes par décalage (le long du contour) ou balayage (zigzag), avec recouvrement choisi.
- **Gravure en V** : fraise en V ; la profondeur suit la largeur de la ligne et donne des lettres et motifs «sculptés».
- **Perçage** : trous aux centres des cercles, avec débourrage (pas de débourrage).

Dans la section «Outil», appuyez sur **Choisir…** pour prendre une fraise dans la base. **Calculer** crée le parcours. En dessous : longueur de coupe, nombre de plongées et durée estimée.

Liste des parcours : toucher sélectionne le parcours et ses vecteurs ; case — afficher/masquer ; «Modifier…» — paramètres ; «Recalculer» — après modification des vecteurs ; «Supprimer».

### Simulation
Icône «Simulation» : vue de dessus du passage de la fraise dans le matériau. Lecture/pause, vitesse, «Résultat» (tout d’un coup), «Depuis le début». Pratique pour vérifier attaches, angles intérieurs et oublis.

### Enregistrer le programme CN
**Parcours → Enregistrer les parcours sous…** :
1. Cochez les parcours voulus.
2. Choisissez le post-processeur : **Weihong (.tap)** pour NcStudio ; **Superstar (.nc)** 4 broches, numéro de fraise 1–4 = numéro de broche ; **votre .con** — «Charger votre propre .con…», le fichier post-processeur de votre machine (format ArtCAM). Il est mémorisé.
3. Donnez un nom. «Aperçu» montre le début du programme. «Enregistrer» — choisissez un dossier (clé USB par exemple).

**Gratuit** : 1 programme machine par jour. **Premium** (achat unique) supprime la limite et la publicité.

**Conseil** : avant la première coupe, vérifiez le zéro et le Z sur la machine et lancez d’abord le programme «à vide» (Z relevé).

## 13. Enregistrer et exporter

- **Enregistrer (DXF)** : un DXF R12 classique s’ouvre dans tout logiciel CAO/FAO. Le projet entier y est stocké de façon invisible : calques, parcours, fraises, fond. En le rouvrant ici, tout revient.
- **Enregistrer sous** : DXF ; SVG (les calques s’ouvrent comme calques dans Inkscape) ; projet .cnc2d.
- **Exporter** : PDF à l’échelle 1:1 (pour imprimer un gabarit) ; PNG ou JPG à la résolution choisie, PNG aussi avec fond transparent.
- **Importer des vecteurs** : ajoute les vecteurs d’un autre DXF ou SVG au modèle.
- Les DXF à l’ancien encodage Windows-1251 (cyrillique d’ArtCAM/AutoCAD) s’ouvrent correctement.

## 14. Calques

Onglet **Projet** → Calques, ou **Édition → Calques…** : ajouter ; renommer ✎ ; couleur ; afficher/masquer 👁 ; verrouiller 🔒 ; supprimer ✕.

Les nouveaux vecteurs vont sur le calque **actif** (surligné). «Déplacer» envoie les vecteurs sélectionnés sur le calque actif.

## 15. Annuler et bouton Retour

- **Annuler / Rétablir** : jusqu’à 80 étapes.
- Le bouton **Retour** du système, dans l’ordre : annule le choix d’un point ; ferme l’outil ouvert ; ferme une fenêtre ; revient à l’accueil (demande si le modèle n’est pas enregistré).

## 16. Importer du G-code (.tap, .nc)

L’app ouvre un programme machine existant (.tap, .nc, .ngc, .gcode, etc.) et en reconstruit le dessin.
- Ouvrez le fichier : **Ouvrir un modèle** sur l’écran d’accueil (nouveau modèle) ou **Fichier → Importer des vecteurs…** (ajouter au modèle actuel).
- **Compensation de fraise** : le programme contient la trajectoire du centre de la fraise.
  - « Aucune » — vecteurs au centre de la fraise (pour la gravure et l’usinage le long des vecteurs) ;
  - « Auto » — les pièces sont décalées vers l’intérieur et les trous vers l’extérieur du rayon de la fraise ;
  - « Tous vers l’intérieur » / « Tous vers l’extérieur ». Indiquez le diamètre de la fraise.
- **Fusionner les passes en profondeur** — plusieurs passes à différentes profondeurs deviennent un seul contour.
- **Chaque outil sur son calque** — calques T1, T2… si le programme utilise plusieurs fraises.
- Ensuite enregistrez le dessin : **Fichier → Enregistrer (DXF)**, modifiez-le ou calculez de nouveaux parcours.

## 17. Questions fréquentes

- **Le parcours ne se calcule pas** : le profil extérieur/intérieur et l’évidement exigent des vecteurs **fermés** — utilisez «Docteur vectoriel» ou «Joindre les points confondus» ; la fraise peut être plus large que la poche.
- **La pièce est coupée du mauvais côté** : vérifiez extérieur/intérieur et le sens du vecteur («Inverser le sens»).
- **Des lettres tombent en découpant un pochoir** : utilisez «Ponts de pochoir» ou les attaches du profil.
- **La machine «dérive»** : vérifiez l’origine du modèle (Modèle → Position du zéro) et le point de repos dans Matériau.
- **Les petits vecteurs sont difficiles à toucher** : zoomez à deux doigts ou utilisez un cadre de droite à gauche.
