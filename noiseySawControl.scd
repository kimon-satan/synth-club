
MIDIIn.connectAll;

(

SynthDef.new(\noiseySaw, {|carrier= 100,
	syncRate = 1,
	freqModFreq = 0.2,
	freqAmp = 0.1,
	freqPhase = 0,
	ampModFreq = 1,
	ampModAmp = 0,
	ampPhase = 0, // it might not make sense to adjust phases as they will go out of sync in anycase
	lfNoiseFreq = 1,
	lfNoiseAmp = 0.2,
	amp = 0.1,
	pan = 0
	|

	var freqMod = SinOsc.kr(freqModFreq,freqPhase,carrier*freqAmp,carrier),
	ampMod = LFTri.ar(ampModFreq, ampPhase, ampModAmp, 1-ampModAmp) * amp,
	//some noise for dirtying amp
	noise = LFNoise1.ar(lfNoiseFreq,lfNoiseAmp,1-lfNoiseAmp),

	sig = Pan2.ar(SyncSaw.ar(
		freqMod,
		syncRate * freqMod, //swap freqMod for carrier for sweep effect
		ampMod * noise),
	pan);

	Out.ar(0,sig);

}).send(s);

~noiseySawControl = [
	[\carrier, ControlSpec.new(10,400,'exp'), 0.5],
	[\syncRate, ControlSpec.new(1,50,'exp'), 0.5],
	[\freqModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
	[\freqAmp, ControlSpec.new(0,1,'lin'), 0.5],
	[\ampModFreq, ControlSpec.new(0.1,50,'exp'), 0.5],
	[\ampModAmp, ControlSpec.new(0,1,'lin'), 0.5],
	[\lfNoiseFreq, ControlSpec.new(1,25,'exp'), 0.5],
	[\lfNoiseAmp, ControlSpec.new(0,1,'lin'), 0.5]
];

~updatePot = {|potIndex, val|
	~pots[potIndex].value = val;
	~potsSynced[potIndex] = false;
	~pots[potIndex].setColors(knobColors: [Color.red]);
};


)

//reset pots to zero
8.do{|i|{~updatePot.value(i,0)}.defer};

//create the new synth with defaults
(
var vals = [];
~noiseySawControl.do({|v,i|
	vals = vals.add(v[0]);
	vals = vals.add(v[1].map(v[2]));
	{~updatePot.value(i, v[2])}.defer;
});
x = Synth.new(\noiseySaw,  vals);

)

x.free;

//create the GUI mirror
(

var kLayout;


try{ w.close}{"no window yet".postln};
w=Window.new("GUI", 700@500).front;
w.view.decorator=FlowLayout(w.view.bounds);
w.view.decorator.gap=4@4;

~potsSynced = Array.fill(8,{false});

~pots = [];

2.do{|r|
	4.do{|c|
		var i = r * 4 + c,
		pot = EZKnob.new(w, 150@120,
		label: ~noiseySawControl[i][0].asString,
		initVal: ~noiseySawControl[i][2],
		action: {|v|
			x.set(~noiseySawControl[i][0],~noiseySawControl[i][1].map(v.value))
		}
		);
		{pot.setColors(knobColors: [Color.red])}.defer;
		~pots = ~pots.add(pot);
	};
	w.view.decorator.nextLine;
};

a.free;
a = MIDIFunc.cc({|val,id|
	var index = id - 70,
	spec = ControlSpec(0,127,\lin,1,0);

	{
		//get the current gui value

		if(~potsSynced.at(index) == true,{
			~pots.at(index).valueAction_(spec.unmap(val));
			~noiseySawControl[index][2] = spec.unmap(val);
		},{
			var diff = (~pots[index].value - spec.unmap(val)).abs;
			if(diff <= (2/128),{
				~potsSynced[index] = true;
				~pots[index].setColors(knobColors: [Color.green]);

			},{diff.postln});
		});



	}.defer;
});


)























