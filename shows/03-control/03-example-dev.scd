[1, 2, 3].remove(2);

[1, 2, 3, 1].differentiate

(
q = Pn(
	Pseries(
		Pseries(0, Pwrand([1, 2], [0.86, 0.14], inf), inf).asStream,
		Pconst({ rrand(5, 10) }, Pwrand([1, 2], [0.7, 0.3], inf)),
		inf
	),
	5
);
)

p = Pbind(\degree, q, \dur, 0.15).play;

q.asStream.all;

p = ProxySpace.new.push;

x = [0, 2, 4, 6, 7, 1, 2, 3, 4, 5, 2,
	3, 5, 6, 7, 8, 10, 3, 5, 6, 8,
	9, 10, 4, 5, 6, 7, 8, 9
];

y = x.separate { |a, b| b - a < -2 };
z = y.collect { |array| Pseq(array, 1) };

~player = Pbind(
	\degree, Pxrand(z, inf),
	\dur, 0.15
);
~player.play;

p.clear;

x = [0, 1, 2];
y = x;

y === x;  // identical

x.put(1, 10);
y;  // prints: [ 0, 10, 2 ]


x = (0..9).scramble;
x.collect { |item|
	if(item.odd) {
		item * 10
	} {
		item
	}
};
x.select { |item| item > 4 };
x.reject { |item| item > 4 };

x = ["An", "array", "of", "strings"];
x.count { |item| item.size > 3 };
x.sum { |item| item.size };
x.maxItem { |item| item.size };


x = (0..9).scramble;
x[3]
x[3] = 22;
x.removeAt(3); x
x = x.insert(3, 22);
x ++ [55, 48, 60];
x.pairsDo { |a, b| "%: %\n".postf(a, b) };
x.doAdjacentPairs { |a, b| "% - % = %\n".postf(b, a, b - a) };

x.sort { |a, b| a > b };


x = [59, 61, 66, 68, 69, 61,
   59, 68, 66, 61, 69, 68];

// unique pitch classes
y = IdentitySet.new;  // OK b/c Integers
x.do { |item| y.add(item % 12) };
y;  // 5 items only: duplicates ignored
z = IdentitySet[11, 1, 2, 4, 6, 7, 9];  // b minor

// which notes in y belong to a b minor scale?
y & z;

// which notes in y are *not* in b minor?
y - z;

// which notes are in either y or z, not both?
y -- z;

(g: 1, b: 2).values;


d = (
	mel1: [0, 7, 3, 4, 6, 7],
	mel2: [9, 7, 6, 4, 3],
	mel3: [3.9, 4, 6, 3, 2]
);

// preserves the keys
e = d.collect { |array| Pseq(array, 1) };

e.keysValuesDo { |key, value| [key, value].postcs }; ""

q = Pbind(
	\degree, Pdict(e, Pxrand([\mel1, \mel2, \mel3], inf)),
	\dur, Pwhite(1, 3, inf) * 0.15,
	\scale, Scale.aeolian,
	\root, 11, \octave, 3
).play;

q.stop;


x = 10.rand;
if(x < 5) {
   "low random number: %\n".postf(x);  // then
} {
   "high random number: %\n".postf(x);  // then
};

x.inclusivelyBetween

(
f = File(thisProcess.platform.startupFiles.last, "r");
while {
	x = f.getLine;
	x.notNil  // keep going until 'nil'
} {
	x.postln;
};
f.close;
)


a = Pbind(  // canonical style
   \degree, Pn(Pseries(0, 1, 8), inf),
   \dur, 0.125.asPattern.collect { |dur|
      if(0.75.coin) { dur } { Rest(dur) }
   }
).play;

a.stop;


o = Button(nil, Rect(600, 100, 100, 20))
.states_([["off"], ["on"]])
.action_({ |button|
   if(button.value == 1) {
      "on".postln;
   } {
      "off".postln;
   };
}).front;

(
w = Window("test", Rect(800, 300, 500, 400))
.layout_(
	VLayout(
		HLayout(
			n = NumberBox().maxWidth_(60),
			z = Slider().orientation_(\horizontal).maxHeight_(20)
		)
	)
)
.front;

n.linkedAction_({ |value| value.postln }, \bipolar, z);
)


p = ProxySpace.new.push;

~sound = { |freq = 440, amp = 0.1|
	VarSaw.ar(freq, 0, 0.5, amp).dup
};
~sound.play;

z = Slider(nil, Rect(600, 200, 200, 20)).front;

y = ControlSpec(110, 880, \exp);

z.action = { |sl|
   ~sound.set(\freq, y.map(sl.value));
};

p.clear;

~sound.dump
~sound.stop;

~sound.isPlaying;
~sound.isMonitoring;

w = Window("window name", Rect(600, 200, 300, 120));
z = EZSlider(w,
	bounds: Rect(5, 5, 290, 20),
	label: "freq",
	controlSpec: [110, 880, \exp],  // short form OK
	action: { |view| ~sound.set(\freq, view.value) },
	initVal: 440
);
w.front;

b = Button(w, Rect(5, 30, 290, 30))
.states_([
	["stopped", Color.black, Color.gray(0.8)],
	["playing", Color.black, Color.green]
])
.action_({ |view|
	if(view.value == 1) {
		~sound.play;
	} {
		~sound.stop;
	};
});



