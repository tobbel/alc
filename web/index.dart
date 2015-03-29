import 'dart:html';
import 'package:three/three.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:math' as Math;

Element container;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Mesh mesh;

bool hideTest = false;

void main() {
  init();
  render(0.0);
}

void init() {
  container = new DivElement();
  document.body.append(container);
  document.body.onClick.listen((e) {
    hideTest = !hideTest; 
    createScene();
    drawLineSegments();
  });
  
  createScene();
  
  calculateLines();
  drawLineSegments();
  
  for (Vector2 intersectionPoint in intersectionPoints) {
    var material = new MeshBasicMaterial(color: 0x00ff00);

    var radius = 0.1;
    var segments = 32;

    var circleGeometry = new CircleGeometry(radius, segments);        
    var circle = new Mesh(circleGeometry, material);
    circle.position = new Vector3(intersectionPoint.x, intersectionPoint.y, 0.0);
    scene.add(circle);
  }
  
  renderer = new WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);

  container.append(renderer.domElement);
}

void createScene() {
  scene = new Scene();
  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight);
  camera.position.z = 15.0;
  
  scene.add(camera);
}

void render(double dt) {
  window.requestAnimationFrame(render);

  camera.lookAt(new Vector3(0.0, 0.0, 0.0));
  renderer.render(scene, camera);
}

class LineSegment {
  Vector2 start;
  Vector2 end;
  LineSegment(this.start, this.end);
  // Might as well use Vector3s to get depth, this is just easier to work with for now
  int depth;
  bool hidden = false;
  bool intersects = false;
  
  // Assumes point is on line
  // TODO: Consider split replacing lines as well
  List<LineSegment> split(Vector2 position) {
    List<LineSegment> newLines = new List<LineSegment>();
    newLines.add(new LineSegment(this.start, position));
    newLines.add(new LineSegment(position, this.end));
    return newLines;
  }
  
  toString() => "($start; $end)";
}

class LineGroup {
  List<LineSegment> Line = new List<LineSegment>();
  void add(LineSegment line) => Line.add(line);
  num get length => Line.length;
  LineSegment operator [](int index) => Line[index];
  void insert(int index, LineSegment line) => Line.insert(index, line);
  LineSegment removeAt(int index) => Line.removeAt(index);
  
  String toString() {
    String out = "";
    for (LineSegment line in Line) {
      out += line.toString() + " (" + (line.hidden ? "hidden" : "visible") + ")";
    }
    return out;
  }
  
  List<LineSegment> split(LineSegment line, Vector2 intersectionPoint) {
    int index = Line.indexOf(line);
    List<LineSegment> splitLines = line.split(intersectionPoint);
    
    // TODO: Remove helper functions if this is the only place they're used
    removeAt(index);
    insert(index, splitLines[0]);
    insert(index + 1, splitLines[1]);
    return splitLines;
  }
}

Vector2 intersects(LineSegment a, LineSegment b) {
  /// u = (q − p) × r / (r × s)
  Vector2 qmp = b.start - a.start;
  Vector2 pmq = a.start - b.start;
  Vector2 r = a.end - a.start;
  Vector2 s = b.end - b.start;
  double qmpxr = qmp.cross(r);
  double qmpxs = qmp.cross(s);
  double rxs = r.cross(s);

  //If r × s = 0 and (q − p) × r = 0, then the two lines are collinear. 
  if (rxs == 0 && qmpxr == 0) {
    //If in addition, either 0 ≤ (q − p) * r ≤ r * r or 0 ≤ (p − q) * s ≤ s * s, then the two lines are overlapping.
    if ((qmp.dot(r) >= 0 && qmp.dot(r) <= r.dot(r)) ||
         pmq.dot(s) >= 0 && pmq.dot(s) <= s.dot(s)) {
      // Overlapping - handle
      return null;
    }
    // Colinear - but don't collide
    return null;
  }
  
  //If r × s = 0 and (q − p) × r = 0, but neither 0 ≤ (q − p) · r ≤ r · r nor 0 ≤ (p − q) · s ≤ s · s, then the two lines are collinear but disjoint.
  if (rxs == 0 && qmpxr == 0) {
    
  }
  
  //If r × s = 0 and (q − p) × r ≠ 0, then the two lines are parallel and non-intersecting.
  if (rxs == 0 && qmpxr != 0) {
    return null;
  }
  
  //If r × s ≠ 0 and 0 ≤ t ≤ 1 and 0 ≤ u ≤ 1, the two line segments meet at the point p + t r = q + u s.
  if (rxs != 0) {
    // Calculate t and u
    var t = qmpxs / rxs;
    if (t < 0 || t > 1)
      return null;
        
    var u = qmpxr / rxs;
    if (u < 0 || u > 1)
      return null;
    
    return a.start + r * t;
  }
  
  //Otherwise, the two line segments are not parallel but do not intersect.
  return null;
}
List<Vector2> intersectionPoints = new List<Vector2>();
List<LineSegment> getPossibleIntersectors(LineSegment line, int parentIndex) {
  List<LineSegment> possibleIntersectors = new List<LineSegment>();
  for (int i = 0; i < Lines.length; i++) {
    if (i == parentIndex)
      continue;
    LineGroup lineGroup = Lines[i];
    for (int j = 0; j < lineGroup.length; j++) {
      LineSegment lineSegment = lineGroup[j];
      if (lineSegment.start.x <= line.start.x && lineSegment.end.x >= line.start.x ||
          lineSegment.start.x >= line.start.x && lineSegment.start.x <= line.end.x) {
        possibleIntersectors.add(lineSegment);
      }
    }
  }
  return possibleIntersectors;
}

