/*
Set up a GUI mirror for the LPD8 which requires the user to sync controls to existing values before accepting midi input.

This is useful for working with multiple control patches
*/

(

var kLayout;

MIDIIn.connectAll;
w.close;
w=Window.new("GUI").front;

~knobsSynced = Array.fill(8,{false});

~knobs = Array.fill(8, {|i|
	var knob = Knob.new(w, 20@20);
	knob.value = 0.5;
	knob.action = {|v| (i + ", " + v.value).postln;};
	knob.color = [Color.red];
	knob;
});

kLayout = Array2D.fromArray(2,4,~knobs);

w.layout_(GridLayout.rows(kLayout.rowAt(0),kLayout.rowAt(1)));

a.free;
a = MIDIFunc.cc({|val,id|
	var index = id - 70,
	spec = ControlSpec(0,127,\lin,1,0);

	{
		//get the current gui value
		var diff = (~knobs.at(index).value - spec.unmap(val)).abs;

		//TODO: control statement for knob isn't synced
		if(~knobsSynced.at(index) == true,{
			~knobs.at(index).valueAction_(spec.unmap(val))
		},{
			if(diff <= (2/128),{
				~knobsSynced[index] = true;
				~knobs.at(index).color = [Color.green];

			});
		});



	}.defer;
});


)








