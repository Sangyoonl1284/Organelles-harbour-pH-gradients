stdIntens = 6000;
classifierPath = "/Users/yklab/Desktop/SL/PM.model"; //Modify to fit the classifier path
run("Duplicate...", "title=RawImage duplicate");
//assign G and R channels according to the imaging settings
run("Duplicate...", "title=G duplicate channels=1");
selectImage("RawImage");
run("Duplicate...", "title=R duplicate channels=2");

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
	
selectImage("G");
regionSize = 30; // Define the region size for background
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

// Loop through the image to find the minimum mean value of a box
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
        } else if (mean < minMean3) {
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

//**Normalization for PM segmentation**

selectImage("G");
run("Duplicate...", "title=ImageforMask duplicate");
selectImage("ImageforMask");
waitForUser("Draw an ROI to include only PM signal with representative brightness, then hit OK");

run("Create Mask");
selectImage("Mask");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit stack", "R","Mask");
selectImage("Result of R");
run("Duplicate...", "duplicate");
selectImage("Result of R-1");
run("Threshold...");
setAutoThreshold("Otsu dark no-reset");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit", "Result of R","Result of R-1");
selectImage("Result of Result of R");
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
specintensR = getValue("Mean");
print(specintensR);
normvalR = stdIntens/specintensR;
print(normvalR);
selectImage("R");
run("Duplicate...", "duplicate");
selectImage("R-1");
run("Multiply...", "value=normvalR stack");

//**Segmentation using Weka**

//Modify the WeKa Segmentation version below if needed
selectImage("R-1");
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
selectImage("Classified image");
selectWindow("Trainable Weka Segmentation v4.0.0");
close();
roiManager("Deselect");
roiManager("Delete");
selectImage("Classified image");
selectImage("G");
waitForUser("select ROIs, then hit OK"); //Select PM ROI using wand tool, exclude intraellular vesicles

selectImage("G");
roiManager("Measure");
selectImage("R");
roiManager("Measure");

selectWindow("Results");

waitForUser("Get Results, then hit OK to clear");
for (x = 0; x <= 9; x++) { 
          selectImage(nImages); 
          close(); 
      } 
roiManager("Deselect");
roiManager("Delete");



