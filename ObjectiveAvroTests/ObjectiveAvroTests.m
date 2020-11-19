//
//  ObjectiveAvroTests.m
//  ObjectiveAvroTests
//
//  Created by Max Zhilyaev on 11/19/20.
//  This is a copy of Example/ObjectiveAbroTests.m with some moditications
//  to remove Expecta stuff
//

#define EXP_SHORTHAND YES

#import <XCTest/XCTest.h>
#import <ObjectiveAvro/OAVAvroSerialization.h>

@interface ObjectiveAvroTests : XCTestCase

@end

@implementation ObjectiveAvroTests

#pragma mark - Private methods

+ (id)JSONObjectFromBundleResource:(NSString *)resource {
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:resource ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return dict;
}

+ (id)stringFromBundleResource:(NSString *)resource {
    NSString *path = [[NSBundle bundleForClass:self] pathForResource:resource ofType:@"json"];
    return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *) dictionaryToJsonString:(NSDictionary*)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:&error];
    XCTAssertNotNil(jsonData);
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)registerSchemas:(OAVAvroSerialization *)avro {
    NSString *personSchema = [[self class] stringFromBundleResource:@"person_schema"];
    NSString *peopleSchema = [[self class] stringFromBundleResource:@"people_schema"];

    [avro registerSchema:personSchema error:NULL];
    [avro registerSchema:peopleSchema error:NULL];
}

#pragma mark - XCTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Tests

- (void)testValidSchemaRegistration {
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];

    NSString *personSchema = [[self class] stringFromBundleResource:@"person_schema"];
    NSString *peopleSchema = [[self class] stringFromBundleResource:@"people_schema"];

    NSError *error;
    BOOL result = [avro registerSchema:personSchema error:&error];
    XCTAssert(result);
    XCTAssertNil(error);

    result = [avro registerSchema:peopleSchema error:&error];
    XCTAssert(result);
    XCTAssertNil(error);
}

- (void)testInvalidJSONSchemaRegistration {
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    NSError *error;
    BOOL result = [avro registerSchema:@"{invalid json}" error:&error];
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
}

- (void)testInvalidSchemaWithNoNameRegistration {
    NSString *schema = @"{\"type\":\"record\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"country\",\"type\":\"string\"},{\"name\":\"age\",\"type\":\"int\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    NSError *error;
    BOOL result = [avro registerSchema:schema error:&error];
    XCTAssertFalse(result);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain,NSCocoaErrorDomain);
    XCTAssertEqual(error.code,NSPropertyListReadCorruptError);
}

- (void)testAvroFileWrite {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];

    NSError *error;
    NSString *fullAvroPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"people.avro"];
    BOOL success = [avro writeJSONObjects:@[dict]
                                  toFile:fullAvroPath
                          forSchemaNamed:@"People" error:&error];
    success = [avro writeJSONObjects:@[dict]
                              toFile:fullAvroPath
                      forSchemaNamed:@"People" error:&error];

    XCTAssertNil(error);
    XCTAssertTrue(success);

    NSArray* seralization = [avro JSONObjectsFromFile:fullAvroPath error:&error];
    XCTAssertTrue(seralization.count == 1);
    // expect different, avro looking json
    NSString* expectedJson = @"{\"people\": [{\"name\": \"Marcelo Fabri\", \"country\": {\"string\": \"Brazil\"}, \"age\": 20}, {\"name\": \"Tim Cook\", \"country\": {\"string\": \"USA\"}, \"age\": 53}, {\"name\": \"Steve Wozniak\", \"country\": {\"string\": \"USA\"}, \"age\": 63}, {\"name\": \"Bill Gates\", \"country\": {\"string\": \"USA\"}, \"age\": 58}, {\"name\": \"Stateless Johnny\", \"country\": null, \"age\": 104}], \"generated_timestamp\": 1389376800000}";
    XCTAssertEqualObjects(seralization[0], expectedJson);
}

- (void)testAvroFileReopen {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];

    NSError *error;

    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"people.avro"];
    NSLog(@"writing to %@", filePath);
    OAVFileWriterToken token = [avro startFile:filePath forSchemaNamed:@"People" error:&error];
    XCTAssertNil(error);

    BOOL success = [avro writeJSONObjects:@[dict] toWriter:token
                           forSchemaNamed:@"People" error:&error];

    XCTAssertNil(error);
    XCTAssertTrue(success);

    [avro closeFile:token];

    token = [avro openFile:filePath error:&error];

    XCTAssertNil(error);

    success = [avro writeJSONObjects:@[dict] toWriter:token
                           forSchemaNamed:@"People" error:&error];

    XCTAssertNil(error);
    XCTAssertTrue(success);

    [avro closeFile:token];

    NSArray* seralization = [avro JSONObjectsFromFile:filePath error:&error];
    XCTAssertTrue(seralization.count == 2);

    for (int i=0; i < 2; i++) {
        NSString* expectedJson = @"{\"people\": [{\"name\": \"Marcelo Fabri\", \"country\": {\"string\": \"Brazil\"}, \"age\": 20}, {\"name\": \"Tim Cook\", \"country\": {\"string\": \"USA\"}, \"age\": 53}, {\"name\": \"Steve Wozniak\", \"country\": {\"string\": \"USA\"}, \"age\": 63}, {\"name\": \"Bill Gates\", \"country\": {\"string\": \"USA\"}, \"age\": 58}, {\"name\": \"Stateless Johnny\", \"country\": null, \"age\": 104}], \"generated_timestamp\": 1389376800000}";
        XCTAssertEqualObjects(seralization[0], expectedJson);

    }

}

