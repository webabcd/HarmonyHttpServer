import { HttpRequest, HttpResponse } from "./Model";
import { buffer, util } from "@kit.ArkTS";

export class Helper {

  public static parseHttpRequest(requestData: string): HttpRequest {

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
    httpRequest.headers = headers

    let body = '';
    const emptyLineIndex = requestData.indexOf('\r\n\r\n');
    if (emptyLineIndex !== -1 && emptyLineIndex + 4 < requestData.length) {
      body = requestData.substring(emptyLineIndex + 4);
    }
    httpRequest.body = body

    return httpRequest
  }

  public static adjustHttpResponse(httpResponse: HttpResponse) {

    if (!httpResponse.statusCode) {
      httpResponse.statusCode = 200
    }

    if (!httpResponse.headers) {
      httpResponse.headers = {}
    }

    if (!httpResponse.headers["Content-Type"]) {
      if (typeof httpResponse.result == 'string') {
        httpResponse.headers["Content-Type"] = 'text/plain'
      } else if (httpResponse.result instanceof ArrayBuffer) {
        httpResponse.headers["Content-Type"] = 'application/octet-stream'
      }
    }

    if (!httpResponse.headers["Content-Length"]) {
      if (typeof httpResponse.result == 'string') {
        httpResponse.headers["Content-Length"] = buffer.byteLength(httpResponse.result, 'utf8').toString();
      } else if (httpResponse.result instanceof ArrayBuffer) {
        httpResponse.headers["Content-Length"] = httpResponse.result.byteLength.toString();
      }
    }
  }

  public static stringToArrayBuffer(str: string): ArrayBuffer {
    const encoder = new util.TextEncoder();
    const uint8Array = encoder.encodeInto(str);
    return uint8Array.buffer;
  }

  public static arrayBufferToString(arrayBuffer: ArrayBuffer): string {
    return buffer.from(arrayBuffer).toString('utf-8')
  }
}