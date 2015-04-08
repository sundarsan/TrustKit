//
//  TrustKitServerTests.m
//  TrustKit
//
//  Created by Eric on 05/03/15.
//  Copyright (c) 2015 Data Theorem. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TrustKit.h"
#import "TrustKit+Private.h"
#import "subjectPublicKeyHash.h"


@interface TrustKitServerTests : XCTestCase

@end

@implementation TrustKitServerTests

- (void)setUp {
    [super setUp];
    [TrustKit resetConfiguration];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



// Tests a secure connection to https://www.datatheorem.com by pinning to any of the 3 public keys

- (void)testConnectionValidatingAnyKey
{
    NSDictionary *trustKitConfig =
    @{
      @"www.datatheorem.com" : @{
              kTSKIncludeSubdomains : [NSNumber numberWithBool:NO],
              kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
              kTSKPublicKeyHashes : @[@"d120dfddc453a3264968cb284b5ee817bd9531abcbc63fcded604d6ac36e891f", // Server key
                                      @"2741caeb7dc87a45083200b10037145d697723ec2bd5721b1e4af4dfcc48c919", // Intermediate key
                                      @"1d75d0831b9e0885394d32c7a1bfdb3dbc1c28e2b0e8391fb135981dbc5ba936" // CA key
                                      ]}};

    [TrustKit initializeWithConfiguration:trustKitConfig];
    
    NSError *error = nil;
    NSHTTPURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.datatheorem.com"]];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    XCTAssertNil(error, @"Connection had an error: %@", error);
    XCTAssert(response.statusCode==200, @"Server did not respond with a 200 OK");
}



// Tests a secure connection to https://www.datatheorem.com by pinning only to the server's public key

- (void)testConnectionValidatingServerPublicKey
{
    NSDictionary *trustKitConfig =
    @{
      @"www.datatheorem.com" : @{
              kTSKIncludeSubdomains : [NSNumber numberWithBool:NO],
              kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
              kTSKPublicKeyHashes : @[@"d120dfddc453a3264968cb284b5ee817bd9531abcbc63fcded604d6ac36e891f", // Server key
                                      ]}};

    [TrustKit initializeWithConfiguration:trustKitConfig];

    NSError *error = nil;
    NSHTTPURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.datatheorem.com"]];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    XCTAssertNil(error, @"Connection had an error: %@", error);
    XCTAssert(response.statusCode==200, @"Server did not respond with a 200 OK");
}



// Tests a secure connection to https://www.datatheorem.com by pinning only to the intermediate certificate public key

- (void)testConnectionValidatingIntermediatePublicKey
{
    NSDictionary *trustKitConfig =
@{
      @"www.datatheorem.com" : @{
              kTSKIncludeSubdomains : [NSNumber numberWithBool:NO],
              kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
              kTSKPublicKeyHashes : @[@"2741caeb7dc87a45083200b10037145d697723ec2bd5721b1e4af4dfcc48c919", //Intermediate key
                                      ]}};
    
    [TrustKit initializeWithConfiguration:trustKitConfig];

    NSError *error = nil;
    NSHTTPURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.datatheorem.com"]];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    XCTAssertNil(error, @"Connection had an error: %@", error);
    XCTAssert(response.statusCode==200, @"Server did not respond with a 200 OK");
}


// Tests a secure connection to https://www.datatheorem.com by pinning only to the CA public key

- (void)testConnectionValidatingCAPublicKey
{
    NSDictionary *trustKitConfig =
  @{
    @"www.datatheorem.com" : @{
            kTSKIncludeSubdomains : [NSNumber numberWithBool:NO],
            kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
            kTSKPublicKeyHashes : @[@"1d75d0831b9e0885394d32c7a1bfdb3dbc1c28e2b0e8391fb135981dbc5ba936" //CA key
                                    ]}};
    
    [TrustKit initializeWithConfiguration:trustKitConfig];
    
    
    NSError *error = nil;
    NSHTTPURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.datatheorem.com"]];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    XCTAssertNil(error, @"Connection had an error: %@", error);
    XCTAssert(response.statusCode==200, @"Server did not respond with a 200 OK");
}



// Tests a secure connection to https://www.datatheorem.com and forces validation to fail by providing a fake hash

- (void)testConnectionUsingFakeHashInvalidatingAllCertificates
{
    NSDictionary *trustKitConfig =
    @{
      @"www.datatheorem.com" : @{
              kTSKIncludeSubdomains : [NSNumber numberWithBool:NO],
              kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
              kTSKPublicKeyHashes : @[@"0000000000000000000000000000000000000000000000000000000000000000" //Fake key
                                      ]}};
    
    [TrustKit initializeWithConfiguration:trustKitConfig];
    
    NSError *error = nil;
    NSHTTPURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.datatheorem.com"]];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    XCTAssert(error.code==-1202 && [error.domain isEqual:@"NSURLErrorDomain"], @"Invalid certificate error not fired");
}

// Tests a secure connection to https://www.datatheorem.com combining both an invalid and a valid key - must pass

- (void)testConnectionUsingValidAndFakeHash
{
    NSDictionary *trustKitConfig =
    @{
      @"www.datatheorem.com" : @{
              kTSKIncludeSubdomains : [NSNumber numberWithBool:NO],
              kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048],
              kTSKPublicKeyHashes : @[@"0000000000000000000000000000000000000000000000000000000000000000", //Fake key
                                      @"1d75d0831b9e0885394d32c7a1bfdb3dbc1c28e2b0e8391fb135981dbc5ba936" //CA key
                                      ]}};
    
    [TrustKit initializeWithConfiguration:trustKitConfig];
    
    NSError *error = nil;
    NSHTTPURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.datatheorem.com"]];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    XCTAssertNil(error, @"Connection had an error: %@", error);
    XCTAssert(response.statusCode==200, @"Server did not respond with a 200 OK");
}

// Don't pin anything (connection must work)

- (void)testConnectionWithoutPinningAnything
{
    NSError *error = nil;
    NSHTTPURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.datatheorem.com"]];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    XCTAssertNil(error, @"Connection had an error: %@", error);
    XCTAssert(response.statusCode==200, @"Server did not respond with a 200 OK");
}


@end