- (void)testAvroSerialization {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];

    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(data);

    NSDictionary *fromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"People" error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(fromAvro);
}

- (void)testAvroCopy {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];

    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(data);

    OAVAvroSerialization *copy = [avro copy];
    XCTAssertNotNil(copy);
    XCTAssertNotEqualObjects(copy,avro);

    NSData *dataFromCopy = [copy dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(dataFromCopy);
    XCTAssertEqualObjects(dataFromCopy,data);
}

- (void)testAvroCoding {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];

    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];

    XCTAssertNil(error);
    XCTAssertNotNil(data);

    NSData *archivedAvroData = [NSKeyedArchiver archivedDataWithRootObject:avro];
    XCTAssertNotNil(archivedAvroData);

    OAVAvroSerialization *archivedAvro = [NSKeyedUnarchiver unarchiveObjectWithData:archivedAvroData];

    XCTAssertNotNil(archivedAvro);

    NSData *dataFromCopy = [archivedAvro dataFromJSONObject:dict
                                             forSchemaNamed:@"People" error:&error];
    
    XCTAssertEqualObjects(dataFromCopy, data);
    XCTAssertNil(error);
    XCTAssertNotNil(dataFromCopy);
    XCTAssertEqualObjects(dataFromCopy,data);
}

// we should fail, but schema validation doesn't seem to work correctly
//  @TODO - https://mindstronghealth.atlassian.net/browse/HEALTH-5227
- (void)testMissingFieldAvroSerialization {
    NSString *json = @"{\"people\":[{\"name\":\"Marcelo Fabri\"},{\"name\":\"Tim Cook\",\"country\":\"USA\",\"age\":53},{\"name\":\"Steve Wozniak\",\"country\":\"USA\",\"age\":63},{\"name\":\"Bill Gates\",\"country\":\"USA\",\"age\":58}],\"generated_timestamp\":1389376800000}";

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];

    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];

    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain,NSCocoaErrorDomain);
    XCTAssertEqual(error.code,NSPropertyListReadCorruptError);
    XCTAssertNil(data);
}

- (void)testNoSchemaRegistred {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];

    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];

    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain,NSCocoaErrorDomain);
    XCTAssertEqual(error.code,NSFileReadNoSuchFileError);
    XCTAssertNil(data);
}

#pragma mark - Type tests

- (void)testStringType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"StringTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"string_value\",\"type\":\"string\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];

    NSArray *strings = @[@"bla", @"test", @"foo", @"bar"];

    for (NSString *str in strings) {
        NSError *error;
        NSData *data = [avro dataFromJSONObject:@{@"string_value": str} forSchemaNamed:@"StringTest" error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(data);

        NSString *strFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"StringTest" error:&error][@"string_value"];

        XCTAssertNil(error);
        XCTAssertEqualObjects(strFromAvro,str);
    }
}

- (void)testIntType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"IntTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"int_value\",\"type\":\"int\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];

    NSArray *numbers = @[@2, @303, @1098, @500000, @-200, @-100001, @0];

    for (NSNumber *number in numbers) {
        NSError *error;
        NSData *data = [avro dataFromJSONObject:@{@"int_value": number} forSchemaNamed:@"IntTest" error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(data);

        NSString *numberFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"IntTest" error:&error][@"int_value"];

        XCTAssertNil(error);
        XCTAssertEqualObjects(numberFromAvro,number);
    }
}

- (void)testLongType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"LongTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"long_value\",\"type\":\"long\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];

    NSArray *numbers = @[@2, @303, @1098, @500000,  @-200, @-100001, @0, @((long) pow(2, 30)), @((long) pow(-2, 30))];

    for (NSNumber *number in numbers) {
        NSError *error;
        NSData *data = [avro dataFromJSONObject:@{@"long_value": number} forSchemaNamed:@"LongTest" error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(data);

        NSString *numberFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"LongTest" error:&error][@"long_value"];

        XCTAssertNil(error);
        XCTAssertEqualObjects(numberFromAvro,number);
    }
}

- (void)testFloatType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"FloatTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"float_value\",\"type\":\"float\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];

    NSArray *numbers = @[@2, @303, @1098, @500000, @-200, @-100001, @0, @1.43f, @100.98420f, @0.001f, @-9.7431f];

    for (NSNumber *number in numbers) {
        NSError *error;
        NSData *data = [avro dataFromJSONObject:@{@"float_value": number} forSchemaNamed:@"FloatTest" error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(data);

        NSString *numberFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"FloatTest" error:&error][@"float_value"];

        XCTAssertNil(error);
        XCTAssertEqualWithAccuracy([numberFromAvro floatValue], [number floatValue], 0.01);
    }
}

