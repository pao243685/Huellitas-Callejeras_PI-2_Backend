import { Module } from '@nestjs/common';
import { RefugioService } from './services/refugio.service';
import { RefugioController } from './controllers/refugio.controller';
import { RolService } from './services/rol.service';
import { RolController } from './controllers/rol.controller';
import { RolValidationService } from './services/rol.validate.service';

@Module({
  providers: [RefugioService, RolService, RolValidationService],
  controllers: [RefugioController, RolController],
})
export class RefugioModule {}
