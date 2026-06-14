package main

import "C"
import "fmt"

//export getVersion
func getVersion() *C.char {
	return C.CString("1.0.0")
}

func main() {
	fmt.Println("Format Converter Go Backend")
}
