SynthDef(\name, { |out|
   ...
   Out.ar(out, ...);
}).add;


// 2-envelope FM synth

a = ();
a.saveAddr = s.addr;
a.debugAddr = DebugNetAddr("127.0.0.1", 57110);

s.addr = a.debugAddr;
s.addr = a.saveAddr;

p = ProxySpace.new.push;
p.clear;

~freq = 440;
~modRatio = 2;
~modIndex = 1.5;

~vibratoFreq = {
	~freq * LFNoise1.kr(3).exprange(0.995, 1.006)
};

~modEg = { |gt|
	EnvGen.kr(Env.adsr(0.01, 0.1, 0.5, 0.3), gt)
};

~mod = {
	SinOsc.ar(~vibratoFreq * ~modRatio, 0) * ~modEg
};

~carEg = { |gt|
	EnvGen.kr(Env.adsr(0.01, 0.2, 0.6, 0.15), gt);
};

~car = {
	(SinOsc.ar(~freq * (1 + (~modIndex * ~mod.ar))) * ~carEg).dup;
};
~car.play;

p.setEvent((freq: exprand(200, 800), sustain: 2)).play;  // test

~freq.objects[0]


SynthDef(\fm1, { |out, freq = 440|
   var vibratoFreq = freq * LFNoise1.kr(3).exprange(0.995, 1.006);
   ...
   Out.ar(out, ...);
}).add;


SynthDef(\fm1, { |out, gate = 1, freq = 440, modRatio = 2, modIndex = 1.5, amp = 0.1|
   var vibratoFreq = freq * LFNoise1.kr(3).exprange(0.995, 1.006);
   var modEg = EnvGen.kr(Env.adsr(0.01, 0.1, 0.5, 0.3), gate);
	var mod = SinOsc.ar(vibratoFreq * modRatio, 0) * modEg;
	var carEg = EnvGen.kr(Env.adsr(0.01, 0.2, 0.6, 0.15), gate, doneAction: 2);
	var car = SinOsc.ar(freq * (1 + (modIndex * mod))) * carEg;
	Out.ar(out, (car * amp).dup);
}).add;

(instrument: \fm1, freq: exprand(220, 880), sustain: 2).play;


a = ();
a.p = ProxySpace.new.push;

a.mixer = MixerChannel(\demo, s, 1, 2, level: 0);

~sound = {
	var trig = Impulse.kr(8),
	eg = EnvGen.kr(Env.perc(0.01, 0.1), trig);
	SinOsc.ar(TExpRand.kr(200, 800, trig)) * eg
};

a.mixer.play(~sound);

a.mixer.levelTo(-15.dbamp, 25);

~sound.clear;
a.mixer.free;
