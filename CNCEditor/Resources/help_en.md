# CNC Editor 2D — user guide

An app for preparing 2D jobs for a CNC router: draw or open vectors, calculate cutter toolpaths and save the NC program for your machine.
- **Weihong / NcStudio**: **.tap** file, one spindle.
- **Superstar (4 spindles)**: **.nc** file. The tool number is the spindle number.

## 1. Getting started

### Start screen
- **Create new model**: set the sheet size.
- **Open model**: DXF, SVG, G-code (.tap / .nc) or a .cnc2d project.
- **Model from picture / photo**: a camera shot or gallery image becomes an underlay.
- **Back to model**: shown when a model is already open.
- At the top — **language** choice (🌐, 17 languages). Below — **User guide**, **Premium**, **Exit** and links to other ARESTI Labs apps and the website.

### Size for new model
- **Width (X)** and **Height (Y)**: the blank size. Buttons 1830×2750, 2070×2800, 1220×2440, 2050×3050 fill in standard sheets.
- **Model origin**: tap a corner or the centre of the diagram. This is the machine X0 Y0. Usually the bottom-left corner.
- **Units**: mm or inches. Everything is stored in millimetres internally.
- **Material thickness**: used for toolpath depths.

## 2. Editor screen

- **Menu bar** (top): 🏠 — back to the start screen, then File, Edit, Model, Vectors, Toolpaths, Help. An item with ▸ opens a submenu, “← Back” returns.
- **View bar** (under the menu):
  - ☰ — show or hide the left panel;
  - zoom to model, zoom in, zoom out, grid;
  - undo, redo;
  - **Select**, **Nodes**, **Add to selection**;
  - ⟳ rotate screen: landscape → portrait → auto-rotate;
  - **Select ▾** menu, ⋮ actions menu;
  - “Selected: N” counter.
- **Panel** with three tabs (at the bottom in portrait, on the left in landscape):
  - **Project**: information, layers, selection tips, underlay;
  - **Assistant**: all drawing and editing tools. When a tool is open, its fields are shown here;
  - **Toolpaths**: toolpath list, material, tool database, calculation and NC saving.
- **Sheet**: the white rectangle is the blank. Red and green ticks are the X and Y axes at the origin.
- **Hint** at the bottom of the sheet says what to do now. When a point is needed there is a “Cancel” button.

Long press on any icon shows its name. An icon with a ◢ corner is a group: tapping it opens the list of its tools. The last chosen tool stays on the button.

## 3. Gestures on the sheet

- **One finger on a vector**: select it.
- **Drag a selected vector**: move it.
- **Square handles at the frame corners**: proportional scaling.
- **Round handle above the frame**: rotation in 1° steps.
- **Drag on empty space**: selection frame.
  - **Left to right** (blue solid): selects vectors fully inside the frame.
  - **Right to left** (green dashed): selects every vector the frame touches.
- **Tap empty space**: clear the selection.
- **Two fingers**: pan and zoom (pinch).
- **Long press on a vector**: turns on multi-select.
  - Each next tap adds the vector or removes it from the selection.
  - Numbers in pink circles show the selection order. Order matters: alignment uses the last selected as the base, subtraction subtracts the last one.
- **Long press with vectors selected** (on empty space) opens the actions menu.

Selected vectors are drawn with a thick pink line with a glow; closed ones are also lightly filled.

## 4. Selecting several vectors (instead of the Shift key)

- **Add to selection** button on the view bar: while it is on, each tap adds or removes a vector. The frame also adds to what is already selected.
- **Long press on a vector** turns on the same mode temporarily. Turn it off with “Add to selection” or “Deselect”.
- **Select ▾** menu:
  - all;
  - all on the current layer;
  - closed only, open only;
  - similar size (like the first selected sample);
  - invert selection;
  - deselect;
  - selected list.
- **Selected list** (or tap “Selected: N”): vectors in order with their sizes. The ✕ cross removes a vector from the selection.

## 5. Drawing shapes

**Assistant** tab → “Vector tools”. Every shape can be drawn two ways:
- **With a finger**: drag on the sheet. The panel fields show the sizes at once.
- **With numbers**: enter centre, width, height, radii, etc. and press “Create / Done”.

While a shape is freshly drawn, changing any field changes it on the sheet. “Done” fixes the shape. “Centre by tap” lets you tap the centre.

- **Rectangle**: width, height, corner radius; corners rounded or reverse (concave).
- **Circle**: centre and radius or diameter.
- **Ellipse**: centre, width, height, rotation angle.
- **Polygon**: number of sides, radius, rotation.
- **Star**: number of points, outer and inner radii.
- **Arc**, three ways: by three points; centre, start and end; start, end and radius.
- **Polyline**: tap the sheet — each tap adds a point. The next point can be typed as numbers. “Close” joins to the first point.

