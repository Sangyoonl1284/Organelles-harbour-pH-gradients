# Organelles-harbour-pH-gradients
imagej macro codes for pH image analysis
System Requirements: ImageJ Fiji, with Trainable Weka Segmentation v4.0.0 (You can easily modify the version number in the macro,, tested on multiple previous versions from 2024)
Installation: Download the files, keep note on the file path of the Weka models so you can modify the filepath of Weka models in the macro. No installation process other than downloading
Demo: Two image files for Demo; Cell surface and mito. The macro for other organelles work in a very similar way.
      When running the macro on demo files, you sould expect segmentation of the target organelle and G, R values of the segmented organelle in the 'Results' window. i.e.) if you make 5 ROIs, the results window will show 5 G values and 5 R values.

Instructions for Use
Minor modifications of the macro is required: filepath of the weka models after downloading, and Weka segmentation plugin version if other than v4.0.0. The macro is intended to work on multichannel 3D hyperstack, so adjust the channel number to match the G and R channel for the used microscope settings.
After background subtraction, you will be asked to 'Draw ROI'. This is for the normalization that is needed for segmentation. Select an ROI that contains only the target organelle with a representative brightness. After segmentation, you will be asked again to 'Draw ROI'. This is for selecting ROI for G and R measurements.
