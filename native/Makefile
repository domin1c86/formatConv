.PHONY: build-windows clean

build-windows:
	cmd /C "set GOOS=windows&& set GOARCH=amd64&& set CGO_ENABLED=1&& go build -buildmode=c-shared -o format_conv.dll ."

clean:
	del /Q format_conv.dll format_conv.h 2>NUL || exit 0
