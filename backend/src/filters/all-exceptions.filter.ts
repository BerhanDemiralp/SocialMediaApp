import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    let message: string;

    if (exception instanceof HttpException) {
      const response = exception.getResponse();
      if (typeof response === 'string') {
        message = response;
      } else if (
        typeof response === 'object' &&
        response !== null &&
        'message' in response &&
        typeof (response as { message: unknown }).message === 'string'
      ) {
        message = (response as { message: string }).message;
      } else {
        message = 'An error occurred';
      }
    } else {
      message = 'Internal server error';
    }

    const request = ctx.getRequest<{ originalUrl?: string }>();
    if (request.originalUrl?.startsWith('/api/notifications')) {
      // Provider tokens and installation secrets can occur in ORM errors.
      console.error('Notification API error:', status);
    } else {
      console.error('Exception:', exception);
    }

    response.status(status).json({
      statusCode: status,
      message,
      timestamp: new Date().toISOString(),
    });
  }
}
