#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(PolarBleSdkModule, RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)
RCT_EXTERN_METHOD(connectToDevice:(NSString *)deviceId)
RCT_EXTERN_METHOD(disconnectFromDevice:(NSString *)deviceId)
RCT_EXTERN_METHOD(startEcgStreaming)
RCT_EXTERN_METHOD(stopEcgStreaming)
RCT_EXTERN_METHOD(startAccStreaming)
RCT_EXTERN_METHOD(stopAccStreaming)
RCT_EXTERN_METHOD(sampleMethod:(NSString *)stringArgument numberArgument:(nonnull NSNumber *)numberArgument callback:(RCTResponseSenderBlock)callback)

@end

/*
#import "PolarBleSdkModule.h"

@implementation PolarBleSdkModule

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"Disconnected", @"Connnecting", @"Connected"];
}

RCT_EXPORT_METHOD(connectToDevice:(NSString *)deviceId)
{

}

RCT_EXPORT_METHOD(disconnectFromDevice:(NSString *)deviceId)
{

}

RCT_EXPORT_METHOD(startEcgStreaming)
{

}

RCT_EXPORT_METHOD(stopEcgStreaming)
{
  
}

RCT_EXPORT_METHOD(startAccStreaming)
{

}

RCT_EXPORT_METHOD(stopAccStreaming)
{
  
}

RCT_EXPORT_METHOD(sampleMethod:(NSString *)stringArgument numberParameter:(nonnull NSNumber *)numberArgument callback:(RCTResponseSenderBlock)callback)
{
    // TODO: Implement some actually useful functionality
    callback(@[[NSString stringWithFormat: @"numberArgument: %@ stringArgument: %@", numberArgument, stringArgument]]);
}

@end
//*/
