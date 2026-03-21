import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { UserResponse } from '../interfaces/jwt.interfaces';

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): UserResponse => {
    const request = ctx.switchToHttp().getRequest<{ user: UserResponse }>();
    return request.user;
  },
);
