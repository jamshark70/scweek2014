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
