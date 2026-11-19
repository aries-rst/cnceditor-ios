# CNC Editor 2D — Anleitung

Eine App zur Vorbereitung von 2D-Arbeiten für eine CNC-Fräse: Vektoren zeichnen oder öffnen, Werkzeugwege berechnen und das NC-Programm für Ihre Maschine speichern.
- **Weihong / NcStudio**: Datei **.tap**, eine Spindel.
- **Superstar (4 Spindeln)**: Datei **.nc**. Die Werkzeugnummer ist die Spindelnummer.

## 1. Erste Schritte

### Startbildschirm
- **Neues Modell erstellen**: Plattengröße festlegen.
- **Modell öffnen**: DXF, SVG oder ein .cnc2d-Projekt.
- **Modell aus Bild / Foto**: Ein Kamera- oder Galeriebild wird zur Unterlage.
- **Zurück zum Modell**: erscheint, wenn bereits ein Modell geöffnet ist.
- Ganz oben wählen Sie die **Sprache** (🌐). Außerdem: **Anleitung**, **Premium** und Links zu weiteren Apps.

### Größe des neuen Modells
- **Breite (X)** und **Höhe (Y)**: Größe des Rohteils. Die Tasten 1830×2750, 2070×2800, 1220×2440, 2050×3050 setzen Standardplatten ein.
- **Modellnullpunkt**: eine Ecke oder die Mitte im Schema antippen. Das ist X0 Y0 der Maschine, meist unten links.
- **Einheiten**: mm oder Zoll. Intern wird alles in Millimetern gespeichert.
- **Materialstärke**: wird für die Tiefen der Werkzeugwege verwendet.

## 2. Editor-Bildschirm

- **Menüleiste** (oben): 🏠 — zurück zum Start, dann Datei, Bearbeiten, Modell, Vektoren, Werkzeugwege, Hilfe. Ein Eintrag mit ▸ öffnet ein Untermenü, «← Zurück» kehrt zurück.
- **Ansichtsleiste** (unter dem Menü):
  - ☰ — Panel ein-/ausblenden;
  - ganzes Modell, vergrößern, verkleinern, Raster;
  - rückgängig, wiederholen;
  - **Auswahl**, **Knoten**, **Zur Auswahl hinzufügen**;
  - ⟳ Bildschirm drehen;
  - Menü **Auswählen ▾**, Aktionsmenü ⋮;
  - Zähler «Ausgewählt: N».
- **Panel** mit drei Reitern (im Hochformat unten, im Querformat links):
  - **Projekt**: Informationen, Ebenen, Auswahltipps, Unterlage;
  - **Assistent**: alle Zeichen- und Bearbeitungswerkzeuge; ein geöffnetes Werkzeug zeigt hier seine Felder;
  - **Werkzeugwege**: Liste, Material, Werkzeugdatenbank, Berechnung und Speichern des NC-Programms.
- **Platte**: Das weiße Rechteck ist das Rohteil. Rote und grüne Striche sind die X- und Y-Achse am Nullpunkt.
- Der **Hinweis** unten sagt, was als Nächstes zu tun ist. Wird ein Punkt erwartet, gibt es die Taste «Abbrechen».

Langes Drücken auf ein Symbol zeigt seinen Namen. Ein Symbol mit ◢-Ecke ist eine Gruppe: Antippen öffnet die Liste ihrer Werkzeuge. Das zuletzt gewählte Werkzeug bleibt auf der Taste.

## 3. Gesten auf der Platte

- **Ein Finger auf einem Vektor**: auswählen.
- **Ausgewählten Vektor ziehen**: verschieben.
- **Quadratische Griffe an den Ecken**: proportional skalieren.
- **Runder Griff über dem Rahmen**: drehen in 1°-Schritten.
- **Auf leerer Fläche ziehen**: Auswahlrahmen.
  - **Links nach rechts** (blau, durchgezogen): wählt Vektoren, die vollständig im Rahmen liegen.
  - **Rechts nach links** (grün, gestrichelt): wählt alle Vektoren, die der Rahmen berührt.
