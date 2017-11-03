/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "Matrix4.h"

@implementation Matrix4

#pragma mark - Matrix creation

+ (Matrix4 *)makePerspectiveViewAngle:(float)angleRad
                          aspectRatio:(float)aspect
                                nearZ:(float)nearZ
                                 farZ:(float)farZ{
  Matrix4 *matrix = [[Matrix4 alloc] init];
  matrix->glkMatrix = GLKMatrix4MakePerspective(angleRad, aspect, nearZ, farZ);
  return matrix;
}

- (instancetype)init{
  self = [super init];
  if(self != nil){
    glkMatrix = GLKMatrix4Identity;
  }
  return self;
}

- (instancetype)copy{
  Matrix4 *mCopy = [[Matrix4 alloc] init];
  mCopy->glkMatrix = self->glkMatrix;
  return mCopy;
}

#pragma mark - Matrix transformation

- (void)scale:(float)x y:(float)y z:(float)z{
  glkMatrix = GLKMatrix4Scale(glkMatrix, x, y, z);
}

- (void)rotateAroundX:(float)xAngleRad y:(float)yAngleRad z:(float)zAngleRad{
  glkMatrix = GLKMatrix4Rotate(glkMatrix, xAngleRad, 1, 0, 0);
  glkMatrix = GLKMatrix4Rotate(glkMatrix, yAngleRad, 0, 1, 0);
  glkMatrix = GLKMatrix4Rotate(glkMatrix, zAngleRad, 0, 0, 1);
}

- (void)translate:(float)x y:(float)y z:(float)z{
  glkMatrix = GLKMatrix4Translate(glkMatrix, x, y, z);
}

- (void)multiplyLeft:(Matrix4 *)matrix{
  glkMatrix = GLKMatrix4Multiply(matrix->glkMatrix, glkMatrix);
}

#pragma mark - Helping methods

- (void *)raw{
  return glkMatrix.m;
}

- (void)transpose{
  glkMatrix = GLKMatrix4Transpose(glkMatrix);
}

+ (float)degreesToRad:(float)degrees{
  return GLKMathDegreesToRadians(degrees);
}

+ (NSInteger)numberOfElements{
  return 16;
}
- (NSString *_Nullable)stringRepresentation{
    return [NSString stringWithFormat:@"{{%f, %f, %f, %f}, {%f, %f, %f, %f}, {%f, %f, %f, %f}, {%f, %f, %f, %f}}", self->glkMatrix.m00, self->glkMatrix.m01, self->glkMatrix.m02, self->glkMatrix.m03,
            self->glkMatrix.m10, self->glkMatrix.m11, self->glkMatrix.m12,self->glkMatrix.m13,
            self->glkMatrix.m20, self->glkMatrix.m21, self->glkMatrix.m22, self->glkMatrix.m23,
            self->glkMatrix.m30, self->glkMatrix.m31, self->glkMatrix.m32, self->glkMatrix.m33];
}
- (void)setMatrixFromStringRepresentation:(NSString *)string{
    NSArray *comps = [string componentsSeparatedByString:@","];
    if(comps.count == 4){
        int counter = 0;
        for (NSString * comp in comps) {
            NSString *comp1 = comp.copy;
            comp1 = [comp1 stringByReplacingOccurrencesOfString:@"{" withString:@""];
            comp1 = [comp1 stringByReplacingOccurrencesOfString:@"}" withString:@""];
            comp1 = [comp1 stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSArray *subComps = [comp1 componentsSeparatedByString:@","];
            switch (counter) {
                case 0:
                {
                    self->glkMatrix.m00 = [subComps[0]floatValue];
                    self->glkMatrix.m01 = [subComps[1]floatValue];
                    self->glkMatrix.m02 = [subComps[2]floatValue];
                    self->glkMatrix.m03 = [subComps[3]floatValue];
                }
                    break;
                case 1:
                {
                    self->glkMatrix.m10 = [subComps[0]floatValue];
                    self->glkMatrix.m11 = [subComps[1]floatValue];
                    self->glkMatrix.m22 = [subComps[2]floatValue];
                    self->glkMatrix.m33 = [subComps[3]floatValue];
                }
                    break;
                case 2:
                {
                    self->glkMatrix.m20 = [subComps[0]floatValue];
                    self->glkMatrix.m21 = [subComps[1]floatValue];
                    self->glkMatrix.m22 = [subComps[2]floatValue];
                    self->glkMatrix.m23 = [subComps[3]floatValue];
                }
                    break;
                case 3:
                {
                    self->glkMatrix.m30 = [subComps[0]floatValue];
                    self->glkMatrix.m31 = [subComps[1]floatValue];
                    self->glkMatrix.m32 = [subComps[2]floatValue];
                    self->glkMatrix.m33 = [subComps[3]floatValue];
                }
                    break;
                default:
                    break;
            }
        }
        
    }
}

@end
