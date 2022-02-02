import java.awt.Image;
import javax.swing.ImageIcon;
import java.awt.image.BufferedImage;
import java.awt.color.ColorSpace;
import java.util.Arrays;

void printArray(String s, float [] a){
  if (s!="") {print(s+": "); println();}
  for (int i=0; i<a.length; i++)
    print(Float.toString(a[i]) + "; "); 
  println();
}

void printMatrix(String s, float[][] a){
  if (s!="") {print(s+": "); println();}
  for (int i=0; i<a.length; i++)
    printArray("", a[i]); 
  println();
}

void draw_rot_line(float angle, float trans_x, float trans_y){
  float lnlen = 10;
  float wt = 2;
  draw_rot_line(angle, trans_x, trans_y, lnlen, wt);
}


void draw_rot_line(float angle, float trans_x, float trans_y, float line_len, float str_weight){
  pushMatrix();
  pushStyle();
  translate(trans_x, trans_y);
  stroke(165);
  circle(0,0,line_len*2);
  strokeWeight(str_weight);
  rotate(angle);
  line(0,0, line_len, 0);
  popStyle();
  popMatrix();
}

void draw_q_phase_line(float angle, int quant, float trans_x, float trans_y){
  float q_angle = 2*PI/(float)quant;
  float flr =  ceil(angle/q_angle); // use ceil to round negs towards zero
  float rotangle = q_angle * flr;
  // print(angle);
  // print("; ");
  // println(rotangle);
  draw_rot_line(rotangle, trans_x, trans_y);
}

void barchart_array(float[] data, String legend){
  float yscl = 47.8;
  float xscl = 134.0;
  
  barchart_array(
    data,
    0, 0,
    yscl, xscl,
    #A0EA9A,
    1,
    1.f,
    legend
  );
}

/**
  float yf1, 
  float xf1, 
  float yscale, 
  float xscale, 
  color clr, 
  int labelplacement,  0 above, 1 below
  float aymax,
  String legend,
  PFont h1,
  PFont l1

  Example:
  float yscl = 47.8;
  float xscl = 134.0;
  barchart_array(
    gateIntegrator.getOutput()[0],
    0, 0,
    yscl, xscl,
    #A0EA9A,
    1,
    1.f,
    "gate",
    font_8, font_8
  );
*/
void barchart_array(float[] data,
  float yf1, 
  float xf1, 
  float yscale, 
  float xscale, 
  color clr, 
  int labelplacement,
  float aymax,
  String legend)
  // PFont h1,
  // PFont l1) 
  {
    pushStyle();
  //Declare a float variabe for the max y axis value.
   float ymax=aymax;
   
   //Declare a float variable for the minimum y axis value.
   float ymin = 0;
   
   //Set the stroke color to a medium gray for the axis lines.
   stroke(175);
   
   //draw the axis lines.
   line(xf1-3,yf1+2,xf1+xscale,yf1+2);  
   line(xf1-3,yf1+2,xf1-3,yf1-yscale); 
     
   //turn off strokes for the bar charts 
   noStroke(); 
    
   //loop the chart drawing once.
   for (int c1 = 0; c1 < 1; c1++){  
   
     //Set the start x point value.
     float xfstart = xf1;  
     //Count the number of rows in the file.
     //for (int i = 0; i < lines.length; i++) {
       
       //For each line split values separated by columns into pieces.
       //String[] pieces = split(lines[i], ',');
       
       //Set the max Y axis value to be 10 greater than the max value in the pieces array.
       // ymax = 1.5* max(data);
       
       //Count the number of pieces in the array.
       float xcount = data.length;
       
       //Draw the minimum and maximum Y Axis labels. 
       // textFont(h1);
       fill (100);
       textAlign(RIGHT, CENTER);
       text(int(ymax), xf1-8, yf1-yscale);
       text(int(ymin), xf1-8, yf1);
       text(legend, xf1+87, yf1+18);
       
       //Draw each column in the data series.
       for (int i2 = 0; i2 < xcount; i2++) {
         
         //Get the column value and set it has the height.
         float yheight = data[i2];
         
         //Declare the variables to hold column height as scaled to the y axis.     
         float ypct;
         float ysclhght;
         
         //calculate the scale of given the height of the chart.
         ypct = yheight / ymax;
         
         //Calculate the scale height of the column given the height of the chart.
         ysclhght = yscale * ypct;
         
         //If the column height exceeds the chart height than truncate it to the max value possible.
         if(ysclhght > yscale){
           ysclhght = yscale;
         }
         
         //Determine the width of the column placeholders on the X axis.
         float xcolumns = xscale / xcount;
         
         //Set the width of the columns to 5 pixels less than the column placeholders.
         float xwidth = xcolumns - 5;
         
         //Set the fill color of the columns.
         fill (clr);
         
         //Draw the columns to scale.
         quad(xf1, yf1, xf1, yf1-ysclhght, xf1 + xwidth, yf1-ysclhght, xf1 + xwidth, yf1);
         
         //Draw the labels.
         // textFont(l1);
         textAlign(CENTER, CENTER);
         fill (100);
         
         //Decide where the labels will be placed.
         if (labelplacement < 1) {
           //Above the columns.
           text(nf(data[i2], 0, 2), xf1 + (xwidth / 2), yf1 - (ysclhght + 8));
         } else {
           //Below the columns.
           text(data[i2], xf1 + (xwidth / 2), yf1 + 8);
         }
         //increment the x point at which to draw a column.
         xf1 = xf1 + xcolumns;
       //}
    }
  }
  popStyle();
}

