
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
Dialog.addCheckbox("Stack Images", false);
Dialog.addCheckbox("Separate LUT", false);

Dialog.show();

//Retrieve Choices
min = Dialog.getNumber();
max = Dialog.getNumber();
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
File.makeDirectory(inDir + "Out-Pictures\\16bit\\");
File.makeDirectory(inDir + "Out-Pictures\\Metadata\\");
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
	print("Set " + k);
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
			saveAs("Text", inBase + "Out-Pictures\\Metadata\\" + strip + ".txt");
			run("Close");
			info = File.openAsString(inBase + "Out-Pictures\\Metadata\\" + strip + ".txt");
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
			if (File.exists(inDir + "Out-Pictures\\16bit\\" + replace(replace(name, ".nd2", ".tif"), "/", "_")) == true) {
				print(name + " was found in the 16bit tif folder from a previous iteration.  Will use the 16bit tif");
				fileset = Array.concat(fileset, "Out-Pictures\\16bit\\" + replace(replace(name, ".nd2", ".tif"), "/", "_"));
				}
			else fileset = Array.concat(fileset, name);
			IJ.deleteRows(i, i);
			i--;
			}
		}
	return fileset;
	}

function AM_setname(fileset) { //Returns a set name (begins with "-")
	len = lengthOf(fileset[0]);
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

function AM_main(inBase, outBase, fileset) {
	len = lengthOf(fileset);
	merge = "";
	file1 = "";
	file2 = "";
	file3 = "";
	file5 = "";
	file7 = "";
	if (endsWith(fileset[0], ".nd2") == true) { //for .nd2 files
		for (n = 0; n < len; n++) { //Loop through the fileset names
			path = inBase + fileset[n]; //Full path name
			filename = replace(substring(fileset[n], 0, indexOf(fileset[n], ".nd2")), "/", "_"); //For 	saving as 16-bit, subdirectory with underscores
			print("File: " + fileset[n]);
			run("Bio-Formats Importer", "open=[" + path + "] autoscale color_mode=Grayscale view=Hyperstack");
			if (nSlices == 1) exit("This program requires unaltered .nd2 files\nPlease restart the macro and point to the unaltered .nd2 files");
			info = getImageInfo(); //Move this to xy and pass to this function
			channel = substring(info, indexOf(info, "Negate") - 6, indexOf(info, "Negate")); //Store the channel
			if (nSlices > 1) run("Z Project...", "projection=[Max Intensity]"); //Z Project
			
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
					else run("Enhance Contrast", "saturated=1.0"); //if DAPI then auto enhance
				}
			else {
				//Manual
				if (indexOf(channel, "= Cy3") > -1 && min_cy3 != 0 && max_cy3 != 0) setMinAndMax(min_cy3,max_cy3); //Cy3
				else if (indexOf(channel, "Cy3.5") > -1 && min_cy35 != 0 && max_cy35 != 0) setMinAndMax(min_cy35,max_cy35); //Cy3.5
				else if (indexOf(channel, "Cy5.5") > -1 && min_cy55 != 0 && max_cy55 != 0) setMinAndMax(min_cy55,max_cy55); //Cy5.5
				else if (indexOf(channel, "FITC") > -1 && min_fitc != 0 && max_fitc != 0) setMinAndMax(min_fitc,max_fitc); //FITC
				else if (indexOf(channel, "DAPI") > -1 && min_dapi != 0 && max_dapi != 0) setMinAndMax(min_dapi,max_dapi); //DAPI
				//Semi-Manual or Auto
				if (indexOf(channel, "= Cy3") > -1 && (min_cy3 == 0 || max_cy3 == 0)){
					run("Enhance Contrast", "saturated=0.01"); //Cy3
					getMinAndMax(temp_min,temp_max);
					if (min_cy3 == 0) setMinAndMax(temp_min,max_cy3); //Cy3
					else if (max_cy3 ==0) setMinAndMax(min_cy3, temp_max);
					}
				else if (indexOf(channel, "Cy3.5") > -1 && (min_cy35 == 0 || max_cy35 == 0)){
					run("Enhance Contrast", "saturated=0.01"); //Cy3.5
					getMinAndMax(temp_min,temp_max);
					if (min_cy35 == 0) setMinAndMax(temp_min,max_cy35); //Cy3.5
					else if (max_cy35 ==0) setMinAndMax(min_cy35, temp_max);
					}
				else if (indexOf(channel, "Cy5.5") > -1 && (min_cy55 == 0 || max_cy55 == 0)){
					run("Enhance Contrast", "saturated=0.01"); //Cy5.5
					getMinAndMax(temp_min,temp_max);
					if (min_cy55 == 0) setMinAndMax(temp_min,max_cy55); //Cy5.5
					else if (max_cy55 ==0) setMinAndMax(min_cy55, temp_max);
					}
				else if (indexOf(channel, "FITC") > -1 && (min_fitc == 0 || max_fitc == 0)){
					run("Enhance Contrast", "saturated=0.001"); //fitc
					getMinAndMax(temp_min,temp_max);
					if (min_fitc == 0) setMinAndMax(temp_min,max_fitc); //fitc
					else if (max_fitc ==0) setMinAndMax(min_fitc, temp_max);
					}
				else if (indexOf(channel, "DAPI") > -1 && (min_dapi == 0 || max_dapi == 0)){
					run("Enhance Contrast", "saturated=1.0"); //dapi
					getMinAndMax(temp_min,temp_max);
					if (min_dapi == 0) setMinAndMax(temp_min,max_dapi); //dapi
					else if (max_dapi ==0) setMinAndMax(min_dapi, temp_max);
					}
				}
				
			setMetadata("Info", channel);
			save(inBase + "Out-Pictures\\16bit\\" + filename + ".tif"); //save as 16bit tif in the appropriate subfolder
			if (len == 2) {
				if (indexOf(channel, "DAPI") > -1) file3 = "c3=[MAX_" + fileset[n] + "] ";//DAPI; Blue
				else file5 = "c4=[MAX_" + fileset[n] + "]";//Other channel; Grey
				}
			else if (len > 2) {
				//Color Merge stuff
				if (indexOf(channel, "Cy5.5") > -1) file1 = "c1=[MAX_" + fileset[n] + "] ";//Cy5.5; Red
				if (indexOf(channel, "FITC") > -1) file2 = "c2=[MAX_" + fileset[n] + "] ";//FITC; Green
				if (indexOf(channel, "DAPI") > -1) file3 = "c3=[MAX_" + fileset[n] + "] ";//DAPI; Blue
				if (indexOf(channel, "= Cy3") > -1) file7 = "c7=[MAX_" + fileset[n] + "]";//Cy3; Yellow
				if (indexOf(channel, "Cy3.5") > -1) file5 = "c5=[MAX_" + fileset[n] + "] ";//Cy3.5; Cyan (Note: c4 is grey, c6 is magenta)
				}
			else if (len == 1) {
				print("Single Channel Detected");
				file5 = "c4=[MAX_" + fileset[n] + "]";
				}
			else exit("Something bad happened... Go talk to Trevor"); //fileset is empty
			}//End of for loop
		name_set = set;
		}
	else if (endsWith(fileset[0], ".tif") == true) { //for .tif files
		for (n = 0; n < len; n++) { //Loop through the fileset names
			path = inBase + fileset[n]; //Full path name
			filename_tif = substring(fileset[n], 19); //Removes the folder parts
			print("File: " + filename_tif);
			open(path);
			channel = getMetadata();
			if (separatelut == false) {
				if (indexOf(channel, "DAPI") == -1 && pretty == true) run("Enhance Contrast", "saturated=0.01"); //Makes the channel thats not DAPI look pretty if that's what the user wanted
				else if (indexOf(channel, "FITC") > -1 && pretty == true) run("Enhance Contrast", "saturated=0.001"); //Makes the FITC channel look pretty if that's what the user wanted
				else if (indexOf(channel, "DAPI") == -1 && pretty == false && (min == 0 || max == 0)) {
					run("Enhance Contrast", "saturated=0.01");
					getMinAndMax(temp_min,temp_max);
					if (min == 0) setMinAndMax(temp_min,max);
					else if (max ==0 ) setMinAndMax(min,temp_max);
					} //if not DAPI and not pretty and either
				else run("Enhance Contrast", "saturated=1.0"); //if DAPI then auto enhance
				}
			else {
				//Manual
				if (indexOf(channel, "= Cy3") > -1 && min_cy3 != 0 && max_cy3 != 0) setMinAndMax(min_cy3,max_cy3); //Cy3
				else if (indexOf(channel, "Cy3.5") > -1 && min_cy35 != 0 && max_cy35 != 0) setMinAndMax(min_cy35,max_cy35); //Cy3.5
				else if (indexOf(channel, "Cy5.5") > -1 && min_cy55 != 0 && max_cy55 != 0) setMinAndMax(min_cy55,max_cy55); //Cy5.5
				else if (indexOf(channel, "FITC") > -1 && min_fitc != 0 && max_fitc != 0) setMinAndMax(min_fitc,max_fitc); //FITC
				else if (indexOf(channel, "DAPI") > -1 && min_dapi != 0 && max_dapi != 0) setMinAndMax(min_dapi,max_dapi); //DAPI
				//Semi-Manual
				if (indexOf(channel, "= Cy3") > -1 && (min_cy3 == 0 || max_cy3 == 0)){
					run("Enhance Contrast", "saturated=0.01"); //Cy3
					getMinAndMax(temp_min,temp_max);
					if (min_cy3 == 0) setMinAndMax(temp_min,max_cy3); //Cy3
					else if (max_cy3 ==0) setMinAndMax(min_cy3, temp_max);
					}
				else if (indexOf(channel, "Cy3.5") > -1 && (min_cy35 == 0 || max_cy35 == 0)){
					run("Enhance Contrast", "saturated=0.01"); //Cy3.5
					getMinAndMax(temp_min,temp_max);
					if (min_cy35 == 0) setMinAndMax(temp_min,max_cy35); //Cy3.5
					else if (max_cy35 ==0) setMinAndMax(min_cy35, temp_max);
					}
				else if (indexOf(channel, "Cy5.5") > -1 && (min_cy55 == 0 || max_cy55 == 0)){
					run("Enhance Contrast", "saturated=0.01"); //Cy5.5
					getMinAndMax(temp_min,temp_max);
					if (min_cy55 == 0) setMinAndMax(temp_min,max_cy55); //Cy5.5
					else if (max_cy55 ==0) setMinAndMax(min_cy55, temp_max);
					}
				else if (indexOf(channel, "FITC") > -1 && (min_fitc == 0 || max_fitc == 0)){
					run("Enhance Contrast", "saturated=0.001"); //fitc
					getMinAndMax(temp_min,temp_max);
					if (min_fitc == 0) setMinAndMax(temp_min,max_fitc); //fitc
					else if (max_fitc ==0) setMinAndMax(min_fitc, temp_max);
					}
				else if (indexOf(channel, "DAPI") > -1 && (min_dapi == 0 || max_dapi == 0)){
					run("Enhance Contrast", "saturated=1.0"); //dapi
					getMinAndMax(temp_min,temp_max);
					if (min_dapi == 0) setMinAndMax(temp_min,max_dapi); //dapi
					else if (max_dapi ==0) setMinAndMax(min_dapi, temp_max);
					}
				}
			if (len == 2) {
				if (indexOf(channel, "DAPI") > -1) file3 = "c3=[" + filename_tif + "] ";//DAPI; Blue
				else file5 = "c4=[" + filename_tif + "]";//Other channel; Grey
				}
			else if (len > 2) {
				//Color Merge stuff
				if (indexOf(channel, "Cy5.5") > -1) file1 = "c1=[" + filename_tif + "] ";//Cy5.5; Red
				if (indexOf(channel, "FITC") > -1) file2 = "c2=[" + filename_tif + "] ";//FITC; Green
				if (indexOf(channel, "DAPI") > -1) file3 = "c3=[" + filename_tif + "] ";//DAPI; Blue
				if (indexOf(channel, "= Cy3") > -1) file7 = "c7=[" + filename_tif + "]";//Cy3; Yellow
				if (indexOf(channel, "Cy3.5") > -1) file5 = "c5=[" + filename_tif + "] ";//Cy3.5; Cyan (Note: c4 is grey, c6 is magenta)
				}
			else if (len == 1) {
				print("Single Channel Detected");
				file5 = "c4=[" + filename_tif + "]";
				}
			else exit("Something bad happened... Go talk to Trevor"); //fileset is empty
			} //End of for loop
		name_end = indexOf(set, ".tif");
		if (name_end == -1) name_end = lengthOf(set);
		name_set = substring(set, 19, name_end);
		}
	
	if (stack == false) {
		merge = file1 + file2 + file3 + file5 + file7 + " create"; //add up the channels that were found
		run("Merge Channels...", merge); //MERGE!
		run("RGB Color"); //Change to rgb color file
		stackname = "RGB-";
		}
	else if (stack == true) {
		run("Images to Stack", "name=Stack title=[] use");
		stackname =  "Stack-";
		}
	save(outBase + name_set + "-" + stackname + "Set" + k + ".tif"); //save
	run("Close All");
	run("Collect Garbage");
	}//End of function


print("-- Done --");
showStatus("Finished.");
} //end of macro