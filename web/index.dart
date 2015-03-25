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
}

class LineGroup {
  List<LineSegment> Line = new List<LineSegment>();
  void add(LineSegment line) => Line.add(line);
  num get length => Line.length;
  LineSegment operator [](int index) => Line[index];
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
  Lines.add(b);
}

void drawLineSegments() {
  for (int i = 0; i < Lines.length; i++) {
    var material = new LineBasicMaterial(linewidth: 100.0, color: 0x0077dd);
    var geometry = new Geometry();
    for (int j = 0; j < Lines[i].length; j++) {
      LineSegment line = Lines[i][j];
      // TODO: Negate y here?
      geometry.vertices.add(new Vector3(line.start.x, line.start.y, 0.0));
      geometry.vertices.add(new Vector3(line.end.x, line.end.y, 0.0));
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