/**
*/
void drawGraph(float[][] units, float[][] adjmatrix){
  pushStyle();
  float inner = 10.9;
  float outer= 40.3;
  color incol = color(0,0,0,151);
  color outcol = color(222, 147);
  color txtcol = color(200);
  color excol = color(217,122,122,255);
  color inhcol= color(122,122,217,255);
  color linecol;
  for(int j=0; j<adjmatrix.length; j++){
    pushStyle();
    fill(outcol);
    circle(units[j][0], units[j][1], outer);
    fill(incol);
    circle(units[j][0], units[j][1], inner);
    popStyle();
    // text
    pushStyle();
    fill(txtcol);
    text("U" + (j+1), units[j][0], units[j][1] + outer+5);
    popStyle();
    for(int i=0; i<adjmatrix[0].length; i++){
        if(adjmatrix[j][i] != 0){
          float[] from = units[j];
          float[] to = units[i];
          pushStyle();
          strokeWeight(4);
          linecol = excol;
          if(adjmatrix[j][i] < 0)
            linecol = inhcol;
          stroke(linecol);
          arrow(from[0], from[1], to[0], to[1]);
          popStyle();
        }
    }
  }
  popStyle();
}

void arrow(float x1, float y1, float x2, float y2) {
  float pt = 7;
  line(x1, y1, x2, y2);
  pushMatrix();
  translate(x2, y2);
  float a = atan2(x1-x2, y2-y1);
  rotate(a);
  line(0, 0, -pt, -pt);
  line(0, 0, pt, -pt);
  popMatrix();
} 

void drawTopologyGrid(float x1, float y1, float dim, float[][] top){
  color exccol = color(217,122,122,255);
  color inhcol= color(122,122,217,255);
  
  float y=y1;
  float margin = 10;
  for(int j=0; j<top.length; j++){
    float x=x1;
    for(int i=0; i<top[0].length; i++){
      pushStyle();
      if(top[j][i] > 0) fill(exccol);
      else if(top[j][i] < 0) fill(inhcol);
      else fill(100);
      square(x, y, dim);
      popStyle();
      x+= dim+margin;
    }
    y+= dim+margin;
  }
}

void drawColGrid(float x1, float y1, float dim, float[][] top){
  /**
  x1 - topleft corner x
  y1 - topleft corner y
  dim - scale dim of individual square
  top - array of values: pos and neg values drawn differently
  */
  
  drawColGrid(x1, y1, dim, 5, "", top);
}

