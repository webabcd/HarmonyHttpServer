import { HttpRequest, HttpResponse, httpServer } from '@webabcd/harmony-httpserver'
import { BusinessError } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';

@Entry
@Component
struct Index {

  @State message: string = ''
  port: number = -1

  startHttpServer() {
    if (this.port == -1) {
      // port 需要大于等于 1024
      httpServer.start(8080, (err: BusinessError, port: number) => {
        this.port = port
        this.message += `port: ${port}\n`
      })
    }
  }

  stopHttpServer() {
    httpServer.stop()
    this.port = -1
  }

  aboutToAppear(): void {

    httpServer.handleHttpRequest((httpRequest:HttpRequest) => {
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