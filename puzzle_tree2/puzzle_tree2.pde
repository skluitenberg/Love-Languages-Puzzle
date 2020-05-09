import gab.opencv.*;
import processing.video.*;
import java.awt.*;

Capture video;
OpenCV opencv;

int Y_AXIS = 1;
int X_AXIS = 2;
color b1, b2, c1, c2;

// List of my Face objects (persistent)
ArrayList<Face> faceList;

// List of detected faces (every frame)
Rectangle[] faces;

// Number of faces detected over all time. Used to set IDs.
int faceCount = 0;

// Scaling down the video
int scl = 2;

ArrayList<Branch> branches = new ArrayList<Branch>(); 


int totalBranches = 1;
int layerCounter = 0;


void setup() {
  size (640, 480);  //size of sketch
  c1 = color(113, 202, 200);
  c2 = color(244, 121, 98);
  
  color c = lerpColor(c1, c2, .33);
  background(c);  
  
  video = new Capture(this, width/scl, height/scl);
  opencv = new OpenCV(this, width/scl, height/scl);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
  
  faceList = new ArrayList<Face>();
  
  video.start();
  smooth();
  
  branches.add(new Branch(width/2, height, int( width/2 + random(-10, 10) ), int( height-175 + random(-5,5)), 1, layerCounter ));//trunk branch
  grow(100, 3);
  //grow(75, 8);
  //grow(50, 10);
}

void draw () {
  
  //setGradient(0, 0, width, height, c1, c2, Y_AXIS);

  for (int i = 0; i < branches.size();  i++ ) {
    Branch part = branches.get(i);
    part.growbranch();
  }
  
  scale(scl);
  opencv.loadImage(video);
  image(video, 0, 0, 10, 10 );

  
  detectFaces();
  
  addbranches();
  die();
}

//void setGradient(int x, int y, float w, float h, color c1, color c2, int axis ) {

//  if (axis == Y_AXIS) {  // Top to bottom gradient
//    for (int i = y; i <= y+h; i++) {
//      float inter = map(i, y, y+h, 0, 1);
//      color c = lerpColor(c1, c2, inter);
//      stroke(c);
//      line(x, i, x+w, i);
//    }
//  }
//}

void grow (int r, int numb ) {
  
  float [] arcs = new float[numb];

  for (int j = 0; j < branches.size(); j++ ) {
    PVector originPoint = new PVector(int(branches.get(j).end.x), int(branches.get(j).end.y));
    Branch currentbranch = branches.get(j);
    if (currentbranch.returnlayer() == layerCounter) {
      for (int i = 0; i < arcs.length; i++){
        arcs[i] = random( (i * ( (.75*TWO_PI/numb))) + (QUARTER_PI + HALF_PI), ((i + 1) * ((.75*TWO_PI) /numb)) + (QUARTER_PI + HALF_PI)) ;
        PVector endPoint = getPoint(originPoint.x, originPoint.y, r, arcs[i]);
        branches.add(new Branch(int(originPoint.x), int(originPoint.y), int(endPoint.x), int(endPoint.y), 1, layerCounter + 1 ) );
      }
    }
  }
  
  
  layerCounter++;
  int k = 10 - layerCounter;
  if (k < 0) {
    k = 0;
  }
  
  if (layerCounter < 10){
    strokeWeight(k);
  }

  if (layerCounter >= 1 && layerCounter < 10) {
    stroke(244, 121, 98, 30);
  } else if (layerCounter > 10 && layerCounter < 25) {
    stroke(104, 47, 121, 75);
  } else if (layerCounter > 25){
    stroke(36, 120, 190, 5);
  }
  println(layerCounter);
}


PVector getPoint( float h, float k, int r, float a){
  PVector newPoint = new PVector(h + r*cos(a), k + r*sin(a)); 
  return newPoint; 
}

void detectFaces() {
  
  // Faces detected in this frame
  faces = opencv.detect();
  
  // Check if the detected faces already exist are new or some has disappeared. 
  
  // SCENARIO 1 
  // faceList is empty
  if (faceList.isEmpty()) {
    // Just make a Face object for every face Rectangle
    for (int i = 0; i < faces.length; i++) {
      println("+++ New face detected with ID: " + faceCount);
      faceList.add(new Face(faceCount, faces[i].x,faces[i].y,faces[i].width,faces[i].height));
      faceCount++;
    }
  
  // SCENARIO 2 
  // We have fewer Face objects than face Rectangles found from OPENCV
  } else if (faceList.size() <= faces.length) {
    boolean[] used = new boolean[faces.length];
    // Match existing Face objects with a Rectangle
    for (Face f : faceList) {
       // Find faces[index] that is closest to face f
       // set used[index] to true so that it can't be used twice
       float record = 50000;
       int index = -1;
       for (int i = 0; i < faces.length; i++) {
         float d = dist(faces[i].x,faces[i].y,f.r.x,f.r.y);
         if (d < record && !used[i]) {
           record = d;
           index = i;
         } 
       }
       // Update Face object location
       used[index] = true;
       f.update(faces[index]);
    }
    // Add any unused faces
    for (int i = 0; i < faces.length; i++) {
      if (!used[i]) {
        println("+++ New face detected with ID: " + faceCount);
        faceList.add(new Face(faceCount, faces[i].x,faces[i].y,faces[i].width,faces[i].height));
        faceCount++;
      }
    }
  
  // SCENARIO 3 
  // We have more Face objects than face Rectangles found
  } else {
    // All Face objects start out as available
    for (Face f : faceList) {
      f.available = true;
    } 
    // Match Rectangle with a Face object
    for (int i = 0; i < faces.length; i++) {
      // Find face object closest to faces[i] Rectangle
      // set available to false
       float record = 50000;
       int index = -1;
       for (int j = 0; j < faceList.size(); j++) {
         Face f = faceList.get(j);
         float d = dist(faces[i].x,faces[i].y,f.r.x,f.r.y);
         if (d < record && f.available) {
           record = d;
           index = j;
         } 
       }
       // Update Face object location
       Face f = faceList.get(index);
       f.available = false;
       f.update(faces[i]);
    } 
    // Start to kill any left over Face objects
    for (Face f : faceList) {
      if (f.available) {
        f.countDown();
        if (f.dead()) {
          f.delete = true;
        } 
      }
    }
  }
  
  // Delete any that should be deleted
  for (int i = faceList.size()-1; i >= 0; i--) {
    Face f = faceList.get(i);
    if (f.delete) {
      faceList.remove(i);
    } 
  }
}

void captureEvent(Capture c) {
  c.read();
}

void addbranches() {
  if (faceCount > 0) {
    //stroke(104, 47, 121, 50);
    grow(int(random(10, 15)), int(random(1, 3)));
    //noStroke();
    //fill(200);
    //rect(10, 10, 10, 10);
  }
}

void die() {
  if (faceCount < 0) {
    branches.remove(int(layerCounter - 1));
  }
  //println(layerCounter);
}