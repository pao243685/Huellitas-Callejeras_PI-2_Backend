import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';

import { SharedModule } from './shared/shared.module';
import { AnimalsModule } from './animals/animals.module';
import { MovementsModule } from './movements/movements.module';
import { AuthModule } from './auth/auth.module';
import { JwtAuthGuard } from './auth/guards/jwt.guard';
import { RefugioModule } from './refugio/refugio.module';
import { UserModule } from './users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    SharedModule,
    AnimalsModule,
    MovementsModule,
    AuthModule,
    RefugioModule,
    UserModule,
  ],

  providers: [
    JwtAuthGuard,
    {
      provide: APP_GUARD,
      useExisting: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
