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