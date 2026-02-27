import { Module } from '@nestjs/common';
import { UsersService } from './services/users.service';
import { UsersController } from './controllers/user.controller';
import { UsersValidationService } from './services/usuario.validation.service';

@Module({
  providers: [UsersService, UsersValidationService],
  controllers: [UsersController],
})
export class UserModule {}
