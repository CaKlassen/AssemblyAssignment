/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
#include <jni.h>
#include <cpu-features.h>
#include <arm_neon.h>
#include "intrinsics.h"

extern "C" JNIEXPORT jfloatArray JNICALL Java_ca_bcit_partc_MyGLRenderer_mmult( JNIEnv* env, jobject thiz, jfloatArray a, jfloatArray b)
{
    // Create the memory objects
    int size = (*env).GetArrayLength(a);
    jfloatArray result = (*env).NewFloatArray(size);

    jfloat *aMatrix = (*env).GetFloatArrayElements(a, 0);
    jfloat *bMatrix = (*env).GetFloatArrayElements(b, 0);


    jfloat *tempResults = new jfloat[size];

    // TODO: Matrix multiplication using NEON

    //Matrix 1
    float32x4_t M1firstCol = vld1q_f32(aMatrix);
    float32x4_t M1secondCol = vld1q_f32(&aMatrix[4]);
    float32x4_t M1thirdCol = vld1q_f32(&aMatrix[8]);
    float32x4_t M1fourthCol = vld1q_f32(&aMatrix[12]);


    //matrix 2
    //float32x4_t M2firstCol = vld1q_f32(bMatrix);
    //float32x4_t M2secondCol = vld1q_f32(&bMatrix[4]);
    //float32x4_t M2thirdCol = vld1q_f32(&bMatrix[8]);
    //float32x4_t M2fourthCol = vld1q_f32(&bMatrix[12]);

    //first column of output matrix
    float32_t scalar = float32_t(bMatrix[0]);
    float32x4_t resCol1 = vmulq_n_f32(M1firstCol, scalar);
    scalar = float32_t(bMatrix[1]);
    vmlaq_n_f32(resCol1, M1secondCol,scalar);
    scalar = float32_t(bMatrix[2]);
    vmlaq_n_f32(resCol1, M1thirdCol,scalar);
    scalar = float32_t(bMatrix[3]);
    vmlaq_n_f32(resCol1, M1fourthCol,scalar);

    //second column
    scalar = float32_t(bMatrix[4]);
    float32x4_t resCol2 = vmulq_n_f32(M1firstCol, scalar);
    scalar = float32_t(bMatrix[5]);
    vmlaq_n_f32(resCol2, M1secondCol,scalar);
    scalar = float32_t(bMatrix[6]);
    vmlaq_n_f32(resCol2, M1thirdCol,scalar);
    scalar = float32_t(bMatrix[7]);
    vmlaq_n_f32(resCol2, M1fourthCol,scalar);

    //third column
    scalar = float32_t(bMatrix[8]);
    float32x4_t resCol3 = vmulq_n_f32(M1firstCol, scalar);
    scalar = float32_t(bMatrix[9]);
    vmlaq_n_f32(resCol3, M1secondCol,scalar);
    scalar = float32_t(bMatrix[10]);
    vmlaq_n_f32(resCol3, M1thirdCol,scalar);
    scalar = float32_t(bMatrix[11]);
    vmlaq_n_f32(resCol3, M1fourthCol,scalar);

    //fourth column
    scalar = float32_t(bMatrix[12]);
    float32x4_t resCol4 = vmulq_n_f32(M1firstCol, scalar);
    scalar = float32_t(bMatrix[13]);
    vmlaq_n_f32(resCol4, M1secondCol,scalar);
    scalar = float32_t(bMatrix[14]);
    vmlaq_n_f32(resCol4, M1thirdCol,scalar);
    scalar = float32_t(bMatrix[15]);
    vmlaq_n_f32(resCol4, M1fourthCol,scalar);


    //transfer results back
    vst1q_f32(tempResults, resCol1);
    vst1q_f32(&tempResults[4], resCol2);
    vst1q_f32(&tempResults[8], resCol3);
    vst1q_f32(&tempResults[12], resCol4);


    // Release memory objects
    (*env).ReleaseFloatArrayElements(a, aMatrix, 0);
    (*env).ReleaseFloatArrayElements(b, bMatrix, 0);

    // Create return structure
    (*env).SetFloatArrayRegion(result, 0, size, tempResults);
    return result;
}