- **Leere Fläche antippen**: Auswahl aufheben.
- **Zwei Finger**: verschieben und zoomen.
- **Langes Drücken auf einen Vektor**: Mehrfachauswahl einschalten.
  - Jedes weitere Antippen fügt einen Vektor hinzu oder entfernt ihn.
  - Zahlen in rosa Kreisen zeigen die Reihenfolge. Sie ist wichtig: Beim Ausrichten ist der zuletzt gewählte die Basis, beim Subtrahieren wird der letzte abgezogen.
- **Langes Drücken bei ausgewählten Vektoren** (auf leerer Fläche) öffnet das Aktionsmenü.

Ausgewählte Vektoren werden mit einer dicken rosa Linie mit Leuchtsaum gezeichnet, geschlossene zusätzlich leicht gefüllt.

## 4. Mehrere Vektoren auswählen (statt Umschalttaste)

- Taste **Zur Auswahl hinzufügen**: Solange sie aktiv ist, fügt jedes Antippen hinzu oder entfernt. Auch der Rahmen erweitert die Auswahl.
- **Langes Drücken auf einen Vektor** schaltet denselben Modus vorübergehend ein. Ausschalten mit «Zur Auswahl hinzufügen» oder «Auswahl aufheben».
- Menü **Auswählen ▾**: alles; alle auf der aktuellen Ebene; nur geschlossene, nur offene; ähnliche Größe (wie das erste Muster); Auswahl umkehren; Auswahl aufheben; Auswahlliste.
- **Auswahlliste** (oder «Ausgewählt: N» antippen): Vektoren in Reihenfolge mit Größe. ✕ entfernt einen Vektor aus der Auswahl.

## 5. Formen zeichnen

Reiter **Assistent** → «Vektorwerkzeuge». Jede Form lässt sich auf zwei Arten zeichnen:
- **Mit dem Finger**: auf der Platte ziehen. Die Felder zeigen sofort die Maße.
- **Mit Zahlen**: Mitte, Breite, Höhe, Radien usw. eingeben und «Erstellen / Fertig» drücken.

Solange die Form frisch gezeichnet ist, ändert jedes Feld sie sofort. «Fertig» fixiert die Form. «Mitte per Antippen» setzt die Mitte durch Antippen.

- **Rechteck**: Breite, Höhe, Eckenradius; Ecken gerundet oder umgekehrt (konkav).
- **Kreis**: Mitte und Radius oder Durchmesser.
- **Ellipse**: Mitte, Breite, Höhe, Drehwinkel.
- **Polygon**: Seitenzahl, Radius, Drehung.
- **Stern**: Zackenzahl, äußerer und innerer Radius.
- **Bogen**, drei Arten: durch drei Punkte; Mitte, Anfang und Ende; Anfang, Ende und Radius.
- **Polylinie**: Platte antippen — jedes Antippen setzt einen Punkt. Der nächste Punkt kann als Zahl eingegeben werden. «Schließen» verbindet mit dem ersten Punkt.

**Fertige Form bearbeiten**: auswählen und ⋮ → «Form / Text bearbeiten…».

## 6. Knoten

Taste **Knoten**: Vektor wählen und seine Punkte ziehen.
- Blaue Quadrate sind Punkte, grün ist der Startpunkt, Kreise sind Bézier-Steuerpunkte.
- **Langes Drücken auf einen Punkt**: Punkt löschen, glätten, zum Start machen, Koordinaten eingeben.
- **Langes Drücken auf ein Segment**: in Linie, Bogen oder Bézierkurve umwandeln; Punkt einfügen; Startpunkt einfügen; Segment löschen (Vektor trennen).

## 7. Vektoren bearbeiten

