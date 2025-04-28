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
      // 自定义 http 响应数据
      let httpResponse: HttpResponse = {
        result: `我是自定义响应数据，当前的 http 请求的 url 为 ${httpRequest.url}`,
      }
      return httpResponse
    })

    setInterval(() => {
      this.requestDemo()
    }, 1000)
  }

  requestDemo() {
    if (this.port == -1) {
      return
    }

    // 构造本地请求的 url 地址
    let url = `http://127.0.0.1:${this.port}/api?${Math.random()}`

    let httpRequest = http.createHttp()
    httpRequest.request(
      url,
      {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
      },
      (err: BusinessError, data: http.HttpResponse) => {
        if (!err) {
          this.message += `result: ${JSON.stringify(data.result)}\n`
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

      Text(this.message)
    }
    .width('95%')
  }
}
 ```

## Demo
Demo 的下载地址 [harmony-httpserver-demo](https://gitee.com/webabcd/HarmonyHttpServer)