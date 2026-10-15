stdIntens = 8000;
acidicThreshold = 2.7;
filterkernelsize=3;
classifierPath = "/Users/yklab/Desktop/SL/mitostack2.model"; //Modify to fit the classifier path
 
 
run("Duplicate...", "title=RawImage duplicate");
//assign G and R channels according to the imaging settings
run("Duplicate...", "title=R duplicate channels=2");
selectImage("RawImage");
run("Duplicate...", "title=G duplicate channels=1");
 
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
regionSize = 30 // Define the region size for background ROI

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
       if(mean>0){
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
}
makeRectangle(minX1, minY1, regionSize, regionSize);
roiManager("Add");
makeRectangle(minX2, minY2, regionSize, regionSize);
roiManager("Add");
makeRectangle(minX3, minY3, regionSize, regionSize);
roiManager("Add");
 n = roiManager("count");
  selectImage("G");
  run("Duplicate...", "title=filteredG duplicate");
  selectImage("filteredG");
  run("Mean...", "radius=2 stack");
 GstdDev=0;
 for (i = 1; i <= nSlices; i++) {
     setSlice(i);
     roiManager("combine");
     getStatistics(area, mean, min, max, stdDev);
     if(GstdDev<stdDev){
     		GstdDev=stdDev;
     	}
     }
  selectImage("R");
   run("Duplicate...", "title=filteredR duplicate");
  selectImage("filteredR");
  run("Mean...", "radius=2 stack");
 RstdDev=0;
 
 for (i = 1; i <= nSlices; i++) {
     setSlice(i);
     roiManager("combine");
     getStatistics(area, mean, min, max, stdDev);
     if(RstdDev<stdDev){
     		RstdDev=stdDev;
     	}
     }
 print("GBkgStd: " + GstdDev);
 print("RBkgStd: " + RstdDev); 
 
 
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
setThreshold(acidicThreshold, 100000000);
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
   
    // Loop through all pixels and replace 0 with NaN (1/0)
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            value = getPixel(x, y);
            if (value == 0) {
                setPixel(x, y, NaN); // NaN
            }
        }
    }
 
    // Update the modified image display
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
   
    // Loop through all pixels and replace 0 with NaN (1/0)
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            value = getPixel(x, y);
            if (value == 0) {
                setPixel(x, y, NaN); // NaN
            }
        }
    }
 
    // Update the modified image display
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


selectImage("Mask");
close();

roiManager("Select", 0);
run("Create Mask");
selectImage("Mask");
run("32-bit");
run("Divide...", "value=255.000");
getDimensions(width,height,channels,slices,frames);
for(x=0;x<width;x++){
	for(y=0;y<height;y++){
		value=getPixel(x,y);
		if(value == 0.0){
			setPixel(x,y,NaN);
		}
	}
}
updateDisplay();
imageCalculator("Multiply create 32-bit", "Result of MAX_Result of Result of G","Mask");
imageCalculator("Multiply create 32-bit", "Result of MAX_Result of Result of R","Mask");

function MeanIgnoringNaNthresholding(ImageforFilter, stdDev){	
	kernelSize=filterkernelsize;
	selectImage(ImageforFilter);
	getDimensions(width, height, channels, slices, frames);
	edgePixel=0;
	underThresholdPixel=0;
	filterArray=newArray(width*height);
	for(x=0;x<width;x++){
		for(y=0;y<height;y++){
			sumValue=0.0;
			count=0;
			threshold=0.0;
			filterbox=(2*kernelSize+1)*(2*kernelSize+1);
			originalvalue=getPixel(x,y);
			if(!isNaN(originalvalue)){
				for(dx=-kernelSize;dx<=kernelSize;dx++){
					for(dy=-kernelSize;dy<=kernelSize;dy++){
						if(x+dx>=0&&x+dx<width&&y+dy>=0&&y+dy<height){
							value=getPixel(x+dx,y+dy);
							if(!isNaN(value)){
								sumValue+=value;
								count++;
							}
						}
					}
				}
				meanValue=sumValue/count;
				if(count>filterbox*0.5){
					if(meanValue > 10*stdDev){
						filterArray[x*width+y]=meanValue;
					
					}
					else{
				
						filterArray[x*width+y]=NaN;
						underThresholdPixel++;
						}
				}
				else{
					filterArray[x*width+y]=NaN;
				
					edgePixel++;
				}
		
			}
			
			else{
				filterArray[x*width+y]=NaN;
			}
		}
	}
	for(x=0;x<width;x++){
		for(y=0;y<height;y++){
			setPixel(x,y,filterArray[x*width+y]);
			}	
		}
	print("edgePixels =", edgePixel);
	print("underThresholdPixels =", underThresholdPixel);
	updateDisplay();

}