Alle Befehle stehen im Menü **Vektoren** und im Assistenten-Abschnitt «Position, Kombinieren, Trimmen».
- **Transformieren**: genau verschieben, Größe (proportional), drehen, scheren, mit oder ohne Kopie.
- **Spiegeln**: horizontal oder vertikal, zur eigenen Mitte oder zur Platte.
- **Versatz (Offset)**: nach außen oder innen um einen Abstand; spitze oder runde Ecken.
- **Blockkopie**: Zeilen und Spalten mit Abstand oder Raster. **Kreisförmig**: N Kopien um eine Mitte.
- **Ausrichten**: an Kanten und Mitten relativ zum zuletzt gewählten; «Plattenmitte» — relativ zum Rohteil.
- **Gruppieren / Gruppierung aufheben**: Eine Gruppe wird als Ganzes gewählt und bewegt.
- **Geschlossene Vektoren kombinieren**: Weld (verbinden); Schnittmenge; Subtrahieren (der zuletzt gewählte wird abgezogen); gemeinsamen Teil ausschließen.
- **Schließen**: mit Linie, Kurve oder durch Verschieben des Endes. **Zwei offene Vektoren verbinden**: mit Linie, Kurve oder durch Verschieben der Enden. **Zusammenfallende Punkte**: viele Stücke mit Toleranz zu Ketten verbinden.
- **Vektor-Doktor**: findet zusammenfallende Punkte, Selbstüberschneidungen und Schleifen und behebt sie.
- **Bögen statt Kurven**: ersetzt Bézierkurven durch Bögen und Linien (kürzeres NC-Programm, sauberer Schnitt).
- **Rundung**: Ecke antippen, Radius setzen. Hier auch: zwei Vektoren bis zum Schnittpunkt verlängern.
- **Schere (Trimmen)**: Antippen eines Segments löscht sein Stück zwischen Schnittpunkten.
- **Zuschneiden (Clipping)**: Vektoren innerhalb oder außerhalb der gewählten Kontur behalten.
- **Teilen**: Vektoren mit einer Linie in X oder Y teilen.
- **Rahmen um**: Rechteck um die Auswahl mit Abstand.
- **Umwandeln**: Kreise oder Rechtecke unter den Vektoren finden und zu «Formen» machen.
- **Richtung umkehren**: wichtig für Reihenfolge und Seite der Bearbeitung.
- **Sperren**: Der Vektor lässt sich nicht versehentlich verschieben.
- **Eigenschaften**: Größe, Länge, Fläche, Anzahl der Punkte, Linien, Bögen und Kurven.

## 8. Text

**Vektortext**:
- Schrift: Arial-, Times-, Courier-ähnlich, DejaVu oder einlinig (für Einzellinien-Gravur);
- Höhe, fett, kursiv;
- Ausrichtung, Zeichen- und Zeilenabstand, Unterschneidung;
- Dehnung, Neigung, Drehung;
- Position X/Y.

«Erstellen» setzt den Text auf die Platte. Später auswählen und über ⋮ → «Form / Text bearbeiten» ändern.

**Text auf Kurve**: Kurve oder Kreis wählen, «Text auf Kurve» öffnen, Anfang auf der Kurve, Abstand und Seite einstellen. Die Buchstaben drehen sich entlang der Kurve.

## 9. Hülle und «Entlang Kurve einfügen»

- **Hülle**: Zeichnung oder Muster wählen, «Hülle» öffnen. Ein Rahmen mit Knoten erscheint. Ecken und Seitenmitten ziehen. Oder «Obere Kurve…» / «Untere Kurve…» drücken und eine vorhandene Kurve (z. B. Bogen) antippen. «Anwenden» verzerrt die Zeichnung — so passt ein Muster in einen Bogen oder eine Welle.
- **Entlang Kurve einfügen**: Kopien der Auswahl werden gleichmäßig entlang einer Kurve verteilt — nach Anzahl oder Schritt, mit oder ohne Drehung entlang der Kurve.

## 10. Schilder und Verschachtelung

- **Multi-Plate**: Eine Schildvorlage (Kontur + Text) wird auf der Platte vervielfacht, die Texte kommen zeilenweise aus einer Textdatei. Beispiel: Wohnungsnummern oder Namen — eine Zeile, ein Schild.
- **Verschachtelung (Nesting)**: Gewählte Teile werden mit Abstand und Randabstand auf Platten gegebener Größe gelegt. Drehung kann erlaubt werden. Löcher bleiben automatisch bei ihrem Teil.

## 11. Bilder und Fotos

