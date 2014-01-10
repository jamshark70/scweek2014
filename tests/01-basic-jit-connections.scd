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