class Branch {
  int b; //branch point
  ArrayList<PVector> vpoints = new ArrayList<PVector>();
  
  int m; //y axis
  float t = 10; //x axis
  float g = random(-10, 10); //random variable for y axis
  
  PVector begin, end;
  int layer;

  
  Branch(int x1, int y1, int x2, int y2, int s, int l){
    begin = new PVector (x1, y1);
    end = new PVector( x2, y2 );
    layer = l;
    
   
     m = int(dist(x1, y1, x2, y2))/s;
           
    vpoints.add( begin ); //adding beginning PVector 
    for (int v = 1; v < s; v++) {
      vpoints.add(new PVector( random(int(vpoints.get(0).x-t)), int(vpoints.get(0).x+t), int(vpoints.get(0).y-m )) ); //adding PVector
 
    }
    vpoints.add( end ); // adding ending PVector
    
  
  
  }
  
  
  void growbranch(){
                        
    for (int i = 0; i <  ( vpoints.size() - 1 ); i ++){
      line(vpoints.get(i).x, vpoints.get(i).y, vpoints.get(i+1).x, vpoints.get(i+1).y);    //branches
      
    } 
  }
  
  PVector endPoint() {
    return end;
  }
  
  int returnlayer(){
    return layer;
  }
   
}