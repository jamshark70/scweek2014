+ NodeProxy {
	put { | index, obj, channelOffset = 0, extraArgs, now = true |
		var container, bundle, orderIndex;

		if(obj.isNil) { this.removeAt(index); ^this };
		if(index.isSequenceableCollection) {
			^this.putAll(obj.asArray, index, channelOffset)
		};

		orderIndex = index ? 0;
		container = obj.makeProxyControl(channelOffset, this, orderIndex);
		if(container !== objects[orderIndex]) {
			container.build(this, orderIndex); // bus allocation happens here

			if(this.shouldAddObject(container, index)) {
				bundle = MixedBundle.new;
				if(index.isNil)
				{ this.removeAllToBundle(bundle) }
				{ this.removeToBundle(bundle, index) };
				objects = objects.put(orderIndex, container);
				this.changed(\source, [obj, index, channelOffset, extraArgs, now]);
			} {
				format("failed to add % to node proxy: %", obj, this).inform;
				^this
			};

			if(server.serverRunning) {
				now = awake && now;
				if(now) {
					this.prepareToBundle(nil, bundle);
				};
				container.loadToBundle(bundle, server);
				loaded = true;
				if(now) {
					container.wakeUpParentsToBundle(bundle);
					this.sendObjectToBundle(bundle, container, extraArgs, index);
				};
				nodeMap.wakeUpParentsToBundle(bundle);
				bundle.schedSend(server, clock ? TempoClock.default, quant);
			} {
				loaded = false;
			}
		};

	}
}

+ Object {
	makeProxyControl { arg channelOffset = 0, proxy, index(0);
		^this.proxyControlClass.new(this, channelOffset, proxy, index);
	}
	buildForProxy { arg proxy, channelOffset=0, index;
		var argNames;
		argNames = this.argNames;
		^ProxySynthDef(
			SystemSynthDefs.tempNamePrefix ++ proxy.generateUniqueName ++ index,
			this.prepareForProxySynthDef(proxy, channelOffset, index),
			proxy.nodeMap.ratesFor(argNames),
			nil,
			true,
			channelOffset,
			proxy.numChannels,
			proxy.rate
		);
	}
}

+ SimpleNumber {
	proxyControlClass { ^ScalarSynthControl }

	prepareForProxySynthDef { arg proxy, channelOffset, index(0);
		proxy.initBus(\control, 1);
		^{ NamedControl(("value" ++ index).asSymbol, this, proxy.rate, 0.05) }
	}
}

+ RawArray {
	proxyControlClass { ^ScalarSynthControl }

	prepareForProxySynthDef { arg proxy, channelOffset, index(0);
		proxy.initBus(\control, this.size);
		^{ NamedControl(("value" ++ index).asSymbol, this, proxy.rate, 0.05) }
	}
}