To **edit a finished shape**: select it and use ⋮ → “Edit shape / text…”.

## 6. Nodes

**Nodes** button: select a vector and drag its points.
- Blue squares are points, green is the start point, circles are Bézier control points.
- **Long press on a point**: delete the point, smooth, make start, enter coordinates.
- **Long press on a segment**:
  - turn into a line, arc or Bézier curve;
  - insert a point;
  - insert a start point;
  - delete the segment (cut the vector).

## 7. Editing vectors

All commands are in the **Vectors** menu and in the Assistant section “Position, combine, trim”.
- **Transform**: exact move, size (keeping proportions), rotation, shear, with or without a copy.
- **Mirror**: horizontal or vertical, about its own centre or the sheet.
- **Offset**: outward or inward by a set distance; sharp or rounded corners.
- **Block copy**: rows and columns with a gap or pitch. **Circular**: N copies around a centre.
- **Align**: by edges and centres relative to the last selected; “Centre of sheet” — relative to the blank.
- **Group / Ungroup**: a group is selected and moved as a whole.
- **Combining closed vectors**:
  - Weld (add);
  - Intersection;
  - Subtract (the last selected is subtracted from the others);
  - Exclude common part.
- **Close**: with a line, curve or by moving the end. **Join two open vectors**: with a line, curve or by moving the ends. **Coincident points**: glue many pieces into chains within a tolerance.
- **Vector doctor**: finds coincident points, self-intersections and loops and fixes them.
- **Arcs instead of curves**: replaces Bézier curves with arcs and lines (fewer NC lines, smoother cut).
- **Fillet**: tap a corner, set the radius. Also here: extend two vectors to their intersection.
- **Scissors (trim)**: tapping a segment deletes its piece between intersections.
- **Clipping**: keep vectors inside or outside the selected contour.
- **Slice**: cut vectors with a line along X or Y.
- **Border around**: a rectangle around the selection with a margin.
- **Convert**: find circles or rectangles among vectors and make them “shapes”.
- **Reverse direction**: important for machining order and side.
- **Lock**: the vector can’t be moved by accident.
- **Properties**: size, length, area, number of points, lines, arcs and curves.

## 8. Text

**Vector text**:
- font: Arial-, Times-, Courier-like, DejaVu or single-line (for one-line engraving);
- height, bold, italic;
- alignment, character and line spacing, kerning;
- stretch, slant, rotation;
- X/Y position.

“Create” adds the text to the sheet. Later you can select it and edit via ⋮ → “Edit shape / text”.

**Text on curve**: select a curve or circle, open “Text on curve”, set the start on the curve, the offset from it and the side. Letters turn along the curve.

## 9. Envelope and “Paste along curve”

- **Envelope**: select a drawing or pattern, open “Envelope”. A frame with nodes appears around it. Drag the corners and side midpoints. Or press “Top curve…” / “Bottom curve…” and tap an existing curve (e.g. an arc) so the frame follows its shape. “Apply” distorts the drawing. This way a pattern fits into an arch, a wave, etc.
- **Paste along curve**: copies of the selected drawing are spread evenly along a curve — by count or by step, rotated along the curve or not.

## 10. Plates and nesting

- **Multi-Plate**: a plate template (contour + text) is repeated on the sheet with lines from a text file substituted. For example flat numbers or names: one line — one plate.
- **Nesting**: selected parts are laid onto sheets of a set size with a gap and an edge margin. Rotation can be allowed. Holes automatically stay with their part.

## 11. Pictures and photos

- **File → Import picture / photo** menu or the “Picture” icon. Source — **gallery** or **camera**. The picture becomes a semi-transparent **underlay**.
- **Underlay settings**: opacity, visibility, lock. Size is set by numbers or **by two points**: tap two points of known distance and enter the real distance.
- **Manual tracing**: draw with polyline and shapes over the underlay.
- **Vectorization** (“Vectorize” icon):
  1. Choose a mode: black & white (silhouette by threshold) or contours.
  2. Set the brightness threshold (or “auto”), smoothing, speck removal, invert.
  3. “Preview” shows the future vectors over the picture.
  4. “Create vectors” adds them to the model.
- **Correct perspective**: if the sheet was shot at an angle, tap the four corners on the photo and enter the real size. The photo becomes straight and at 1:1 scale.
- **Stencil bridges**: small links so the inner parts of letters and shapes don’t fall out.

## 12. Toolpaths (machining)

Workflow:
1. **Material** (Toolpaths tab → material icon): thickness, safe Z height, home point (where the machine goes at the end).
2. **Tool database**: cutters with number, diameter, angle (for V-bits), stepdown and stepover, spindle speed, feed and plunge rate. Feed is in mm/s or mm/min. Tools can be added, copied, edited and deleted; the database is saved on the phone.
3. **Select vectors** on the sheet and press the machining type.

