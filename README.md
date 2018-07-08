# Toy Photo Gallery

- [Required Dependency Setup](#required-dependency-setup)
- [Code Examples](code-examples)
- [Client Brief](#client-brief)

*ToyPhotoGallery* implements the design for a Google code interview that shows a photo gallery transitioning into a preview view.  All work was authored, without referencing proprietary code, during the week provided.

> video of the transition

The transition is achieved by...

In order to achieve an example reflecting a typical production application's functions, the gallery's photos are archived in a remote repository, rather than on device.  Clean UX transitions for most apps must exist within the contexts of fetching paged results, 
cacheing sized copies, securing connections, reachability, and other concerns.  

For the purpose of this exercise, given the time constraints, the model controllers are representative of the foundation needed to support common activities by a mobile application.

*ToyPhotoGallery* uses a variation of the MVVM design pattern to acheieve the gallery view controller design.  An object graph is
included below:

> description of object graph

More detail about the examples of [techniques](#code-examples) is offered in the section below.

### Additional Portfolio Documents

In addition to the code sample included in this repository, and the content located on the public [porfolio](http://voxels.github.com) site, samples of past work can be found at the following address:

[Past Work Samples]()

The zipped file above includes examples of:
- Planning documents
- Code Reviews
- White papers

```


```

---

## Required Dependency Setup

*ToyPhotoGallery* requires [Carthage](https://github.com/Carthage/Carthage#installing-carthage)) for a run script build phase that copies in the frameworks for [Bugsnag](https://www.bugsnag.com) and [Parse](http://parseplatform.org).  Carthage is a lightweight alternative to [Cocoapods](https://cocoapods.org).  Carthage can be installed with [Homebrew](https://brew.sh).  In order to compile the project on a machine that does not have Carthage installed, follow the steps below:

1) **Install Homebrew** with the follwing command in the Terminal:

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

2) **Install Carthage** with the following command in the Terminal:

```
brew install carthage
```

3) Optionally, run the following commands to update the dependencies, however this should not be necessary to get the project to build from a clean checkout:
```
carthage update --platform iOS
```

**NOTE:** At the time of writing, the FBSDKIntegrationTests are misconfigured for building in Carthage.  If checking out the framework dependencies source again, remove the dependency from the FacebookSDK.xcworkspace schemes to pass through the build.

### Backend Setup

This project requires setting up a back end to serve images.  [Parse](http://parseplatform.org) was chosen as the remote store API because it's relatively easy to configure.  The sections below describe how content was generated and installed into the Parse instance, located on an AWS box.

#### Asset Generation

1) Choose photos
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


#### Upload image assets to AWS
1) Setup an S3 bucket on AWS
2) Synchronize thumbnails and full-res folders to the bucket using 
```
aws s3 sync ./resources s3://<BUCKET_NAME>/path/to/resources
```

#### Parse Server Setup

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


```


```

---

## Code Examples

*ToyPhotoGallery* includes code that demonstrates the following techniques:

#### Unit Testing

#### Inline Documentation

#### API Key Obfuscation

#### Launch Control with Notifications

#### Remote Store

#### Non-Fatal Error Handling

#### URLSession

#### Buffered Images

#### Collection View Layout

#### Manual Auto Layout

#### Generic Protocols

#### Template Functions

#### Dispatch Queues and Operation Queues

#### Delegation


```


```

---

## Client Brief

```
You're designing a mobile photo gallery interface. 
A designer on the team delivers mockups for a grid view and detailed photo view and 
asks you to help define the transition between the two states. 
If you have additional time, you can consider secondary actions, 
such as items in the detail view toolbar.

zThings to think about:

How might you build a smooth transition from the grid view to the detail view?
How could you use gestures to enhance the interactivity? e.g. should users swipe to move between images?
Feel free to use any technologies, libraries, or frameworks you like to build the gallery.
The gallery should be viewable on a mobile device, and any code you produce should be clean and extensible.
```



