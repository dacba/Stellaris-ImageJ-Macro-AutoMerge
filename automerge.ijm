macro "NEW Macro 3.0... [r]" {
/*
Based off of Trevor's NEW Macro

Output:
	Metadata text file in Out\Metadata\
	16bit tiff's of Z-stack images, adjusted, in Out\16bit\
	Merged RGB sets in Out\

Changelog:
	3.0 - Start:12/17/14 Completed:12/23/14
		Complete Re-write of Trevor's NEW Macro (too much to keep track of)
		Gathers X and Y values of each image
		Grabs the list of file names that have the same x and y values
		Merges those files
	3.1 - 1/5/15
		Added a few checks for errors
		Added a estimate time remaining for image merging
*/ 



//Default Variables
min = 0;
max = 0;
pretty = false;
inc = 1;
group = false;
stack = false;

//Dialog
Dialog.create("ND2 PROCESSOR");

Dialog.addMessage("Probe Min Max\n");
Dialog.addNumber("min:", 700);
Dialog.addNumber("max:", 1300);
Dialog.addCheckbox("Auto Min Max", true);
Dialog.addCheckbox("Stack Images", false);
Dialog.show();

//Retrieve Choices
min = Dialog.getNumber();
max = Dialog.getNumber();
pretty = Dialog.getCheckbox();
stack = Dialog.getCheckbox();

//Initialize 
requires("1.39u");
setBatchMode(true);
run("Bio-Formats Macro Extensions");
inDir = getDirectory("Choose Directory Containing .ND2 Files ");
outDir = inDir + "Out-Pictures\\";
File.makeDirectory(outDir);
File.makeDirectory(outDir + "16bit\\");
File.makeDirectory(outDir + "Metadata\\");
run("Close All");
run("Clear Results");
print("\\Clear"); //Clear log window

//Primary Function Calls
xy(inDir, outDir, ""); //Fill result table with x and y values for all files
start_time = getTime();
total_results = nResults;
for (k = 0; nResults > 0; k++) {
	fileset = newArray();
	print("Set " + k);
	fileset = match(fileset);
	//Array.print(fileset); //Debug
	set = setname(fileset);
	main(inDir, outDir, fileset);
	if (nResults > 0) {
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

function xy(inBase, outBase, sub) { //Iterates through file system and finds x and y values
	list = getFileList(inBase + sub);
	for (i = 0; i < list.length; i++) {
		path = sub + list[i];
		if (endsWith(path, "/") && indexOf(path, "Out") == -1) {
			xy(inBase, outBase, path); //Recursion
			}
		else if (indexOf(path, "Out") == -1 && endsWith(path, ".nd2") == true) {
			strip = replace(substring(path, 0, indexOf(path, ".nd2")), "/", "_");
			run("Bio-Formats Importer", "open=[" + inBase + path + "] display_metadata view=[Metadata only]");
			wait(50);
			saveAs("Text", outBase + "Metadata\\" + strip + ".txt");
			run("Close");
			info = File.openAsString(outBase + "Metadata\\" + strip + ".txt");
			xpos = indexOf(info, "dXPos") + 6;
			ypos = indexOf(info, "dYPos") + 6;
			setResult("Label", nResults, sub + list[i]);
			setResult("X", nResults - 1, substring(info, xpos, ypos - 7));
			setResult("Y", nResults - 1, substring(info, ypos, indexOf(info, "dZ") - 1));
			updateResults();
			}
		}
	}

function match(fileset) { //Returns an array of the paths of a set, and deletes the entries in the results table
	xtemp = getResult("X", 0);
	ytemp = getResult("Y", 0);
	updateResults();
	for (i = 0; i < nResults; i++) {
		if (xtemp == getResult("X", i) && ytemp == getResult("Y", i)) {
			fileset = Array.concat(fileset, getResultLabel(i));
			IJ.deleteRows(i, i);
			i--;
			}
		}
	return fileset;
	}

function setname(fileset) { //Returns a set name (begins with "-")
	len = lengthOf(fileset[0]);
	p = lengthOf(fileset);
	q = 1;
	for (n = 0; n < len; n++) { //For the length of the first file take the first len - n characters
		sub = substring(fileset[0], 0, len - n);
		//print("Sub is " + sub); //Debug
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

function main(inBase, outBase, fileset) {
	len = lengthOf(fileset);
	merge = "";
	file1 = "";
	file2 = "";
	file3 = "";
	file5 = "";
	file7 = "";
	for (n = 0; n < len; n++) {//Loop through the fileset names
		path = inBase + fileset[n]; //Full path name
		filename = replace(substring(fileset[n], 0, indexOf(fileset[n], ".nd2")), "/", "_"); //For saving as 16-bit, subdirectory with underscores
		print("File: " + fileset[n]);
		run("Bio-Formats Importer", "open=[" + path + "] autoscale color_mode=Grayscale view=Hyperstack");
		if (nSlices == 1) exit("This program requires unaltered .nd2 files\nPlease restart the macro and point to the unaltered .nd2 files");
		info = getImageInfo(); //Move this to xy and pass to this function
		channel = substring(info, indexOf(info, "Negate") - 6, indexOf(info, "Negate")); //Store the channel
		if (nSlices > 1) run("Z Project...", "projection=[Max Intensity]"); //Z Project
		if (indexOf(channel, "DAPI") == -1 && pretty == true) run("Enhance Contrast", "saturated=0.01"); //Makes the channel thats not DAPI look pretty if that's what the user wanted
		else if (indexOf(channel, "FITC") > -1 && pretty == true) run("Enhance Contrast", "saturated=0.001"); //Makes the FITC channel look pretty if that's what the user wanted
		else if (indexOf(channel, "DAPI") == -1 && pretty == false) setMinAndMax(min,max); //if not DAPI and not pretty then apply min max
		else run("Enhance Contrast", "saturated=1.0"); //if DAPI then auto enhance
		setMetadata("Info", channel);
		save(outBase + "16bit\\" + filename + ".tif"); //save as 16bit tif in the appropriate subfolder
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
	//waitForUser("Debug");
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
	save(outBase + set + stackname + "Set " + k + ".tif"); //save
	run("Close All");
	run("Collect Garbage");
	}//End of function


print("-- Done --");
showStatus("Finished.");
} //end of macro