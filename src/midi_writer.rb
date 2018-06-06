require 'bin_tools'
class MidiWriter
  attr_reader :events, :ppqn, :tempo

  def initialize(events, ppqn: 96, tempo: 120)
    @events = events
    @tempo = tempo
    @ppqn = ppqn
  end

  def write(fn)
    events.sort! { |a,b| [a[:timestamp], a[:id]] <=> [b[:timestamp], b[:id]] }

    #puts events
    last_t = 0

    #puts map
    progmap = {}
    drummap = {}
    chtmap = {}

    BinTools::Writer.open fn do |f|
      f.write_str "MThd"
      f.write_u32_be 6
      f.write_u16_be 0
      f.write_u16_be 1
      f.write_u16_be ppqn
      f.write_str "MTrk"
      p = f.tell
      f.write_u32_be 0
      s = f.tell
      f.write_varlen_be 0
      f.write_byte 0xFF
      f.write_byte 0x51
      f.write_byte 0x03
      f.write_u24_be (60000000.0 / tempo.to_f).to_i

      (0..15).each do |i|
        f.write_varlen_be 0
        f.write_byte 0xB0 + i
        f.write_byte 0x65
        f.write_byte 0x00

        f.write_varlen_be 0
        f.write_byte 0xB0 + i
        f.write_byte 0x64
        f.write_byte 0x00

        f.write_varlen_be 0
        f.write_byte 0xB0 + i
        f.write_byte 0x06
        f.write_byte 0x0C

        f.write_varlen_be 0
        f.write_byte 0xB0 + i
        f.write_byte 0x38
        f.write_byte 0x00
      end

      events.each do |e|
        ch = e[:channel]

        cc = ch
        cc = 9 if ch == 10 || ch == 11

        case e[:type]
        when :note_off
          cht = chtmap[ch] || [0]
          cht.each do |ct|
            ts = e[:timestamp] - last_t
            last_t = e[:timestamp]
            f.write_varlen_be ts 
            f.write_byte 0x90 + cc
            note = (drummap[ch] && drummap[ch][e[:note]]) || e[:note]
    #      note += 15 if ch == 9
            f.write_byte note + ct
          f.write_byte e[:vel] || 0
          end
        when :note_on
          cht = chtmap[ch] || [0]
          cht.each do |ct|
            ts = e[:timestamp] - last_t
            last_t = e[:timestamp]
            f.write_varlen_be ts 
            f.write_byte 0x90 + cc
            note = (drummap[ch] && drummap[ch][e[:note]]) || e[:note]
      #      note += 15 if ch == 9
            f.write_byte note + ct
          f.write_byte e[:vel]
          end
        when :cc
          unless cc == 9
            ts = e[:timestamp] - last_t
            last_t = e[:timestamp]
            f.write_varlen_be ts 
            f.write_byte 0xB0 + cc
            f.write_byte e[:num]
            f.write_byte e[:val]
          end
        when :program
          ts = e[:timestamp] - last_t
          last_t = e[:timestamp]
          f.write_varlen_be ts 
          f.write_byte 0xC0 + cc
          if cc == 9
            prg = 8
          else
            prg = progmap[e[:program]] || e[:program]
          end
          f.write_byte prg
        when :pitch
          pitch_int = e[:val] + 0x2000
          ts = e[:timestamp] - last_t
          last_t = e[:timestamp]
          f.write_varlen_be ts
          f.write_byte 0xE0 + cc
          f.write_byte pitch_int & 0x7F
          f.write_byte (pitch_int >> 7) & 0x7F
        end
      end
      f.write_varlen_be 0
      f.write_byte 0xFF
      f.write_byte 0x2F
      f.write_byte 0x00
      len = f.tell - s
      f.seek p
      f.write_u32_be len
    end
  end
end
