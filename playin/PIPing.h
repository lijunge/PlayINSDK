/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An object wrapper around the low-level BSD Sockets ping function.
 */

@import Foundation;

#include <AssertMacros.h>           // for __Check_Compile_Time

NS_ASSUME_NONNULL_BEGIN

@protocol PIPingDelegate;

/*! Controls the IP address version used by PIPing instances.
 */

typedef NS_ENUM(NSInteger, PIPingAddressStyle) {
    PIPingAddressStyleAny,          ///< Use the first IPv4 or IPv6 address found; the default.
    PIPingAddressStyleICMPv4,       ///< Use the first IPv4 address found.
    PIPingAddressStyleICMPv6        ///< Use the first IPv6 address found.
};

/*! An object wrapper around the low-level BSD Sockets ping function.
 *  \details To use the class create an instance, set the delegate and call `-start`
 *      to start the instance on the current run loop.  If things go well you'll soon get the
 *      `-PIPing:didStartWithAddress:` delegate callback.  From there you can can call
 *      `-sendPingWithData:` to send a ping and you'll receive the
 *      `-PIPing:didReceivePingResponsePacket:sequenceNumber:` and
 *      `-PIPing:didReceiveUnexpectedPacket:` delegate callbacks as ICMP packets arrive.
 *
 *      The class can be used from any thread but the use of any single instance must be
 *      confined to a specific thread and that thread must run its run loop.
 */

@interface PIPing : NSObject

- (instancetype)init NS_UNAVAILABLE;

/*! Initialise the object to ping the specified host.
 *  \param hostName The DNS name of the host to ping; an IPv4 or IPv6 address in string form will
 *      work here.
 *  \returns The initialised object.
 */

- (instancetype)initWithHostName:(NSString *)hostName NS_DESIGNATED_INITIALIZER;

/*! A copy of the value passed to `-initWithHostName:`.
 */

@property (nonatomic, copy, readonly) NSString * hostName;

/*! The delegate for this object.
 *  \details Delegate callbacks are schedule in the default run loop mode of the run loop of the
 *      thread that calls `-start`.
 */

@property (nonatomic, weak, readwrite, nullable) id<PIPingDelegate> delegate;

/*! Controls the IP address version used by the object.
 *  \details You should set this value before starting the object.
 */

@property (nonatomic, assign, readwrite) PIPingAddressStyle addressStyle;

/*! The address being pinged.
 *  \details The contents of the NSData is a (struct sockaddr) of some form.  The
 *      value is nil while the object is stopped and remains nil on start until
 *      `-PIPing:didStartWithAddress:` is called.
 */

@property (nonatomic, copy, readonly, nullable) NSData * hostAddress;
@property (nonatomic, copy, readonly, nullable) NSString *IPAddress;
@property (nonatomic, assign, readonly) NSInteger packetLength;

/*! The address family for `hostAddress`, or `AF_UNSPEC` if that's nil.
 */

@property (nonatomic, assign, readonly) sa_family_t hostAddressFamily;

/*! The identifier used by pings by this object.
 *  \details When you create an instance of this object it generates a random identifier
 *      that it uses to identify its own pings.
 */

@property (nonatomic, assign, readonly) uint16_t identifier;

/*! The next sequence number to be used by this object.
 *  \details This value starts at zero and increments each time you send a ping (safely
 *      wrapping back to zero if necessary).  The sequence number is included in the ping,
 *      allowing you to match up requests and responses, and thus calculate ping times and
 *      so on.
 */

@property (nonatomic, assign, readonly) uint16_t nextSequenceNumber;

/*! Starts the object.
 *  \details You should set up the delegate and any ping parameters before calling this.
 *
 *      If things go well you'll soon get the `-PIPing:didStartWithAddress:` delegate
 *      callback, at which point you can start sending pings (via `-sendPingWithData:`) and
 *      will start receiving ICMP packets (either ping responses, via the
 *      `-PIPing:didReceivePingResponsePacket:sequenceNumber:` delegate callback, or
 *      unsolicited ICMP packets, via the `-PIPing:didReceiveUnexpectedPacket:` delegate
 *      callback).
 *
 *      If the object fails to start, typically because `hostName` doesn't resolve, you'll get
 *      the `-PIPing:didFailWithError:` delegate callback.
 *
 *      It is not correct to start an already started object.
 */

- (void)start;

- (nonnull NSData *)packetWithPingData:(nullable  NSData *)data;

/*! Sends a ping packet containing the specified data.
 *  \details Sends an actual ping.
 *
 *      The object must be started when you call this method and, on starting the object, you must
 *      wait for the `-PIPing:didStartWithAddress:` delegate callback before calling it.
 *  \param data Some data to include in the ping packet, after the ICMP header, or nil if you
 *      want the packet to include a standard 56 byte payload (resulting in a standard 64 byte
 *      ping).
 */

- (void)sendPacket:(nonnull NSData *)data;

/*! Stops the object.
 *  \details You should call this when you're done pinging.
 *
 *      It's safe to call this on an object that's stopped.
 */

- (void)stop;

@end

/*! A delegate protocol for the PIPing class.
 */

@protocol PIPingDelegate <NSObject>

@optional

/*! A PIPing delegate callback, called once the object has started up.
 *  \details This is called shortly after you start the object to tell you that the
 *      object has successfully started.  On receiving this callback, you can call
 *      `-sendPingWithData:` to send pings.
 *
 *      If the object didn't start, `-PIPing:didFailWithError:` is called instead.
 *  \param pinger The object issuing the callback.
 *  \param address The address that's being pinged; at the time this delegate callback
 *      is made, this will have the same value as the `hostAddress` property.
 */

- (void)pi_ping:(PIPing *)pinger didStartWithAddress:(NSData *)address;