### Machining types
- **Profile**: cut outside or inside the contour (allowing for the cutter radius) or on the line. Settings:
  - start and finish depth;
  - allowance;
  - direction (climb or conventional);
  - machining order.
- **Tabs (bridges)**: parts don’t break off while cutting. Placed automatically (by count or by distance) or manually by tapping on the contour. Length and height are set.
- **Ramped plunge**: the cutter enters the material at an angle, not vertically — less load and fewer marks.
- **Machine along vectors**: the cutter goes right along the line. For engraving, grooves, single-line text.
- **Area clearance**: a pocket inside a contour. Offset passes (along the contour) or raster (zigzag), with a set overlap.
- **V-carving**: V-bit; depth changes with line width, giving “carved” letters and patterns.
- **Drilling**: holes at circle centres, with peck drilling (peck step).

Press **Select…** in the “Tool” section to take a cutter from the database. The **Calculate** button builds the toolpath. Below it you see cut length, number of plunges and estimated time.

Toolpath list:
- tap selects the toolpath and its vectors;
- tick — show or hide;
- “Edit…” — open the parameters;
- “Recalculate” — after changing the vectors;
- “Delete”.

### Simulation
“Simulation” icon: top view of how the cutter goes through the material. Play/pause, speed, “Result” (everything at once), “From start”. Handy to check tabs, inner corners and gaps.

### Saving the NC program
**Toolpaths → Save toolpaths as…**:
1. Tick the needed toolpaths.
2. Choose the post processor:
   - **Weihong (.tap)**: for NcStudio;
   - **Superstar (.nc)**: 4 spindles; cutter number 1–4 = spindle number;
   - **your own .con**: “Load your own .con…” — the post processor file from your machine (ArtCAM format). It is remembered.
3. Set the file name. “Preview” shows the start of the program. “Save” — choose a folder (e.g. a USB stick or a folder for transfer to the machine).

**Free:** 1 machine program per day can be saved. **Premium** (one-time purchase, forever) removes the limit and the ads.

**Tip:** before the first cut check zero and Z on the machine. Run the program “in the air” first (with Z raised).

## 13. Saving and export

- **Save (DXF)**: a normal DXF R12 opens in any CAD/CAM program. Inside it the whole project is invisibly stored: layers, toolpaths, cutters, underlay. Opening such a DXF here restores everything.
- **Save as**:
  - DXF;
  - SVG (layers open as layers in Inkscape);
  - .cnc2d project.
- **Export**:
  - PDF at 1:1 scale (for printing a template);
  - PNG or JPG at the chosen resolution; PNG can have a transparent background.
- **Import vectors**: add vectors from another DXF, SVG or G-code to the current model.
- DXF in the old Windows-1251 encoding (Cyrillic from ArtCAM/AutoCAD) opens correctly.

## 14. Layers

**Project** tab → Layers, or **Edit → Layers…**:
- add a layer;
- rename ✎;
- colour;
- show or hide 👁;
- lock 🔒;
- delete ✕.

New vectors go to the **active** (highlighted) layer. “Move” moves the selected vectors to the active layer.

## 15. Undo and the Back button

- **Undo / Redo**: up to 80 steps.
- The system **Back** button, in order:
  1. cancels point picking;
  2. closes the open tool;
  3. closes a dialog;
  4. returns to the start screen (asking if the model isn’t saved).

## 16. Importing G-code (.tap, .nc)

The app opens a ready machine program (.tap, .nc, .ngc, .gcode, etc.) and recovers the drawing from it.
- Open the file: **Open model** on the start screen (new model) or **File → Import vectors…** (add to the current one).
- **Cutter compensation**: the program stores the cutter centre path.
  - “None” — vectors along the cutter centre (right for engraving and machining along vectors);
  - “Auto” — parts are shifted inward and holes outward by the cutter radius;
  - “All inward” / “All outward”. Enter the cutter diameter.
- **Merge depth passes** — several passes at different depths become one contour.
- **Each tool on its own layer** — layers T1, T2… if the program uses several cutters.
- Then save the drawing: **File → Save (DXF)**, edit it or calculate new toolpaths.

## 17. FAQ

- **The toolpath isn’t calculated:**
  - profile outside/inside and clearance need **closed** vectors. Use “Vector doctor” or “Join coincident points”;
  - the cutter may be wider than the pocket.
- **The part is cut on the wrong side:** check outside/inside and the vector direction (“Reverse direction”).
- **Letters fall out when cutting a stencil:** use “Stencil bridges” or tabs in the profile.
- **The machine “drifts”:** check the model origin (Model → Zero position) and the home point in Material.
- **Small vectors are hard to select:** zoom in with two fingers or use a right-to-left frame.
