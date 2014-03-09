// one proxy per plug
// src keeps playing on its own bus
// you should not .play or .stop it!
// instead, plug and unplug it into the mc:
// mc <<> proxy
// mc <<>.stop proxy
// the mc *is* the proxy's monitor after that


MixerChannelBusPlug : NodeProxy {
	var <mixer, srcProxy, monitorOn = false;
	*new { |mixer|
		^super.new(mixer.server, \audio, mixer.inChannels).init2(mixer)
	}
	init2 { |mix|
		this.group = Group.new;
		this.mixer = mix;
		this.playToMixer;
	}
	clear {
		mixer.removeDependant(this);
		srcProxy.removeDependant(this);
		Library.global.removeEmptyAt(this.class, srcProxy);
		super.clear;
	}
	mixer_ { |mix|
		mixer.removeDependant(this);
		mixer = mix;
		mixer.addDependant(this);
		group.moveToTail(mixer.synthgroup);
		this.bus = mixer.inbus;
	}
	<<> { |proxy, adverb|
		if(adverb != \stop and: { proxy.respondsTo(\ar) }) {
			srcProxy.removeDependant(this);
			Library.global.removeAt(this.class, srcProxy);
			srcProxy = proxy;
			srcProxy.addDependant(this);
			Library.put(this.class, srcProxy, this);
			monitorOn = true;
			this.playToMixer(true);
		} {
			monitorOn = false;
			this.playToMixer(true);
		};
	}

	playToMixer { |proxyChanged = false|
		if(proxyChanged) {
			if(monitorOn) {
				this.source = { srcProxy.ar(mixer.inChannels) };
			} {
				this.source = { DC.ar(0) ! mixer.inChannels };
			};
		};
	}

	update { |obj, what|
		if(obj === mixer) {
			if(what == \mixerFreed) { this.clear };
		} {
			if(what == \clear) { this.clear };
		};
	}
}

// flippin' hell, what a mess
// How to trace back to a specific bus plug?
// Library for now...

+ MixerChannel {
	<<> { |proxy, adverb|
		var result;
		if(Library.at(MixerChannelBusPlug, proxy).isNil) {
			result = MixerChannelBusPlug(this);
		} {
			result = Library.at(MixerChannelBusPlug, proxy);
		};
		^result.perform('<<>', proxy, adverb);
	}
}

// supports aMixer.playfx(nodeproxy)
+ NodeProxy {
	playInMixerGroup { |mixer, target, patchType, args|
		if(target === mixer.effectgroup) {
			// you might not be able to undo this mapping...
			this.bus = mixer.inbus;
			this.group.moveToTail(target);
		} {
			mixer <<> this;
		}
	}
}
