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
#include "intrinsics.h"

extern "C" JNIEXPORT jfloatArray JNICALL Java_ca_bcit_partc_MyGLRenderer_mmult( JNIEnv* env, jobject thiz, jfloatArray a, jfloatArray b)
{
    // Create the memory objects
    int size = (*env).GetArrayLength(a);
    jfloatArray result = (*env).NewFloatArray(size);

    jfloat *aMatrix = (*env).GetFloatArrayElements(a, 0);
    jfloat *bMatrix = (*env).GetFloatArrayElements(b, 0);

    jfloat *temp = new jfloat[size];

    // TODO: Matrix multiplication using NEON



    // Release memory objects
    (*env).ReleaseFloatArrayElements(a, aMatrix, 0);
    (*env).ReleaseFloatArrayElements(b, bMatrix, 0);

    // Create return structure
    (*env).SetFloatArrayRegion(result, 0, size, temp);
    return result;
}