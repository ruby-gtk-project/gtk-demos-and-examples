require 'gtk4'

class SpinButtonsDemo
  MONTHS = %w[January February March April May June
              July August September October November December].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Spin Buttons'
          win.resizable = false
          win.child = grid
        end

        grid.tap do |g|
          rows.each_with_index do |(label, spin, value_label), row|
            g.attach(label, 0, row, 1, 1)
            g.attach(spin, 1, row, 1, 1)
            g.attach(value_label, 2, row, 1, 1)

            # Gtk::Adjustment#bind_property cannot format the value on the way
            # across, so the label is updated by hand instead.
            spin.adjustment.tap do |adjustment|
              adjustment.signal_connect('value-changed') { value_label.label = format('%g', adjustment.value) }
              value_label.label = format('%g', adjustment.value)
            end
          end

          hex_spin.tap do |spin|
            spin.signal_connect('input') { parse_hex(spin) }
            spin.signal_connect('output') { render(spin, format_hex(spin)) }
          end

          time_spin.tap do |spin|
            spin.signal_connect('input') { parse_time(spin) }
            spin.signal_connect('output') { render(spin, format_time(spin)) }
          end

          month_spin.tap do |spin|
            spin.signal_connect('input') { parse_month(spin) }
            spin.signal_connect('output') { render(spin, MONTHS[spin.adjustment.value.round - 1]) }
          end
        end

        window.present
      end
    end
  end

  INPUT_ERROR = -1

  def app = @app ||= Gtk::Application.new('org.example.spin_buttons', :default_flags)
  def window = @window ||= Gtk::Window.new
  def basic_label = @basic_label ||= value_label
  def hex_label = @hex_label ||= value_label
  def time_label = @time_label ||= value_label
  def month_label = @month_label ||= value_label

  def grid
    @grid ||= Gtk::Grid.new.tap do |g|
      g.row_spacing = 10
      g.column_spacing = 10
      g.margin_start = 10
      g.margin_end = 10
      g.margin_top = 10
      g.margin_bottom = 10
    end
  end

  def basic_spin
    @basic_spin ||= spin(Gtk::Adjustment.new(0, -10_000, 10_000, 0.5, 100, 0), 5).tap do |s|
      s.climb_rate = 1
      s.digits = 2
      s.numeric = true
    end
  end

  def hex_spin
    @hex_spin ||= spin(Gtk::Adjustment.new(0, 0, 255, 1, 16, 0), 4).tap { |s| s.wrap = true }
  end

  def time_spin
    @time_spin ||= spin(Gtk::Adjustment.new(0, 0, 1410, 30, 60, 0), 5).tap { |s| s.wrap = true }
  end

  def month_spin
    @month_spin ||= spin(Gtk::Adjustment.new(1, 1, 12, 1, 5, 0), 9).tap do |s|
      s.wrap = true
      s.update_policy = :if_valid
    end
  end

  def rows
    @rows ||= [
      [mnemonic_label('_Numeric', basic_spin), basic_spin, basic_label],
      [mnemonic_label('_Hexadecimal', hex_spin), hex_spin, hex_label],
      [mnemonic_label('_Time', time_spin), time_spin, time_label],
      [mnemonic_label('_Month', month_spin), month_spin, month_label]
    ]
  end

  private

  def spin(adjustment, width_chars)
    Gtk::SpinButton.new(adjustment, 0, 0).tap { |s| s.width_chars = width_chars }
  end

  def value_label
    Gtk::Label.new.tap do |label|
      label.width_chars = 10
      label.xalign = 1
    end
  end

  def mnemonic_label(text, widget)
    Gtk::Label.new(text).tap do |label|
      label.use_underline = true
      label.xalign = 1
      label.mnemonic_widget = widget
    end
  end

  # The "output" handler only rewrites the entry when the text really changed,
  # so that the caret does not jump around while typing.
  def render(spin, text)
    spin.text = text unless spin.text == text
    true
  end

  def format_hex(spin)
    spin.adjustment.value.then { |value| value.abs < 1e-5 ? '0x00' : format('0x%.2X', value.to_i) }
  end

  def parse_hex(spin)
    Integer(spin.text, 16).then { |value| [true, value.to_f] }
  rescue ArgumentError
    [INPUT_ERROR, 0.0]
  end

  def format_time(spin)
    (spin.adjustment.value / 60.0).then do |hours|
      format('%02d:%02d', hours.floor, ((hours - hours.floor) * 60).round)
    end
  end

  def parse_time(spin)
    spin.text.split(':', 2).then do |parts|
      if parts.size == 2 && parts.all? { |part| part.match?(/\A\d+\z/) } &&
         (0...24).cover?(parts[0].to_i) && (0...60).cover?(parts[1].to_i)
        [true, ((parts[0].to_i * 60) + parts[1].to_i).to_f]
      else
        [INPUT_ERROR, 0.0]
      end
    end
  end

  def parse_month(spin)
    MONTHS.index { |name| name.upcase.start_with?(spin.text.upcase) }.then do |index|
      index ? [true, (index + 1).to_f] : [INPUT_ERROR, 0.0]
    end
  end
end

SpinButtonsDemo.new.build.run
