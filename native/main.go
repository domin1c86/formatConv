package main

/*
#include <stdlib.h>

extern void callProgressCallback(void* callback, long long id, double progress, long long processed, long long total, int status, char* error);
*/
import "C"
import (
	"encoding/json"
	"fmt"
	"runtime"
	"unsafe"

	"native/converter"
	"native/models"
)

var conv *converter.Converter

func init() {
	conv = converter.NewConverter()
}

//export getVersion
func getVersion() *C.char {
	return C.CString("1.0.0")
}

//export getSupportedFormats
func getSupportedFormats() *C.char {
	formats := conv.GetSupportedFormats()
	jsonData, err := json.Marshal(formats)
	if err != nil {
		return C.CString("{}")
	}
	return C.CString(string(jsonData))
}

//export detectFormat
func detectFormat(filePath *C.char) *C.char {
	goPath := C.GoString(filePath)
	info, err := conv.DetectFormat(goPath)
	if err != nil {
		return C.CString("{}")
	}
	jsonData, err := json.Marshal(info)
	if err != nil {
		return C.CString("{}")
	}
	return C.CString(string(jsonData))
}

//export convertFile
func convertFile(inputPath, outputPath, optionsJSON *C.char, callback unsafe.Pointer) C.longlong {
	goInput := C.GoString(inputPath)
	goOutput := C.GoString(outputPath)
	goOptions := C.GoString(optionsJSON)

	var options models.ConversionOptions
	if err := json.Unmarshal([]byte(goOptions), &options); err != nil {
		return -1
	}

	var progressFunc func(uintptr, float64, int64, int64, int, string)
	if callback != nil {
		progressFunc = func(id uintptr, progress float64, processed, total int64, status int, errMsg string) {
			runtime.LockOSThread()
			defer runtime.UnlockOSThread()
			cErr := C.CString(errMsg)
			defer C.free(unsafe.Pointer(cErr))
			C.callProgressCallback(callback, C.longlong(id), C.double(progress), C.longlong(processed), C.longlong(total), C.int(status), cErr)
		}
	}

	conversionID, err := conv.ConvertFile(goInput, goOutput, options, progressFunc)
	if err != nil {
		return -1
	}

	return C.longlong(conversionID)
}

//export runMediaOperation
func runMediaOperation(optionsJSON *C.char, callback unsafe.Pointer) C.longlong {
	goOptions := C.GoString(optionsJSON)

	var options models.MediaOperationOptions
	if err := json.Unmarshal([]byte(goOptions), &options); err != nil {
		return -1
	}

	var progressFunc func(uintptr, float64, int64, int64, int, string)
	if callback != nil {
		progressFunc = func(id uintptr, progress float64, processed, total int64, status int, errMsg string) {
			runtime.LockOSThread()
			defer runtime.UnlockOSThread()
			cErr := C.CString(errMsg)
			defer C.free(unsafe.Pointer(cErr))
			C.callProgressCallback(callback, C.longlong(id), C.double(progress), C.longlong(processed), C.longlong(total), C.int(status), cErr)
		}
	}

	conversionID, err := conv.RunMediaOperation(options, progressFunc)
	if err != nil {
		return -1
	}

	return C.longlong(conversionID)
}

//export getConversionStatus
func getConversionStatus(conversionID C.longlong) *C.char {
	id := uintptr(conversionID)
	status := conv.GetConversionStatus(id)
	if status == nil {
		return C.CString("{}")
	}
	jsonData, err := json.Marshal(status)
	if err != nil {
		return C.CString("{}")
	}
	return C.CString(string(jsonData))
}

//export cancelConversion
func cancelConversion(conversionID C.longlong) C.int {
	id := uintptr(conversionID)
	if conv.CancelConversion(id) {
		return 1
	}
	return 0
}

//export freeString
func freeString(str *C.char) {
	C.free(unsafe.Pointer(str))
}

func main() {
	fmt.Println("Format Converter Go Backend")
}
