export class RemoteUploadImageData {
  path: string = '';
  url: string = '';

  constructor(path: string = '', url: string = '') {
    this.path = path;
    this.url = url;
  }
}

export class RemoteUploadImageResponse {
  code: number = 1;
  message: string = '';
  data?: RemoteUploadImageData = undefined;

  constructor(
    code: number = 1,
    message: string = '',
    data?: RemoteUploadImageData
  ) {
    this.code = code;
    this.message = message;
    this.data = data;
  }
}