void drawColGrid(float x1, float y1, float dim, float margin, String title, float[][] top){
  /**
  x1 - topleft corner x
  y1 - topleft corner y
  dim - scale dim of individual square
  margin - between square margin
  top - array of values: pos and neg values drawn differently
  */
  color exccol = color(217,122,122,255);
  color inhcol= color(122,122,217,255);
  
  pushMatrix();
  translate(0, -10);
  text(title, 0, 0);
  popMatrix();
  
  pushStyle();
  colorMode(HSB);
  
  float y=y1;
  // float margin = 10;
  for(int j=0; j<top.length; j++){
    float x=x1;
    for(int i=0; i<top[0].length; i++){
      pushStyle();
      if(top[j][i] > 0) fill(hue(exccol), saturation(exccol), top[j][i]);
      else if(top[j][i] < 0) fill(hue(inhcol), saturation(inhcol), top[j][i]);
      else fill(0);
      square(x, y, dim);
      popStyle();
      x+= dim+margin;
    }
    y+= dim+margin;
  }
  popStyle();
}

/** Draw a time-series plot
*/
void drawTimeSeries(float[] series, float maxy, float x_margin, float thresh){
 float y_length=100;
 float x_length=100;
// float x_margin = 20;
 //float ptsz = 10;
 pushStyle();
 stroke(200);
 strokeWeight(2);
 //draw y
 line(0,0,0,2*y_length);
 line(0,y_length, x_length, y_length);
 pushStyle();
 stroke(200, 100, 0);
 float y_thr = y_length*(1 - thresh/maxy);
 line(0,  y_thr, x_length, y_thr); 
 popStyle();
 // draw data
 float x = x_margin;
 pushStyle();
 //fill(150);
 noFill();
 strokeWeight(1);
 beginShape();
 for(int i=0; i<series.length; i++){
   float y = y_length*(1 - series[i]/maxy);
   //circle(x, y,  ptsz);
   vertex(x, y);
   x+=x_margin;
 }
 endShape();
 popStyle();
 popStyle();
}

