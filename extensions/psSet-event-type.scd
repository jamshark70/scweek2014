(
Event.addEventType(\psSet, {
	var value,
	sustain = ~sustain.value,
	releaseHolder = ~releaseHolder,
	skipArgs = IdentitySet.with(\gate, \fadeTime, \out).addAll(~skipArgs);
	~freq = ~detunedFreq.value;
	~amp = ~amp.value;
	~proxyspace.keysValuesDo { |name, proxy|
		var ctl = proxy.objects[0];
		case
		{ ctl.isKindOf(SynthDefControl) } {
			ctl.synthDef.allControlNames.do { |cn|
				if(skipArgs.includes(cn.name.asSymbol).not and: {
					(value = cn.name.asSymbol.envirGet).notNil
				}) {
					proxy.set(cn.name, value);
				};
				if(cn.name == \gt and: { sustain.notNil }) {
					if(releaseHolder.notNil) {
						releaseHolder[proxy] = thisThread.beats + sustain;
					};
					thisThread.clock.sched(sustain, {
						if(releaseHolder.isNil or: { releaseHolder[proxy] ? 0 <= thisThread.beats }) {
							proxy.set(cn.name, 0)
						};
					});
				};
			};
		}
		{ ctl.isKindOf(ScalarSynthControl) } {
			if((value = name.envirGet).notNil) {
				proxy.set(\value0, value);
				proxy.source = value;
			};
			if(name == \gt and: { sustain.notNil }) {
				if(releaseHolder.notNil) {
					releaseHolder[proxy] = thisThread.clock.beats + sustain;
				};
				thisThread.clock.sched(sustain, {
					if(releaseHolder.isNil or: { releaseHolder[proxy] ? 0 <= thisThread.clock.beats }) {
						proxy.set(name, 0);
						proxy.source = 0;
					};
				});
			};
		}
	};
});

AbstractPlayControl.proxyControlClasses[\psSet] = PatternControl;
AbstractPlayControl.buildMethods[\psSet] = { |pattern, proxy, channelOffset = 0, index|
	var watcher, rest = false;
	if(currentEnvironment.isKindOf(ProxySpace).not) {
		Error("\\psSet may not be used outside of a ProxySpace").throw;
	};
	// I don't have access to the stream player in here.
	// To silence the proxy upon 'stop', I have to set a flag
	// to turn events into rests.
	// If rest is true, all events will be rests.
	// Otherwise respect the existing isRest
	watcher = SimpleController(proxy)
	.put(\play, { rest = false })
	.put(\stop, { rest = true })
	.put(\clear, { rest = true; watcher.remove });
	// releaseHolder may well be a hack,
	// but it should actually be local to the pattern
	// must protect in a Ref
	// Pbindf will extract its value automatically
	// but not use composeEvents()
	Pbindf(pattern,
		\type, \psSet,
		\proxyspace, currentEnvironment,
		\releaseHolder, `(IdentityDictionary.new),
		#[isRest, gt, t_trig], Pfunc { |ev|
			[
				rest or: { ev[\isRest] ?? { false } },
				ev[\gt] ?? { 1 },
				ev[\t_trig] ?? { 1 }
			]
		}
	).buildForProxy(proxy, channelOffset, index)
};
)