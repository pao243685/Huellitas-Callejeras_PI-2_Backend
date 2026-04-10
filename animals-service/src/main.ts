import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, OpenAPIObject } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import * as fs from 'fs';
import { AppModule } from './app.module';

interface BigIntWithToJSON {
  toJSON(this: bigint): string;
}
(BigInt.prototype as unknown as BigIntWithToJSON).toJSON = function (
  this: bigint,
): string {
  return this.toString();
};

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.enableCors({
    origin: [
      'https://huellitas-callejeras.duckdns.org',
      'http://huellitas-callejeras.duckdns.org',
      'http://localhost:3000',
    ],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    credentials: true,
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept',
      'Origin',
      'X-Requested-With',
    ],
    exposedHeaders: ['Authorization'],
    preflightContinue: false,
    optionsSuccessStatus: 204,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: false,
      },
    }),
  );

  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads',
  });

  app.setGlobalPrefix('api/v1');

  const swaggerDocument = JSON.parse(
    fs.readFileSync(join(process.cwd(), 'swagger.json'), 'utf8'),
  ) as OpenAPIObject;

  SwaggerModule.setup('docs', app, swaggerDocument);

  const port = process.env.PORT || 3001;
  await app.listen(port);
  console.log(`Animals Service corriendo en http://localhost:${port}`);
  console.log(`Swagger en http://localhost:${port}/api/v1/docs`);
}
bootstrap().catch(err => {
  console.error('Error starting server', err);
  process.exit(1);
});
