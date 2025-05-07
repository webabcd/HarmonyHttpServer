export interface HttpRequest {
  method: string
  url: string
  protocol: string
  headers: Record<string, string>
  body: string
}

export interface HttpResponse {
  headers?: Record<string, string>
  result: string | ArrayBuffer
  statusCode?: number
}

export type RequestAndResponse = (httpRequest:HttpRequest) => HttpResponse;
export type RequestAndResponseAsync = (httpRequest:HttpRequest) => Promise<HttpResponse>;

// http 响应的状态码（status code）及其对应的文本描述（reason phrase）
export const HttpStatus: Record<number, string> = {
  // 1xx Informational
  100: 'Continue',
  101: 'Switching Protocols',
  102: 'Processing',

  // 2xx Success
  200: 'OK',
  201: 'Created',
  202: 'Accepted',
  204: 'No Content',
  206: 'Partial Content',

  // 3xx Redirection
  301: 'Moved Permanently',
  302: 'Found',
  304: 'Not Modified',
  307: 'Temporary Redirect',
  308: 'Permanent Redirect',

  // 4xx Client Error
  400: 'Bad Request',
  401: 'Unauthorized',
  403: 'Forbidden',
  404: 'Not Found',
  405: 'Method Not Allowed',
  408: 'Request Timeout',
  429: 'Too Many Requests',

  // 5xx Server Error
  500: 'Internal Server Error',
  502: 'Bad Gateway',
  503: 'Service Unavailable',
  504: 'Gateway Timeout',
  507: 'Insufficient Storage'
};

