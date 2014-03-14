//
//  ObjectiveAvroTests.m
//  ObjectiveAvroTests
//
//  Created by Marcelo Fabri on 14/03/14.
//  Copyright (c) 2014 Movile. All rights reserved.
//

#define EXP_SHORTHAND YES

#import <XCTest/XCTest.h>
#import <Expecta.h>
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
    expect(result).to.beTruthy();
    expect(error).to.beNil();
    
    result = [avro registerSchema:peopleSchema error:&error];
    expect(result).to.beTruthy();
    expect(error).to.beNil();
}

- (void)testInvalidJSONSchemaRegistration {
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    NSError *error;
    BOOL result = [avro registerSchema:@"{invalid json}" error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
}

- (void)testInvalidSchemaWithNoNameRegistration {
    NSString *schema = @"{\"type\":\"record\",\"namespace\":\"com.movile.objectiveavro.unittest.v1\",\"fields\":[{\"name\":\"name\",\"type\":\"string\"},{\"name\":\"country\",\"type\":\"string\"},{\"name\":\"age\",\"type\":\"int\"}]}";
    
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    NSError *error;
    BOOL result = [avro registerSchema:schema error:&error];
    expect(result).to.beFalsy();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(NSCocoaErrorDomain);
    expect(error.code).to.equal(NSPropertyListReadCorruptError);
}

- (void)testAvroSerialization {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];
    
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];
    
    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];
    
    expect(error).to.beNil();
    expect(data).notTo.beNil();
    
    NSDictionary *fromAvro = [avro JSONObjectFromData:data forSchemaNamed:@"People" error:&error];
    
    expect(error).to.beNil();
    expect(fromAvro).notTo.beNil();
    
    expect(fromAvro).to.equal(dict);
}

- (void)testAvroCopy {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];
    
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];
    
    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];
    
    expect(error).to.beNil();
    expect(data).notTo.beNil();
    
    OAVAvroSerialization *copy = [avro copy];
    expect(copy).notTo.beNil();
    expect(copy).toNot.equal(avro);
    
    NSData *dataFromCopy = [copy dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];
    expect(error).to.beNil();
    expect(dataFromCopy).notTo.beNil();
    expect(dataFromCopy).to.equal(data);
}

- (void)testAvroCoding {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];
    
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];
    
    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];
    
    expect(error).to.beNil();
    expect(data).notTo.beNil();
    
    NSData *archivedAvroData = [NSKeyedArchiver archivedDataWithRootObject:avro];
    expect(archivedAvroData).notTo.beNil();
    
    OAVAvroSerialization *archivedAvro = [NSKeyedUnarchiver unarchiveObjectWithData:archivedAvroData];
    
    expect(archivedAvro).notTo.beNil();
    expect(archivedAvro).toNot.equal(avro);
    
    NSData *dataFromCopy = [archivedAvro dataFromJSONObject:dict
                                             forSchemaNamed:@"People" error:&error];
    expect(error).to.beNil();
    expect(dataFromCopy).notTo.beNil();
    expect(dataFromCopy).to.equal(data);
}

- (void)testMissingFieldAvroSerialization {
    NSString *json = @"{\"people\":[{\"name\":\"Marcelo Fabri\",\"age\":20},{\"name\":\"Tim Cook\",\"country\":\"USA\",\"age\":53},{\"name\":\"Steve Wozniak\",\"country\":\"USA\",\"age\":63},{\"name\":\"Bill Gates\",\"country\":\"USA\",\"age\":58}],\"generated_timestamp\":1389376800000}";
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    [self registerSchemas:avro];
    
    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];
    
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(NSCocoaErrorDomain);
    expect(error.code).to.equal(NSPropertyListReadCorruptError);
    expect(data).to.beNil();
}

- (void)testNoSchemaRegistred {
    NSDictionary *dict = [[self class] JSONObjectFromBundleResource:@"people"];
    
    OAVAvroSerialization *avro = [[OAVAvroSerialization alloc] init];
    
    NSError *error;
    NSData *data = [avro dataFromJSONObject:dict forSchemaNamed:@"People" error:&error];
    
    expect(error).toNot.beNil();
    expect(error.domain).to.equal(NSCocoaErrorDomain);
    expect(error.code).to.equal(NSFileReadNoSuchFileError);
    expect(data).to.beNil();
}


@end
