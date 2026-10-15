stdIntens = 2000;
acidicThreshold = 2.7;
filterkernelsize=3;
classifierPath = "/Users/yklab/Desktop/SL/ERstack.model copy"; //Modify to fit the classifier path

run("Duplicate...", "title=RawImage duplicate");
//assign G, R, Y channels according to the imaging settings. Y is the lysosome mask channel
run("Duplicate...", "title=G duplicate channels=4");
selectImage("RawImage");
run("Duplicate...", "title=oriR duplicate channels=2");
selectImage("RawImage");
run("Duplicate...", "title=Y duplicate channels=1");

selectImage("Y");
run("Duplicate...", "title=Yleak duplicate");
selectImage("Yleak");
run("Multiply...", "value=0.1 stack");
imageCalculator("Subtract create 32-bit stack", "oriR","Yleak");
selectImage("Result of oriR");
run("Duplicate...", "title=R duplicate");

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

selectImage("R");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_R");
regionSize = 30; // Define the region size
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

	setRadius = 2;
	setRepeatTimes = 5;
	
selectImage("Y");
run("Duplicate...", "duplicate");
selectImage("Y-1");
setMinAndMax(0,1);
for (i = 1; i <= nSlices; i++) {
    setSlice(i);
    getDimensions(width, height, channels, slices, frames);
    // Loop through all pixels and replace 0 with NaN (1/0)
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            value = getPixel(x, y);
            if (value >= 1500) {
                setPixel(x, y, 0); // NaN
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
		
    // Update the modified image display
    updateDisplay();
     for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            value = getPixel(x, y);
            if (value == 0) {
                setPixel(x, y, NaN); // NaN
            }
        }
    }
}

selectImage("Y-1");
	
	
imageCalculator("Multiply create 32-bit stack", "G","Y-1");
imageCalculator("Multiply create 32-bit stack", "R","Y-1");

//**Normalization for segmentation**

selectImage("Result of G");
run("Z Project...", "projection=[Max Intensity]");
selectImage("MAX_Result of G");
run("Duplicate...", "title=ImageforMask duplicate");
roiManager("Deselect");
roiManager("Delete");
selectImage("ImageforMask");
waitForUser("Draw an ROI that contains only ER signal with representative brightness, then hit OK");
run("Create Mask");
selectImage("Mask");
run("Divide...", "value=255");
imageCalculator("Multiply create 32-bit stack", "Result of G","Mask");
selectImage("Result of Result of G");
run("Duplicate...", "duplicate");
selectImage("Result of Result of G-1");
run("Smooth", "stack");
run("Threshold...");
run("Convert to Mask", "method=Otsu background=Dark calculate black create");
run("Divide...", "value=255 stack");
imageCalculator("Multiply create 32-bit stack", "Result of Result of G-1","MASK_Result of Result of G-1");
selectImage("Result of Result of Result of G-1");
run("Z Project...", "projection=[Max Intensity]");
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
specintensG = getValue("Mean");
print(specintensG);
normvalG = stdIntens/specintensG;
print(normvalG);
selectImage("Result of G");
run("Duplicate...", "duplicate");
selectImage("Result of G-1");
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


selectImage("Result of R");
imageCalculator("Multiply create 32-bit stack", "Result of R","Mask");
selectImage("Result of Result of R");
run("Duplicate...", "duplicate");
selectImage("Result of Result of R-1");
run("Smooth", "stack");
run("Threshold...");
run("Convert to Mask", "method=Otsu background=Dark calculate black create");
run("Divide...", "value=255 stack");
imageCalculator("Multiply create 32-bit stack", "Result of Result of R-1","MASK_Result of Result of R-1");
selectImage("Result of Result of Result of R-1");
run("Z Project...", "projection=[Max Intensity]");
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
selectImage("Result of R");
run("Duplicate...", "duplicate");
selectImage("Result of R-1");
run("Multiply...", "value=normvalR stack");
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
run("Duplicate...", "title=ClassifiedR duplicate");
selectImage("Classified image");
close();
selectImage("ClassifiedR");
run("Remove Outliers...", "radius=2 threshold=0.5 which=Bright stack");


imageCalculator("Multiply create 32-bit stack", "ClassifiedG","ClassifiedR");
run("Duplicate...", "title=ClassifiedGR duplicate");
selectImage("Result of ClassifiedG");
close();
selectImage("ClassifiedGR");
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
ConvertZeroToNaN("MAX_ClassifiedGR");
selectImage("Result of Result of G");
close();
selectImage("Result of Result of R");
close();
imageCalculator("Multiply create 32-bit stack", "Result of G","ClassifiedGR");
imageCalculator("Multiply create 32-bit stack", "Result of R","ClassifiedGR");
selectImage("Result of Result of G");
run("Z Project...", "projection=[Max Intensity]");
selectImage("Result of Result of R");
run("Z Project...", "projection=[Max Intensity]");

imageCalculator("Multiply create 32-bit", "MAX_Result of Result of G","MAX_ClassifiedGR");
imageCalculator("Multiply create 32-bit", "MAX_Result of Result of R","MAX_ClassifiedGR");

selectImage("Mask");
close();

roiManager("Select", 0);
run("Create Mask");
selectImage("Mask");
run("32-bit");
run("Divide...", "value=255.000");
ConvertZeroToNaN("Mask");
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


imageCalculator("Divide create 32-bit", "Result of Result of MAX_Result of Result of G","Result of Result of MAX_Result of Result of R");
selectImage("Result of Result of Result of MAX_Result of Result of G");

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

getStatistics(area, ImageGbyR, min, max, std);

print("GbyR =", ImageGbyR);
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
highOutlierCount("logr", modeValue, 0.424);
waitForUser("Save log image, then hit OK");

for (x = 0; x <= 40; x++) {
          selectImage(nImages);
          close();
      }
roiManager("Deselect");
roiManager("Delete");