MeanIgnoringNaNthresholding("Result of Result of MAX_Result of Result of G", GstdDev);
MeanIgnoringNaNthresholding("Result of Result of MAX_Result of Result of R", RstdDev);

selectImage("Result of Result of MAX_Result of Result of G");
roiManager("Measure");
selectImage("Result of Result of MAX_Result of Result of R");
roiManager("Measure");


imageCalculator("Divide create 32-bit", "Result of Result of MAX_Result of Result of R","Result of Result of MAX_Result of Result of G");
selectImage("Result of Result of Result of MAX_Result of Result of R");

getDimensions(width,height,channels,slices,frames);
for(x=0;x<width;x++){
	for(y=0;y<height;y++){
		value=getPixel(x,y);
		if(value >= 100){
			setPixel(x,y,NaN);
		}
	}
}
updateDisplay();

getStatistics(area, ImageRbyG, min, max, std);

print("RbyG =", ImageRbyG);
run("Duplicate...", "title=logr");
selectImage("logr");
run("Log");

kernelSize=1;
	getDimensions(width, height, channels, slices, frames);
	RbyGfilterArray=newArray(width*height);
	for(x=0;x<width;x++){
		for(y=0;y<height;y++){
			sumValue=0.0;
			count=0;
			threshold=0.0;
			originalvalue=getPixel(x,y);
			if(!isNaN(originalvalue)){
				for(dx=-kernelSize;dx<=kernelSize;dx++){
					for(dy=-kernelSize;dy<=kernelSize;dy++){
						if(x+dx>=0&&x+dx<width&&y+dy>=0&&y+dy<height){
							value=getPixel(x+dx,y+dy);
							if(!isNaN(value)){
								sumValue+=value;
								count++;
							}
						}
					}
				}
				meanValue=sumValue/count;
						RbyGfilterArray[x*width+y]=meanValue;
			}
			else{
				RbyGfilterArray[x*width+y]=NaN;
			}
		}
	}
	for(x=0;x<width;x++){
		for(y=0;y<height;y++){
			setPixel(x,y,RbyGfilterArray[x*width+y]);
			}	
		}
	updateDisplay();

getDimensions(width, height, channels, slices, frames);
n=0;
values=newArray(width*height);
	for(x=0;x<width;x++){
		for(y=0;y<height;y++){
			v=getPixel(x,y);
			if(v==v){
				values[n]=v;
				n++;
				}
			}
		}
values=Array.trim(values, n);
Array.sort(values);
q1_index=round(n*0.25);
q3_index=round(n*0.75);
q1=values[q1_index];
q3=values[q3_index];
iqr=q3-q1;

getStatistics(area, mean, minVal, maxVal, std, histogram);
range=maxVal-minVal;
cubeRootN=pow(n, 1/3);
optimalWidth=(2*iqr)/cubeRootN;
optimalBins=round(range/optimalWidth);

getHistogram(values, counts, optimalBins);
maxCount=0;
modeValue=0;
for(i=0;i<lengthOf(counts);i++){
	if(counts[i]>maxCount){
		maxCount=counts[i];
		modeValue=values[i];
		}
	}
binWidth=values[1]-values[0];

print("binWidth =", binWidth);
print("IQR =", iqr);
print("bin =", optimalBins);
print("mode =", modeValue);

function highOutlierCount (lnImage, mode, critD){
getDimensions(width, height, channels, slices, frames);
	maxcrit = mode+critD;
	PixCount=0;
	OutlierCount=0;
	
	for(x=0;x<width-1;x++){
		for(y=0;y<height-1;y++){
			originalvalue=getPixel(x,y);
			if(!isNaN(originalvalue)){
				PixCount++;
				if(originalvalue>maxcrit){
					OutlierCount++;
					}
				}
			}
		}
		OutlierFrequency=OutlierCount/PixCount;
		print("totalpix =",PixCount);
		print(critD,"out =", OutlierCount);
		print(critD,"outratio =", OutlierFrequency);
	}

highOutlierCount("logr", modeValue, 0.233);
highOutlierCount("logr", modeValue, 0.329);
waitForUser("Save log image, then hit OK");

for (x = 0; x <= 30; x++) {
          selectImage(nImages);
          close();
      }
roiManager("Deselect");
roiManager("Delete");