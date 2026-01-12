stdintens=1000;
classifierPath = "/Users/yklab/Desktop/SL/Npm1.model"; //Modify to fit the classifier path
run("Duplicate...", "title=RawImage duplicate");
//assign G,R,Y channels according to the imaging settings (Y for lysosome mask channel)
run("Duplicate...", "title=G duplicate channels=4");
selectImage("RawImage");
run("Duplicate...", "title=oriR duplicate channels=2");
selectImage("RawImage");
run("Duplicate...", "title=Y duplicate channels=1");

//**Background subtraction**

function getRectangleMean(x, y, width, height) {
    sum = 0;
    for (i = x; i < x + width; i++) {
        for (j = y; j < y + height; j++) {
            sum += getPixel(i, j);
        }
    }
    return sum / (width * height);
}
//subtraction of fluorescence leak from lysosome mask to R channel
selectImage("Y");
run("Duplicate...", "title=Yleak duplicate");
selectImage("Yleak");
run("Multiply...", "value=0.1 stack");
imageCalculator("Subtract create 32-bit stack", "oriR","Yleak");
selectImage("Result of oriR");
run("Duplicate...", "title=R duplicate");

selectImage("R");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_R");
regionSize = 30
// Get the width and height of the current image
width = getWidth();
height = getHeight();

// Initialize variables to store the minimum mean value and its coordinates
minMean1 = 65500; // Set to maximum possible value
minMean2 = 65500; // Set to maximum possible value
minMean3 = 65500; // Set to maximum possible value
minX1 = 0;
minY1 = 0;
minX2 = 0;
minY2 = 0;
minX3 = 0;
minY3 = 0;

// Loop through the image to find the minimum mean value
for (x = 0; x <= getWidth() - regionSize; x += regionSize) {
    for (y = 0; y <= getHeight() - regionSize; y += regionSize) {
        // Calculate the mean of the pixel region
        mean = getRectangleMean(x, y, regionSize, regionSize);
        
        // Update the minimum means and positions if a new minimum is found
        if (mean < minMean1) {
            minMean3 = minMean2;
            minY3 = minY2;
            minX3 = minX2;
            
            minMean2 = minMean1;
            minY2 = minY1;
            minX2 = minX1;
            
            minMean1 = mean;
            minY1 = y;
            minX1 = x;
        } else if (mean < minMean2) {
            minMean3 = minMean2;
            minY3 = minY2;
            minX3 = minX2;
            
            minMean2 = mean;
            minY2 = y;
            minX2 = x;
            minMean3 = mean;
            minY3 = y;
            minX3 = x;
        }
    }
}
makeRectangle(minX1, minY1, regionSize, regionSize);
roiManager("Add");
makeRectangle(minX2, minY2, regionSize, regionSize);
roiManager("Add");
makeRectangle(minX3, minY3, regionSize, regionSize);
roiManager("Add");
 n = roiManager("count");
 
selectImage("R");
        for (i = 1; i <= nSlices; i++) {
    setSlice(i);
     sum = 0;
      for (j=0; j<n; j++) {
          roiManager("select", j);
          getStatistics(area, mean);
          sum += mean;
      }
      average = sum/n;
      run("Select None");
      run("Subtract...", "stack value="+average);
}

roiManager("Deselect");
roiManager("Delete");



selectImage("G");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_G");
regionSize = 30
width = getWidth();
height = getHeight();

// Initialize variables to store the minimum mean value and its coordinates
minMean1 = 65500; // Set to maximum possible value
minMean2 = 65500; // Set to maximum possible value
minMean3 = 65500; // Set to maximum possible value
minX1 = 0;
minY1 = 0;
minX2 = 0;
minY2 = 0;
minX3 = 0;
minY3 = 0;

// Loop through the image to find the minimum mean value
for (x = 0; x <= getWidth() - regionSize; x += regionSize) {
    for (y = 0; y <= getHeight() - regionSize; y += regionSize) {
        // Calculate the mean of the pixel region
        mean = getRectangleMean(x, y, regionSize, regionSize);
        
        // Update the minimum means and positions if a new minimum is found
        if (mean < minMean1) {
            minMean3 = minMean2;
            minY3 = minY2;
            minX3 = minX2;
            
            minMean2 = minMean1;
            minY2 = minY1;
            minX2 = minX1;
            
            minMean1 = mean;
            minY1 = y;
            minX1 = x;
        } else if (mean < minMean2) {
            minMean3 = minMean2;
            minY3 = minY2;
            minX3 = minX2;
            
            minMean2 = mean;
            minY2 = y;
            minX2 = x;
            minMean3 = mean;
            minY3 = y;
            minX3 = x;
        }
    }
}
makeRectangle(minX1, minY1, regionSize, regionSize);
roiManager("Add");
makeRectangle(minX2, minY2, regionSize, regionSize);
roiManager("Add");
makeRectangle(minX3, minY3, regionSize, regionSize);
roiManager("Add");
 n = roiManager("count");

selectImage("G");
            for (i = 1; i <= nSlices; i++) {
    setSlice(i);
     sum = 0;
      for (j=0; j<n; j++) {
          roiManager("select", j);
          getStatistics(area, mean);
          sum += mean;
      }
      average = sum/n;
      run("Select None");
      run("Subtract...", "stack value="+average);
}

//**Lysosome masking**
	setRadius = 2;
	setRepeatTimes = 5;
	
