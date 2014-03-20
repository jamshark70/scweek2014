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
	env = EnvGen.kr(Env.perc(0.01, 0.3), trig),
	pan = env * TRand.kr(0.5, 1.0, trig) * (TIRand.kr(0, 1, trig) * 2 - 1);
	Pan2.ar(BPF.ar(sig, freq, 0.1, env), pan)
};
~src.play;

// a.m.addMix(~src, 0);
a.m.addMix(~src, 0.7/*, mono: false*/);

~src.vol = 0;

p.gui;
a.m.gui;

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

// stereo really working?
a.m.inspect;
a.m.objects.indices;

s.sendMsg(\n_trace, a.m.objects[1].nodeID);

a.m.clear;

ProxySubmix.findRespondingMethodFor(\clear);



// doppler
a = {
	var sig = SinOsc.ar(440, 0, 0.1),
	delaytime = Line.kr(1.2, 0.2, 2),
	delay = DelayL.ar(sig, 1.2, delaytime),
	eg1 = EnvGen.kr(Env.linen(0.01, 0.98, 0.01)),
	eg = EnvGen.kr(Env.linen(0.01, 1.98, 0.01), doneAction: 2);
	(((sig * eg1) + delay) * eg).dup
}.play;

a.trace;



// distortion
x = Signal.sineFill(512, [1]).as(Array);

[x, (x * 3).tanh].lace(x.size * 2).plot(numChannels: 2);


// frequency is too low!

x = Signal.sineFill(512, [1]);
y = (x * 3).tanh;

a = x.fft(Signal.newClear(x.size), Signal.fftCosTable(x.size));
a.real.plot;
a.real.maxItem;

a = y.fft(Signal.newClear(y.size), Signal.fftCosTable(y.size));


// phase increment for 441 Hz @ 44100 = 100 samples / cycle
i = 2pi / 100;

x = Signal.fill(2048, { |x| sin(x * i) });
x = x * Signal.hanningWindow(x.size);
x.plot;

a = x.fft(Signal.newClear(x.size), Signal.fftCosTable(x.size));
a.real.keep(a.real.size >> 1).abs.plot;
a.real.maxItem;

y = Signal.fill(2048, { |x| (8 * sin(x * i)).tanh });
y = y * Signal.hanningWindow(y.size);
y.plot;

b = y.fft(Signal.newClear(y.size), Signal.fftCosTable(y.size));
b.real.keep(b.real.size >> 1).abs.plot;
b.real.maxItem;

[a.real.as(Array).abs, b.real.as(Array).abs].lace(a.real.size).plot(numChannels: 2);
[a.real.as(Array).abs, b.real.as(Array).abs].lace(a.real.size div: 2).plot(numChannels: 2);

x = Pseries.fromEndpoints(-1, 1, 513).asStream.all;

p = [x, (x * 2).tanh, (x * 8).tanh].lace(x.size * 3).plot(numChannels: 3);
p.domainSpecs = [[-1, 1]];
p.refresh;

Shaper.ar(bufnum, in)

p = [x, (x * 2).tanh, (x * 2).tanh - x].lace(x.size * 3).plot(numChannels: 3);
p.domainSpecs = [[-1, 1]];
p.refresh;

p = [x, (x * 2).tanh, (x * 8).tanh - x].lace(x.size * 3).plot(numChannels: 3);
p.domainSpecs = [[-1, 1]];
p.refresh;

[x, x.softclip].lace(x.size * 2).plot(numChannels: 2);


p.clear;  // p = ProxySpace.new.push;

~kick.ar(2);  // initialize stereo
~kick[1] = \filter -> { |in, preamp = 5, postamp = 0.1|
	(in * preamp).tanh * postamp
};
~kick.addSpec(\preamp, [0.25, 20, \exp]);
~kick.addSpec(\postamp, \amp);
~kick.play;

~kick[0] = {
	var trig = Impulse.ar(2),
	freq = EnvGen.ar(Env([400, 400, 50], [0, 0.07], \exp), trig),
	ampeg = EnvGen.ar(Env.perc(0.01, 0.4), trig),
	sig = SinOsc.ar(freq);
	(sig * ampeg).dup
};

~kick.source

~kick.play;

~kick.gui

p.clear;


x = Signal.sineFill(512, [1]);  // x.plot to see
b = Buffer.sendCollection(s, x.asWavetable, 1, action: { "done".postln });

b.sendCollection(x.asWavetable);

~kick[1] = \filter -> { |in, postamp = 0.1|
	in = Limiter.ar(in, 1);
	Shaper.ar(b, in, postamp);
};

b.sendCollection(
	Signal.sineFill(512, [1, 0.5, 0.33]).asWavetable
);

// "sine1" on a Buffer is a shortcut
b.sine1([0, 0, 0, 0, 0, 0, 0, 1]);

BPeakEQ.filenameSymbol
BEQSuite
BPeakEQ.ar(in, freq, rq, db)
BLowShelf.ar(in, freq, rs, db)
BLowPass.ar(in, freq, rq)
p.clear;

s.sendMsg(\n_trace, ~kick.objects[1].nodeID);

x = Signal.sineFill(512, [1]);
y = x.collect { |x| sin(x.linlin(-1, 1, -0.5pi, 1.5pi)) };

y = x.collect { |x| sin(x.linlin(-1, 1, 0, 2pi)) };

[x.as(Array), y].lace(x.size * 2).plot(numChannels: 2);

[0, 1, 2].asSignal;

Limiter.ar(in, level, dur)


a = ();
a.addEQ = { |dict, proxy, slot, eqClass(BPeakEQ), freq = 440, rq = 1, gain|
	var freqname, rqname, gainname, gainSpec;
	if(slot.isNil) { slot = proxy.objects.indices.maxItem + 1 };
	if([BPeakEQ, BLowShelf, BHiShelf].includes(eqClass)) {
		gainSpec = [-20, 20];
		if(gain.isNil) { gain = 0 };
	} {
		gainSpec = \amp;
		if(gain.isNil) { gain = 1 };
	};
	freqname = ("eqFreq" ++ slot).asSymbol;
	rqname = ("eqRq" ++ slot).asSymbol;
	gainname = ("eqGain" ++ slot).asSymbol;
	proxy.addSpec(freqname, \freq)
	.addSpec(rqname, [1, 0.01, -2])
	.addSpec(gainname, gainSpec);
	proxy.set(freqname, freq, rqname, rq, gainname, gain);
	proxy[slot] = \filter -> { |in|
		var freq = NamedControl.kr(freqname, freq),
		rq = NamedControl.kr(rqname, rq),
		db = NamedControl.kr(gainname, gain);
		eqClass.ar(in, freq, rq, db);
	};
};

~saw = { Saw.ar(50, 0.1).dup };
~saw.play;
~saw.gui;

a.addEQ(~saw, 1);

a.addEQ(~saw, 1, BLowPass);


p.clear;

s.sendMsg(\n_trace, ~saw.objects[1].nodeID);

BHiShelf.ar

FreeVerb2.ar(in, in2, mix, room, damp)
GVerb.ar(in, roomsize, revtime, damping, inputbw, spread, drylevel, earlyreflevel, taillevel, maxroomsize)
PartConv.ar(in, fftsize, irbufnum)