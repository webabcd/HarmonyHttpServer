import { socket } from "@kit.NetworkKit";
import { AsyncCallback, BusinessError } from "@kit.BasicServicesKit";
import { buffer } from "@kit.ArkTS";
import { RequestAndResponse, HttpRequest, HttpResponse, HttpStatus } from "./Model";

class HttpServer {

  tcpServer: socket.TCPSocketServer = socket.constructTCPSocketServerInstance()

  public async start(port:number, callback: AsyncCallback<number>) {

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
        let httpRequest = this.parseHttpRequest(requestData)
        if (this.requestAndResponse) {
          let httpResponse = this.requestAndResponse(httpRequest)

          if (!httpResponse.statusCode) {
            httpResponse.statusCode = 200
          }
          if (!httpResponse.headers) {
            httpResponse.headers = {}
          }
          if (!httpResponse.headers["Content-Type"]) {
            httpResponse.headers["Content-Type"] = 'text/plain'
          }if (!httpResponse.headers["Content-Length"]) {
            httpResponse.headers["Content-Length"] = buffer.byteLength(httpResponse.result, 'utf8').toString();
          }

          let responseData = `HTTP/1.1 ${httpResponse.statusCode} ${HttpStatus[httpResponse.statusCode] ?? "unknown"}\r\n` +
            Object.entries(httpResponse.headers).map(p => `${p[0]}: ${p[1]}`).join('\r\n') +
            '\r\n\r\n' +
            httpResponse.result

          let tcpSendOptions: socket.TCPSendOptions = {
            data: responseData,
            encoding: 'utf-8'
          }

          client.send(tcpSendOptions).then(() => {

          }).catch((err: BusinessError) => {

          }).finally(() => {

            client.close().then(() => {

            }).catch((err: BusinessError) => {

            });
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

  private parseHttpRequest(requestData: string): HttpRequest {

    let httpRequest = {} as HttpRequest

    const lines = requestData.split('\r\n');
    const array: string[] = lines[0].split(' ');

    httpRequest.method = array[0]
    httpRequest.url = array[1]
    httpRequest.protocol = array[2]

    const headers: Record<string, string> = {};
    for (let i = 1; i < lines.length; i++) {
      let line = lines[i]
      if (line === '') { // 空行表示头结束
        break;
      }
      const ary = line.split(': ')
      headers[ary[0]] = ary[1]
    }

    let body = '';
    const emptyLineIndex = requestData.indexOf('\r\n\r\n');
    if (emptyLineIndex !== -1 && emptyLineIndex + 4 < requestData.length) {
      body = requestData.substring(emptyLineIndex + 4);
    }
    httpRequest.body = body

    return httpRequest
  }
}

export let httpServer = new HttpServer()

