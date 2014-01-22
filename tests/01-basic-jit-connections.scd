p.pop;

~saveAddr = s.addr;
~debugAddr = DebugNetAddr("127.0.0.1", 57110);

s.addr = Environment.top[\debugAddr];
s.addr = Environment.top[\saveAddr];


p = ProxySpace.new;
p.push;

~s.play;

~s = { |t_trig = 1, freq = 440, decay = 0.1, amp = 0.1|
	var eg = EnvGen.kr(Env.perc(0.01, decay), t_trig);
	(SinOsc.ar(freq, 0, amp) * eg).dup
};

~s.set(\t_trig, 1);

~freq = { LFNoise1.kr(2).exprange(200, 800) };
~s.map(\freq, ~freq);

s.sendMsg(\n_trace, 1005);

~s.inspect

// this is clumsy
z = Pbind(
	\type, \set, \id, ~s.nodeID, \args, #[t_trig],
	\t_trig, 1,
	// \freq, Pexprand(200, 800, inf),
	\dur, 0.2
).play;

z.stop;

p.clear;



// analog-style monosynth
p = ProxySpace.new;
p.push;

~oscil = { |freq = 440|
	var detunes = NamedControl.kr(\detunes, { exprand(-0.1.midiratio, 0.1.midiratio) });
	Mix(Saw.ar(freq * detunes))
};

~filtEg = { |t_trig, decay = 0.2, mul = 2|
	EnvGen.kr(Env.perc(0.01, decay, mul - 1), t_trig, levelBias: 1)
};

~ffreq = 1200;
~rq = 0.1;

// interesting, assumes a NodeProxy is kr if you don't say otherwise
~filter = { RLPF.ar(~oscil.ar, ~ffreq * ~filtEg, ~rq) };

