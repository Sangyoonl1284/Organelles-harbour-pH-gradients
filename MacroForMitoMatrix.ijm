stdIntens = 8000;
acidicThreshold = 2.7;
classifierPath = "/Users/yklab/Desktop/SL/mitostack2.model"; //Modify to fit the classifier path
 
run("Duplicate...", "title=RawImage duplicate");
//assign G and R channels according to the imaging settings
run("Duplicate...", "title=R duplicate channels=1");
selectImage("RawImage");
run("Duplicate...", "title=G duplicate channels=2");
 
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
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_G");
regionSize = 30// Define the region size

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
 

//**Acidic compartment masking**
 
imageCalculator("Divide create 32-bit stack", "G","R");
selectImage("Result of G");
                  setRadius = 2;
                  setRepeatTimes = 10;
                 
                  for (i = 1; i <= nSlices; i++) {
                      setSlice(i);
                      getDimensions(width, height, channels, slices, frames);
                    
                      for (x = 0; x < width; x++) {
                          for (y = 0; y < height; y++) {
                              value = getPixel(x, y);
                              if (value >= 10) {
                                  setPixel(x, y, 10);
                }
                                                      }
        }
                  }// Loop through all pixels and replace very high or infinity values to 10
                 
setMinAndMax(0, 5);
setThreshold(acidicThreshold, 100000);
setOption("BlackBackground", true);
run("Convert to Mask", "background=Dark black");
// Threshold by G/R >= acidicTheshold
selectImage("Result of G");
                  for (i = 1; i <= nSlices; i++) {
                      setSlice(i);
                                    for (j = 0; j < setRepeatTimes; j++){
                      run("Remove Outliers...", "radius=setRadius threshold=1 which=Dark");
                                    }
                                    run("Remove Outliers...", "radius=setRadius threshold=1 which=Bright");
                                   
                                    updateDisplay();
                  }// Make clusters into filled patches
 
                  run("Invert", "stack");
                  run("Divide...", "value=255 stack");
                  setMinAndMax(0,1);
                 
selectImage("Result of G");
run("Duplicate...", "duplicate");
selectImage("Result of G");
close();
imageCalculator("Multiply create 32-bit stack", "G","Result of G-1");
imageCalculator("Multiply create 32-bit stack", "R","Result of G-1");

//**Normalization for segmentation**

selectImage("Result of R");
run("Duplicate...", "title=RR duplicate");
selectImage("RR");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_RR");
run("Duplicate...", "title=ImageforMask duplicate");
roiManager("Deselect");
roiManager("Delete");
selectImage("ImageforMask");
waitForUser("Draw ROI and hit OK");
run("Create Mask");
selectImage("Mask");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit stack", "MAX_RR","Mask");
selectImage("Result of MAX_RR");
run("Duplicate...", "duplicate");
selectImage("Result of MAX_RR-1");
run("Threshold...");
run("Convert to Mask", "method=Otsu background=Dark calculate black create");
run("Divide...", "value=255 stack");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Bright stack");
imageCalculator("Multiply create 32-bit stack", "ImageforMask","Result of MAX_RR-1");

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
specintens = getValue("Mean");
print(specintens);
normval = stdIntens/specintens;
print(normval);
selectImage("R");
run("Duplicate...", "duplicate");
selectImage("R-1");
run("Multiply...", "value=normval stack");

//**Segmentation using Weka**

run("Trainable Weka Segmentation 3D");

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
selectImage("Classified image");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Bright stack");
imageCalculator("Multiply create 32-bit stack", "Classified image","Result of G-1");
selectImage("Result of Classified image");
run("Z Project...", "projection=[Max Intensity]");
 
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
ConvertZeroToNaN("MAX_Result of Classified image");
 
imageCalculator("Multiply create 32-bit stack", "Result of G","Result of Classified image");
imageCalculator("Multiply create 32-bit stack", "Result of R","Result of Classified image");
selectImage("Result of Result of G");
run("Z Project...", "projection=[Max Intensity]");
selectImage("Result of Result of R");
run("Z Project...", "projection=[Max Intensity]");
 
imageCalculator("Multiply create 32-bit", "MAX_Result of Result of G","MAX_Result of Classified image");
imageCalculator("Multiply create 32-bit", "MAX_Result of Result of R","MAX_Result of Classified image");
roiManager("Deselect");
roiManager("Delete");
waitForUser("Draw ROI, then hit OK");
selectImage("Result of MAX_Result of Result of G");
roiManager("Measure");
selectImage("Result of MAX_Result of Result of R");
roiManager("Measure");
 
selectWindow("Results");
 
waitForUser("Get Results, then hit OK to clear");
for (x = 0; x <= 24; x++) {
          selectImage(nImages);
          close();
      }
roiManager("Deselect");
roiManager("Delete");