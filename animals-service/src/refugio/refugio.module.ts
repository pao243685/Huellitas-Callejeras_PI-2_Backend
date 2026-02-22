import { Module } from '@nestjs/common';
import { RefugioService } from './services/refugio.service';
import { RefugioController } from './controllers/refugio.controller';

@Module({
  providers: [RefugioService],
  controllers: [RefugioController],
})
export class RefugioModule {}
