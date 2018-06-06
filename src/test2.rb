require './midi_builder'

song = MidiBuilder.new('test2.mid', tempo: 150) do
  set_auto_advance

  set_tonic :g
  set_scale :ionian
  advance

  
end
