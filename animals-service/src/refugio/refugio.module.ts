import { Module } from '@nestjs/common';
import { RefugioService } from './services/refugio.service';
import { RefugioController } from './controllers/refugio.controller';
import { RolService } from './services/rol.service';
import { RolController } from './controllers/rol.controller';

@Module({
  providers: [RefugioService, RolService],
  controllers: [RefugioController, RolController],
})
export class RefugioModule {}
