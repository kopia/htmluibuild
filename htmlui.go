package htmluibuild

import (
	"embed"
	"io/fs"
	"net/http"
)

//go:embed build
var data embed.FS

// AssetFile return a http.FileSystem instance that data backend by asset.
func AssetFile() http.FileSystem {
	f, err := fs.Sub(data, "build")
	if err != nil {
		panic("could not embed htmlui")
	}

	return http.FS(f)
}
