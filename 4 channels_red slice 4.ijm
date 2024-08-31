dir = getDirectory("Gimme the folder !");
Dialog.create("Alllllllright, let's get started");
Dialog.addMessage("Script will need those informations on your dataset (You probably want to let in in default)");
Dialog.addString("Format of your images", ".tif");
Dialog.addNumber("Expected minimum particle size", 100);
Dialog.addChoice("Thresholding methods", newArray("Li dark", "Default dark", "MaxEntropy dark", "MinError dark", "Moments dark", "Otsu dark", "Percentile dark", "Triangle dark", "IsoData dark", "IJ_IsoData dark", "Mean dark"));
Dialog.addCheckbox("Plotting  and display the data", false);
Dialog.show();

ImgFormat = Dialog.getString();
ParticleSize = Dialog.getNumber();
tresholdmethod = Dialog.getChoice();
wantgraph = Dialog.getCheckbox();


setBatchMode(true);

folderlist = getFileList(dir);
Array.sort(folderlist);



//Loop in all folders contained in folder
for (z = 0 ; z < lengthOf(folderlist); z++){
input_path = dir + folderlist[z];
output_path = File.makeDirectory(input_path+"Results/");
output_path = input_path+"Results";

list = getFileList(input_path);
Array.sort(list);
i = 0 ;
CTCF_sum = 0;
CTCF_sum_value = 0;
CTCF_sum_1 = 0;
CTCF_sum_value_1 = 0;

list = getFileList(input_path);


for (i = 0; i < lengthOf(list); i++) {
	
    if (endsWith(list[i], ImgFormat)) { 
        open(input_path + File.separator + list[i]);
        
title = getTitle();
setSlice(4);
    
run("Duplicate...", "title=mask duplicate range=4");
selectWindow("mask");
setAutoThreshold("Li dark");
run("Convert to Mask");
run("Watershed", "slice");


run("Analyze Particles...", "size=" + ParticleSize + "-Infinity add slice");
Particle = roiManager("count");
run("Set Measurements...", "area mean min integrated redirect=None decimal=2");


//Measuring red channel
selectImage(title);
setSlice(4);
roiManager("measure");


//Measuring background slice 4
run("Set Measurements...", "area mean integrated redirect=None decimal=2");
selectImage(title);
setSlice(4);
roiManager("Select All");
roiManager("Combine");
run("Enlarge...", "enlarge=10");
run("Make Inverse");
run("Measure");


IJ.renameResults("Results");
    for (row=0; row < Particle ; row++) {
			CTCF = getResult("IntDen", row) - getResult("Area", row) * getResult("Mean", Particle);
   			setResult("CTCF", row, CTCF);
		}
		
				for (row = 0; row < Particle-1 ; row++) {
	
					CTCF_sum = CTCF_sum + getResult("CTCF", row);
				}
			
			CTCF_mean = CTCF_sum / nResults;
			setResult("CTCF_mean", row, CTCF_mean);
			//print(CTCF_mean);
			updateResults();
			
saveAs("results", input_path+"Results/" + "Slice4_" + i + ".csv");
CTCF_sum = 0;
CTCF_sum_value = 0;
CTCF_sum_1 = 0;
CTCF_sum_value_1 = 0;
run("Clear Results");
close("Results");			
			
selectImage(title);
setSlice(3);
roiManager("measure");			
		
		
//Measuring background slice 3		
		run("Set Measurements...", "area mean integrated redirect=None decimal=2");
selectImage(title);
setSlice(3);
roiManager("Select All");
roiManager("Combine");
run("Enlarge...", "enlarge=10");
run("Make Inverse");
run("Measure");
		
		IJ.renameResults("Results");

		for (row=0; row<Particle ; row++) {
			CTCF_1 = getResult("IntDen", row) - getResult("Area", row) * getResult("Mean", Particle);
   			setResult("CTCF", row, CTCF_1);
		}
		for (row = 0; row < Particle-1 ; row++) {
	
					CTCF_sum = CTCF_sum + getResult("CTCF", row);
				}
			
			CTCF_mean = CTCF_sum / nResults;
			setResult("CTCF_mean", row, CTCF_mean);
			//print(CTCF_mean);
			updateResults();
			
			 
		//	 for (row = 0; row < Particle-1 ; row++) {
			// 	CTCF_sum_value_1 = CTCF_sum_value_1 + ((getResult("CTCF", row)- CTCF_sum_1)*(getResult("CTCF", row)- CTCF_sum_1));
	 	

			 

			// CTCF_sd = sqrt(CTCF_sum_value / nResults);
			// setResult("CTCF_sd", row, CTCF_sd);
			// updateResults();

saveAs("results", input_path+"Results/" + "Slice3_" + i + ".csv");


run("Clear Results");
close("Results");
run("Collect Garbage");
		
//Reseting the ROI manager for the next round
				run("Close All");
				roiManager("reset");
CTCF_sum = 0;
CTCF_sum_value = 0;
CTCF_sum_1 = 0;
CTCF_sum_value_1 = 0;
		
    } 
}
close("*");


nb_row = 0;


//TO BE DELETED
//input_path = getDirectory("Gimme the folder !");
//TO BE DELETED

//Get one channel

list = getFileList(output_path);
Array.sort(list);
length = (lengthOf(list)/2);

for (i = 0 ; i < length; i++) {
	open(input_path+"Results/"+list[i]);
	nrow = (Table.size)-2;
	
		for (j = 0; j < nrow; j++) {
			CTCF_value = (Table.get("CTCF", j));
			setResult("Slice_3", nb_row, CTCF_value);
			nb_row = nb_row+1;
	}


	close(list[i]);
	
}


updateResults();



//get the other channel
nb_row = 0;

for (k = 0; k < length ; k++) {
	open(input_path+"Results/"+list[k+length]);
	nrow = (Table.size)-2;

	for (l = 0; l < nrow; l++) {
		CTCF_value = (Table.get("CTCF", l));
		setResult("Slice_4", nb_row, CTCF_value);
		nb_row = nb_row +1;
	
	}
	
close(list[k+length]);


}

updateResults();
saveAs("results", input_path+"Results/" + "Results"+ ".csv");


//Drawing a beautiful graph

if (wantgraph) {

Plot.create("Compared_Intensities", "Slice_3", "Slice_4");
Plot.add("Circle", Table.getColumn("Slice_3", "Results"), Table.getColumn("Slice_4", "Results"));
Plot.setStyle(0, "black,black,1.0,Circle");

Fit.doFit("Straight Line", Table.getColumn("Slice_3", "Results"), Table.getColumn("Slice_4", "Results"));
Fit.plot;

Plot.setAxisLabelSize(14.0, "plain");
Plot.setFontSize(14.0);
Plot.setXYLabels("Slice_3", "Slice_4");
Plot.setFormatFlags("11001100111111");
selectWindow("y = a+bx");
Plot.addFromPlot("y = a+bx", 0);
Plot.setStyle(1, "red,none,2.0,Line");
Plot.addFromPlot("y = a+bx", 2);
Plot.setStyle(2, "black,none,1.0,Line");
close("y = a+bx");

print(Fit.rSquared);
print("And a good day to you, dear macro user");
}
run("Clear Results");
close("Results");
}