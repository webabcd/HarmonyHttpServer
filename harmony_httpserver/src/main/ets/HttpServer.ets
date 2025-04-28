import { socket } from "@kit.NetworkKit";
import { AsyncCallback, BusinessError } from "@kit.BasicServicesKit";
import { buffer } from "@kit.ArkTS";
import { RequestAndResponse, HttpRequest, HttpResponse, HttpStatus } from "./Model";
import { Helper } from "./Helper";

class HttpServer {

  tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance()

  public async start(port:number, callback: AsyncCallback<number>) {

    // port 要大于等于 1024
    if (port < 1024) {
      port  = 1024
    }

    let maxRetryTimes = 50
    let currentRetryTimes = 0
    while (currentRetryTimes <= maxRetryTimes) {
      try {

        let ipAddress: socket.NetAddress = {
          address: "0.0.0.0",
          port: port
        }

        await this.tcpServer.listen(ipAddress)
        callback(undefined, port)
        break
      } catch (err) {
        let error = err as BusinessError
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

    this.tcpServer.on("connect", (client: socket.TCPSocketConnection) => {

      client.on("message",  (value: socket.SocketMessageInfo)  => {

        let requestData = buffer.from(value.message).toString('utf-8')
        let httpRequest = Helper.parseHttpRequest(requestData)
        if (this.requestAndResponse) {
          let httpResponse = this.requestAndResponse(httpRequest)
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

  public async stop() {
    this.tcpServer.off("connect")
  }

  requestAndResponse: RequestAndResponse | undefined
  public handleHttpRequest(requestAndResponse: RequestAndResponse) {
    this.requestAndResponse = requestAndResponse
  }
}

export let httpServer = new HttpServer()

