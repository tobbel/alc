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
  
  drawTriangles();
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