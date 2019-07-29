//
//  
//  playin
//
//  Created by A on 2019/1/17.
//  Copyright © 2019年 A. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma pack(1)

// 包
typedef struct {
    uint8_t     pkt_type;   // 包类型 0x01 控制 0x02 二进制流
    uint32_t    length;     // data 长度
    char        data[];     // control 或 二进制流
} pi_packet_t;

// 控制消息
typedef struct {
    uint32_t    packetid;   // 0x00 unused
    uint16_t    msgid;      // 消息类型 控制协议用的，区分控制协议的类型 0x01 0x02
    char        buf[];      // json
} pi_packet_control_t;

// 流数据
typedef struct {
    uint8_t     streamtype;
    char        buf[];
} pi_packet_stream_t;

enum stream_type {
    
    pi_stream_touch = 0, // 触摸
    pi_stream_h264 = 1, // H264
    pi_stream_aac = 2, // 音频
    pi_stream_androidVideoStart = 6 //Android
};

#pragma pack()

//
//protocol cmd
enum {
    MsgID_Req_Ping_C                = 0x0001,
    MsgID_Res_Pong_C                = 0x0002,
    MsgID_Req_Ping_S                = 0x0003,
    MsgID_Res_Pong_S                = 0x0004,
    MsgID_Noti_Heartbeat            = 0x0f00,   // headtbeat     {}
    MsgID_Noti_DControl_Play        = 0x0f01,
    MsgID_Req_User_Apply            = 0x0101,   // user register  {device_id, resolution, product}
    MsgID_Res_User_Apply            = 0x0201,   // user register response    {errno, error, server_ip, server_port, connect_id}
    MsgID_Req_User_Connect          = 0x0102,   // user connect to stream server {connect_id, device_ip}
    MsgID_Res_User_Connect          = 0x0202,   // user connect to stream server response {errno, error}
    MsgID_Req_User_Disconnect       = 0x0103,   // user close {}
    MsgID_Res_User_Disconnect       = 0x0203,   // user close response {errno, error}
    MsgID_Req_Device_Register       = 0x0301,   // device register {device_id, resolution, product, used, app_id}
    MsgID_Res_Device_Register       = 0x0401,   // {errno, error}
    MsgID_Req_Device_Connect        = 0x0302,   //
    MsgID_Res_Device_Connect        = 0x0402,   //
    MsgID_Req_Device_Reset          = 0x0303,   //
    MsgID_Res_Device_Reset          = 0x0403,   //
    MsgID_Req_Device_Play           = 0x0304,   //
    MsgID_Res_Device_Play           = 0x0404,   //
    MsgID_Req_Disconnect_Device     = 0x0701,   //
    MsgID_Res_Disconnect_Device     = 0x0801,   //
    MsgID_Noti_Background_Transmit  = 0x0f02,
    MsgID_Req_Transmit              = 0x0005,   // 转发给指定设备
    MsgID_Res_Transmit              = 0x0006,
};

@interface PIPacket : NSObject
//@property (nonatomic, assign) NSData *packet;
@end

NS_ASSUME_NONNULL_END
