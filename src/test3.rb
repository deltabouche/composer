require 'rbau'
require './midi_builder'

base_file = 'test3'

song = MidiBuilder.new("#{base_file}.mid", tempo: 150) do
  set_auto_advance

  set_tonic :c
  set_scale :aeolian

  # saw
  note_pat = ->(offs) do
    time_block do
      len 16
      aryx = ->(offs2, mod = 0) do
        oct 5; note 1+offs2
        oct 3; note 1+offs2, velocity: 80
        oct 4; note 1+offs2, velocity: 80
        oct 3; note 1+offs2, velocity: 80
        oct 5; note 5+offs2
        oct 3; note 1+offs2, velocity: 80
        oct 5; note 4+offs2
        oct 5; note 5+offs2
        oct 4; note 1+offs2, velocity: 80
        oct 3; note 1+offs2, velocity: 80
        oct 5; note 1+offs2
        oct 3; note 1+offs2, velocity: 80
        oct 5; note 2+offs2, mod
        oct 3; note 1+offs2, velocity: 80
        oct 5; note 3+offs2
        oct 3; note 1+offs2, velocity: 80
      end

      2.times do
        aryx[0]
        aryx[2]
        aryx[4, 1]

        oct 5; note 7
        oct 3; note 7, velocity: 80
        oct 4; note 7, velocity: 80
        oct 3; note 7, velocity: 80
        oct 5; note 4
        oct 3; note 7, velocity: 80
        oct 4; note 7, velocity: 80
        oct 5; note 2
        oct 4; note 7, velocity: 80
        oct 3; note 7, velocity: 80
        oct 5; note 2
        oct 3; note 7, velocity: 80
        oct 5; note 4
        oct 3; note 7, velocity: 80
        oct 5; note 5
        oct 3; note 7, velocity: 80
      end
    end
  end
  lol = ->(c, pit, pan) do
    ch c
    pitch pit
    cc 10, pan
    patch 81
    cc 7, 80
    time_block do
      len 16
      128.times do |i|
        cc 74, i
        advance
      end
    end
    note_pat[0]
    note_pat[12]
  end

  #supersaw
  width = 0.08
  pan_width = 48
  count = 4
  start = -width / 2.0
  step = width / count.to_f
  pan_start = (-pan_width.to_f / 2.0)
  pan_step = pan_width.to_f / count.to_f
  
  count.times do |i|
    lol[i, start + step * i.to_f, (pan_start + pan_step * i.to_f + 64.0).to_i]
  end

  # drums
  ch 10
  patch 24
  len 16
  32.times do
    drum :k
    drum :hc, velocity: 50
    drum :ho, velocity: 90
    drum :hc, velocity: 50
  end
end

host = RbAU.new
host.add_track("SOUND Canvas VA")
host.load_au_preset("sc88pro.aupreset")
host.load_midi_file("#{base_file}.mid")
host.bounce_to_file("#{base_file}.wav")
