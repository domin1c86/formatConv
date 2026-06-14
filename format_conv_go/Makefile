.PHONY: build-windows build-macos build-linux clean

build-windows:
	set GOOS=windows
	set GOARCH=amd64
	go build -buildmode=c-shared -o format_conv.dll .

build-macos:
	GOOS=darwin GOARCH=amd64 go build -buildmode=c-shared -o libformat_conv.dylib .

build-linux:
	GOOS=linux GOARCH=amd64 go build -buildmode=c-shared -o libformat_conv.so .

clean:
	rm -f *.dll *.dylib *.so *.h
