import 'dart:html';
import 'package:three/three.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:math' as Math;

Element container;

PerspectiveCamera camera;
Scene scene;
WebGLRenderer renderer;

Mesh mesh;

void main() {
  init();
  render(0.0);
}

void init() {
  container = new DivElement();
  document.body.append(container);
  
  scene = new Scene();
  camera = new PerspectiveCamera(70.0, window.innerWidth / window.innerHeight);
  camera.position.z = 15.0;
  
  scene.add(camera);
  
  calculateLines();
  drawLineSegments();
  //drawTriangles();
  //drawLines();
  
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
  bool visible = true;
  bool intersects = false;
  
  // Assumes point is on line
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
      out += line.toString() + " (" + (line.visible ? "visible" : "not visible") + ")";
    }
    return out;
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
  const int lineCount = 10;
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
  for (LineSegment line in b.Line) {
    List<LineSegment> possibleIntersectors = getPossibleIntersectorsWithHorizon(line);
    for (LineSegment intersector in possibleIntersectors) {
      Vector2 intersectionPoint = intersects(line, intersector);
      if (intersectionPoint != null) {
        intersectionPoints.add(intersectionPoint);
      }
    }
  }
  
  // Iteration first try
//  for (LineGroup lineGroup in Lines) {
//    // TODO: Iterable?
//    // TODO: We don't need to check against all other lines, only horizon.
//    for (LineSegment line in lineGroup.Line) {
//      // Get all other lines which start before and end after this one
//      List<LineSegment> possibleIntersectors = getPossibleIntersectors(line, Lines.indexOf(lineGroup));
//      print('Number of possibles: ' + possibleIntersectors.length.toString());
//      for (LineSegment intersector in possibleIntersectors) {
//        Vector2 intersectionPoint = intersects(line, intersector);
//        if (intersectionPoint != null) {
//          intersectionPoints.add(intersectionPoint);
//        }
//      }
//    }
//    
//  }
  
  // TODO: Iteration
//  Vector2 intersectionPoint = intersects(a[0], b[0]);
//  if (intersectionPoint != null)
//  {
//    // Split and replace
//    List<LineSegment> split = a[0].split(intersectionPoint);
//    a.removeAt(0);
//    a.insert(0, split[0]);
//    a.insert(1, split[1]);
//    
//    split = b[0].split(intersectionPoint);
//    b.removeAt(0);
//    b.insert(0, split[0]);
//    b.insert(1, split[1]);
//    
//    // Hide second part of second line
//    b[1].visible = false;
//    print(b.toString());
//  }
//  
//  intersectionPoint = intersects(a[2], b[2]);
//  if (intersectionPoint != null) {
//    var split = a[2].split(intersectionPoint);
//    a.removeAt(2);
//    a.insert(2, split[0]);
//    a.insert(3, split[1]);
//    
//    split = b[2].split(intersectionPoint);
//    b.removeAt(2);
//    b.insert(2, split[0]);
//    b.insert(3, split[1]);
//    b[2].visible = false;
//  }
}

void drawLineSegments() {
  for (int i = 0; i < Lines.length; i++) {
    var material = new LineBasicMaterial(linewidth: 100.0, color: (i == 0 ? 0x0077dd : 0xff0000));
    var geometry = new Geometry();
    bool done = false;
    int counter = 0;
    
    // TODO: Support for invisible lines at end of line group
    while (!done) {
      // Out at end of line group
      if (counter >= Lines[i].length)
        break;
      
      LineSegment line = Lines[i][counter];
      if (line.visible) {
        geometry.vertices.add(new Vector3(line.start.x, line.start.y, 0.0));
        geometry.vertices.add(new Vector3(line.end.x, line.end.y, 0.0));
      } else {
        var line = new Line(geometry, material);
        scene.add(line);
        geometry = new Geometry();
      }
      counter++;
    }

    var line = new Line(geometry, material);
    scene.add(line);
  }
}

void drawTriangles() {

  // Triangle test
  var geometry = new Geometry();
  
  int numIterations = 8;
  double xModifier = 20.0 / numIterations;
  Math.Random rand = new Math.Random();
  geometry.vertices.add(new Vector3(-10.0, -2.0, 1.0));
  for (int i = 0; i < numIterations + 1; i++) {
    // start at -10, go to 10
    // 0 to 20
    double x = -10.0 + i * xModifier;
    double y = Math.sin(i.toDouble());
    y = rand.nextDouble() * 2.0;
    double z = 1.0;
    geometry.vertices.add(new Vector3(x, y, z));
  }
  
  for (int i = 0; i < numIterations; i+= 2) {
    geometry.faces.add(new Face4(i, i + 1, i + 2, 0));
    print("added face " + i.toString() + ", " + (i + 1).toString() + ", " + (i + 2).toString());
  }
  
//  geometry.vertices.add(new Vector3(1.0, 0.0, 0.0));
//  geometry.vertices.add(new Vector3(1.0, 1.0, 0.0));
//  geometry.vertices.add(new Vector3(0.0, 0.0, 0.0));
//  geometry.faces.add(new Face3(0, 1, 2));
  
  var material = new MeshLambertMaterial(color: 0xcc0000);
  
  mesh = new Mesh(geometry, material);
  scene.add(mesh);
}

void drawLines() {
  var material = new LineBasicMaterial(linewidth: 100.0, color: 0x0077dd);
  var geometry = new Geometry();
  int numIterations = 100;
  double xModifier = 20.0 / numIterations;
  Math.Random rand = new Math.Random();
  for (int i = 0; i < numIterations; i++) {
    // start at -10, go to 10
    // 0 to 20
    double x = -10.0 + i * xModifier;
    double y = Math.sin(i.toDouble());
    y = rand.nextDouble() * 2.0;
    double z = 1.0;
    geometry.vertices.add(new Vector3(x, y, z));
  }

  var line = new Line(geometry, material);
  scene.add(line);
  
  geometry = new Geometry();
  for (int i = 0; i < numIterations; i++) {
    // start at -10, go to 10
    // 0 to 20
    double x = -10.0 + i * xModifier;
    double y = Math.sin(i.toDouble());
    y = 0.75 + rand.nextDouble() * 2.0;
    double z = 0.0;
    geometry.vertices.add(new Vector3(x, y, z));
  }
  
  line = new Line(geometry, material);
  scene.add(line);
}