stdIntens = 2400;
classifierPath = "/Users/yklab/Desktop/SL/NucleolusbyDiffusion.model"; //Modify to fit the classifier path, use model for NucleolusbyDiffusion

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
run("32-bit");
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
selectImage("Result of R");
run("Duplicate...", "title=RR duplicate");
selectImage("RR");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_RR");
run("Duplicate...", "title=ImageforMask duplicate");
roiManager("Deselect");
roiManager("Delete");
selectImage("ImageforMask");
selectImage("Y-1");
run("Z Project...", "projection=[Min Intensity]");
imageCalculator("Multiply create 32-bit stack", "ImageforMask","MIN_Y-1");
waitForUser("Draw ROI and hit OK");

selectImage("RR");
run("Duplicate...", "title=RR-1 duplicate");
selectImage("RR-1");
 for (i = 1; i <= nSlices; i++) {
    setSlice(i);
 getDimensions(width, height, channels, slices, frames);
    specintensR=0;
    normvalR=0;
    roiManager("Select",0);
    getStatistics(area, mean, min, max, std, histogram);
    specintensR = mean;
print(specintensR);
normvalR = stdIntens/specintensR;
print(normvalR);
run("Select None");
run("Multiply...", "value=normvalR slice");
    updateDisplay();
 }
 
//**Segmentation using Weka**
selectImage("RR-1");
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
run("32-bit");

for (i = 1; i <= nSlices; i++) {
    setSlice(i);
getDimensions(width,height,channels,slices,frames);
for(x=0;x<width;x++){
	for(y=0;y<height;y++){
		value=getPixel(x,y);
		
		if(value == 1){
			setPixel(x,y,1);
			}
		if(value == 2){
			setPixel(x,y,0);
			}
	}
}
updateDisplay();
}

run("Remove Outliers...", "radius=5 threshold=0.5 which=Bright stack");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Dark stack");
imageCalculator("Multiply create 32-bit stack", "GG","Classified image");
imageCalculator("Multiply create 32-bit stack", "RR","Classified image");
selectImage("Result of GG");
run("Z Project...", "projection=[Max Intensity]");
selectImage("Result of RR");
run("Z Project...", "projection=[Max Intensity]");
selectImage("Classified image");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_Classified image");
getDimensions(width,height,channels,slices,frames);
for(x=0;x<width;x++){
	for(y=0;y<height;y++){
		value=getPixel(x,y);
		if(value == 0){
			setPixel(x,y,NaN);
		}

	}
}
updateDisplay();
imageCalculator("Multiply create 32-bit stack", "MAX_Result of GG", "MAX_Classified image");
imageCalculator("Multiply create 32-bit stack", "MAX_Result of RR", "MAX_Classified image");
roiManager("Deselect");
roiManager("Delete");
waitForUser("Draw ROI, then hit OK");
selectImage("Result of MAX_Result of GG");
roiManager("Measure");
selectImage("Result of MAX_Result of RR");
roiManager("Measure");

selectWindow("Results");

waitForUser("Get Results, then hit OK to clear");
for (x = 0; x <= 26; x++) { 
          selectImage(nImages); 
          close(); 
      } 
roiManager("Deselect");
roiManager("Delete");
