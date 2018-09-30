require 'rbau'
require './midi_builder'

song = MidiBuilder.new('test.mid', tempo: 150) do
  set_auto_advance

  set_tonic :g
  set_scale :ionian
  advance

  # square
  ch 0
  patch 80
  oct 5
  len 16, 3
  note 3
  len 16
  note 4

  time_block do
    len 4
    note 5
    note 8
    note 7
    note 6
    
    len 4, 3
    note 5
    len 16, 3
    note 2
    len 16
    note 3
    
    len 4
    note 4
    note 11
    note 10
    note 9
    
    len 2
    note 8
    note 9

    len 1
    note 10

    note 12

    len 4
    patch 100
    note 6
    oct_up
    note 1
    note 5
    note 4
    note 8
    note 6, -1
    note 5
    note 4
  end

  # arp
  time_block do
    ch 3
    patch 79
    len 8
    set_gate 0.5
    oct 5

    arp_pattern = ->(*args) do
      advance

      if (args.size == 3)
        lo, mid, hi = args
        note lo
        note mid
        note lo
        note hi
        note lo
        note mid
        note lo
      else
        args.each do |n|
          note n
        end
      end
    end

    2.times do
      arp_pattern[5, 8, 9]
      arp_pattern[5, 7, 12]
      arp_pattern[4, 6, 11]
      arp_pattern[4, [6, -1], 8, 11, 8, [6, -1], 4]
    end
  end

  # bass
  time_block do
    ch 2
    patch 38
    len 4
    set_gate 0.5
    oct 2
    8.times do
      note 1
      advance
      advance
      advance
    end
  end

  chords = [
    [5, 8, 10],
    [5, 7, 9],
    [4, 6, 8],
    [4, [6, -1], 8],
    [4, [6, -1], 9]
  ]

  # strings
  time_block do
    ch 4
    patch 49
    set_gate 1
    oct 4
    chord_pattern = ->(lo, mid, hi) do
      group_block do
        time_block { note lo }
        time_block { note mid }
        time_block { note hi }
      end
    end

    2.times do
      len 1
      chord_pattern[*chords[0]]
      chord_pattern[*chords[1]]
      chord_pattern[*chords[2]]
      len 2
      chord_pattern[*chords[3]]
      chord_pattern[*chords[4]]
    end
  end

  # piano
  time_block do
    ch 5
    patch 0
    len 8
    set_gate 0.5
    oct 4
    chord_pattern = ->(lo, mid, hi) do
      advance
      7.times do
        together_block do
          note lo
          note mid
          note hi
        end
      end
    end

    2.times do
      chord_pattern[*chords[0]]
      chord_pattern[*chords[1]]
      chord_pattern[*chords[2]]
      chord_pattern[*chords[3]]
    end
  end

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
host.add_track("SOUND Canvas VA")
host.load_au_preset("sc88pro.aupreset")
host.load_midi_file("test.mid")
host.bounce_to_file("test.wav")
