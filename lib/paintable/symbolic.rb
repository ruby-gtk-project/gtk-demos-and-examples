require 'gtk4'
require_relative 'nuclear'

# A paintable that follows the theme's colours. GTK calls icons that do this
# symbolic; a paintable joins in by implementing GtkSymbolicPaintable, whose
# snapshot method is handed the palette to draw with.
class NuclearSymbolic < GLib::Object
  type_register
  include Gdk::Paintable
  include Gtk::SymbolicPaintable

  NONE = 0
  ALERT = 1
  EMERGENCY = 2

  TRANSPARENT = Gdk::RGBA.new(0, 0, 0, 0).freeze

  attr_reader :warning_level

  def initialize
    super()
    @warning_level = NONE
  end

  def virtual_do_snapshot_symbolic(snapshot, width, height, colors)
    Nuclear.snapshot(snapshot,
                     colors[Gtk::SymbolicColor::FOREGROUND.to_i],
                     background(colors),
                     width, height, 0)
  end

  # Passing no colours makes GTK fill in the theme's defaults and call the
  # symbolic snapshot above.
  def virtual_do_snapshot(snapshot, width, height)
    snapshot_symbolic(snapshot, width, height, [])
  end

  # Winds the warning up one notch, and back to nothing past the top.
  def escalate
    @warning_level = warning_level >= EMERGENCY ? NONE : warning_level + 1
    invalidate_contents
  end

  private

  def background(colors)
    case warning_level
    when ALERT then colors[Gtk::SymbolicColor::WARNING.to_i]
    when EMERGENCY then colors[Gtk::SymbolicColor::ERROR.to_i]
    else TRANSPARENT
    end
  end
end

class SymbolicPaintableDemo
  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = "Don't click!"
          win.set_default_size(200, 200)
          win.child = button
        end

        button.tap do |btn|
          btn.child = image
          btn.signal_connect('clicked') { press }
        end

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.paintable_symbolic', :default_flags)
  def window = @window ||= Gtk::Window.new
  def button = @button ||= Gtk::Button.new
  def nuclear = @nuclear ||= NuclearSymbolic.new
  def image = @image ||= Gtk::Image.new(paintable: nuclear).tap { |i| i.pixel_size = 256 }

  private

  # At maximum warning the alarm resets, and sometimes — but not always, to
  # keep everyone guessing — the window closes.
  def press
    (nuclear.warning_level >= NuclearSymbolic::EMERGENCY).then do |maxed_out|
      nuclear.escalate
      window.close if maxed_out && [true, false].sample
    end
  end
end

SymbolicPaintableDemo.new.build.run
