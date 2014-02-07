ScalarSynthControl : SynthDefControl {
	*new { |source, channelOffset = 0, proxy, index(0)|
		var existing = proxy.objects[index],
		ctlName = ("value" ++ index).asSymbol;
		if(existing.class !== this) {
			proxy.nodeMap.set(ctlName, source);
			^super.new(source, channelOffset, proxy)
		} {
			proxy.set(ctlName, source);
			existing.source = source;
			^existing
		}
	}
	source_ { |newSource|
		source = newSource
	}
}