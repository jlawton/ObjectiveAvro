//
//  OAVAvroSerialization.h
//  Objective-Avro
//
//  Created by Marcelo Fabri on 23/01/14.
//  Copyright (c) 2014 Movile. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Converts from NSData to JSON objects (and vice-versa). 
 *  A wrapper on Avro-C, (almost) mimicking the interface of NSJSONSerialization.
 */
@interface OAVAvroSerialization : NSObject <NSCopying, NSCoding>

/**
 * An opaque token type used to track a file to which the consumer is writing.
 * @discussion Should be used only as a token; do not free or do anything else weird.
 */
typedef void * OAVFileWriterToken;

/**
 * Start a file for writing with the given schema. The schema must already be
 * registered with this serialization object.
 *
 * @param filePath      The path to which to write the Avro file
 * @param schemaName    The schema name used to describe the object
 * @param error         A pointer to the error object that will represent any errors ocurred
 *
 * @return An `OAVFileWriterToken`, to be used in future calls.
 */
- (nullable OAVFileWriterToken)startFile:(nonnull NSString *)filePath
                          forSchemaNamed:(nonnull NSString *)schemaName
                                   error:( NSError * _Nullable  __autoreleasing *)error;
/**
 * Re-open a file for writing. The file must already have been created with
 * startFile:forSchemaNamed:error:.
 *
 * @param filePath      The path to which to write the Avro file
 * @param error         A pointer to the error object that will represent any errors ocurred
 *
 * @return An `OAVFileWriterToken`, to be used in future calls.
 */
- (nullable OAVFileWriterToken)openFile:(NSString *)filePath
                                  error:(NSError * __autoreleasing *)error;

/**
 * Serializes the given JSON objects to the already-open file. Can be called
 * multiple times with different objects.
 *
 * @param jsonObjects   An array of objects to be encoded
 * @param writer        The token obtained by calling startFile:forSchemaNamed:
 * @param schemaName    The schema name used to describe the object
 * @param error         A pointer to the error object that will represent any errors ocurred
 *
 * @return A BOOL, `YES` if writing succeeded, `NO` if it failed
 */
- (BOOL)writeJSONObjects:(nonnull NSArray *)jsonObjects
                toWriter:(nonnull OAVFileWriterToken)writer
          forSchemaNamed:(nonnull NSString *)schemaName
                   error:( NSError * _Nullable  __autoreleasing *)error;

/**
 * Close the given file, finalizing it and making it ready for use.
 *
 * @param writer        The token obtained by calling startFile:forSchemaNamed:
 */
- (void)closeFile:(nonnull OAVFileWriterToken)writer;

/**
 * Serializes a complete Avro file to disk. Unlike `dataFromJSONObject`, this
 * includes the header and schema, yielding a complete, transferrable file.
 *
 * @param jsonObjects   An array of objects to be encoded
 * @param filePath      The path to which to write the Avro file
 * @param schemaName    The schema name used to describe the object
 * @param error         A pointer to the error object that will represent any errors ocurred
 *
 * @return A BOOL, `YES` if writing succeeded, `NO` if it failed
 */
- (BOOL)writeJSONObjects:(nonnull NSArray *)jsonObjects
                  toFile:(nonnull NSString *)filePath
          forSchemaNamed:(nonnull NSString *)schemaName
                   error:( NSError * _Nullable  __autoreleasing *)error;

/**
 *  Serializes a JSON object to NSData, containing the Avro-encoded object.
 *
 *  @param jsonObject The object to be encoded
 *  @param schemaName The schema name used to describe the object
 *  @param error      A pointer to the error object that will represent any errors ocurred
 *
 *  @return An NSData object, containing the result of serialization to Avro format
 */
- (nullable NSData *)dataFromJSONObject:(nonnull id)jsonObject forSchemaNamed:(nonnull NSString *)schemaName
                         error:( NSError * _Nullable  __autoreleasing *)error;

/**
 *  Creates a Foundation object from a NSData Avro object.
 *
 *  @param data       NSData object with the result of a previous Avro serialization
 *  @param schemaName The schema's name of the object being unserialized
 *  @param error      A pointer to the error object that will represent any errors ocurred
 *
 *  @return A Foundation representation of the Avro encoded object
 */
- (nullable id)JSONObjectFromData:(nonnull NSData *)data forSchemaNamed:(nonnull NSString *)schemaName
                   error:( NSError * _Nullable  __autoreleasing *)error;

/**
*  Creates a Foundation object from Avro written file.
*
*  @param filePath  fiel path to saved avro file
*  @param error      A pointer to the error object that will represent any errors ocurred
*
*  @return An array of json strings
*/
- (NSArray *)JSONObjectsFromFile:(NSString *)filePath error:(NSError * __autoreleasing *)error;

/**
 *  Register a schema so the wrapper can serialize objects later.
 *
 *  @param schema A JSON describing the Avro schema
 *  @param error  A pointer to the error object that will represent any errors ocurred
 *
 *  @return Whether the schema was registered or not
 */
- (BOOL)registerSchema:(nonnull NSString *)schema error:( NSError * _Nullable  __autoreleasing *)error;

@end