/*! A PIPing delegate callback, called if the object fails to start up.
 *  \details This is called shortly after you start the object to tell you that the
 *      object has failed to start.  The most likely cause of failure is a problem
 *      resolving `hostName`.
 *
 *      By the time this callback is called, the object has stopped (that is, you don't
 *      need to call `-stop` yourself).
 *  \param pinger The object issuing the callback.
 *  \param error Describes the failure.
 */

- (void)pi_ping:(PIPing *)pinger didFailWithError:(NSError *)error;

/*! A PIPing delegate callback, called when the object has successfully sent a ping packet.
 *  \details Each call to `-sendPingWithData:` will result in either a
 *      `-PIPing:didSendPacket:sequenceNumber:` delegate callback or a
 *      `-PIPing:didFailToSendPacket:sequenceNumber:error:` delegate callback (unless you
 *      stop the object before you get the callback).  These callbacks are currently delivered
 *      synchronously from within `-sendPingWithData:`, but this synchronous behaviour is not
 *      considered API.
 *  \param pinger The object issuing the callback.
 *  \param packet The packet that was sent; this includes the ICMP header (`ICMPHeader`) and the
 *      data you passed to `-sendPingWithData:` but does not include any IP-level headers.
 *  \param sequenceNumber The ICMP sequence number of that packet.
 */

- (void)pi_ping:(PIPing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber;

/*! A PIPing delegate callback, called when the object fails to send a ping packet.
 *  \details Each call to `-sendPingWithData:` will result in either a
 *      `-PIPing:didSendPacket:sequenceNumber:` delegate callback or a
 *      `-PIPing:didFailToSendPacket:sequenceNumber:error:` delegate callback (unless you
 *      stop the object before you get the callback).  These callbacks are currently delivered
 *      synchronously from within `-sendPingWithData:`, but this synchronous behaviour is not
 *      considered API.
 *  \param pinger The object issuing the callback.
 *  \param packet The packet that was not sent; see `-PIPing:didSendPacket:sequenceNumber:`
 *      for details.
 *  \param sequenceNumber The ICMP sequence number of that packet.
 *  \param error Describes the failure.
 */

- (void)pi_ping:(PIPing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error;

/*! A PIPing delegate callback, called when the object receives a ping response.
 *  \details If the object receives an ping response that matches a ping request that it
 *      sent, it informs the delegate via this callback.  Matching is primarily done based on
 *      the ICMP identifier, although other criteria are used as well.
 *  \param pinger The object issuing the callback.
 *  \param packet The packet received; this includes the ICMP header (`ICMPHeader`) and any data that
 *      follows that in the ICMP message but does not include any IP-level headers.
 *  \param sequenceNumber The ICMP sequence number of that packet.
 */

- (void)pi_ping:(PIPing *)pinger didReceivePingResponsePacket:(NSData *)packet timeToLive:(NSInteger)timeToLive sequenceNumber:(uint16_t)sequenceNumber timeElapsed:(NSTimeInterval)timeElapsed;

/*! A PIPing delegate callback, called when the object receives an unmatched ICMP message.
 *  \details If the object receives an ICMP message that does not match a ping request that it
 *      sent, it informs the delegate via this callback.  The nature of ICMP handling in a
 *      BSD kernel makes this a common event because, when an ICMP message arrives, it is
 *      delivered to all ICMP sockets.
 *
 *      IMPORTANT: This callback is especially common when using IPv6 because IPv6 uses ICMP
 *      for important network management functions.  For example, IPv6 routers periodically
 *      send out Router Advertisement (RA) packets via Neighbor Discovery Protocol (NDP), which
 *      is implemented on top of ICMP.
 *
 *      For more on matching, see the discussion associated with
 *      `-PIPing:didReceivePingResponsePacket:sequenceNumber:`.
 *  \param pinger The object issuing the callback.
 *  \param packet The packet received; this includes the ICMP header (`ICMPHeader`) and any data that
 *      follows that in the ICMP message but does not include any IP-level headers.
 */

- (void)pi_ping:(PIPing *)pinger didReceiveUnexpectedPacket:(NSData *)packet;

@end

#pragma mark * ICMP On-The-Wire Format
/*! Describes the on-the-wire header format for an ICMP ping.
 *  \details This defines the header structure of ping packets on the wire.  Both IPv4 and
 *      IPv6 use the same basic structure.
 *
 *      This is declared in the header because clients of PIPing might want to use
 *      it parse received ping packets.
 */

struct PIICMPHeader {
    uint8_t     type;
    uint8_t     code;
    uint16_t    checksum;
    uint16_t    identifier;
    uint16_t    sequenceNumber;
    // data...
};
typedef struct PIICMPHeader PIICMPHeader;

__Check_Compile_Time(sizeof(PIICMPHeader) == 8);
__Check_Compile_Time(offsetof(PIICMPHeader, type) == 0);
__Check_Compile_Time(offsetof(PIICMPHeader, code) == 1);
__Check_Compile_Time(offsetof(PIICMPHeader, checksum) == 2);
__Check_Compile_Time(offsetof(PIICMPHeader, identifier) == 4);
__Check_Compile_Time(offsetof(PIICMPHeader, sequenceNumber) == 6);

enum {
    PIICMPv4TypeEchoRequest = 8,          ///< The ICMP `type` for a ping request; in this case `code` is always 0.
    PIICMPv4TypeEchoReply   = 0           ///< The ICMP `type` for a ping response; in this case `code` is always 0.
};

enum {
    PIICMPv6TypeEchoRequest = 128,        ///< The ICMP `type` for a ping request; in this case `code` is always 0.
    PIICMPv6TypeEchoReply   = 129         ///< The ICMP `type` for a ping response; in this case `code` is always 0.
};

NS_ASSUME_NONNULL_END