~ampEg = { |t_trig| EnvGen.kr(Env(#[0, 1, 0.5], #[0.01, 0.1]), t_trig) };
~amp = 0.05;

// this is a control proxy? Really?
~out2 = { (~filter.ar * ~ampEg.ar * ~amp.ar).dup };

~out2.play;

Tdef(\bass, {
	loop {
		~ampEg.set(\t_trig, 1);
		~filtEg.set(\t_trig, 1);
		~oscil.set(\freq, exprand(80, 160));
		0.2.wait;
	}
}).play;

~filtEg.set(\mul, 4);
s.sendMsg(\n_trace, 1029);

~out = nil

p.clean;

Tdef(\bass).stop;

p.clear;
p.pop;



// introspect

~s = { Silent.ar(2) };

~s.inspect;

~s.objects[0]  // a SynthDefControl

~s.objects[0].source === ~s[0]

~num = 1;

~num = 2;

~num.inspect;

~num.source

~num.objects[0].source === ~num[0]

~num.objects[0]  // a SynthDefControl -- this could be a NumberControl

~num.objects[0].dump

~pat = Pbind(\dur, 1);
~pat.play;

~pat.objects[0]  // a PatternControl

~pat.clear;


// well crikey, numbercontrol seems to work!
~num = 1;

~num = 2;

// let's plug it into something
~num = 440;

~osc = { VarSaw.ar(~num, 0, 0.25, 0.1) ! 2 };
~osc.play;

~num = 220;  // note, source doesn't update

~osc.stop;

e = EZSlider(nil, Rect(800, 200, 300, 50), "freq", #[20, 2000, \exp], { |view| ~num = view.value }, 220);

~num = { LFNoise1.kr(2).exprange(200, 800) };

~num.inspect

p.clear;

NumberSynthControl.findRespondingMethodFor('source_')


// proxynodemap issue

~num.nodeMap[\value].dump

~num = nil;


// RawArray?

~num = FloatArray[0.0, 0.5, 1.0];
~num = FloatArray[1.0, 2.0, 3.0];


// what about multiple scalars?
~num = 1;

~num[1] = 2;

~num = 3;

~num[1] = 4;

~num.inspect
~num.nodeMap

p.clear;

Bus(\control, 0, 1, s).get(_.postln)


// try regular arrays
~num = [1, 2, 3];

~num = [3, 2, 1];

~num = [1, { LFNoise0.kr(10) }, 3];




// psSet event
// need to figure how to handle multiple objects in a proxy
// bug: sustain > delta should suppress release (but we don't know at sched time)

(
Event.addEventType(\psSet, {
	var value,
	sustain = ~sustain.value,
	releaseHolder = ~releaseHolder;
	~freq = ~detunedFreq.value;
	~proxyspace.keysValuesDo { |name, proxy|
		var ctl = proxy.objects[0];
		case
		{ ctl.isKindOf(SynthDefControl) } {
			ctl.synthDef.allControlNames.do { |cn|
				if(#[gate, fadeTime, out].includes(cn.name.asSymbol).not and: {
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
	if(currentEnvironment.isKindOf(ProxySpace).not) {
		Error("\\psSet may not be used outside of a ProxySpace").throw;
	};
	// releaseHolder may well be a hack,
	// but it should actually be local to the pattern
	// must protect in a Ref
	// Pbindf will extract its value automatically
	// but not use composeEvents()
	Pbindf(pattern, \type, \psSet, \proxyspace, currentEnvironment, \releaseHolder, `(IdentityDictionary.new))
	.buildForProxy(proxy, channelOffset, index)
};
)

p = ProxySpace.new; p.push;

~oscil = { |freq = 220, detun = 1.003|
   Mix(Saw.ar(freq * [1, detun, detun.reciprocal], 0.1))
};
~filter = { |ffreq = 2000| LPF.ar(~oscil.ar, ffreq) };
~filter.addSpec(\ffreq, \freq);
~eg = { |t_trig = 0, decay = 0.6|
	EnvGen.kr(
		envelope: Env([0, 1, 0], [0.01, decay], -4),
		gate: t_trig
	)
};

~out = { (~filter.ar * ~eg).dup }; ~out.play;

~eg.set(\t_trig, 1);

p.setEvent((freq: exprand(200, 800), t_trig: 1)).play;

(type: \psSet, proxyspace: Environment.current, freq: exprand(200, 800), t_trig: 1).play;

~sequencer = \psSet -> Pbind(\freq, Pexprand(110, 440, inf), \t_trig, 1, \dur, 0.25);

~sequencer = \psSet -> Pbind(
	\freq, Pexprand(110, 440, inf),
	\t_trig, 1,
	\dur, Pexprand(0.05, 0.5, inf),
	\decay, Pkey(\dur) * 1.2
);

~sequencer = nil;

~out.stop;  // We'll use these proxies some more

// introspect oscil
~oscil.dump
~oscil.objects[0].dump
~oscil.objects[0].synthDef.dump
~oscil.objects[0].synthDef.allControlNames

p.gui;


~eg = { |gt = 0|
	EnvGen.kr(
		envelope: Env.adsr(0.01, 0.15, 0.4, 0.1),
		gate: gt
	)
};

~eg.set(\gt, 1);  // trigger
~eg.set(\gt, 0);  // release

p.setEvent((freq: exprand(200, 800), gt: 1, sustain: 3)).play;

~sequencer = \psSet -> Pbind(
	\freq, Pexprand(110, 440, inf),
	\gt, 1,
	\dur, 1, // Pexprand(0.12, 0.5, inf),
	\legato, 1.2 // Pwhite(0.9, 1.1, inf)
);

~sequencer = nil;

p.clear;


Halo.lib;


/*********
Listing 29. Basic detuned synth.
 *********/

p = ProxySpace.new; p.push;

~oscil = { |freq = 120|
   var freq1 = freq * [0.5, 0.498, 0.503],
   freq2 = freq * [1, 0.997, 1.004];
   Mix(Pulse.ar(freq1)) + Mix(Saw.ar(freq2))
};
~filter = { |ffreq = 2000, rq = 0.08|
   RLPF.ar(~oscil.ar, ffreq, rq, 0.1).dup;
};
// ~filter.play;

~filter.addSpec(\ffreq, \freq);
~filter.addSpec(\rq, [1, 0.02, \exp]);
p.gui;


/*********
Listing 30. Add an LFO to the filter.
 *********/

~lfreq = 1; ~lfreq.addSpec(\value0, [0.5, 18, \exp]);
~depth = 100; ~depth.addSpec(\value0, [0, 1000]);
~filtlfo = { SinOsc.kr(~lfreq) * ~depth };

~filter = { |ffreq = 2000, rq = 0.08|
   ffreq = (ffreq + ~filtlfo).clip(20, 20000);
   RLPF.ar(~oscil.ar, ffreq, rq, 0.1).dup;
};



/*********
Listing 31. Play with some other common LFO shapes.
 *********/

~filtlfo = { LFPulse.kr(~lfreq) * ~depth };
~filtlfo = { LFTri.kr(~lfreq) * ~depth };
~filtlfo = { LFSaw.kr(~lfreq) * ~depth };
~filtlfo = { LFSaw.kr(~lfreq) * ~depth.neg };


/*********
Listing 32. LFO shapes not commonly found in other software.
 *********/

~filtlfo = { LFNoise0.kr(~lfreq) * ~depth };
~filtlfo = { LFNoise1.kr(~lfreq) * ~depth };


