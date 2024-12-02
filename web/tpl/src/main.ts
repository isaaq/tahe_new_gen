class Main {

    wasm(name) {
        return (async () => {
            const fetchPromise = fetch(name + '.wasm');
            const { instance } = await WebAssembly.instantiateStreaming(fetchPromise);
            return instance
        })();
    }

}

// let _main = new Main();
// Opal.loaded(typeof (OpalLoaded) === "undefined" ? [] : OpalLoaded);
// Opal.require("opal"); Opal.require("ui/web");