require 'gtk4'

# Gtk::Fixed can place a child anywhere, and can also hand it an arbitrary
# transform. Here the label spins and pulses, driven by the frame clock.
class FixedTransformationsDemo
  DEGREES_PER_SECOND = 90

  def build
    app.tap do
      app.signal_connect('activate') do
        app.add_window(window)

        window.tap do |win|
          win.title = 'Fixed Layout ‐ Transformations'
          win.set_default_size(400, 300)
          win.child = scrolled_window
        end

        scrolled_window.tap { |sw| sw.child = fixed }

        fixed.tap do |f|
          f.put(label, 0, 0)
          f.add_tick_callback { animate; GLib::Source::CONTINUE }
        end

        @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        window.present
      end
    end
  end

  def app = @app ||= Gtk::Application.new('org.example.fixed2', :default_flags)
  def window = @window ||= Gtk::Window.new
  def scrolled_window = @scrolled_window ||= Gtk::ScrolledWindow.new
  def label = @label ||= Gtk::Label.new('All fixed?')

  # Overflow has to be visible or the spinning label is clipped away.
  def fixed = @fixed ||= Gtk::Fixed.new.tap { |f| f.overflow = :visible }

  private

  def animate
    (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time).then do |seconds|
      fixed.set_child_transform(label, transform(seconds))
    end
  end

  # Move to the centre, spin, pulse, then step back by half the label so it
  # turns about its own middle.
  def transform(seconds)
    Gsk::Transform.new
                  .translate(Graphene::Point.new(fixed.width / 2, fixed.height / 2))
                  .rotate(seconds * DEGREES_PER_SECOND)
                  .then { |t| (2 + Math.sin(seconds * Math::PI)).then { |scale| t.scale(scale, scale) } }
                  .translate(Graphene::Point.new(-label.width / 2.0, -label.height / 2.0))
  end
end

FixedTransformationsDemo.new.build.run
