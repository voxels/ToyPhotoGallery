import json,httplib,os
start_path = './converted/' # current directory
connection = httplib.HTTPConnection('<IP_ADDRESS>', 80)

for path,dirs,files in os.walk(start_path):
	for filename in files:
		name = filename
		thumbnailURLString = "https://s3.amazonaws.com/com-federalforge-repository/public/resources/thumbnails/" + filename
		fileURLString = "https://s3.amazonaws.com/com-federalforge-repository/public/resources/converted/" + filename
		connection.connect()
		connection.request('POST', '/parse/classes/Resource', json.dumps({"filename":name,
			"thumbnailURLString":thumbnailURLString,
			"fileURLString":fileURLString}), {
		       "X-Parse-Application-Id": "<APPLICATION_ID>",
		       "Content-Type": "application/json"
		     })
		results = json.loads(connection.getresponse().read())
		print(results)
