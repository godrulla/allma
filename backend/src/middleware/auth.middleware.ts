import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { AppError } from './errorHandler';

export interface AuthRequest extends Request {
  userId?: string;
  user?: any;
}

export const authenticate = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      throw new AppError('No authentication token provided', 401);
    }

    const userId = await authService.verifyToken(token);
    req.userId = userId;
    
    next();
  } catch (error) {
    next(new AppError('Invalid or expired token', 401));
  }
};

export const optionalAuth = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (token) {
      const userId = await authService.verifyToken(token);
      req.userId = userId;
    }
    
    next();
  } catch (error) {
    next();
  }
};