(
w = Window("window name", Rect(600, 200, 300, 120));
f = FlowView(w, w.view.bounds);
z = EZSlider(f,
	bounds: Point(290, 20),
	label: "freq",
	controlSpec: [110, 880, \exp],  // short form OK
	action: { |view| ~sound.set(\freq, view.value) },
	initVal: 440
);

b = Button(f, Point(290, 30))
.states_([
	["stopped", Color.black, Color.gray(0.8)],
	["playing", Color.black, Color.green]
])
.action_({ |view|
	if(view.value == 1) {
		~sound.play;
	} {
		~sound.stop;
	};
});

w.front;
)

k = Knob(nil, Rect(600, 200, 100, 100)).front;

o = OSCFunc({ |msg, time, addr, recvPort|
	[msg, time, addr, recvPort].postln;
}, '/status.reply');

o.free;

OSCFunc.trace(true);
OSCFunc.trace(false);


p.clear;  // or p = ProxySpace.new.push;

~freq = 440;

u.remove;
u = Updater(~freq, { |obj, what, args| [what, args].postcs });

~freq = 660;  // [ 'set', [ 'value0', 660 ] ]

~oscil = {
	VarSaw.ar(~freq, 0, 0.3, 0.1).dup
};
~oscil.play;


p.gui;

OSCdef(\sl1, { |msg|
	~freq = \freq.asSpec.map(msg[1])
}, '/1/fader1', NetAddr("192.168.43.1", nil));

OSCdef(\sl1).free;

OSCFunc.allEnabled

OSCFunc.trace(true, true);
OSCFunc.trace(false);

n = NetAddr("192.168.43.1", 9000);

u.remove;
u = SimpleController(~freq).put(\set, { |obj, what, array|
	array.debug;
	n.sendMsg('/1/fader1', \freq.asSpec.unmap(array[1]));
});

NetAddr("127.0.0.1", nil).sendMsg(\oops);




p.clear;  // or p = ProxySpace.new.push;

// MODEL: A numeric NodeProxy
~freq.addSpec(\value0, \freq);
~freq = 440;

~oscil = { VarSaw.ar(~freq, 0, 0.25, 0.1).dup };

// VIEW: EZSlider
w = Window("MVC demonstration", Rect(700, 300, 300, 100));
z = EZSlider(w, Rect(5, 5, 290, 20), "freq", \freq,
	// CONTROLLER: Callback function
	{ |sl| ~freq = sl.value }, 440
);
b = Button(w, Rect(5, 30, 290, 30))
.states_([["stopped"], ["playing"]])
.action_({ |btn|
	if(btn.value == 1) { ~oscil.play } { ~oscil.stop };
});
w.front;

c.remove;
c = Updater(~freq, { |obj, what ... allArgs|
	[obj, what, allArgs].postcs;
});

// When finished tracing:
c.remove;

u = SimpleController(~freq)
.put(\set, { |changer, what, setArray|
	{ z.value = setArray[1] }.defer;
});

// Try it:
~freq = exprand(220, 880);

// When finished:
u.remove;

// Receiving OSC
OSCdef(\sl1, { |msg|
	~freq = \freq.asSpec.map(msg[1]);
}, '/1/fader1', NetAddr("192.168.1.100", nil));

// Sending OSC
n = NetAddr("192.168.1.100", 9000);  // Where to send
o.remove;
o = SimpleController(~freq)
.put(\set, { |changer, what, setArray|
	n.sendMsg('/1/fader1', \freq.asSpec.unmap(setArray[1]));
});

y = SimpleController(~oscil)
.put(\play, {
	{ b.value = 1 }.defer;
	n.sendMsg('/1/toggle1', 1);
})
.put(\stop, {
	{ b.value = 0 }.defer;
	n.sendMsg('/1/toggle1', 0);
});

OSCdef(\tg1, { |msg|
	if(msg[1] == 1) { ~oscil.play } { ~oscil.stop };
}, '/1/toggle1', NetAddr("192.168.1.100", nil));

// cleanup
// these will clean up after p.clear
u.put(\clear, { u.remove });
y.put(\clear, { y.remove });

w.close;
OSCdef(\sl1).free;
OSCdef(\tg1).free;

atask.play
u.put(\play, {
	{ b.value = 1 }.defer;
})
.put(\stop, {
	{ b.value = 0 }.defer;
});

o.put(\play, {
})
.put(\stop, {
	n.sendMsg('/1/toggle1', 0);
});

o.slotAt(\actions)

// can ScalarSynthControl use a spec automatically? -- could, but shouldn't
p = ProxySpace.new.push;

~freq = 440;
~freq.getSpec(\value0);
~freq.getSpec(\freq);

Tdef(\onoff, {
	loop {
		~oscil.play;
		defer { b.value = 1 };
		rrand(0.25, 0.5).wait;
		~oscil.stop;
		b.value = 0;
		defer { b.value = 0 };
		exprand(0.15, 0.5).wait;
	}
}).play;

Tdef(\onoff).stop;



// new timepoint
p = PTimePoints(Pbind(
	\timept, Pseq([0, 1, 2, 2], 3)
)).asStream;

TempoClock.sched(0, { p.next(()).postln });