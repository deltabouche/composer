require 'rbau'
require './midi_builder'

song = MidiBuilder.new('test2.mid', tempo: 135) do
  set_auto_advance

  set_tonic :g
  set_scale :ionian
  advance

  chords = [
    [5, 8, 9],
    [5, 8, 10],
    [5, 8, 11]
  ]

  bass = [
    8, 6, 4, 1
  ]

  time_block do
    # chords
    ch 0
    oct 3
    len 8
    play_chord = ->(chord_idx, velocity) do
      together_block do
        chords[chord_idx].each do |c|
          note c, velocity: velocity
        end
      end
    end

    4.times do
      play_chord[0, 90]
      play_chord[0, 60]
      play_chord[0, 40]
      play_chord[1, 90]
      play_chord[1, 60]
      play_chord[1, 40]
      play_chord[1, 40]
      play_chord[1, 40]
      play_chord[2, 90]
      play_chord[2, 60]
      play_chord[2, 40]
      play_chord[1, 90]
      play_chord[1, 60]
      play_chord[1, 40]
      play_chord[1, 40]
      play_chord[1, 40] 
    end
  end

  # bass
  time_block do
    ch 0
    oct 2
    len 8
    bass.each do |n|
      16.times { note n, velocity: 100 }
    end
  end

  # arp
  time_block do
    ch 0
    oct 6
    len 16
    
    (4 * 4).times do
      [1, 2, 3, 5, 8, 5, 3, 2].each { |n| note n, velocity: 48 }
    end
  end

  # riff
  time_block do
    ch 0
    oct 5
    len 8; advance
    4.times do
      len 8, 12
      advance
      len 8
      note 1, velocity: 100
      note 1, velocity: 100
      note 5, velocity: 100
      note 3, velocity: 100
    end
  end
end

host = RbAU.new
host.add_track("Serum")
host.load_au_preset("test.aupreset")
host.load_midi_file("test2.mid")
host.bounce_to_file("test2.wav")
