# Toy Photo Gallery

The Toy Photo Gallery implements the design for a Google code interview that shows a photo gallery which transitions into a preview view.  

## Dependencies

ToyPhotoGallery requires Carthage for a run script build phase.  Carthage can be installed with Homebrew.  In order to compile the project on a machine that does not have Carthage installed, follow the steps below:

1) Install [Homebrew](https://brew.sh) with the follwing command in the Terminal:

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

2) Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage) with the following command in the Terminal:

```
brew install carthage
```


## Instructions

```
You're designing a mobile photo gallery interface. A designer on the team delivers mockups for a grid view and detailed photo view and asks you to help define the transition between the two states. If you have additional time, you can consider secondary actions, such as items in the detail view toolbar.
Things to think about:

How might you build a smooth transition from the grid view to the detail view?
How could you use gestures to enhance the interactivity? e.g. should users swipe to move between images?
Feel free to use any technologies, libraries, or frameworks you like to build the gallery.
The gallery should be viewable on a mobile device, and any code you produce should be clean and extensible.

The attached zip file includes 3 mock ups and a Photoshop source file (.psd).
```

## Project Depedencies

ToyPhotoGallery relies on Carthage to add dependencies for:
- Parse 
- Bugsnag

**NOTE:** At the time of writing, the FBSDKIntegrationTests are misconfigured for building in Carthage.  Remove the dependency from the FacebookSDK.xcworkspace schemes to pass through the build.

Run the following commands to update the dependencies:
```
carthage update --platform iOS
```

Typically, the Carthage build products would not be added to the github repo via a line in the .gitignore, however, for the purposes of this project, they are included so that the project can be compiled out of the box.

## Backend Setup

This project requires setting up a back end to serve progressing JPEG images.  Parse was chosen because it's easy to configure.  The seconds below describe how content was generated and installed into a Parse instance.

### Asset Generation
1) Choose photos from iPhoto
2) Export as original size, JPG format into ./assets/originals/
3) Fetch [mozjpeg](https://github.com/kornelski/mozjpeg/releases) from Github
4) Copy and run the following shell script from ./assets/originals/

```
# Convert.sh
# Uses cjpeg (https://github.com/kornelski/mozjpeg/releases) to convert a folder of
# unmodified original images into progressive JPEG

INDEX=0
for FILENAME in *.jpg; do
	echo $FILENAME
	../cjpeg/cjpeg -quant-table 2 -quality 70 -outfile "../converted/$FILENAME" $FILENAME
done
```
5) Create thumbnails from the converted files
6) Upload folders to s3 bucket

### Create EXIF Data
1) Use the EXIFTool to export EXIF data from the images to a csv file:
```
exiftool -common -T ./ > ./exif.txt
```

### Upload image assets
1) Setup an S3 bucket on AWS
2) Synchronize thumbnails and full-res folders to the bucket using 
```
aws s3 sync ./resources s3://<BUCKET_NAME>/path/to/resources
```

### Parse Server Setup

1) Setup a Parse service on AWS using Bitnami or something else
2) SSH into the box and grab the application ID from /apps/parse/htdocs/server.js
3) Create the classes and columns for EXIF and Resource tables
4) Upload the resource links using Python:

```
import json,httplib,os
start_path = './converted/' # current directory
connection = httplib.HTTPConnection('<IP_ADDRESS>', 80)

for path,dirs,files in os.walk(start_path):
	for filename in files:
		name = filename
		thumbnailURLString = "https://s3.amazonaws.com/<AWS_BUCKET_NAME>/path/to/resources/thumbnails/" + filename
		fileURLString = "https://s3.amazonaws.com/<AWS_BUCKET_NAME>/path/to/resources/converted/" + filename
		connection.connect()
		connection.request('POST', '/parse/classes/Resource', json.dumps({"filename":name,
			"thumbnailURLString":thumbnailURLString,
			"fileURLString":fileURLString}), {
		       "X-Parse-Application-Id": "<APPLICATION_ID",
		       "Content-Type": "application/json"
		     })
		results = json.loads(connection.getresponse().read())
		print(results)
```
5) Set the **allowClientClassCreation** parse server configuration setting to FALSE
6) Create an Administrator Role and an admin user with that role
7) Set the ACL for the EXIF and Resource classes to 'public>read', 'administrator>read+write'
8) Configure for HTTPS if necessary