void drawTimeSeries(float[][] series, float miny, float maxy, float x_margin, float thresh, color[] palette){
 /**
   series: matrix of time series, cols are y values, 
   miny: min value on y axis, 
   maxy: max value on y axis
   x_margin: distance between points 
   thresh: y pos of a threshold line 
   palette: list of color values to use for each time series
   
   Example:
   drawTimeSeries(series, 0, 1, 0.1, 0.5, null) // use default colors
 */
 float y_length=100;
 float x_length=100;
 color[] default_cols = {#e76f51, #2a9d8f, #e9c46a, #f4a261, #2676a3};
 color[] colors = null;
 if(palette == null || palette.length == 0){
   colors = new color[series.length];
   for(int i = 0; i < colors.length; i++) colors[i] = default_cols[i%(default_cols.length)]; // change
 }
 else colors = palette;
 // float x_margin = 20;
 //float ptsz = 10;
 pushStyle();
 stroke(200);
 strokeWeight(2);
 //draw y
 line(0,0,0,(maxy-miny)*y_length);
 line(0,y_length, x_length, y_length);
 pushStyle();
 stroke(200, 100, 0);
 float y_thr = y_length*(1 - thresh/maxy);
 line(0,  y_thr, x_length, y_thr); 
 popStyle();
 // draw data
 
 for (int j = 0; j < series.length; ++j) {
    float x = x_margin;
    pushStyle();
    stroke(colors[j]);
    //fill(150);
    noFill();
    strokeWeight(1.5);
    beginShape();
    for(int i=0; i<series[j].length; i++){
      float y = y_length*(1 - series[j][i]/maxy);
      //circle(x, y,  ptsz);
      vertex(x, y);
      x+=x_margin;
    }
    endShape();
    popStyle();
  }
 popStyle();
}


class Buffer{
  FloatList data; 
  Buffer(int sz){
    data = new FloatList(sz);
    for(int i=0; i<sz; i++)
      data.append(0);
  }
  
  float[] array(){
    return data.array();
  }
  
  float head(){
    return data.get(0);
  }
  
  float get(int ix){
    return data.get(ix);
  }
  
  void append(float val){
    data.append(val);
    data.remove(0);
  }
}

void drawSpikeStrip(Buffer[] aspikes, float threshold){
  pushStyle();
  color ptcolor = color(228, 106, 218);
  float x=0; float y=0;
  float x_i =4; float y_i=10;  
  float margin = 1;
  fill(ptcolor);
  noStroke();  
  for(int j=0; j<aspikes.length; j++){
    x=0;
    text("U"+(j+1), x-25, y+5);
    for(int i=0; i<aspikes[0].array().length; i++){
      // draw the strip  
    if(aspikes[j].array()[i] > threshold){
      rect(x, y, x_i, y_i);}
    x+= x_i + margin;
    }
   y+= y_i;
  }
  popStyle();
}

int countSpikes(float[] data, float threshold){
  int retval = 0;
  for(int i=0; i< data.length; i++)
    if(data[i] >= threshold) retval++;
  return retval;
}

float[][] makeTopology(int dim, int type){
 float[][] retval = new float[dim*dim][dim*dim];
  // types
 // 1 nearest neighbor
 // 2 random
 /*
  [M, N] = size(T);       
  [X, Y] = meshgrid(max(1,m-5):min(M,m+5), max(1,n-5):min(N,n+5));
  I = sub2ind(size(T), X(:), Y(:));
 */  
 //switch (type){
   if (type==1){ // nearest neighbor   
     // make a source matrix filled with indeces and a border equal to 
     // kernel size
     int[][] kernel ={{-1,-1}, {-1, 0}, {-1, 1},  
                       {0,-1}, {0, 1},
                     {1,-1}, {1,0}, {1,1}};
     int border = 1; 
     int[][] ixm = makeIxMatrix(dim, dim, border);
     
     // every kernel movement adds a row to output topology
     int ctr = 0;
     for(int j=border; j<ixm.length-border; j++)
     {
       for(int i=border; i<ixm.length-border; i++)
       {
         for(int k=0; k<kernel.length; k++)
          {
            int ix = ixm[j+kernel[k][0]] [i+kernel[k][1]];
            // println("j= "+j+", i= " +i+ ", k= "+k+", ix= "+ix);
            if(ix>=0) retval[ctr][ix]=1; 
          }
          ctr++;
       }
     }
       
     
   }       
   else
   {// TODO implement random
   }
 
 return retval;   
}


int[][] makeIxMatrix(int x, int y, int border){
  int [][] retval = new int[y+2*border][x+2*border];
  int ctr=0;
  for (int[] row: retval)
    Arrays.fill(row, -1);
  //Arrays.fill(retval, -1);
  for(int j=border; j<retval.length-border; j++)
  {
    for(int i=border; i<retval[0].length-border; i++)
    {
      retval[j][i] = ctr;
      ctr++;
    }
  }
  return retval;
  
}

float[][] getColorGrid(PImage im, int col){
  /** Yield an array of r,g,b, or alpha values
  * im - image to process
  * col - 1=red, 2=green, 3=blue, 4=alpha
  */
  float [][] ret = new float[im.height][im.width];
  for(int j=0; j<ret.length; j++)
    for (int i=0; i<ret[0].length; i++){
    
      if (col ==1){
        ret[j][i] = red(im.get(i, j));
      } else if (col == 2){
        ret[j][i] = green(im.get(i, j));
      } else if (col == 3){
        ret[j][i] = blue(im.get(i, j));
      } else {
        ret[j][i] = alpha(im.get(i, j));
      }
    }
  return ret;
}

float[][] spikesToScalar(Buffer[] buffers, int rows, int cols){
  /*
  convert spikes from a population to scalars to be visualized
  */
  float maxspkval = 64;
  float [][] decod_act = new float[rows][cols];     
  for(int j=0; j<rows; j++)    
    for(int i=0; i<cols; i++){    
      float[] spk = buffers[i+rows*j].array();     
        
      decod_act[j][i] = 20*countSpikes(spk, maxspkval); 
      //println(decod_act[j][i]);      
    }  
  return decod_act;
}

float[] getCol(float[][] a, int col){
  float[] retval = new float[a.length];
  for(int j=0; j< a.length; j++)
    retval[j] = a[j][col];
  return retval;
}

float[] copyArray(float[] a){
  float[] retval = zeros(a.length);
  System.arraycopy(a, 0, retval, 0, a.length);
  return retval;
}

int[] copyArray(int[] a){
  int[] retval = new int[a.length];
  System.arraycopy(a, 0, retval, 0, a.length);
  return retval;
}

float[][] copyMatrix(float[][] dest, float[][] m){
    float[][] retval = dest;
    for (int j = 0; j < m.length; j++) {
        for (int i = 0; i < m[0].length; i++) {
            retval[j][i] = m[j][i];
        }
    }
    return retval;
}
/**
 * Return indeces based on a threshold value
 ' m: matrix to evaluate
 * threshold: threshold which must be equalled or exceeded to yield inclusion
*/
int[][] getThresholdedIndeces(float[][] m, float threshold){
  IntList rows = new IntList();
  IntList cols = new IntList();
  for (int j = 0; j < m.length; j++) {
    for (int i = 0; i < m[0].length; i++) {
      if (m[j][i] >= threshold){
        rows.push(j);
        cols.push(i);
      }
    }
  }
  int[][] retval = new int[rows.size()][2];
  for(int j=0; j<retval.length; j++){
    retval[j][0] = rows.get(j);
    retval[j][1] = cols.get(j);
  }
  
  return retval;
}

/**
m - 1d array 
*/
int[] getThresholdedIndeces(float[] m, float threshold){
  IntList rows = new IntList();
  // IntList cols = new IntList();
  for (int j = 0; j < m.length; j++) {
    //for (int i = 0; i < m[0].length; i++) {
      if (m[j] >= threshold){
        rows.push(j);
        
      }
    //}
  }
  /*
  int[][] retval = new int[rows.size()][2];
  for(int j=0; j<retval.length; j++){
    retval[j][0] = rows.get(j);
    retval[j][1] = cols.get(j);
  }
  */
  
  return rows.array();
}

/**
top - a topology
indeces - indeces to find neighbors to
*/
int[] getNeighborIndeces(float[][] top, int[] indeces){
  IntList retval = new IntList();
  for(int i: indeces){
    float[] col = getCol(top, i);
    int[] neighbors = getThresholdedIndeces(col, 1);
    retval.append(neighbors);
  }
  return retval.array();
}

float[] map_array(float[] a, float from1 , float to1, float from2, float to2){
  float[] retval = zeros(a.length);
  for(int i=0; i< a.length; i++){
    retval[i] = map(a[i], from1, to1, from2, to2);
  }
  return retval;
}

float[] copyByIx(float[] a, int[] ix){
  float[] ret = zeros(a.length);
  for(int i: ix){
    ret[i] = a[i];
  }
  return ret;
}



float[][] arrayToMatrix(float[] a, int r, int c){
  float[][] ret = zeros(r, c);
  
  for (int j=0, row=0, col=0; j<a.length && row<r; j++){
     ret[row][col] = a[j];
     if (++col >= c){ col=0; row++;}
  }
  return ret;
}

float[] mask_array(float[] a, int[] keep){
  float[] retval = zeros(a.length);
  for(int i : keep){
    retval[i] = a[i];
  }
  return retval;
}

float[] genMask(int size, int[] ixes){
  float[] retval = zeros(size);
  for (int i : ixes){
    retval[i] = 1.0;
  }
  return retval;
}

int[] genIndeces(int from, int to) {
  int length = to-from+1;
  int[] retval = new int[length];
  for (int i = 0; i < length; ++i) {
    retval[i] = from + i;
  }
  return retval;
}

FloatList arrayToList(float[] a){
  FloatList retval = new FloatList(a.length);

  for (int i = 0; i < a.length; ++i) {
    retval.append(a[i]);
  }
  return retval;
}

/**
*/
float[][] flipMatrixHor(float[][] m){
  float[][] ret = zeros(m.length, m[0].length);
  for (int j=0; j<ret.length; j++){
    for (int i=0; i<ret[0].length; i++){
      ret[j][i] = m[j][m[0].length-1-i];  
    }
  }

  return ret;
}

float[][] flipMatrixVer(float[][] m){
  float[][] ret = zeros(m.length, m[0].length);
  for (int j=0; j<ret.length; j++){
    for (int i=0; i<ret[0].length; i++){
      ret[j][i] = m[m.length-1-j][i];  
    }
  }

  return ret;
}

PImage pngBytesToImage(byte[] a){
 PImage ret = null;
 try {
        byte[] bytes = a;
        if (bytes == null) {
          return null;
        } else {
          //Image awtImage = Toolkit.getDefaultToolkit().createImage(bytes);
          Image awtImage = new ImageIcon(bytes).getImage();
 
          if (awtImage instanceof BufferedImage) {
            BufferedImage buffImage = (BufferedImage) awtImage;
            int space = buffImage.getColorModel().getColorSpace().getType();
            if (space == ColorSpace.TYPE_CMYK) {
              System.err.println("pngBytesToImage: bytes is a CMYK image, " +
                                 "only RGB images are supported.");
              return null;
              /*
              // wishful thinking, appears to not be supported
              // <a href="https://community.oracle.com/thread/1272045?start=0&tstart=0" target="_blank" rel="nofollow">https://community.oracle.com/thread/1272045?start=0&tstart=0</a>
              BufferedImage destImage =
                new BufferedImage(buffImage.getWidth(),
                                  buffImage.getHeight(),
                                  BufferedImage.TYPE_3BYTE_BGR);
              ColorConvertOp op = new ColorConvertOp(null);
              op.filter(buffImage, destImage);
              image = new PImage(destImage);
              */
            }
          }
 
          PImage image = new PImage(awtImage);
          if (image.width == -1) {
            System.err.println("pngBytesToImage: Bytes" +
                               " contains bad image data, or may not be an image.");
          }
 
          // if it's a .gif image, test to see if it has transparency
          //image.checkAlpha();
          
 
//          if (params != null) {
//            image.setParams(g, params);
//          }
          ret  = image;
        
      }
    } catch (Exception e) {
      // show error, but move on to the stuff below, see if it'll work
      e.printStackTrace();
    }
 
 return ret;
}

float[] blobToPoint(float[] a, float threshold){
  float[] retval = new float[a.length];
  int start=-1, stop=-1;
  for(int i=0; i<a.length; i++){
    if(a[i] > threshold){
      start = i;
      continue;
    }
  }
  for(int i=a.length-1; i>=0; i--){
    if(a[i] > threshold){
      stop = i;
      continue;
    }
  }
  if(start==stop && start >= 0 && stop >= 0) retval[start] = 1.0;
  else{
    int ix = (stop-start)/2 + start;
    if(ix >=0 && ix < retval.length) retval[ix] = 1.0;
  }
  return retval;
}

boolean isZero(float[] a, float tolerance){
  for(float i: a)
    if(i-tolerance > 0) return false;
  return true;
}

float hysteresis(float in, float prev, float lo_thr, float hi_thr){
  float r = -1.f;
  float hi = 1.f;
  float lo = 0.f;
  if(in  <= lo_thr) r = lo;
  else if(in >= hi_thr) r = hi;
  else r = prev;
  return r;
}

int len(float[] a){
  return a.length;
}

float[] generateRndOneHotVec(int size, int hots) {
  float[] retval = zeros(size);
  
  for (int i=0; i<hots; i++){
    int ix = 0;
    do {
      ix = (int)random(0, size);
    } while (retval[ix] == 1.f); // fixme: termination issue
    retval[ix] = 1.0;
  }
  
  return retval;
}

boolean equal(float[] a, float[] b){
  if (a.length != b.length) return false;
  
  for(int i=0; i<a.length; i++)
    if(a[i] != b[i])
      return false;
  return true;
}

float[][] generateUniquePatterns(int rows, int cols, int hots){
  float[][] retval = zeros(rows, cols);
  for(int j=0; j<rows; j++){
    float[] vec;
    do {
      vec = generateRndOneHotVec(cols, hots);
    } while (isInMatrix(vec, retval));
    retval[j] = vec;
  }
  
  return retval;
}

boolean isInMatrix(float[] vec, float[][] matrix){
  if(vec.length != matrix[0].length) return false;
  
  for(int i=0; i<matrix.length; i++)
    if(equal(vec, matrix[i])) return true;
  return false;
}

float[][] repeatRows(int rows, float[][] a){
  float[][] retval = zeros(a.length*rows, a[0].length);

  for (int j = 0; j < a.length; ++j) {
    for (int i = 0; i < rows; ++i) {
      retval[rows*j + i] = a[j];
    }
  }

  return retval;  
}

float[][] repeatCols(int cols, float[][] a){
  float[][] retval = zeros(a.length, a[0].length * cols);
  for (int j = 0; j < a.length; ++j) {
    int start = 0;
    for (int i = 0; i < a[0].length; ++i) {
      for (int c = 0; c < cols; ++c) {
        retval[j][start+c] = a[j][i];
      }
      start += cols;
    }
  }
  return retval;  
}

float[][] tileRows(int times, float[][] a){
  float[][] retval = zeros(a.length*times, a[0].length);
  for (int j = 0; j < times; ++j) {
    for (int i = 0; i < a.length; ++i) {
      System.arraycopy(a[i], 0, retval[j*a.length + i], 0, a[0].length);
    }
  }
  return retval;
}

float[][] tileCols(int times, float[][] a) {
  float[][] retval = zeros(a.length, a[0].length * times);
  for (int j = 0; j < a.length; ++j) {
    for (int i = 0; i < times; ++i) {
      System.arraycopy(a[j], 0, retval[j], i*a[0].length, a[0].length);
    }
  }
  return retval;
}

float[] strideTile(int times, int stride, float[] a) {
  float[] retval = zeros(a.length * times);
  int divs = a.length / stride;
  assert(divs != 0 && a.length % stride == 0) : 
    "a.length / stride = " + (a.length / stride) 
    + "a.length % stride = " + a.length % stride;
  int retstart = 0;
  for (int i = 0; i < divs; ++i) {
    for (int t = 0; t < times; ++t) {
      System.arraycopy(a, i * stride, retval, retstart, stride);
      retstart += stride;
    }
  }
  return retval;
}

float[] populationEncode(float val, int size, float min, float max, float sigma) {
    float[] retval = zeros(size);
    retval = gaussian1(size, (size-1)*(val-min)/(max-min), sigma);
    float n = norm1(retval);

    if(n != 0)
        multiply(1.0/n, retval);
    return retval;
}

float[] setSubArray(float[] source, float[] target, int start){
  // todo assert
  float[] retval = zeros(target.length);
  System.arraycopy(target, 0, retval, 0, target.length);
  System.arraycopy(source, 0, retval, start, source.length);
  return retval;
    
}


float[] getSubArray(float[] source, int start, int length){
  float[] retval = zeros(length);
  System.arraycopy(source, start, retval, 0, length);
  return retval;
}

float[][] mapFrom4d(float [][][][] source, 
      int sx, int sy, int kx, int ky) {
  float[][] retval = zeros(sx*sy, kx*ky);
  int k=0;
  for (int ssy = 0; ssy < sy; ++ssy)
  {
      for (int ssx = 0; ssx < sx; ++ssx)
      {
          int k_ix=0;
          for (int kky = 0; kky < ky; ++kky)
          {
              for (int kkx = 0; kkx < kx; ++kkx)
              {
                  retval[k][k_ix] = source[ssy][ssx][kky][kkx];
                  k_ix++;
              }
          }
          k++;
      }
  }
  return retval;
}

float[][][][] mapTo4d(float[][] source,
        int sx, int sy, int kx, int ky) {
  float[][][][] retval = new float[sy][sx][ky][kx];
  int k=0;
  for (int ssy = 0; ssy < sy; ++ssy)
  {
      for (int ssx = 0; ssx < sx; ++ssx)
      {
          int k_ix=0;
          for (int kky = 0; kky < ky; ++kky)
          {
              for (int kkx = 0; kkx < kx; ++kkx)
              {
                  retval[ssy][ssx][kky][kkx] = source [k][k_ix];
                  k_ix++;
              }
          }
          k++;
      }
  }
  return retval;    
}

// create 
float[][] spanned_im2row(
        
        float[][] in, 
        // int out_r, int out_c,
        int map_size_x, 
        int map_size_y, 
        int kernel_size_x,
        int kernel_size_y, 
        int stride_x, 
        int stride_y,
        int block_x,
        int block_y,
        int span_x,
        int span_y)  // mode = 'sliding'
    {
        int out_c = kernel_size_x*kernel_size_y;
        int out_r = map_size_x*map_size_y;
        int source_size_y = in.length; 
        int source_size_x = in[0].length;
        float[] r = zeros(out_c*out_r);
        
        float[] source = ravel(in);
        int r_ix = 0;
        for(int j=0; j<map_size_y; j++)
            for(int i=0; i<map_size_x; i++)
            {
                int[] s = new int[kernel_size_y];
                // for rows
                for(int k=0; k<kernel_size_y; k++){
                    int dv = k/block_y;
                    int offset = dv*span_y;
                    s[k] = (j*stride_y+k+offset)*source_size_x + i*stride_x;
                }
                for(int k=0; k<kernel_size_y; k++)
                    for(int v=0; v<kernel_size_x; v++){
                        int dv = v/block_x;
                        int offset = dv*span_x;
                        int s_ix = offset + s[k]++;
                        r[r_ix++] = source[s_ix];
                    }
            }
        return arrayToMatrix(r, out_r, out_c);
    }

float [][] spanned_row2im( 
        float[][] ain, 
        int out_x, int out_y,
        int map_x, int map_y,
        int rf_x, int rf_y,
        int inc_x, int inc_y,
        int blk_x, int blk_y,
        int spn_x, int spn_y)
{
    int []s = new int[rf_y];
    float[] in = ravel(ain);
    float[] o = zeros(out_y*out_x);

    int r_ix = 0;
    for (int j = 0; j < map_y; ++j)
        for (int i = 0; i < map_x; ++i)
        {
            //resetArray(s);
            Arrays.fill(s, 0);
            for (int k = 0; k < rf_y; ++k)
            {
                int dv = k / blk_y;
                int offset = dv * spn_y;
                s[k] = (j*inc_y + k + offset) * out_x + 
                    i * inc_x;
            }
            for (int k = 0; k < rf_y; ++k)
                for (int v = 0; v < rf_x; ++v)
                {
                    int dv = v / blk_x;
                    int offset = dv * spn_x;
                    int s_ix = offset + s[k];
                    o[s_ix] += in[r_ix];
                    r_ix += 1;
                    s[k] += 1;
                }
        }
    // free (s);
    return arrayToMatrix(o, out_y, out_x);
}

void drawMatrix4(float my, float mx, float[][][][] m){
  pushMatrix();
    for(int r = 0; r < 3; r++){
      
      translate(my, 0);
      pushMatrix();
      for(int c = 0; c < 3; c++){
        translate(0, mx);
        drawColGrid(0,0, 5, m[r][c]);
      }
      popMatrix();
    }
  popMatrix();
}

float hammingDistanceZero(float[] a, float[] b) {
  // counts the number of ixes that are unequal in being zero
  float retval = 0;
  assert(a.length == b.length) : a.length + " := " + b.length;
  for (int i = 0; i < a.length; ++i) {
    if(a[i] == 0. && b[i] != 0 || a[i] > 0 && b[i]==0) retval += 1.0;
  }
  return retval;
}

float[] set_one(float[] a, int ix) {
  a[ix] = 1.0;
  return a;
}

void drawStrip(float[] data, String legend){
    float[][] viz = {data};
    
    translate(0, 20);
    pushMatrix();
    text(legend, 0,0);
    pushMatrix();
    translate(100, -10);
    drawColGrid(0,0, 10, multiply(200, viz));
    popMatrix();
    popMatrix();
        
}

void drawBarChart(float[] data, String legend){
    translate(0, 100);
    pushMatrix();
    text(legend, 0,0);
    pushMatrix();
    translate(100, -10);
    barchart_array(data, "");
    popMatrix();
    popMatrix();
}

void drawTimeSeriesPlot(float[][] data, String legend){
        translate(0, 100);
        pushMatrix();
        text(legend, 0,0);
        pushMatrix();
        translate(100, -10);
        drawTimeSeries(data, 0., 1., 1., 0., null);
        popMatrix();
        popMatrix();
    }

class ArrayListExt<T> extends ArrayList {
  ArrayListExt() {}
  
  ArrayListExt(T[] a) {
    super();
    for(T o: a) this.add(o);
  }
  
  void add(T[] a) {
    for(T o: a) this.add(o);
  }
}