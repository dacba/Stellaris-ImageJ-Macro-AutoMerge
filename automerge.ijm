
macro "Auto Merge .nd2... [r]" {
/*
Output:
	Metadata text file in Out\Metadata\
	16bit tiff's of Z-stack images, adjusted, in Out\16bit\
	Merged RGB sets in Output folders
*/ 



//Default Variables
min = 0;
max = 0;
norm = false;
raw = false;
name_minmax = "";
name_auto = "";
min_cy3 = 0;
min_cy35 = 0;
min_cy55 = 0;
min_fitc = 0;
min_dapi = 0;
max_cy3 = 0;
max_cy35 = 0;
max_cy55 = 0;
max_fitc = 0;
max_dapi = 0;
pretty = false;
stack = false;
check_xy = false;
separatelut = false;

//Dialog
Dialog.create("ND2 PROCESSOR");

Dialog.addMessage("Probe Min Max\nLeave at Zero for Automatic Contrast");
Dialog.addNumber("min:", 0);
Dialog.addNumber("max:", 0);
Dialog.addCheckbox("Use Normalized Data", norm);
Dialog.addCheckbox("Use Raw Files", raw);
Dialog.addCheckbox("Stack Images", stack);
Dialog.addCheckbox("Separate LUT", separatelut);

Dialog.show();

//Retrieve Choices
min = Dialog.getNumber();
max = Dialog.getNumber();
norm = Dialog.getCheckbox();
raw = Dialog.getCheckbox();
stack = Dialog.getCheckbox();
separatelut = Dialog.getCheckbox();

if (separatelut == true) {
	Dialog.create("Separate LUT");
	
	Dialog.addMessage("DAPI");
	Dialog.addNumber("min:", 0);
	Dialog.addNumber("max:", 0);
	Dialog.addMessage("FITC");
	Dialog.addNumber("min:", 0);
	Dialog.addNumber("max:", 0);
	Dialog.addMessage("Cy3");
	Dialog.addNumber("min:", 0);
	Dialog.addNumber("max:", 0);
	Dialog.addMessage("Cy3.5");
	Dialog.addNumber("min:", 0);
	Dialog.addNumber("max:", 0);
	Dialog.addMessage("Cy5.5");
	Dialog.addNumber("min:", 0);
	Dialog.addNumber("max:", 0);
	
	Dialog.show();
	
	min_dapi = Dialog.getNumber();
	max_dapi = Dialog.getNumber();
	min_fitc = Dialog.getNumber();
	max_fitc = Dialog.getNumber();
	min_cy3 = Dialog.getNumber();
	max_cy3 = Dialog.getNumber();
	min_cy35 = Dialog.getNumber();
	max_cy35 = Dialog.getNumber();
	min_cy55 = Dialog.getNumber();
	max_cy55 = Dialog.getNumber();
	}


if (stack == true) grey = true;
if (min == 0 && max == 0) pretty = true;
if (pretty == true && separatelut == false) {
	min = "";
	max = "";
	name_minmax = "";
	name_auto = "auto";
	}
else if (pretty == false && separatelut == false) {
	name_auto = "";
	name_minmax = "-";
	}
if (separatelut == true) {
	min = "";
	max = "";
	name_auto = "";
	name_minmax = "Cy3-" + min_cy3 + "-" + max_cy3 + "_Cy3.5-" + min_cy35 + "-" + max_cy35 + "_Cy5.5-" + min_cy55 + "-" + max_cy55 + "_FITC-" + min_fitc + "-" + max_fitc + "_DAPI-" + min_dapi + "-" + max_dapi;
	}
if (stack == false) name_stack = "";
else name_stack = "stack";



//Initialize 
requires("1.49m");
setBatchMode(true);
run("Bio-Formats Macro Extensions");
run("Input/Output...", "jpeg=85 gif=-1 file=.csv");
inDir = getDirectory("Choose Directory Containing .ND2 Files ");
outDir = inDir + "Out-Pictures\\" + min + name_minmax + max + name_auto + name_stack + "-Results\\";
File.makeDirectory(inDir + "Out-Pictures\\");
File.makeDirectory(outDir);
if (File.exists(inDir + "Out-Merged Images\\Normalized Max\\") && norm == true) {
	fullDir = inDir + "Out-Merged Images\\Normalized Max\\";
	halfDir = inDir + "Out-Merged Images\\Normalized Max 8-bit\\";
	}
else {
	fullDir = inDir + "Out-Merged Images\\Max\\";
	halfDir = inDir + "Out-Merged Images\\Max 8-bit\\";
	}
metaDir = inDir + "Out-Merged Images\\Metadata\\";
DAPIDir = inDir + "Out-Merged Images\\Max 8-bit DAPI\\";
File.makeDirectory(inDir + "Out-Merged Images\\");
File.makeDirectory(fullDir);
File.makeDirectory(halfDir);
File.makeDirectory(metaDir);
run("Close All");
run("Clear Results");
print("\\Clear"); //Clear log window

//Primary Function Calls
check_xy = AM_xycheck(); //Checks for a xyvalues.txt in the output folder and opens it into the results table
if (check_xy == false) {
	AM_xy(inDir, outDir, ""); //Fill result table with x and y values for all files
	saveAs("Results", inDir + "Out-Pictures\\xyvalues.txt"); //Save results table for later use
	}
start_time = getTime();
total_results = nResults;
for (k = 0; nResults > 0; k++) { //Loop as long as there are results
	fileset = newArray();
	print("----------\nSet " + k);
	fileset = AM_match(fileset); //Get the set of files for the current set
	//Array.print(fileset); //Debug
	set = AM_setname(fileset); //Get the set name
	AM_main(inDir, outDir, fileset); //Main function call
	if (nResults > 0) { //Estimated time remaining
		estimate = round(((getTime() - start_time) * nResults / (total_results - nResults)) / 1000);
		if (estimate >= 60) {
			if (estimate/60 >= 60) {
				if (estimate/3600 >= 24) {
					print("Estimated Time Remaining: " round(estimate/86400) + " days " + estimate%86400 + " hours " + estimate%3600 + " min " + estimate%60 + " s");
					}
				else print("Estimated Time Remaining: " + round(estimate/3600) + " hours " + estimate%3600 + " min " + estimate%60 + " s");
				}
			else print("Estimated Time Remaining: " + round(estimate/60) + " min " + estimate%60 + " s");
			}
		else print("Estimated Time Remaining: " + estimate + " s");
		}
	}

function AM_xycheck() { //Initializes the result table and checks to see if an xyvalues.txt already exists
	setResult("Label", 0, "Initialize");
	setResult("X", 0, "0");
	setResult("Y", 0, "0");
	updateResults();
	run("Clear Results");
	if (File.exists(inDir + "Out-Pictures\\xyvalues.txt") == true) { //If the file exists, open it and split it up into lines
		print("xyvalues.txt was found");
		file = File.openAsString(inDir + "Out-Pictures\\xyvalues.txt");
		lines = split(file, "\n");
		for (n = 0; n < lines.length; n++) { //Iterate through each line, split it up by tabs and then add the cells to the results table
			cell = split(lines[n], "	");
			setResult("Label", nResults, cell[0]);
			setResult("X", nResults - 1, cell[1]);
			setResult("Y", nResults - 1, cell[2]);
			}
		return true;
		}
	else return false;
	}

function AM_xy(inBase, outBase, sub) { //Iterates through file system and finds x and y values
	list = getFileList(inBase + sub);
	for (i = 0; i < list.length; i++) {
		path = sub + list[i];
		if (endsWith(path, "/") && indexOf(path, "Out") == -1) {
			AM_xy(inBase, outBase, path); //Recursion
			}
		else if (indexOf(path, "Out") == -1 && endsWith(path, ".nd2") == true) {
			strip = replace(substring(path, 0, indexOf(path, ".nd2")), "/", "_");
			run("Bio-Formats Importer", "open=[" + inBase + path + "] display_metadata view=[Metadata only]");
			selectWindow("Original Metadata - " + list[i]);
			saveAs("Text", metaDir + strip + ".txt");
			run("Close");
			info = File.openAsString(metaDir + strip + ".txt");
			xpos = indexOf(info, "dXPos") + 6;
			ypos = indexOf(info, "dYPos") + 6;
			setResult("Label", nResults, sub + list[i]);
			setResult("X", nResults - 1, substring(info, xpos, ypos - 7));
			setResult("Y", nResults - 1, substring(info, ypos, indexOf(info, "dZ") - 1));
			updateResults();
			}
		}
	}

function AM_match(fileset) { //Returns an array of the paths of a set, and deletes the entries in the results table
	xtemp = getResult("X", 0);
	ytemp = getResult("Y", 0);
	updateResults();
	for (i = 0; i < nResults; i++) {
		if (xtemp == getResult("X", i) && ytemp == getResult("Y", i)) {
			name = getResultLabel(i);
			//print(name); //Debug
			if (File.exists(replace(replace(name, ".nd2", ".tif"), "/", "_")) == true) {
				//print(name + " was found in the 16bit tif folder from a previous iteration.  Will use the 16bit tif");
				fileset = Array.concat(fileset, replace(replace(name, ".nd2", ".tif"), "/", "_"));
				}
			else fileset = Array.concat(fileset, name);
			IJ.deleteRows(i, i);
			i--;
			}
		}
	return fileset;
	}

function AM_setname(fileset) { //Returns a set name (begins with "-")
	if (fileset.length == 0) return "Unknown";
	len = 100;
	for (i = 0; i < fileset.length; i++) {
		if (lengthOf(fileset[i]) < len) len = lengthOf(fileset[i]);
		}
	p = lengthOf(fileset);
	q = 1;
	for (n = 0; n < len; n++) { //For the length of the first file take the first len - n characters
		sub = substring(fileset[0], 0, len - n);
		for (i = 1; i < lengthOf(fileset); i++) { //Check against the other file names
			if (sub == substring(fileset[i], 0, len - n)) {
				q++;
				//print(sub + " matches " + substring(fileset[i], 0, len - n)); //Debug
				}
			}
		if (q == p) return replace(sub, "/", "_");
		}
	return "Unknown";
	}

function AM_Slice_Naming() {
	for (n = 1; n <= nSlices; n++) {
		setSlice(n);
		drawString(getMetadata(), 10, 40, 'white');
		}
	}
	
function AM_main(inBase, outBase, fileset) {
	len = lengthOf(fileset);
	merge = "";
	file1 = "";
	file2 = "";
	file3 = "";
	file5 = "";
	file7 = "";
	
	for (n = 0; n < len; n++) { //Loop through the fileset names
		path = inBase + fileset[n]; //Full path name
		filename = replace(substring(fileset[n], 0, indexOf(fileset[n], ".nd2")), "/", "_"); //For saving as 16-bit, subdirectory with underscores
		short_filename = substring(fileset[n], lastIndexOf(fileset[n], "/") + 1, lengthOf(fileset[n]));
		//print(fullDir + replace(replace(fileset[n], ".nd2", ".tif"), "/", "_"));
		
		//Get Channel info
		run("Bio-Formats Importer", "open=[" + path + "] display_metadata view=[Metadata only]");
		selectWindow("Original Metadata - " + short_filename);
		saveAs("Text", inBase + "temp.txt");
		run("Close");
		info = File.openAsString(inBase + "temp.txt");
		File.delete(inBase + "temp.txt");
		channel = "Unknown";
		if (indexOf(info, "Name	Cy3") > -1) channel = "Cy3.0";
		else if (indexOf(info, "Name	Cy3.5") > -1) channel = "Cy3.5";
		else if (indexOf(info, "Name	Cy5.5") > -1) channel = "Cy5.5";
		else if (indexOf(info, "Name	FITC") > -1) channel = "FITC";
		else if (indexOf(info, "Name	DAPI") > -1) channel = "DAPI";
		
		//Check if 16bit tif files exist and use those instead
		if (channel == "DAPI" && File.exists(DAPIDir + replace(replace(fileset[n], ".nd2", ".tif"), "/", "_")) && raw == false) {
			open(DAPIDir + replace(replace(fileset[n], ".nd2", ".tif"), "/", "_"));
			window_name = filename + ".tif";
			}
		else if (File.exists(fullDir + replace(replace(fileset[n], ".nd2", ".tif"), "/", "_")) && raw == false) { //16 bit tif exists
			open(fullDir + replace(replace(fileset[n], ".nd2", ".tif"), "/", "_"));
			window_name = filename + ".tif";
			}
		else {
			run("Bio-Formats Importer", "open=[" + path + "] autoscale color_mode=Grayscale view=Hyperstack");
			window_name = filename + ".nd2";
			//if (nSlices == 1 && channel != "DAPI") exit("This program requires unaltered multi image nd2 files\nPlease restart the macro and point to the unaltered .nd2 files");
			}
		
		print("File used: " + window_name);
		print("Channel: " + channel);
		
		if (nSlices > 1) {
			run("Z Project...", "projection=[Max Intensity]"); //Z Project
			window_name = getInfo("image.filename");
			selectImage(window_raw);
			close();
			}
		if (separatelut == false) {
			//Can be optimized
			if (indexOf(channel, "DAPI") == -1 && pretty == true) run("Enhance Contrast", "saturated=0.01"); //Makes the channel thats not DAPI look pretty if that's what the user wanted
			else if (indexOf(channel, "FITC") > -1 && pretty == true) run("Enhance Contrast", "saturated=0.001"); //Makes the FITC channel look pretty if that's what the user wanted
			else if (indexOf(channel, "DAPI") == -1 && pretty == false && min != 0 && max != 0) setMinAndMax(min,max); //if not DAPI and not pretty then apply min max
			else if (indexOf(channel, "DAPI") == -1 && pretty == false && (min == 0 || max == 0)) {
				run("Enhance Contrast", "saturated=0.01");
				getMinAndMax(temp_min,temp_max);
				if (min == 0) setMinAndMax(temp_min,max);
				else if (max ==0 ) setMinAndMax(min,temp_max);
				} //if not DAPI and not pretty and either
				else run("Enhance Contrast", "saturated=0.0"); //if DAPI then auto enhance
			}
		else {
			//Manual
			if (indexOf(channel, "Cy3.0") > -1 && min_cy3 != 0 && max_cy3 != 0) setMinAndMax(min_cy3,max_cy3); //Cy3
			else if (indexOf(channel, "Cy3.5") > -1 && min_cy35 != 0 && max_cy35 != 0) setMinAndMax(min_cy35,max_cy35); //Cy3.5
			else if (indexOf(channel, "Cy5.5") > -1 && min_cy55 != 0 && max_cy55 != 0) setMinAndMax(min_cy55,max_cy55); //Cy5.5
			else if (indexOf(channel, "FITC") > -1 && min_fitc != 0 && max_fitc != 0) setMinAndMax(min_fitc,max_fitc); //FITC
			else if (indexOf(channel, "DAPI") > -1 && min_dapi != 0 && max_dapi != 0) setMinAndMax(min_dapi,max_dapi); //DAPI
			//Semi-Manual or Auto
			if (indexOf(channel, "Cy3.0") > -1 && (min_cy3 == 0 || max_cy3 == 0)){
				run("Enhance Contrast", "saturated=0.01"); //Cy3
				getMinAndMax(temp_min,temp_max);
				if (min_cy3 == 0 && max_cy3 != 0) setMinAndMax(temp_min,max_cy3); //Cy3
				else if (max_cy3 ==0 && min_cy3 != 0) setMinAndMax(min_cy3, temp_max);
				}
			else if (indexOf(channel, "Cy3.5") > -1 && (min_cy35 == 0 || max_cy35 == 0)){
				run("Enhance Contrast", "saturated=0.01"); //Cy3.5
				getMinAndMax(temp_min,temp_max);
				if (min_cy35 == 0 && max_cy35 != 0) setMinAndMax(temp_min,max_cy35); //Cy3.5
				else if (max_cy35 ==0 && min_cy35 != 0) setMinAndMax(min_cy35, temp_max);
				}
			else if (indexOf(channel, "Cy5.5") > -1 && (min_cy55 == 0 || max_cy55 == 0)){
				run("Enhance Contrast", "saturated=0.01"); //Cy5.5
				getMinAndMax(temp_min,temp_max);
				if (min_cy55 == 0 && max_cy55 != 0) setMinAndMax(temp_min,max_cy55); //Cy5.5
				else if (max_cy55 ==0 && min_cy55 != 0) setMinAndMax(min_cy55, temp_max);
				}
			else if (indexOf(channel, "FITC") > -1 && (min_fitc == 0 || max_fitc == 0)){
				run("Enhance Contrast", "saturated=0.001"); //fitc
				getMinAndMax(temp_min,temp_max);
				if (min_fitc == 0 && max_fitc != 0) setMinAndMax(temp_min,max_fitc); //fitc
				else if (max_fitc ==0 && min_fitc != 0) setMinAndMax(min_fitc, temp_max);
				}
			else if (indexOf(channel, "DAPI") > -1 && (min_dapi == 0 || max_dapi == 0)){
				run("Enhance Contrast", "saturated=1.0"); //dapi
				getMinAndMax(temp_min,temp_max);
				if (min_dapi == 0 && max_dapi != 0) setMinAndMax(temp_min,max_dapi); //dapi
				else if (max_dapi ==0 && min_dapi != 0) setMinAndMax(min_dapi, temp_max);
				}
			}
			
		setMetadata("Info", channel);
		save(fullDir + filename + ".tif"); //save as 16bit tif in the appropriate subfolder
		run("8-bit");
		save(halfDir + filename + ".tif");
		if (len == 2) {
			print("Single Channel with DAPI Detected");
			if (indexOf(channel, "DAPI") > -1) file3 = "c3=[" + window_name + "] ";//DAPI; Blue
			else file5 = "c4=" + window_name + " ";//Other channel; Grey
			}
		else if (len > 2) {
			//Color Merge stuff
			if (indexOf(channel, "Cy5.5") > -1) file1 = "c1=" + window_name + " ";//Cy5.5; Red
			if (indexOf(channel, "FITC") > -1) file2 = "c2=" + window_name + " ";//FITC; Green
			if (indexOf(channel, "DAPI") > -1) file3 = "c3=" + window_name + " ";//DAPI; Blue
			if (indexOf(channel, "Cy3.0") > -1) file7 = "c7=" + window_name + "";//Cy3; Yellow
			if (indexOf(channel, "Cy3.5") > -1) file5 = "c5=" + window_name + " ";//Cy3.5; Cyan (Note: c4 is grey, c6 is magenta)
			}
		else if (len == 1) {
			print("Single Channel Detected");
			file5 = "c4=" + window_name + "";
			}
		else exit("Something bad happened... Go talk to Trevor"); //fileset is empty
		} //End of for loop
	name_set = set;
	if (stack == false) {
		merge = file1 + file2 + file3 + file5 + file7 + " create"; //add up the channels that were found
		//print(merge);
		run("Merge Channels...", "\"" + merge + "\""); //MERGE!
		run("RGB Color"); //Change to rgb color file
		stackname = "RGB-";
		}
	else if (stack == true) {
		run("Images to Stack", "name=Stack title=[] use");
		//run("StackReg", "transformation=Translation"); //Align the images
		run("Enhance Contrast...", "saturated=0.01 process_all");
		//AM_Slice_Naming();
		stackname =  "Stack-";
		}
	if (endsWith(name_set, "-") == true) name_set = substring(name_set, 0, lengthOf(name_set) - 1);
	save(outBase + name_set + "-" + stackname + "Set" + k + ".tif"); //save
	run("Close All");
	run("Collect Garbage");
	}//End of function


print("-- Done --");
showStatus("Finished.");
} //end of macro