- (void)testDoubleType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"DoubleTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"double_value\",\"type\":\"double\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];

    NSArray *numbers = @[@2, @303, @1098, @500000, @-200, @-100001, @0, @1.43, @100.98420, @0.001, @-9.7431, @(DBL_MAX), @((double) pow(2.4, 20)), @(M_PI)];

    for (NSNumber *number in numbers) {
        NSError *error;
        NSData *data = [avro dataFromJSONObject:@{@"double_value": number} forSchemaNamed:@"DoubleTest" error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(data);

        NSString *numberFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"DoubleTest" error:&error][@"double_value"];

        XCTAssertNil(error);
        XCTAssertEqualObjects(numberFromAvro,number);
    }
}

- (void)testBooleanType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"BooleanTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"boolean_value\",\"type\":\"boolean\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];

    NSArray *numbers = @[@NO, @YES];

    for (NSNumber *number in numbers) {
        NSError *error;
        NSData *data = [avro dataFromJSONObject:@{@"boolean_value": number} forSchemaNamed:@"BooleanTest" error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(data);

        NSString *numberFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"BooleanTest" error:&error][@"boolean_value"];

        XCTAssertNil(error);
        XCTAssertEqual(numberFromAvro,number);
    }
}

- (void)testNullType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"NullTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"null_value\",\"type\":\"null\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];


    NSError *error;
    NSData *data = [avro dataFromJSONObject:@{@"null_value": [NSNull null]} forSchemaNamed:@"NullTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    id nullFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"NullTest" error:&error][@"null_value"];

    XCTAssertNil(error);
    XCTAssertEqualObjects(nullFromAvro, [NSNull null]);
}

- (void)testArrayType {
    NSString *schema = @"{\"type\":\"array\",\"name\":\"ArrayTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"items\": {\"type\": \"int\"}}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];


    NSError *error;
    NSArray *array = @[@1, @5, @-2, @0, @10021, @500000];
    NSData *data = [avro dataFromJSONObject:array forSchemaNamed:@"ArrayTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    NSArray *arrayFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"ArrayTest" error:&error];

    XCTAssertNil(error);
    XCTAssertEqualObjects(arrayFromAvro,array);
}

- (void)testMapType {
    NSString *schema = @"{\"type\":\"map\",\"name\":\"MapTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"values\": \"int\"}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];


    NSError *error;
    NSDictionary *map = @{@"one": @1, @"zero": @0, @"two": @2, @"-one": @-1};
    NSData *data = [avro dataFromJSONObject:map forSchemaNamed:@"MapTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    NSDictionary *mapFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"MapTest" error:&error];

    XCTAssertNil(error);
    XCTAssertEqualObjects(mapFromAvro,map);
}

- (void)testBytesType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"BytesTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"bytes_value\",\"type\":\"bytes\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];


    NSError *error;
    NSString *bytes = @"\"\\u00de\\u00ad\\u00be\\u00ef\"";

    NSData *data = [avro dataFromJSONObject:@{@"bytes_value": bytes} forSchemaNamed:@"BytesTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    id bytesFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"BytesTest" error:&error][@"bytes_value"];

    XCTAssertNil(error);
    XCTAssertEqualObjects(bytesFromAvro,bytes);
}

- (void)testUnionType {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"UnionTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"union_value\",\"type\":[\"null\", \"string\"],  \"default\": null}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];


    NSError *error;
    NSData *data = [avro dataFromJSONObject:@{@"union_value": [NSNull null]} forSchemaNamed:@"UnionTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    id nullFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"UnionTest" error:&error][@"union_value"];

    XCTAssertNil(error);
    XCTAssertEqualObjects(nullFromAvro, [NSNull null]);

    data = [avro dataFromJSONObject:@{@"union_value": @"Tibet"} forSchemaNamed:@"UnionTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    id stringFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"UnionTest" error:&error][@"union_value"];

    XCTAssertNil(error);
    XCTAssertEqualObjects(stringFromAvro, @{@"string": @"Tibet"});
}

- (void)testDefault {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"UnionTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"union_value\",\"type\":[\"int\", \"string\"], \"default\": 10}, {\"name\":\"no_default\",\"type\":\"string\"}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];


    NSError *error;
    NSData *data = [avro dataFromJSONObject:@{@"no_default": @"hey"} forSchemaNamed:@"UnionTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    NSString *numberFromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"UnionTest" error:&error][@"union_value"];

    XCTAssertNil(error);
    XCTAssertEqualObjects(numberFromAvro, @{@"int": @10});
}

- (void)testNullDefault {
    NSString *schema = @"{\"type\":\"record\",\"name\":\"NumericDefaultTest\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"test\",\"type\":[\"null\", \"long\"], \"default\": null}]}";

    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [avro registerSchema:schema error:NULL];


    NSError *error;
    NSData *data = [avro dataFromJSONObject:@{@"test": @10} forSchemaNamed:@"NumericDefaultTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);

    data = [avro dataFromJSONObject:@{@"test": [NSNull null]} forSchemaNamed:@"NumericDefaultTest" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(data);
}

@end
