# ObjectiveAvro

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](http://cocoapod-badges.herokuapp.com/v/ObjectiveAvro/badge.png)](http://cocoadocs.org/docsets/ObjectiveAvro)
[![Platform](http://cocoapod-badges.herokuapp.com/p/ObjectiveAvro/badge.png)](http://cocoadocs.org/docsets/ObjectiveAvro)

## What is ObjectiveAvro?

**ObjectiveAvro** is a wrapper on [Avro-C](http://avro.apache.org/docs/current/api/c/index.html), following the API conventions of Foundation's `NSJSONSerialization` class.

## But what is this Avro thing?

From [Avro Documentation](http://avro.apache.org/docs/current/):

> Apache Avro™ is a data serialization system.

> Avro provides:

>    - Rich data structures.
>    - A compact, fast, binary data format.
>    - A container file, to store persistent data.
>    - Remote procedure call (RPC).
>    - Simple integration with dynamic languages. Code generation is not required to read or write data files nor to use or implement RPC protocols. Code generation as an optional optimization, only worth implementing for statically typed languages.

Basically, you can serialize data to a fast and compact binary format (which is very handy on a mobile device!). However, there isn't an official API for Objective-C, only C, C++, C#, Java and Python. **ObjectiveAvro** is the midfield between your Objective-C code and [Avro-C](http://avro.apache.org/docs/current/api/c/index.html).

## Usage Examples

### Registering schemas

Avro works with [schemas](http://avro.apache.org/docs/current/index.html#schemas). Before using `OAVAvroSerialization` to serialize objects, you must register the schemas you'll use.

```objective-c
NSString *schema = @"{\"type\":\"record\",\"name\":\"Person\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"country\",\"type\":\"string\"},{\"name\":\"age\",\"type\":\"int\"}]}";

OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
NSError *error;
BOOL result = [avro registerSchema:schema error:&error];
```    

### Transforming JSON to NSData

Note that this `NSData` will be an `Avro` *fragment*, rather than a full `Avro` *file*. This is great for many uses, but it means that the receiver will need to have the same schema used to generate the data.
```objective-c
NSError *error;
NSDictionary *dict = @{@"name": @"Marcelo Fabri", @"country": @"Brazil", @"age": @20};
NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"Person" error:&error];
```

### Transforming NSData to JSON

```objective-c
NSError *error;
NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"marcelo" ofType:@"avro"]];
NSData *data = [avro JSONObjectFromData:data forSchemaNamed:@"Person" error:&error];
```

### Serializing to Disk (Including Schema)

This method of serialization encodes the schema along with the data, resulting in a complete `Avro` file that can be distributed and interpreted without a schema alongside.
```objective-c
[avro writeJSONObjects:@[dict]
    toFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"marcelo_with_schema.avro"]
    forSchemaNamed:@"Person" error:&error];
```

### Serializing Over Time

```objective-c
OAVFileWriterToken token = [avro startFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"marcelo_with_schema.avro"]
    forSchemaNamed:@"People" error:&error];
[avro writeJSONObjects:@[dict] toWriter:token forSchemaNamed:@"People" error:&error]
[avro closeFile:token];
// file is now valid and ready for processing
…
token = [avro openFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"marcelo_with_schema.avro"] error:&error];
[avro writeJSONObjects:@[dict] toWriter:token forSchemaNamed:@"People" error:&error]
[avro closeFile:token];
// file is again valid, with additional data
```

## Requirements

**ObjectiveAvro** requires Xcode 5, targeting either iOS 8.0 and above, or Mac OS 10.8 Mountain Lion ([64-bit with modern Cocoa runtime](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtVersionsPlatforms.html)) and above.

**ObjectiveAvro** also requires [Avro-C](http://avro.apache.org/docs/current/api/c/index.html), which is automatically imported when using [CocoaPods](http://cocoapods.org). It uses an old version, which is included in the release.

## Installation

**ObjectiveAvro** is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:
```
    pod "ObjectiveAvro"
```
Note that because of Cocoapod's magic, this may end up with an incompatible version of `Avro-C`. Try it and let us know.

#### Carthage (iOS 8+, OS X 10.9+)

You can use [Carthage](https://github.com/Carthage/Carthage) to install **ObjectiveAvro** by adding it to your `Cartfile`:

```
github "Mindstronghealth/ObjectiveAvro"
```


## Testing

To run the testing project; clone the repo, and run `pod install` from the Example directory first. You can run the unit tests by pressing `CMD + U` on Xcode.
Tests are done with `XCTest` and [`Expecta`](https://github.com/specta/expecta).

## Known limitations

- Currently, only the following types are supported: `string`, `float`, `double`, `int`, `long`, `boolean`, `null`, `bytes`, `array`, `map`, `union` and `record`. That means that `enum` and `fixed` **are not** currently supported. Although the library knows how to write complete `Avro` files, it does not yet know how to read them. (Any of these would make excellent self-contained beginner tasks.)

## Author

Marcelo Fabri, me@marcelofabri.com

## License

**ObjectiveAvro** is available under the MIT license. See the LICENSE file for more info.

