+ FormantTable {
	*atKlank { |preset, sr(Server.default.sampleRate ?? { Server.default.options.sampleRate ?? { 44100 } })|
		var out = table[preset].copy;
		out[2] = (log(0.001) / log(1 - (pi/sr * out[0] * out[2]))) / sr;
		^out
	}

	*getKlank { |preset, sr(Server.default.sampleRate)|
		^this.atKlank(preset, sr)
	}
}