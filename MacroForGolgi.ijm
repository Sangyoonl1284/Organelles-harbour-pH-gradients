stdIntens = 7000;
classifierPath = "/Users/yklab/Desktop/SL/TGN_stack_4.model"; //Modify to fit the classifier path

run("Duplicate...", "title=RawImage duplicate");
//assign G,R,Y channels according to the imaging settings (Y for lysosome mask channel)
run("Duplicate...", "title=G duplicate channels=3");
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
            if (value >= 500) {
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
selectImage("Result of R");
run("Duplicate...", "title=RR duplicate");
selectImage("GG");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_GG");
run("Duplicate...", "title=ImageforMask duplicate");
roiManager("Deselect");
roiManager("Delete");
selectImage("ImageforMask");
waitForUser("Draw ROI and hit OK");
run("Create Mask");
selectImage("Mask");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit stack", "MAX_GG","Mask");
selectImage("Result of MAX_GG");
run("Duplicate...", "duplicate");
selectImage("Result of MAX_GG-1");
run("Threshold...");
run("Convert to Mask", "method=Otsu background=Dark calculate black create");
run("Divide...", "value=255 stack");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Bright stack");
imageCalculator("Multiply create 32-bit stack", "ImageforMask","Result of MAX_GG-1");

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
specintensG = getValue("Mean");
print(specintensG);
normvalG = stdIntens/specintensG;
print(normvalG);
selectImage("GG");
run("Duplicate...", "duplicate");
selectImage("GG-1");
run("Multiply...", "value=normvalG stack");

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
run("Duplicate...", "title=ClassifiedG duplicate");
selectImage("Classified image");
close();
selectWindow("Trainable Weka Segmentation v4.0.0");
close();
selectImage("ClassifiedG");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Bright stack");
run("32-bit");

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
ConvertZeroToNaN("MAX_ClassifiedG");

imageCalculator("Multiply create 32-bit stack", "GG","ClassifiedG");
imageCalculator("Multiply create 32-bit stack", "RR","ClassifiedG");
selectImage("Result of GG");
run("Z Project...", "projection=[Max Intensity]");
selectImage("Result of RR");
run("Z Project...", "projection=[Max Intensity]");

imageCalculator("Multiply create 32-bit", "MAX_Result of GG","MAX_ClassifiedG");
imageCalculator("Multiply create 32-bit", "MAX_Result of RR","MAX_ClassifiedG");
roiManager("Deselect");
roiManager("Delete");
waitForUser("Draw ROI, then hit OK");
selectImage("Result of MAX_Result of GG");
roiManager("Measure");
selectImage("Result of MAX_Result of RR");
roiManager("Measure");

selectWindow("Results");

waitForUser("Get Results, then hit OK to clear");
for (x = 0; x <= 27; x++) { 
          selectImage(nImages); 
          close(); 
      } 
roiManager("Deselect");
roiManager("Delete");