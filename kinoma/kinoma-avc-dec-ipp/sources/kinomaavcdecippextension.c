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
#define __FSKIMAGE_PRIV__
#include "kinomaavcdecipp.h"

static FskImageDecompressorRecord avcDecompress =
	{avcDecodeCanHandle, avcDecodeNew, avcDecodeDispose, avcDecodeDecompressFrame, NULL, avcDecodeGetMetaData, avcDecodeProperties, NULL, avcDecodeFlush };


FskExport(FskErr) kinomaavcdecipp_fskLoad(FskLibrary library)
{
	FskErr err = kFskErrNone;
	
	dlog( "into kinomaavcdecipp_fskLoad\n"); 
	FskImageDecompressorInstall(&avcDecompress);
	dlog( "out of kinomaavcdecipp_fskLoad\n"); 
	
	return err;
}


FskExport(FskErr) kinomaavcdecipp_fskUnload(FskLibrary library)
{
	dlog( "into kinomaavcipp_fskUnload\n");
	FskImageDecompressorUninstall(&avcDecompress);
	dlog( "out of kinomaavcdecipp_fskUnload\n"); 
	
	return kFskErrNone;
}
