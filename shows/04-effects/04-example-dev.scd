// post-fader sends

currentEnvironment

a = NodeProxy.new(s, \audio, 2);
a.clear;

AbstractPlayControl.proxyControlClasses.put(\filterFb, SynthDefControl);
AbstractPlayControl.buildMethods.put(\filterFb, { arg func, proxy, channelOffset=0, index;
	var ok, ugen;
	if(proxy.isNeutral) {
		ugen = func.value(Silent.ar);
		ok = proxy.initBus(ugen.rate, ugen.numChannels);
		if(ok.not) { Error("NodeProxy input: wrong rate/numChannels").throw }
	};

	{ arg out;
		var e;
		e = EnvGate.new * Control.names(["wet"++(index ? 0)]).kr(1.0);
		if(proxy.rate === 'audio') {
			XOut.ar(out, e, SynthDef.wrap(func, nil, [InFeedback.ar(out, proxy.numChannels)]))
		} {
			XOut.kr(out, e, SynthDef.wrap(func, nil, [In.kr(out, proxy.numChannels)]))				};
	}.buildForProxy( proxy, channelOffset, index )
});

p = ProxySpace.new.push;

~src = { |amp = 3|
	var sig = PinkNoise.ar(amp),
	trig = Dust.kr(2.5) > 0,
	freq = TExpRand.kr(200, 1200, trig),
	env = Decay2.kr(trig, 0.01, 0.3);
	BPF.ar(sig, freq, 0.1, env).dup
};

~src.set(\amp, 8);

~src.play;

~src.stop;

~src.inspect;

// shared reverb

// ~rvb = NodeProxy(s, \audio, 2);
~rvb.defineBus(\audio, 2).source_(\filterFb -> { |in|
	FreeVerb2.ar(in[0], in[1], 1, 0.8, 0.2);
}).play;

s.sendMsg(\n_trace, ~rvb.objects[0].nodeID);
s.sendMsg(\n_trace, ~rvb.objects[1].nodeID);

~rvb = \filterFb -> { |in|
	FreeVerb2.ar(in[0], in[1], 1, 0.8, 0.2);
};

~rvb.bus

~hardwareOut.defineBus(\audio, 2).source_(\filterFb -> { |in| in }).play;

// note "index" -- unnecessary implementation detail
~send.defineBus(\audio, 2).source_(\filterFb -> { |in| in }).play(~rvb.bus.index);

p.gui;

// I guess 'send' should be

~src.playN([~hardwareOut.bus.index, ~send.bus.index]);
~src.playN([~hardwareOut.bus.index]);

p.clear;

s.audioBusAllocator.debug;

~rvb.clear;

p.clear;
s.newAllocators;

~send.monitor.dump;
~send.monitor.ins;
~send.monitor.outs;

p.pop;

// well, all that failed... try MixerChannel
a = ();
a.p = ProxySpace.new.push;

a.src = MixerChannel(\src, s, 2, 2);

// lose play/stop with this (though you can mute the mixer)

~src = { |amp = 8|
	var sig = PinkNoise.ar(amp),
	trig = Dust.kr(2.5) > 0,
	freq = TExpRand.kr(200, 1200, trig),
	env = Decay2.kr(trig, 0.01, 0.3);
	BPF.ar(sig, freq, 0.1, env).dup
};
~src.bus = a.src.inbus;
~src.group = a.src.synthgroup;


a.rvb = MixerChannel(\rvb, s, 2, 2, 1);

~rvb.bus = a.rvb.inbus;
~rvb.group = a.rvb.effectgroup;
~rvb = \filter -> { |in| FreeVerb2.ar(in[0], in[1], 1, 0.8, 0.2) };

s.sendMsg(\n_trace, ~rvb.objects[0].nodeID);

MixingBoard(\test, nil, a.src, a.rvb);

a.src.newPostSend(a.rvb, 1);

~src.set(\amp, 8);

s.sendMsg(\n_trace, 1003);
a.p.clear;

a.do { |thing| if(thing.isKindOf(MixerChannel)) { thing.free } };


// test MixerChannelBusPlug
a = ();
a.p = ProxySpace.new.push;

a.saveAddr = s.addr;
a.debugAddr = DebugNetAddr("127.0.0.1", 57110);

s.addr = a.debugAddr;

a.src = MixerChannel(\src, s, 2, 2);
// a.src.inbus

~src = { |amp = 8|
	var sig = PinkNoise.ar(amp),
	trig = Dust.kr(2.5) > 0,
	freq = TExpRand.kr(200, 1200, trig),
	env = Decay2.kr(trig, 0.01, 0.3);
	BPF.ar(sig, freq, 0.1, env).dup
};

a.src <<> ~src;

a.rvb = MixerChannel(\rvb, s, 2, 2, 1);

~rvb.defineBus(\audio, 2).source_(\filter -> { |in|
	FreeVerb2.ar(in[0], in[1], 1, 0.8, 0.2)
});

a.rvb.playfx(~rvb);

a.src.newPostSend(a.rvb, 0.8);

a.src <<>.stop ~src;  // or, a.src.mute(true)

MixingBoard(\test, nil, a.src, a.rvb);


s.sendMsg(\n_trace, ~rvb.objects[0].nodeID);



s.sendMsg(\n_trace, 1005);
s.sendMsg(\n_trace, 1007);

a.p.clear;

Library.at(MixerChannelBusPlug)

Library.at(MixerChannelBusPlug, ~src).dump

Nil.findRespondingMethodFor(\ar)



(
switch(1)
{ 1 } { "match".postln };
)