- Menü **Datei → Bild / Foto importieren** oder Symbol «Bild». Quelle: **Galerie** oder **Kamera**. Das Bild wird eine halbtransparente **Unterlage**.
- **Unterlage einstellen**: Deckkraft, anzeigen, sperren. Größe per Zahlen oder **über zwei Punkte**: zwei Punkte bekannter Entfernung antippen und den echten Abstand eingeben.
- **Von Hand nachzeichnen**: mit Polylinie und Formen über der Unterlage zeichnen.
- **Vektorisierung** (Symbol «Vektorisieren»):
  1. Modus wählen: Schwarz-Weiß (Silhouette nach Schwelle) oder Konturen.
  2. Helligkeitsschwelle (oder «auto»), Glättung, Fleckenentfernung, Invertieren einstellen.
  3. «Vorschau» zeigt die künftigen Vektoren über dem Bild.
  4. «Vektoren erstellen» fügt sie dem Modell hinzu.
- **Perspektive korrigieren**: Bei schräg fotografierter Platte die vier Ecken antippen und die echte Größe eingeben. Das Foto wird gerade und im Maßstab 1:1.
- **Schablonenstege**: kleine Verbindungen, damit Innenteile von Buchstaben nicht herausfallen.

## 12. Werkzeugwege (Bearbeitung)

Ablauf:
1. **Material** (Reiter Werkzeugwege → Materialsymbol): Stärke, sichere Z-Höhe, Home-Punkt (wohin die Maschine am Ende fährt).
2. **Werkzeugdatenbank**: Fräser mit Nummer, Durchmesser, Winkel (V-Fräser), Zustellung, seitlicher Zustellung, Drehzahl, Vorschub und Eintauchgeschwindigkeit. Vorschub in mm/s oder mm/min. Fräser können hinzugefügt, kopiert, bearbeitet und gelöscht werden; die Datenbank wird auf dem Telefon gespeichert.
3. **Vektoren auswählen** und die Bearbeitungsart drücken.

### Bearbeitungsarten
- **Profil**: außen oder innen an der Kontur (mit Fräserradius) oder auf der Linie. Einstellungen: Start- und Endtiefe; Aufmaß; Richtung (Gleich- oder Gegenlauf); Reihenfolge.
- **Stege (Haltestege)**: Teile reißen beim Schneiden nicht ab. Automatisch (Anzahl oder Abstand) oder manuell durch Antippen der Kontur. Länge und Höhe einstellbar.
- **Rampeneintauchen**: Der Fräser taucht schräg statt senkrecht ein — weniger Last, weniger Spuren.
- **Entlang Vektoren**: Der Fräser fährt genau auf der Linie. Für Gravur, Nuten, Einzellinien-Text.
- **Flächenausräumung**: Tasche in einer Kontur. Versatzbahnen (entlang der Kontur) oder Raster (Zickzack), mit gewählter Überlappung.
- **V-Gravur**: V-Fräser; die Tiefe folgt der Linienbreite — «geschnitzte» Buchstaben und Muster.
- **Bohren**: Löcher in Kreismitten, mit Entspanen (Entspanschritt).

Im Abschnitt «Werkzeug» **Wählen…** drücken, um einen Fräser aus der Datenbank zu nehmen. **Berechnen** erstellt den Werkzeugweg. Darunter stehen Schnittlänge, Anzahl der Eintauchungen und geschätzte Zeit.

Liste der Werkzeugwege: Antippen wählt den Weg und seine Vektoren; Häkchen — anzeigen/ausblenden; «Ändern…» — Parameter öffnen; «Neu berechnen» — nach Änderung der Vektoren; «Löschen».

### Simulation
Symbol «Simulation»: Draufsicht, wie der Fräser durch das Material geht. Start/Pause, Geschwindigkeit, «Ergebnis» (alles auf einmal), «Von vorn». Gut, um Stege, Innenecken und Lücken zu prüfen.

### NC-Programm speichern
**Werkzeugwege → Werkzeugwege speichern unter…**:
1. Gewünschte Wege ankreuzen.
2. Postprozessor wählen: **Weihong (.tap)** für NcStudio; **Superstar (.nc)** mit 4 Spindeln, Fräsernummer 1–4 = Spindelnummer; **eigene .con** — «Eigene .con laden…», die Postprozessordatei Ihrer Maschine (ArtCAM-Format). Sie wird gespeichert.
3. Dateiname festlegen. «Vorschau» zeigt den Programmanfang. «Speichern» — Ordner wählen (z. B. USB-Stick).

