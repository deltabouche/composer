require 'rbau'
require './midi_builder'

base_file = 'test3'

song = MidiBuilder.new("#{base_file}.mid", tempo: 150, ppqn: 1920) do
  set_auto_advance

  set_tonic :c
  set_scale :aeolian

  # saw
  note_pat = ->(offs) do
    second_vel = 64
    second_gate = 0.8

    time_block do
      len 16
      notefuncs = {
        '1' => ->(n, _) { oct 5+offs; note n },
        '2' => ->(n, mod) { oct 5+offs; note n, mod },
        'a' => ->(n, _) { oct 3+offs; note n, velocity: second_vel, note_gate: second_gate },
        'b' => ->(n, _) { oct 4+offs; note n, velocity: second_vel, note_gate: second_gate }
      }

      play_pattern = ->(nv, nf, offs2 = 0, mod = 0) do
        nv.each_char.with_index do |v, i|
          notefuncs[nf[i]][v.to_i + offs2, mod]
        end
      end

      aryx = ->(offs2, mod = 0) do
        play_pattern[
          '1111514511112131',
          '1aba1a11ba1a2a1a',
          offs2,
          mod
        ]
      end

      2.times do
        aryx[0]
        aryx[2]
        aryx[4, 1]

        play_pattern[
          '7777477277274757',
          '1aba1ab1ba1a1a1a',
        ]
      end
    end
  end

  lol = ->(c, pit, pan, vol_mult = 1.0, filt_mult = 1.0) do
    ch c
    pitch pit
    cc 10, pan
    patch 81
    cc 7, (80.0 * vol_mult).to_i

    # filter sweep
    time_block do
      len 16
      128.times do |i|
        cc 74, (i.to_f * filt_mult).to_i
        advance
      end
    end

    note_pat[0]
    # note_pat[1]
  end

  #supersaw
  width = 0.1
  pan_width = 48
  count = 4
  start = -width / 2.0
  step = width / count.to_f
  pan_start = (-pan_width.to_f / 2.0)
  pan_step = pan_width.to_f / count.to_f
  
  count.times do |i|
    time_block do
      pit_val = (start + step * i.to_f)
      pan_val = (pan_start + pan_step * i.to_f + 64.0).to_i
      lol[i, pit_val, pan_val]

      # delay L
      len 4
      advance
      lol[i+count, pit_val, 0, 0.35, 0.4]

      # delay R
      len 4
      advance
      lol[i+12, pit_val, 127, 0.18, 0.2]
    end
  end

  # kick
  time_block do
    ch 8
    patch 79
    32.times do
      time_block do
        len 256
        '94'.each_char do |s|
          envstep = s.to_f / 9.0
          pitch -1.0 + 2.0 * envstep
          advance
        end
        '9754333322221110'.each_char do |s|
          envstep = s.to_f / 9.0
          pitch -1.0 + 2.0 * envstep
          advance
        end
      end
      time_block do
        len 128; oct 5; note 1
        len 256; oct 4; note 1, note_gate: 13.0
      end
      len 16; 4.times { advance }
    end
  end

  # drums
  time_block do
    ch 9
    patch 25
    len 16
    32.times do
      drum :k, velocity: 40
      drum :hc, velocity: 50
      drum :ho, velocity: 70
      drum :hc, velocity: 50
    end
  end
end

host = RbAU.new
host.add_track("SOUND Canvas VA")
host.load_au_preset("sc88pro.aupreset")
host.load_midi_file("#{base_file}.mid")
host.bounce_to_file("#{base_file}.wav")
