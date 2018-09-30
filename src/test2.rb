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
    patch 0
    oct 4
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
    ch 1
    patch 33
    oct 2
    len 8
    bass.each do |n|
      16.times { note n, velocity: 127 }
    end
  end

  # arp
  time_block do
    ch 2
    patch 87
    oct 6
    len 16
    
    (4 * 4).times do
      [1, 2, 3, 5, 8, 5, 3, 2].each { |n| note n, velocity: 48 }
    end
  end

  # riff
  time_block do
    ch 3
    patch 66
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

  # drums

  ch 10
  set_gate 1
  patch 8

  # Hi hats
  time_block do
    8.times do
      3.times do
        len 8
        drum :hc
        len 16
        drum :hc
        drum :hc
      end
      len 8
      drum :ho
      len 16
      drum :hc
      drum :hc
    end
  end

  # Kick/Snare
  time_block do
    8.times do
      len 4
      drum :k
      drum :s
      drum :k
      len 8
      drum :s
      drum :k
    end
  end

  # Crash
  time_block do
    len 1
    drum :cr
  end
end

host = RbAU.new
# host.add_track("Serum")
# host.load_au_preset("test.aupreset")
host.add_track("SOUND Canvas VA")
host.load_au_preset("sc88pro.aupreset")
host.load_midi_file("test2.mid")
host.bounce_to_file("test2.wav")
