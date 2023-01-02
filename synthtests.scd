MIDIIn.connectAll;

(
x.free;
x = {|modFreq = 10, rq=0, rqFreq = 0 |
	var modFreqMapped = LinExp.kr(modFreq,0,127,1,20);
	var rqMapped = LinLin.kr(rq,0,127,0,0.5);
	var rqFreqMapped = LinExp.kr(rqFreq,0,127,100,4000);
	var mod = SinOsc.kr(modFreq,0,10,40);
	var sig = RLPF.ar(Saw.ar(mod,1),rqFreqMapped,rqMapped).clip(0,0.2);
	sig = [DelayC.ar(sig,1,2) , sig ];

}.play;
)

(
a.free;
a = MIDIFunc.cc({|...args|
	args.postln;
	if(args[1] == 70,{
		("modFreq_"+args[0]).postln;
		x.set(\modFreq, args[0])
	});

	if(args[1] == 71,{
		("rq_"+args[0]).postln;
		x.set(\rq, args[0])});

		if(args[1] == 72,{
		("rq_freq"+args[0]).postln;
		x.set(\rqFreq, args[0])});

});

)

(
x.free;
x = {|noiseFreq=0, freq=0, noiseMul=0|
	var noiseMod = LFNoise1.ar(10,10);
	Saw.ar(50+noiseMod,0.1)
}.scope;
)