selectImage("Y");
run("Duplicate...", "duplicate");
selectImage("Y-1");
setMinAndMax(0,1);
for (i = 1; i <= nSlices; i++) {
    setSlice(i);
    getDimensions(width, height, channels, slices, frames);
    
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            value = getPixel(x, y);
            if (value >= 200) {
                setPixel(x, y, 0); 
            }
            else{
            	setPixel(x, y, 1);
            }
        }
    }
for (j = 0; j < setRepeatTimes; j++){
	    run("Remove Outliers...", "radius=setRadius threshold=0.5 which=Bright");
		}
		run("Remove Outliers...", "radius=setRadius threshold=0.5 which=Dark");
		
    updateDisplay();
     for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            value = getPixel(x, y);
            if (value == 0) {
                setPixel(x, y, NaN); 
            }
        }
    }
}

selectImage("Y-1");
	
	
imageCalculator("Multiply create 32-bit stack", "G","Y-1");
imageCalculator("Multiply create 32-bit stack", "R","Y-1");

//**Normalization for segmentation**

selectImage("Result of G");
run("Duplicate...", "title=GG duplicate");
selectImage("GG");
run("Z Project...","projection=[Max Intensity]");
selectImage("MAX_GG");
run("Duplicate...", "title=ImageforMaskG duplicate");
selectImage("Result of R");
run("Duplicate...", "title=RR duplicate");
selectImage("RR");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_RR");
run("Duplicate...", "title=ImageforMaskR duplicate");
roiManager("Deselect");
roiManager("Delete");
selectImage("ImageforMaskR");
waitForUser("Draw ROI and hit OK");

run("Create Mask");
selectImage("Mask");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit stack", "ImageforMaskR","Mask");
roiManager("Deselect");
roiManager("Delete");
selectImage("Result of ImageforMaskR");

waitForUser("Draw ROI and hit OK");

sum = 0;
      for (j=0; j<n; j++) {
          roiManager("select", j);
          getStatistics(area, mean);
          sum += mean;
      }
      specintensR = sum/n;
      print(specintensR);
      run("Select None");
normvalR=stdintens/specintensR;
print(normvalR);
selectImage("Result of ImageforMaskR");
run("Multiply...", "value=normvalR");

selectImage("ImageforMaskG");
imageCalculator("Multiply create 32-bit stack", "ImageforMaskG","Mask");
selectImage("Result of ImageforMaskG");
sum = 0;
      for (j=0; j<n; j++) {
          roiManager("select", j);
          getStatistics(area, mean);
          sum += mean;
      }
      specintensG = sum/n;
      print(specintensG);
      run("Select None");
normvalG=stdintens/specintensG;
print(normvalG);
selectImage("Result of ImageforMaskG");
run("Multiply...", "value=normvalG");

//**Segmentation using Weka**

selectImage("Result of ImageforMaskR");
run("Advanced Weka Segmentation");
//Modify the WeKa Segmentation version below if needed
while (!isOpen("Trainable Weka Segmentation v4.0.0")) {
    wait(200);
}
selectWindow("Trainable Weka Segmentation v4.0.0");
call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifierPath);
wait(3000);
call("trainableSegmentation.Weka_Segmentation.getResult");
//Press 'get results' in the Weka window if it does not start automatically
while (!isOpen("Classified image")) {
    wait(100);
}
selectWindow("Trainable Weka Segmentation v4.0.0");
close();

selectImage("Classified image");
run("Duplicate...", "title=ClassifiedR duplicate");
selectImage("Classified image");
close();
selectImage("ClassifiedR");
run("Remove Outliers...", "radius=5 threshold=0.5 which=Bright stack");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Dark stack");
run("32-bit");


selectImage("Result of ImageforMaskG");
run("Advanced Weka Segmentation");
while (!isOpen("Trainable Weka Segmentation v4.0.0")) {
    wait(200);
}
selectWindow("Trainable Weka Segmentation v4.0.0");
call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifierPath);
wait(3000);
call("trainableSegmentation.Weka_Segmentation.getResult");
while (!isOpen("Classified image")) {
    wait(100);
}
selectWindow("Trainable Weka Segmentation v4.0.0");
close();

selectImage("Classified image");
run("Duplicate...", "title=ClassifiedG duplicate");
selectImage("Classified image");
close();
selectImage("ClassifiedG");
run("Remove Outliers...", "radius=5 threshold=0.5 which=Bright stack");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Dark stack");
run("32-bit");

imageCalculator("Multiply create 32-bit stack", "ClassifiedG","ClassifiedR");
selectImage("Result of ClassifiedG");
run("Remove Outliers...", "radius=5 threshold=0.5 which=Bright stack");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Dark stack");

function ConvertZeroToNaN(ImageNaNBkg){
 
selectImage(ImageNaNBkg);
    getDimensions(width, height, channels, slices, frames);
   
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            value = getPixel(x, y);
            if (value == 0) {
                setPixel(x, y, NaN); 
            }
        }
    }
 
    updateDisplay();
}
ConvertZeroToNaN("Result of ClassifiedG");


imageCalculator("Multiply create 32-bit stack", "MAX_RR","Result of ClassifiedG");
imageCalculator("Multiply create 32-bit stack", "MAX_GG","Result of ClassifiedG");

selectImage("Result of MAX_GG");
roiManager("Measure");
selectImage("Result of MAX_RR");
roiManager("Measure");

selectWindow("Results");

waitForUser("Get Results, then hit OK to clear");
for (x = 0; x <= 25; x++) { 
          selectImage(nImages); 
          close(); 
      } 
roiManager("Deselect");
roiManager("Delete");


