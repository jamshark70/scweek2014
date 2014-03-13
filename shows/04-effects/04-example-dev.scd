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



~x = { |vol = 0.1| Dust.ar(100 ! 2, vol) };
~y = { |vol = 0.1| Impulse.ar(LFNoise0.kr(2 ! 2).range(1, 3), 0, vol) };

(
~mix1 = ~x + ~y;
~mix1.play;

~send1 = { |volX = 0.8, volY = 0.4|
	Mix([~x.ar, ~y.ar] * [volX, volY])
};

~fx1 = {
	var sig = ~send1.ar(2);
	CombL.ar(sig, 0.2, MouseX.kr(0.001, 0.2, 1), 0.5)
};
~fx1.play;
)


(
s.boot;
a = ();
a.p = ProxySpace.new.push;
)

(
a.x = MixerChannel(\x, s, 2, 2, level: 0.1);
a.y = MixerChannel(\y, s, 2, 2, level: 0.1);
a.comb = MixerChannel(\comb, s, 2, 2, level: 1);

a.x.newPostSend(a.comb, 0.8);
a.y.newPostSend(a.comb, 0.4);

~x = { Dust.ar(100 ! 2) };
~y = { Impulse.ar(LFNoise0.kr(2 ! 2).range(1, 3)) };
~comb.defineBus(\audio, 2).source = \filter -> { |in|
	CombL.ar(in, 0.2, MouseX.kr(0.001, 0.2, 1), 0.5);
};
)

(
// a.x <<> ~x;
// a.y <<> ~y;
a.x.play(~x);
a.y.play(~y);
a.comb.playfx(~comb);
MixingBoard(mixers: [a.x, a.y, a.comb]);
)

a.p.clear;

s.sendMsg(\n_trace, 1028);
s.sendMsg(\n_trace, 1030);

s.sendMsg(\n_trace, ~comb.objects[0].nodeID);
s.sendMsg(\n_trace, ~x.objects[0].nodeID);
s.sendMsg(\n_trace, ~y.objects[0].nodeID);

a.x.postSends[0].sendSynth.trace

a.comb.synth.trace

a.do(_.free)

PeakMonitor(a.comb);
PeakMonitor(0);

-14.dbamp




p = ProxySpace.new.push;

~saw = { Saw.ar(440, 0.1).dup };
~saw.play;

~chorus.ar(2);
~chorus <-- ~saw;

~chorus = {
	var in = ~saw.ar;
	in + DelayL.ar(in, 0.05, 0.02 + SinOsc.kr([0.1, 0.11], 0, 0.014));
};

p.clear;

~chorus.clear;

~saw.stop;
~saw.rate.asCompileString;


NodeProxy.findRespondingMethodFor(\stop)
s.makeBundle(0.2, { ~saw.play; });

s.makeBundle(0.2, { ~saw.stop(0.5); });



p = ProxySpace.new.push;

~saw = { Saw.ar(440, 0.1).dup };
~saw.play;

~saw.addSpec(\predelay, [0, 0.025]);
~saw.addSpec(\wet1, [0, 1]);
~saw.set(\wet1, 0.5);
~saw[1] = \filter -> { |in, predelay = 0.02|
	DelayL.ar(in, 0.05, predelay + SinOsc.kr([-0.1, 0.11], 0, 0.014));
};

p.gui;

p.clear;

s.sendMsg(\n_trace, 1005);

// is orderNodesMsg completely broken?

x = { SinOsc.ar(880, 0, 0.1) }.play;

y = {
	var mod = In.ar(0, 1),
	sig = SinOsc.ar(440 * (1 + (mod * 20)), 0, 0.1);
	ReplaceOut.ar(0, sig);
}.play;

x.orderNodesMsg(y);
s.sendBundle(nil, Node.orderNodesMsg([x, y]));

s.sendBundle(nil, Node.orderNodesMsg([y, x]));



// try ProxySubmix

p.clear;  // p = ProxySpace.new.push;
a = ();

a.m = ProxySubmix(\revin);
a.m.ar(2);

~rev = {
	var in = a.m.ar;  // why repeat numChannels here?
	FreeVerb2.ar(in[0], in[1], 1, 0.8, 0.2);
};
~rev.play;

~src = { |amp = 8|
	var sig = PinkNoise.ar(amp),
	trig = Dust.kr(2.5) > 0,
	freq = TExpRand.kr(200, 1200, trig),
	// env = Decay2.kr(trig, 0.01, 0.3);
	env = EnvGen.kr(Env.perc(0.01, 0.3), trig);
	BPF.ar(sig, freq, 0.1, env).dup
};
~src.play;

// a.m.addMix(~src, 0);
a.m.addMix(~src, 0.7);

~src.vol = 0;


// automation
~fadeInRvb = {
	Line.kr(0, 0.7.sqrt, 15, doneAction: 2).squared
};
a.m <<>.snd_src ~fadeInRvb;

// ending automation is clumsy - must wait in between these
a.m.set(\snd_src, 0.7);
~fadeInRvb.clear;

NdefGui(a.m, 8);

p.clear;
a.m.clear;
