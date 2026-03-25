import { Router, Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { AppError } from '../middleware/errorHandler';
import { authRateLimiter } from '../middleware/rateLimiter';
import Joi from 'joi';

const router = Router();

const signUpSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).required(),
  displayName: Joi.string().min(2).max(50).required(),
});

const signInSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

router.post('/signup', authRateLimiter, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { error, value } = signUpSchema.validate(req.body);
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    const user = await authService.createUser(
      value.email,
      value.password,
      value.displayName
    );

    const token = await authService.signIn(value.email, value.password);

    res.status(201).json({
      success: true,
      data: {
        user,
        token: token.token
      }
    });
  } catch (error) {
    next(error);
  }
});

router.post('/signin', authRateLimiter, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { error, value } = signInSchema.validate(req.body);
    if (error) {
      throw new AppError(error.details[0].message, 400);
    }

    const result = await authService.signIn(value.email, value.password);

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
});

router.post('/firebase-auth', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { idToken } = req.body;
    
    if (!idToken) {
      throw new AppError('ID token is required', 400);
    }

    const result = await authService.signInWithFirebaseToken(idToken);

    res.json({
      success: true,
      data: result
    });
  } catch (error) {
    next(error);
  }
});

router.post('/reset-password', authRateLimiter, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      throw new AppError('Email is required', 400);
    }

    await authService.resetPassword(email);

    res.json({
      success: true,
      message: 'Password reset email sent'
    });
  } catch (error) {
    next(error);
  }
});

export default router;