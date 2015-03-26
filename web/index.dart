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

  renderer = new WebGLRenderer();
  renderer.setSize(window.innerWidth, window.innerHeight);

  container.append(renderer.domElement);
}

void render(double dt) {
  window.requestAnimationFrame(render);

  camera.lookAt(new Vector3(0.0, 0.0, 0.0));
  renderer.render(scene, camera);
}

// TODO: LineSegment?
class LineSegment {
  Vector2 start;
  Vector2 end;
  LineSegment(this.start, this.end);
  // Might as well use Vector3s to get depth, this is just easier to work with for now
  int depth;
  bool visible = true;
  
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

List<LineGroup> Lines = new List<LineGroup>();
LineGroup Horizon = new LineGroup();
void calculateLines() {
  // Start w/ two lines - set up manually
  LineGroup a = new LineGroup();
  a.add(new LineSegment(new Vector2(-2.0, 1.0), new Vector2(0.0, -1.0)));
  a.add(new LineSegment(new Vector2(0.0, -1.0), new Vector2(2.0, 1.0)));
  Lines.add(a);
  Horizon = a;
  
  LineGroup b = new LineGroup();
  b.add(new LineSegment(new Vector2(-2.0, -1.0), new Vector2(0.0, 1.0)));
  b.add(new LineSegment(new Vector2(0.0, 1.0), new Vector2(2.0, -1.0)));
  
  // Check for all intersection points.
  // On intersect, remove line and add two new lines with start/end at intersect position.
  // Of those two lines, second line will not be drawn.
  // Until another line segment in new line intersects, all will be marked as hidden.
  // On next intersection, split lines and hide first of the two new lines.
  
  // Manual intersection points - first line
  Vector2 intersection = new Vector2(-1.0, 0.0);
  // Split and replace
  List<LineSegment> split = a[0].split(intersection);
  a.removeAt(0);
  a.insert(0, split[0]);
  a.insert(1, split[1]);
  
  List<LineSegment> split2 = b[0].split(intersection);
  print('Split line ${b[0]} intersecting at ${intersection.toString()} into ${split2[0]} and ${split2[1]}');
  b.removeAt(0);
  b.insert(0, split2[0]);
  b.insert(1, split2[1]);
  
  // Hide second part of second line
  b[1].visible = false;
  print(b.toString());
  Lines.add(b);
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