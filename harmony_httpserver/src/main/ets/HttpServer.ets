import { socket } from "@kit.NetworkKit";
import { AsyncCallback, BusinessError } from "@kit.BasicServicesKit";
import { buffer } from "@kit.ArkTS";
import { RequestAndResponse, HttpRequest, HttpResponse, HttpStatus, RequestAndResponseAsync } from "./Model";
import { Helper } from "./Helper";
import { log, model } from '@webabcd/harmony-utils'

class HttpServer {

  tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance()

  /**
   * 是否打印日志（默认开启）
   */
  public enableLog(enable:boolean) {
    log.LOGLEVEL = enable ? model.LogLevel.DEBUG : model.LogLevel.NONE
  }

  /**
   * 启动本地 http server
   * @param port 端口号
   * @param callback 返回实际监听的端口号
   */
  public async start(port:number, callback: AsyncCallback<number>) {

    // port 要大于等于 1024
    if (port < 1024) {
      port  = 1024
      log.w("监听端口必须大于等于 1024")
    }

    let maxRetryTimes = 50
    let currentRetryTimes = 0
    while (currentRetryTimes <= maxRetryTimes) {
      try {

        let ipAddress: socket.NetAddress = {
          address: "0.0.0.0",
          port: port
        }

        log.i(`尝试监听端口：${port}`)
        await this.tcpServer.listen(ipAddress)
        log.i(`尝试监听端口 ${port} 成功`)
        callback(undefined, port)
        break
      } catch (err) {
        let error = err as BusinessError
        log.w(`尝试监听端口 ${port} 失败 errCode:${error.code}, errMessage:${error.message}`)
        if (currentRetryTimes >= maxRetryTimes) {
          callback(error, -1)
          break
        }
        currentRetryTimes ++
        port ++
      }
    }

    if (currentRetryTimes >= maxRetryTimes) {
      return
    }

    this.tcpServer.off("connect")
    this.tcpServer.on("connect", (client: socket.TCPSocketConnection) => {

      client.on("message",  async (value: socket.SocketMessageInfo) => {

        let requestData = buffer.from(value.message).toString('utf-8')
        let httpRequest = Helper.parseHttpRequest(requestData)
        log.i(`收到请求 ${httpRequest.url}`)
        if (this.requestAndResponse || this.requestAndResponseAsync) {
          let httpResponse = {} as HttpResponse
          if (this.requestAndResponse) {
            httpResponse = this.requestAndResponse(httpRequest)
          } else if (this.requestAndResponseAsync) {
            httpResponse = await this.requestAndResponseAsync(httpRequest)
          }
          Helper.adjustHttpResponse(httpResponse)

          // 需要响应的 status line 和 headers
          let responseMetadata = `HTTP/1.1 ${httpResponse.statusCode} ${HttpStatus[httpResponse.statusCode!] ?? "unknown"}\r\n` +
            Object.entries(httpResponse.headers!).map(p => `${p[0]}: ${p[1]}`).join('\r\n') +
            '\r\n\r\n'
          let responseMetadataOptions: socket.TCPSendOptions = {
            data: responseMetadata,
            encoding: 'utf-8'
          }

          // 需要响应的 body
          let responseBodyOptions: socket.TCPSendOptions = {
            data: httpResponse.result,
            encoding: 'utf-8'
          }

          // 发送 status line 和 headers
          client.send(responseMetadataOptions).then(() => {

            // 发送 body
            client.send(responseBodyOptions).then(() => {

            }).catch((err: BusinessError) => {

            }).finally(() => {

              client.close().then(() => {

              }).catch((err: BusinessError) => {

              });
            });

          }).catch((err: BusinessError) => {

          }).finally(() => {

          });
        }
      });

      client.on("close", () => {

      });
    });
  }

  /**
   * 停止本地 http server
   */
  public stop() {
    this.tcpServer.off("connect")
    log.i(`停止本地 http server`)
  }

  requestAndResponse: RequestAndResponse | undefined
  requestAndResponseAsync: RequestAndResponseAsync | undefined
  /**
   * 处理本地 http 请求（同步）
   */
  public handleHttpRequest(requestAndResponse: RequestAndResponse) {
    this.requestAndResponseAsync = undefined
    this.requestAndResponse = requestAndResponse
  }
  /**
   * 处理本地 http 请求（异步）
   */
  public handleHttpRequestAsync(requestAndResponseAsync: RequestAndResponseAsync) {
    this.requestAndResponse = undefined
    this.requestAndResponseAsync = requestAndResponseAsync
  }
}

export let httpServer = new HttpServer()