List<LineSegment> getPossibleIntersectorsWithHorizon(LineSegment line) {
  List<LineSegment> possibleIntersectors = new List<LineSegment>();
  for (int i = 0; i < Horizon.length; i++) {
    LineSegment horizonSegment = Horizon[i];
    if (horizonSegment.start.x <= line.start.x && horizonSegment.end.x >= line.start.x ||
        horizonSegment.start.x >= line.start.x && horizonSegment.start.x <= line.end.x) {
      possibleIntersectors.add(horizonSegment);
    }
  }
  return possibleIntersectors;
}

List<LineGroup> Lines = new List<LineGroup>();
LineGroup Horizon = new LineGroup();
void calculateLines() {
  Lines.clear();
  intersectionPoints.clear();
  const int lineCount = 3;
  Math.Random rand = new Math.Random();
  // Start w/ two lines - set up manually
  LineGroup a = new LineGroup();
  Vector2 from = new Vector2(-6.0, 3.0 * rand.nextDouble());
  for (int i = 0; i < lineCount; i++) {
    Vector2 to = new Vector2(i - 5.0, 3.0 * rand.nextDouble());
    a.add(new LineSegment(from, to));
    from = to;
  }
//  a.add(new LineSegment(new Vector2(-2.0, 1.0), new Vector2(0.0, -1.0)));
//  a.add(new LineSegment(new Vector2(0.0, -1.0), new Vector2(2.0, 1.0)));
  Lines.add(a);
  Horizon = a;
  
  LineGroup b = new LineGroup();
  from = new Vector2(-6.0, 3.0 * rand.nextDouble());
  for (int i = 0; i < lineCount; i++) {
    Vector2 to = new Vector2(i - 5.0, 3.0 * rand.nextDouble());
    b.add(new LineSegment(from, to));
    from = to;
  }
  //b.add(new LineSegment(new Vector2(-2.0, -1.0), new Vector2(0.0, 1.0)));
  //b.add(new LineSegment(new Vector2(0.0, 1.0), new Vector2(2.0, -1.0)));
  Lines.add(b);

  // On intersect, remove line and add two new lines with start/end at intersect position.
  // Of those two lines, second line will not be drawn.
  // Until another line segment in new line intersects, all will be marked as hidden.
  // On next intersection, split lines and hide first of the two new lines.
  
  // Compare with horizon
  //for (LineSegment line in b.Line) {
  for (int i = 0; i < b.Line.length; i++) {
    if (i > 50) break;
    LineSegment line = b.Line[i];
    List<LineSegment> possibleIntersectors = getPossibleIntersectorsWithHorizon(line);
    // TODO: Break and redo after intersection and split
    bool intersected = false;
    for (LineSegment intersector in possibleIntersectors) {
      Vector2 intersectionPoint = intersects(line, intersector);
      if (intersectionPoint != null) {
        intersected = true;
        intersectionPoints.add(intersectionPoint);
        // New line has intersected with horizon
        // Determine if line should be visible or hidden: compare y of start points
        bool aboveHorizon = line.start.y > intersector.start.y;
        print('line ${i}, y: ${line.start.y}, above horizon: ${aboveHorizon.toString()}');
        List<LineSegment> newSplitLines = b.split(line, intersectionPoint);
        i++;
        //List<LineSegment> horizonSplitLines = Horizon.split(intersector, intersectionPoint);
        
        // If line start is above horizon start, line should be visible and replace horizon line
        if (aboveHorizon) {
          newSplitLines[0].hidden = false;
          newSplitLines[1].hidden = true;
        } else { // If line start is below horizon start, line should be invisible.
          newSplitLines[0].hidden = true;
          newSplitLines[1].hidden = false;
        }
        continue;
      }
    }

    if (!intersected) 
    {
      // If line has no intersections, entire line should be visible or invisible. Determine which.
      // TODO: Messy
      bool aboveHorizon = false;
      for (LineSegment intersector in possibleIntersectors) {
        if (intersector.start.x == line.start.x) {
          aboveHorizon = line.start.y > intersector.start.y;
        } else if (intersector.start.x == line.end.x) {
          aboveHorizon = line.end.y > intersector.start.y;
        } else if (intersector.end.x == line.start.x) {
          aboveHorizon = line.start.y > intersector.end.y;
        } else if (intersector.end.x == line.end.x) {
          aboveHorizon = line.end.y > intersector.end.y;
        }
      }
      if (!aboveHorizon) {
        line.hidden = true;
      }
    }
  }
}

void drawLineSegments() {
  for (int i = 0; i < Lines.length; i++) {
    var material = new LineBasicMaterial(linewidth: 100.0, color: (i == 0 ? 0xff0000 : 0x0077dd));
    var geometry = new Geometry();
    bool done = false;
    int counter = 0;
    
    // TODO: Support for invisible lines at end of line group
    // TODO: Consider using LinePieces (GL_LINES) instead of default LineStrip (GL_LINE_STRIP) (might simplify line removal etc.)
    while (!done) {
      // Out at end of line group
      if (counter >= Lines[i].length)
        break;
      
      LineSegment line = Lines[i][counter];
      if (!hideTest) {
        geometry.vertices.add(new Vector3(line.start.x, line.start.y, 0.0));
        geometry.vertices.add(new Vector3(line.end.x, line.end.y, 0.0));
      } else {
        if (!line.hidden) {
          geometry.vertices.add(new Vector3(line.start.x, line.start.y, 0.0));
          geometry.vertices.add(new Vector3(line.end.x, line.end.y, 0.0));
        } else {
          var line = new Line(geometry, material);
          scene.add(line);
          geometry = new Geometry();
        } 
      }
      counter++;
    }

    var line = new Line(geometry, material);
    scene.add(line);
  }
}