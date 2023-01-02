
//run this first
MIDIIn.connectAll;

//load the synth defs
(
SynthDef(\MySaw,{|vel=0,note|
	var freq = note.midicps;
	var amp = LinLin.kr(vel,0,127,0.05,0.8);
	var env = EnvGen.ar(Env.perc(0.5,2), doneAction: 2);
	var sig = Saw.ar(freq,env);
	Out.ar(0,[sig,sig]);
}).send(s);

SynthDef(\MySustainSaw,{|vel=0,note,gate=1|
	var freq = Lag.kr(note.midicps);
	var amp = LinLin.kr(vel,0,127,0.05,0.8).lag(0.5);
	var env = EnvGen.ar(Env.adsr,gate: gate, doneAction: 2);
	var sig = Saw.ar(freq,env);
	Out.ar(0,[sig*amp,sig*amp]);
}).send(s);

SynthDef(\MyModSaw,{|vel=0,note,gate=1|
	var freq = Lag.kr(note.midicps);
	var amp = LinLin.kr(vel,0,127,0.05,0.8).lag(0.5);
	var env = EnvGen.ar(Env.adsr,gate: gate, doneAction: 2);
	var sig = Saw.ar(freq,env);
	Out.ar(0,[sig*amp,sig*amp]);
}).send(s);

)


//now handle midi input
(
~synths = Array.newClear(8);

n.free;
n = MIDIFunc.noteOn({|...args|
	args.postln;
	~synths[0].set(\gate, 0);
	~synths[0] = Synth(\MySustainSaw,[\vel,0 ,\note, args[1]]);
},40); // match any noteOn

m.free;
m = MIDIFunc.noteOff({|...args|
	~synths[0].set(\gate, 0);
},40);


a.free;
a = MIDIFunc.cc({|...args| args.postln});

o.free;
o = MIDIFunc.polytouch({|...args|
	args.postln;
	~synths[0].set(\vel, args[0]);
},40);

)