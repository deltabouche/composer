require './midi_writer'

class MidiBuilder
  attr_reader :events, :timestamp, :note_len, :ppqn, :tempo, :tonic, :octave, :scale, :auto_advance, :channel, :gate, :eid

  NOTE_SHARP = [:c, :c, :d, :ds, :e, :f, :fs, :g, :gs, :a, :as, :b]
  NOTE_FLAT = [:c, :df, :d, :ef, :e, :f, :ff, :g, :gf, :a, :af, :b]
  SCALES = {
    chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    ionian: [0, 2, 4, 5, 7, 9, 11],
    dotian: [0, 2, 3, 5, 7, 9, 10],
    phrygian: [0, 1, 3, 5, 7, 8, 10],
    lydian: [0, 2, 4, 6, 7, 9, 11],
    mixolydian: [0, 2, 4, 5, 7, 9, 10], 
    aeolian: [0, 2, 3, 5, 7, 8, 10],
    locrian: [0, 1, 3, 5, 6, 8, 10]
  }

  DRUM_NOTES = {
    k2: 34,
    k: 36,
    s: 38,
    s2: 40,
    hc: 42,
    hp: 44,
    ho: 46,
    cr: 49
  }

  def base_note(sym_or_num)
    if sym_or_num.is_a? Symbol
      return NOTE_SHARP.index(sym_or_num) if NOTE_SHARP.include?(sym_or_num)
      return NOTE_FLAT.index(sym_or_num) if NOTE_FLAT.include?(sym_or_num)
      raise "Unrecognized base note :#{sym_or_num}"
    elsif sym_or_num.is_a? Integer
      sym_or_num -= 1
      sc = SCALES[scale]
      oct_offset = sym_or_num / sc.size
      num = sym_or_num % sc.size
      return SCALES[scale][num] + oct_offset * 12
    end

    raise "Invalid base note type #{sym_or_num.class.name}"
  end

  def note_with_octave(sym_or_num)
    base_note(sym_or_num) + octave * 12 + tonic
  end


  def initialize(fn = nil, ppqn: 96, tempo: 120, &block)
    @events = []
    @eid = 0
    @timestamp = 0
    @octave = 5
    @tonic = base_note(:c)
    @ppqn = ppqn
    @note_len = ppqn
    @tempo = tempo
    @auto_advance = false
    @scale = :chromatic
    @gate = 1
    @channel = 0
    if block_given?
      instance_eval(&block)
      write(fn) if fn
    end
  end

  def add_event(event)
    @events << event.merge(id: eid)
    @eid += 1
  end

  def time_block(force_len = nil, &block)
    start = tell
    instance_eval(&block)
    len = force_len || tell - start
    seek start
    len
  end

  def group_block(&block)
    advance instance_eval(&block)
  end

  def together_block(&block)
    push_advance = auto_advance
    set_auto_advance false
    instance_eval(&block)
    advance
    @auto_advance = push_advance
  end

  def patch(n, ch: channel)
    add_event(
      timestamp: timestamp,
      channel: ch,
      type: :program,
      program: n
    )
  end

  def ch(val)
    @channel = val
  end

  def len(division, multiplier = 1.0)
    @note_len = (((1.0 / (division.to_f / 4.0)) * ppqn.to_f) * multiplier.to_f).round
  end

  def oct_up(n = 1)
    @octave += n
  end

  def oct_dn(n = 1)
    @octave -= n
  end

  def oct(n)
    @octave = n
  end

  def set_tonic(base)
    @tonic = base_note(base)
  end

  def set_scale(val)
    @scale = val
  end

  def set_gate(gate)
    @gate = gate.to_f
  end

  def set_auto_advance(val = true)
    @auto_advance = val
  end

  def note_full(n, ch: channel, velocity: 127, duration: note_len, off_velocity: 0)
    add_event(
      timestamp: timestamp,
      channel: ch,
      type: :note_on,
      note: n,
      vel: velocity
    )

    add_event(
      timestamp: timestamp + (duration * gate).round,
      channel: ch,
      type: :note_off,
      note: n,
      vel: off_velocity
    )
    advance if auto_advance
  end

  def note(n, modifier = 0, ch: channel, velocity: 127, duration: note_len, off_velocity: 0, oct_offset: 0)
    n, modifier = n if n.is_a? Array
    note_full(note_with_octave(n) + oct_offset * 12 + modifier, ch: ch, velocity: velocity, duration: duration, off_velocity: off_velocity)
  end

  def drum(n, ch: channel, velocity: 127, duration: note_len, off_velocity: 0, oct_offset: 0)
    note_full(drum_n(n), ch: ch, velocity: velocity, duration: duration, off_velocity: off_velocity)
  end

  def seek(position)
    @timestamp = position
  end

  def chromatic
    set_tonic :c
    set_scale :chromatic
  end

  def drum_n drum_note
    DRUM_NOTES[drum_note]
  end

  def advance(duration = note_len)
    @timestamp += duration
  end

  def tell
    timestamp
  end

  def render
    events
  end

  def write(fn)
    MidiWriter.new(events, ppqn: ppqn, tempo: tempo).write(fn)
  end
end
