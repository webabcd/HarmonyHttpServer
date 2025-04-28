# @webabcd/harmony-httpserver
用于在鸿蒙系统中启动本地 http Server，并为指定的本地 http 请求提供自定义的响应内容

## 简介
[harmony-httpserver](https://ohpm.openharmony.cn/#/cn/detail/@webabcd%2Fharmony-httpserver)
一款简单易用的本地 http server 库，可以方便地根据不同的本地 http 请求响应不同的自定义数据

## 下载安装
`ohpm i @webabcd/harmony-httpserver`

## API详解
| HttpServer方法 | 介绍 |
| --- | --- |
| start | 启动本地 http server |
| stop | 停止本地 http server |
| handleHttpRequest | 处理指定的请求，并响应指定的数据  |

## 使用说明与示例代码
```
import { HttpRequest, HttpResponse, httpServer } from '@webabcd/harmony-httpserver'
import { BusinessError } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import { buffer, util } from '@kit.ArkTS';
import { LengthMetrics } from '@kit.ArkUI';

@Entry
@Component
struct Index {

  @State message: string = ''

  // 本地的 http server 的端口号（要求要大于等于 1024）
  port: number = -1

  startHttpServer() {
    if (this.port == -1) {
      // 指定端口号，并启动本地 http server
      // 返回值为真实监听的端口号
      httpServer.start(8080, (err: BusinessError, port: number) => {
        this.port = port
        this.message += `port: ${port}\n`
      })
    }
  }

  stopHttpServer() {
    // 停止本地 http server
    httpServer.stop()
    this.port = -1
  }

  aboutToAppear(): void {

    // 处理本地 http 请求
    httpServer.handleHttpRequest((httpRequest:HttpRequest) => {

      let httpResponse = { } as HttpResponse

      let responseString = `我是自定义响应数据\n` +
        `request url: ${httpRequest.url}\n` +
        `request protocol: ${httpRequest.protocol}\n` +
        `request method: ${httpRequest.method}\n` +
        `request headers: ${Object.entries(httpRequest.headers).map(p => `${p[0]}:${p[1]}`).join(', ')}\n` +
        `request body: ${httpRequest.body}\n`

      if (httpRequest.method == 'GET') {
        // 如果是 get 请求，则响应自定义的 string 数据
        httpResponse.result = responseString
      } else if (httpRequest.method == 'POST') {
        // 如果是 post 请求，则响应自定义的 ArrayBuffer 数据
        httpResponse.result = stringToArrayBuffer(responseString)
      } else {
        httpResponse.result = ''
        httpResponse.statusCode = 404
      }

      return httpResponse
    })
  }

  // 通过 get 请求 http server，并获取服务端响应的 string 数据
  requestDemo1() {
    if (this.port == -1) {
      this.message += '本地 http server 未启动\n'
      return
    }

    // 构造本地请求的 url 地址
    let url = `http://127.0.0.1:${this.port}/api?${Math.random()}`

    let httpRequest = http.createHttp()
    httpRequest.request(
      url,
      {
        method: http.RequestMethod.GET,
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          this.message += `response: ${data.result}\n`
        } else {
          this.message += `error: ${JSON.stringify(err)}\n`
        }
        httpRequest.destroy()
      }
    )
  }

  // 通过 post 请求 http server，并获取服务端响应的 ArrayBuffer 数据
  requestDemo2() {
    if (this.port == -1) {
      this.message += '本地 http server 未启动\n'
      return
    }

    // 构造本地请求的 url 地址
    let url = `http://127.0.0.1:${this.port}/api?${Math.random()}`

    let httpRequest = http.createHttp()
    httpRequest.request(
      url,
      {
        method: http.RequestMethod.POST,
        extraData: "post data"
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          this.message += `response: ${arrayBufferToString(data.result as ArrayBuffer)}\n`
        } else {
          this.message += `error: ${JSON.stringify(err)}\n`
        }
        httpRequest.destroy()
      }
    )
  }

  build() {
    Column({space:10}) {

      Button('启动 http server').onClick(() => {
        this.startHttpServer()
      })

      Button('停止 http server').onClick(() => {
        this.stopHttpServer()
      })

      Button() {
        Text('通过 get 请求 http server\n并获取服务端响应的 string 数据')
          .textAlign(TextAlign.Center).fontColor(Color.White).lineSpacing(LengthMetrics.vp(10))
      }
      .padding(10)
      .onClick(() => {
        this.requestDemo1()
      })

      Button() {
        Text('通过 post 请求 http server\n并获取服务端响应的 ArrayBuffer 数据')
          .textAlign(TextAlign.Center).fontColor(Color.White).lineSpacing(LengthMetrics.vp(10))
      }
      .padding(10)
      .onClick(() => {
        this.requestDemo2()
      })

      Text(this.message)
    }
    .width('100%')
  }
}

function stringToArrayBuffer(str: string): ArrayBuffer {
  const encoder = new util.TextEncoder();
  const uint8Array = encoder.encodeInto(str);
  return uint8Array.buffer;
}

function arrayBufferToString(arrayBuffer: ArrayBuffer): string {
  return buffer.from(arrayBuffer).toString('utf-8')
}
 ```

## Demo
Demo 的下载地址 [harmony-httpserver-demo](https://gitee.com/webabcd/HarmonyHttpServer)