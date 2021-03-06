/*
     Copyright (C) 2010-2015 Marvell International Ltd.
     Copyright (C) 2002-2010 Kinoma, Inc.

     Licensed under the Apache License, Version 2.0 (the "License");
     you may not use this file except in compliance with the License.
     You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

     Unless required by applicable law or agreed to in writing, software
     distributed under the License is distributed on an "AS IS" BASIS,
     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
     See the License for the specific language governing permissions and
     limitations under the License.
*/
#include "cryptTypes.h"

enum aes_cipher_direction {aes_cipher_encryption, aes_cipher_decryption};

extern void aes_keysched(const UInt8 *key, int Nk, int Nb, int Nr, enum aes_cipher_direction direction, UInt32 *subkey);
extern void aes_encrypt4(const UInt8 *in, UInt8 *out, int Nr, UInt32 *subkey);
extern void aes_decrypt4(const UInt8 *in, UInt8 *out, int Nr, UInt32 *subkey);
