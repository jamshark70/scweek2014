+ SimpleNumber {
	proxyControlClass { ^StreamControl }

	buildForProxy { | proxy, channelOffset = 0 |
		^[this].buildForProxy(proxy, channelOffset)
	}
}

+ Array {

	proxyControlClass { ^StreamControl }

	buildForProxy { | proxy, channelOffset = 0 |
		proxy.initBus(\control, this.size);
		^(
			type: \fadeBus,
			array: this,
			finish: {
				~out = proxy.index + channelOffset;
				~group = proxy.group;
				~rate = proxy.rate;
				~numChannels = proxy.numChannels;
				~fadeTime = proxy.fadeTime;
				~curve = proxy.nodeMap.at(\curve);
			}
		)
	}
}

+ NdefParamGui {
	setFunc { |key|
		if(object.objects.notEmpty and: { object.objects.array.first.isKindOf(SynthControl) }) {
			^{ |sl| object.set(key, sl.value) }
		} {
			^{ |sl| object.source = sl.value }
		};
	}
}