**Kostenlos** kann 1 Maschinenprogramm pro Tag gespeichert werden. **Premium** (einmaliger Kauf) hebt die Grenze auf und entfernt Werbung.

**Tipp:** Vor dem ersten Schnitt Nullpunkt und Z an der Maschine prüfen und das Programm zuerst «in der Luft» (mit angehobenem Z) laufen lassen.

## 13. Speichern und Export

- **Speichern (DXF)**: Ein normales DXF R12 öffnet sich in jedem CAD/CAM-Programm. Darin ist unsichtbar das ganze Projekt gespeichert: Ebenen, Werkzeugwege, Fräser, Unterlage. Öffnet man es hier wieder, ist alles da.
- **Speichern unter**: DXF; SVG (Ebenen öffnen sich als Ebenen in Inkscape); .cnc2d-Projekt.
- **Export**: PDF 1:1 (zum Drucken einer Schablone); PNG oder JPG in gewählter Auflösung, PNG auch mit transparentem Hintergrund.
- **Vektoren importieren**: Vektoren aus einem anderen DXF oder SVG hinzufügen.
- DXF in alter Windows-1251-Kodierung (Kyrillisch aus ArtCAM/AutoCAD) öffnet sich korrekt.

## 14. Ebenen

Reiter **Projekt** → Ebenen oder **Bearbeiten → Ebenen…**: Ebene hinzufügen; umbenennen ✎; Farbe; ein-/ausblenden 👁; sperren 🔒; löschen ✕.

Neue Vektoren kommen auf die **aktive** (markierte) Ebene. «Verschieben» bringt gewählte Vektoren auf die aktive Ebene.

## 15. Rückgängig und Zurück-Taste

- **Rückgängig / Wiederholen**: bis zu 80 Schritte.
- Die System-Taste **Zurück** der Reihe nach: bricht die Punktauswahl ab; schließt das offene Werkzeug; schließt ein Fenster; kehrt zum Start zurück (mit Rückfrage bei ungespeichertem Modell).

## 16. G-Code importieren (.tap, .nc)

Die App öffnet ein fertiges Maschinenprogramm (.tap, .nc, .ngc, .gcode usw.) und stellt daraus die Zeichnung wieder her.
- Datei öffnen: **Modell öffnen** im Startbildschirm (neues Modell) oder **Datei → Vektoren importieren…** (zum aktuellen hinzufügen).
- **Fräserradiuskorrektur**: Das Programm enthält die Bahn des Fräsermittelpunkts.
  - „Keine“ — Vektoren entlang der Fräsermitte (richtig für Gravur und Fräsen entlang Vektoren);
  - „Auto“ — Teile werden um den Fräserradius nach innen, Löcher nach außen versetzt;
  - „Alle nach innen“ / „Alle nach außen“. Fräserdurchmesser eingeben.
- **Tiefenzustellungen zusammenfassen** — mehrere Durchgänge in verschiedenen Tiefen werden zu einer Kontur.
- **Jedes Werkzeug auf eigener Ebene** — Ebenen T1, T2…, wenn mehrere Fräser verwendet werden.
- Danach die Zeichnung speichern: **Datei → Speichern (DXF)**, bearbeiten oder neue Werkzeugwege berechnen.

## 17. Häufige Fragen

- **Werkzeugweg wird nicht berechnet:** Profil außen/innen und Ausräumung brauchen **geschlossene** Vektoren — «Vektor-Doktor» oder «Zusammenfallende Punkte verbinden» verwenden; der Fräser kann breiter als die Tasche sein.
- **Teil wird auf der falschen Seite geschnitten:** außen/innen und Vektorrichtung prüfen («Richtung umkehren»).
- **Buchstaben fallen beim Schablonenschnitt heraus:** «Schablonenstege» oder Stege im Profil verwenden.
- **Maschine «läuft weg»:** Modellnullpunkt (Modell → Nullpunkt) und Home-Punkt im Material prüfen.
- **Kleine Vektoren schwer zu treffen:** mit zwei Fingern zoomen oder Rahmen von rechts nach links verwenden.
