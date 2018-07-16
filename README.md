# Toy Photo Gallery

- [Required Dependency Setup](#required-dependency-setup)
- [Code Examples](#code-examples)
- [Client Brief](#client-brief)

*ToyPhotoGallery* implements the design for a photo gallery transitioning into a preview view.

#### Design Goals

The design goals of the original **[v1.0](https://github.com/voxels/ToyPhotoGallery/releases/tag/v_1.0)** object map include:
- Provide abstract protocols for common services so that libraries can be swapped if needed
- Hide API interfaces behind model controllers
- Provide launch safety for reachability or other issues
- Provide thread safe access to network fetching and local storage
- Provide robust non-fatal error handling for debugging
- Use the Model View View Model design pattern
- Use abstract models within model controllers so that content can be expanded without rearchitecture
- Offer the ability to swap out views as much as possible
- Provide convenience structures for configuring requests and appearances

A description of the **[v1.0](https://github.com/voxels/ToyPhotoGallery/releases/tag/v_1.0)** object graph diagram below can be found at [voxels.github.io](https://voxels.github.io/codesamples_toyphotogallery_diagram)

![Diagram](https://s3.amazonaws.com/com-federalforge-repository/public/resources/originals/ToyPhotoGallery_ObjectGraphDiagram.png)

[Version 1.1](https://github.com/voxels/ToyPhotoGallery/releases/tag/v_1.1) has a slightly improved object graph from the one diagramed above.  Model objects have been simplified for handling images.

More detail about the examples of [techniques](#code-examples) is offered in the section below.

```


```

---

## Required Dependency Setup

*ToyPhotoGallery* requires [Carthage](https://github.com/Carthage/Carthage)) for a run script build phase that copies in the frameworks for [Bugsnag](https://www.bugsnag.com) and [Parse](http://parseplatform.org).  Carthage is a lightweight alternative to [Cocoapods](https://cocoapods.org).  Carthage can be installed with [Homebrew](https://brew.sh).  In order to compile the project on a machine that does not have Carthage installed, follow the steps below:

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

**NOTE:** At the time of writing, the **FBSDKIntegrationTests** are **misconfigured** for building in Carthage.  If checking out the framework dependencies source again, remove the dependency from the *FacebookSDK.xcworkspace* schemes to pass through the build.

### Backend Setup

This project requires setting up a back end to serve images.  [Parse](http://parseplatform.org) was chosen as the remote store API because it's relatively easy to configure.  The sections below describe how content was generated and installed into the Parse instance, located on an [AWS](https://aws.amazon.com) box.

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
1) Setup an [S3](https://aws.amazon.com/free/storage/?sc_channel=PS&sc_campaign=acquisition_US&sc_publisher=google&sc_medium=ACQ-P%7CPS-GO%7CBrand%7CSU%7CStorage%7CS3%7CUS%7CEN%7CText&sc_content=s3_e&sc_detail=aws%20s3&sc_category=s3&sc_segment=278699799512&sc_matchtype=e&sc_country=US&s_kwcid=AL!4422!3!278699799512!e!!g!!aws%20s3&ef_id=W0IR5gAAAeKB3yeM:20180708133014:s) bucket on AWS
2) Synchronize thumbnails and full-res folders to the bucket using 
```
aws s3 sync ./resources s3://<BUCKET_NAME>/path/to/resources
```

#### Parse Server Setup

1) Setup a Parse service on AWS using [Bitnami](https://aws.amazon.com/marketplace/pp/B01BLQ17TO?qid=1531056576513&sr=0-2&ref_=srh_res_product_title) or something else
2) SSH into the box and grab the application ID from /apps/parse/htdocs/server.js
3) Create the classes and columns for Resource tables
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
7) Set the ACL for the Resource classes to 'public>read', 'administrator>read+write'
8) [Configure](https://docs.bitnami.com/aws/apps/parse/#how-to-enable-https-support-with-ssl-certificates) for HTTPS if necessary


```


```

---

## Code Examples

*ToyPhotoGallery* includes code that demonstrates the following techniques:

### Unit Testing

**ImageRepositoryTests.swift** *[Line 33 - 55](https://github.com/voxels/ToyPhotoGallery/blob/5a09509a8c6623cced2e3af6819915021b10b803/src/ToyPhotoGallery/ToyPhotoGalleryTests/ImageRepositoryTests.swift#L33-L55)*
```
func testExtractImageResourcesExtractsExpectedEntries() {
    let waitExpectation = expectation(description: "Wait for completion")
    
    let rawResourceArray = [ImageRepositoryTests.imageResourceRawObject]
    ImageResource.extractImageResources(from: rawResourceArray) { (repository, errors) in
        if let errors = errors, errors.count > 0 {
            XCTFail("Found unexpected errors")
            return
        }
        
        guard let first = repository.map.first else {
            XCTFail("Did not find expected resource")
            return
        }
        
        XCTAssertEqual(first.key, ImageRepositoryTests.imageResourceRawObject["objectId"] as! String)
        
        waitExpectation.fulfill()
    }
    
    let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
    XCTAssertTrue(actual)
}
```

### Inline Documentation

**ResourceModelController.swift** *[Line 110 - 119](https://github.com/voxels/ToyPhotoGallery/blob/88ef1e7a6334b56f3445777e841254ea90e4867c/src/ToyPhotoGallery/ToyPhotoGallery/Model/Resource/ResourceModelController.swift#L110-L119)*
```
/**
 Checks the existing number of resources in the repository and fills in entries for indexes between the skip and limit, if necessary
 - parameter repository: the *Repository* that needs to be filled
 - parameter skip: the number of items to skip when finding new resources
 - parameter limit: the number of items we want to fetch
 - parameter timeoutDuration:  the *TimeInterval* to wait before timing out the request
 - parameter completion: a callback used to pass back the filled repository
 - Throws: Throws any error surfaced from *tableMap*
 - Returns: void
 */
```

### API Key Obfuscation

**LaunchController.swift** *[Line 88](https://github.com/voxels/ToyPhotoGallery/blob/3f600d85db70ea4b880059e09e2e1f550f5ed393/src/ToyPhotoGallery/ToyPhotoGallery/Model/Launch/LaunchController.swift#L88)*
```
try service.launch(with:service.launchControlKey?.decoded(), with:center)

```

### Launch Control with DispatchGroup

**ResourceModelController.swift** *[Line 67 - 97](https://github.com/voxels/ToyPhotoGallery/blob/master/src/ToyPhotoGallery/ToyPhotoGallery/Model/Resource/ResourceModelController.swift#L77-L97)*
```
do {
    try strongSelf.fill(repository: strongSelf.imageRepository, skip: 0, limit: strongSelf.remoteStoreController.defaultQuerySize, timeoutDuration:timeoutDuration, on:queue, completion:{ [weak self] (repository) in
	guard let strongSelf = self else {
	    return
	}

	let writeQueue = DispatchQueue(label: "\(strongSelf.writeQueueLabel)")
	writeQueue.async { [weak self] in
	    self?.imageRepository = repository
	    DispatchQueue.main.async { [weak self] in
		self?.delegate?.didUpdateModel()
	    }
	}
    })
}
catch {
    errorHandler.report(error)
    DispatchQueue.main.async { [weak self] in
	self?.delegate?.didFailToUpdateModel(with: error.localizedDescription)
    }
}
```

### Remote Store

**ParseInterface.swift** *[Line 77 - 99](https://github.com/voxels/ToyPhotoGallery/blob/59e42825380eab5c435223a256f49f64277d65ef/src/ToyPhotoGallery/ToyPhotoGallery/Model/RemoteStore/Parse/ParseInterface.swift#L77-L99)*
```
    /**
     Finds the objects in the given schemaClass, sorted by the given String, with the expected fetch skip and limit constants.  Calls a completion block when completed
     - parameter table: a *RemoteStoreTable* table that should be queried on the remote store
     - parameter sortBy: the *String* of the column name to sort by, or nil if no sorting is needed
     - parameter skip: an *Int* of the number of records to skip in the query
     - parameter limit: an *Int* of the limit of the number of records returned by the query
     - parameter queue: The *DispatchQueue* we need to call the completion block on
     - parameter errorHandler: The *ErrorHandlerDelegate* that will report the error
     - parameter completion: the *FindCompletion* callback executed when the query is complete
     - Returns: void
     */
    func find(table: RemoteStoreTableMap, sortBy: String?, skip: Int, limit: Int, on queue:DispatchQueue, errorHandler: ErrorHandlerDelegate, completion: @escaping RawResourceArrayCompletion) {
        
        let wrappedCompletion = parseFindCompletion(with:errorHandler, for: completion)
        
        do {
            let pfQuery = try query(for: table, sortBy: sortBy, skip: skip, limit: limit)
            find(query: pfQuery, on:queue, completion: wrappedCompletion)
        } catch {
            errorHandler.report(error)
            completion(RawResourceArray())
        }
    }
```

### Non-Fatal Error Handling

**Extractor.swift** *[Line 12 - 33](https://github.com/voxels/ToyPhotoGallery/blob/708babee8965af46330edf01906458a570c1307c/src/ToyPhotoGallery/ToyPhotoGallery/Model/Utility/Extractor.swift#L12-L33)*
```
static func extractValue<T>(named key:String, from dictionary:[String:AnyObject]) throws -> T {
    
    guard var value = dictionary[key] else {
        if key == RemoteStoreTableMap.CommonColumn.objectId.rawValue {
            throw ModelError.EmptyObjectId
        } else {
            throw ModelError.MissingValue
        }
    }
    
    // We need to convert the string to an URL type
    if T.self is URL.Type{
        value = try Extractor.constructURL(from: value) as AnyObject
    }
    
    // We need to make sure we have the type of variable we expect to have
    guard let castValue = value as? T else {
        throw ModelError.IncorrectType
    }
    
    return castValue
}
```

### URLSession

**NetworkSesionInterface** *[Line 53 - 81](https://github.com/voxels/ToyPhotoGallery/blob/88ef1e7a6334b56f3445777e841254ea90e4867c/src/ToyPhotoGallery/ToyPhotoGallery/Network/NetworkSessionInterface.swift#L53-L81)*
```
func fetch(url:URL, with session:URLSession? = nil, completion:@escaping (Data?)->Void) {
    // Using a default session here may crash because of a potential bug in Foundation.
    // Ephemeral and Shared sessions don't crash.
    // See: https://forums.developer.apple.com/thread/66874
    
    if NetworkSessionInterface.isAWS(url: url), let filename = filename(for: url) {
        fetchWithAWS(filename: filename, completion: completion)
        return
    }
    
    let useSession = session != nil ? session : FeaturePolice.networkInterfaceUsesEphemeralSession ? URLSession(configuration: .ephemeral) : URLSession(configuration: .default)
    
    let taskCompletion:((Data?, URLResponse?, Error?) -> Void) = { [weak self] (data, response, error) in
        if let e = error {
            self?.errorHandler.report(e)
            completion(nil)
            return
        }
        
        completion(data)
    }
    
    guard let task = useSession?.dataTask(with: url, completionHandler: taskCompletion) else {
        completion(nil)
        return
    }
    
    task.resume()
}
```

### Collection View Flow Layout Customization

**GalleryCollectionViewLayout.swift** *[Line 100 - 110](https://github.com/voxels/ToyPhotoGallery/blob/88ef1e7a6334b56f3445777e841254ea90e4867c/src/ToyPhotoGallery/ToyPhotoGallery/View/Gallery/GalleryCollectionViewLayout.swift#L100-L110)*
```
func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    var relativeSize = CGSize.zero
    
    guard let configuration = configuration, let delegate = sizeDelegate else {
        return relativeSize
    }
    
    relativeSize = delegate.sizeForItemAt(indexPath: indexPath, layout:self, currentConfiguration: configuration)
    
    return relativeSize
}
```

### Manual Auto Layout

**GalleryViewController.swift** *[Line 253 - 267](https://github.com/voxels/ToyPhotoGallery/blob/88ef1e7a6334b56f3445777e841254ea90e4867c/src/ToyPhotoGallery/ToyPhotoGallery/View/Gallery/GalleryViewController.swift#L253-L267)*
```
override func updateViewConstraints() {
        if customConstraints.count > 0 {
            NSLayoutConstraint.deactivate(customConstraints)
            view.removeConstraints(customConstraints)
        }
        
        customConstraints.removeAll()
        
        if let currentCollectionView = collectionView, let collectionViewConstraints = constraints(for: currentCollectionView) {
            customConstraints.append(contentsOf: collectionViewConstraints)
        }
        
        NSLayoutConstraint.activate(customConstraints)
        super.updateViewConstraints()
    }
```

### Generic Protocols

**ImageRespository.swift** *[Line 13 - 19](https://github.com/voxels/ToyPhotoGallery/blob/88ef1e7a6334b56f3445777e841254ea90e4867c/src/ToyPhotoGallery/ToyPhotoGallery/Model/Repository/ImageRepository.swift#L13-L19)*
```
/// Implementation of the *Repository* protocol for images
class ImageRepository : Repository {
    typealias AssociatedType = ImageResource
    
    /// A map of image resources 
    var map: [String : ImageResource] = [:]
}
```

### Template Functions

**ResourceModelController.swift** *[Line 255 - 266](https://github.com/voxels/ToyPhotoGallery/blob/88ef1e7a6334b56f3445777e841254ea90e4867c/src/ToyPhotoGallery/ToyPhotoGallery/Model/Resource/ResourceModelController.swift#L255-L266)*
```
func sort<T>(repository:T, skip:Int, limit:Int, completion:@escaping ([T.AssociatedType])->Void) where T:Repository, T.AssociatedType:Resource {
    let queue = DispatchQueue(label: "\(readQueueLabel).sort")
    queue.async {
        let values = Array(repository.map.values).sorted { $0.updatedAt > $1.updatedAt }
        let endSlice = skip + limit < values.count ? skip + limit : values.count
        let resources = Array(values[skip..<(endSlice)])
        DispatchQueue.main.async {
            completion(resources)
        }
    }
}
```

### Dispatch Queues and Operation Queues

**ResourceModelController+GalleryCollectionViewModelDelegate** *[Line 25 - 66](https://github.com/voxels/ToyPhotoGallery/blob/4302b56a9c2d04f1c6474081a34f74c44f8c3464/src/ToyPhotoGallery/ToyPhotoGallery/Model/Resource/ResourceModelController%2BGalleryCollectionViewModelDelegate.swift#L25-L66)*
```
func imageResources(skip: Int, limit: Int, timeoutDuration:TimeInterval = ResourceModelController.defaultTimeout, completion:ImageResourceCompletion?) -> Void {
    // We need to make sure we don't skip fetching any images for this purpose
    let readQueue = DispatchQueue(label: readQueueLabel)
    var checkCount = 0
    readQueue.sync { checkCount = imageRepository.map.values.count }
    let finalSkip = skip > checkCount ? checkCount : skip
    
    // We also need to make sure we still get the requested number of images
    let finalLimit = abs(finalSkip - skip) + limit
    
    // FillAndSort returns on the main queue but we are doing this for safety
    let wrappedCompletion:([Resource])->Void = {[weak self] (sortedResources) in
        guard let imageResources = sortedResources as? [ImageResource] else {
            self?.errorHandler.report(ModelError.IncorrectType)
            DispatchQueue.main.async {
                self?.delegate?.didFailToUpdateModel(with: ModelError.IncorrectType.errorDescription)
                completion?([ImageResource]())
            }
            return
        }
        
        DispatchQueue.main.async {
            self?.delegate?.didUpdateModel()
            completion?(imageResources)
        }
    }
    
    var copyImageRepository = ImageRepository()
    readQueue.sync {
        copyImageRepository = imageRepository
        do {
            try fillAndSort(repository: copyImageRepository, skip: finalSkip, limit: finalLimit, timeoutDuration:timeoutDuration, completion: wrappedCompletion)
        } catch {
            errorHandler.report(error)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didFailToUpdateModel(with: error.localizedDescription)
                completion?([ImageResource]())
            }
        }
    }
}
```

### Delegation

**GalleryCollectionViewModel.swift** *[Line 11 - 17](https://github.com/voxels/ToyPhotoGallery/blob/4302b56a9c2d04f1c6474081a34f74c44f8c3464/src/ToyPhotoGallery/ToyPhotoGallery/Model/Resource/ResourceModelController%2BGalleryCollectionViewModelDelegate.swift#L25-L66)*
```
/// Protocol to fetch the image resources for the model and get an error handler if necessary
protocol GalleryCollectionViewModelDelegate : class {
    var networkSessionInterface:NetworkSessionInterface { get }
    var errorHandler:ErrorHandlerDelegate { get }
    var timeoutDuration:TimeInterval { get }
    func imageResources(skip: Int, limit: Int, timeoutDuration:TimeInterval, completion:ImageResourceCompletion?)
}
```

---

## Client Brief

```
You're designing a mobile photo gallery interface. 
A designer on the team delivers mockups for a grid view and detailed photo view and 
asks you to help define the transition between the two states. 

Things to think about:

How might you build a smooth transition from the grid view to the detail view?
How could you use gestures to enhance the interactivity? e.g. should users swipe to move between images?
Feel free to use any technologies, libraries, or frameworks you like to build the gallery.
The gallery should be viewable on a mobile device, and any code you produce should be clean and extensible.
```

### Questions for the designer:

- The "Image gallery" label on the gallery view appears to be in the Roboto font, however the character width is wider that the default Roboto character.  What is the intention?  Should we use an image instead of the font?
- How should the space between the icons on the preview view's toolbar shrink and grow on differently sized devices?  An assumption was made to flex the outer margins and keep the space between fixed.

